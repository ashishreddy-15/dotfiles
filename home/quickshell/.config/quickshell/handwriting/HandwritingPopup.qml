import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import "../ui"

// Handwriting input (Super + Shift + W -> `qs ipc call handwriting toggle`).
// A slim strip that opens where the pen last pointed (or under the launcher's search field). While it is open the whole
// pad is mapped onto the strip (Tablet.mapToRect), so the pen can write and also tap the strip's own buttons.
// Write a line; after a short pause (Theme.handwritingPause) the ink is saved as a picture and read by the hw-ocr daemon
// (Handwriting.qml has the protocol); the text appears in the field, where you can correct it.
// Keys: Enter confirms, Shift+Enter submits (types, then presses Enter), Esc cancels, Ctrl+Z undoes, Ctrl+Backspace clears,
// Tab changes what Enter does (type / copy / launcher).
// Continuous mode: each pause delivers the line and clears the ink; the strip takes no keyboard focus (type mode), so the
// text lands in the window you are writing for.
// IPC (target "handwriting"): toggle, open, close, confirm, submit, undo, cancel, pen, continuous(on).
Scope {
    id: root

    readonly property bool open: Handwriting.open

    IpcHandler {
        target: "handwriting"
        function toggle(): void { if (Handwriting.open) Handwriting.cancel(); else Handwriting.open = true }
        function open(): void   { Handwriting.open = true }
        function close(): void  { Handwriting.cancel() }
        function cancel(): void { Handwriting.cancel() }
        // Steps of the closing order (Handwriting.guardScript calls these).
        function shut(): void    { Handwriting.shut() }
        function padback(): void { Handwriting.padback() }
        // Deliver the text (no Enter). Waits for a reading that is under way.
        function confirm(): void { if (root.open) root.request(false) }
        // Deliver the text, then press Enter (the only way the strip presses Enter).
        function submit(): void  { if (root.open) root.request(true) }
        // Undo the last stroke; in continuous mode with no ink, take the last delivered line back.
        function undo(): void    { if (root.open) root.undoAction() }
        // The pen's button: open, or confirm when open.
        function pen(): void     { if (root.open) root.request(false); else Handwriting.open = true }        // continuous("on" | "off" | anything else = toggle)
        function continuous(on: string): void {
            const v = on.toLowerCase()
            root.setContinuous(v === "on" || v === "true" || v === "1" ? true : v === "off" || v === "false" || v === "0" ? false : !Handwriting.continuous)
        }
    }

    // ---- the ink ----
    // strokes: [[ [x, y, pressure, t_ms], ... ], ...] in canvas pixels, the format of ~/handwriting/data/*.json.
    property var strokes: []
    property bool drawing: false
    property real startedAt: 0
    property int revision: 0            // changes with every stroke added, removed or cleared
    property int readRevision: -1       // the revision that was last sent to the daemon
    property int exportedRevision: -1   // the revision the picture and strokes files hold
    readonly property int canvasWidth: Theme.handwritingInkWidth
    readonly property int canvasHeight: Theme.handwritingInkHeight

    // The recipe of the training data (/home/ashish/handwriting/collect.py): a stroke's width follows pressure,
    // and the picture is the ink on white, cropped tight with a margin, at 3x.
    readonly property real padding: 14
    readonly property real exportScale: 3
    function widthFor(p) { return 1.2 + 3.8 * p }
    function mid(a, b) { return [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2] }
    // Draw segment i of a stroke as a smooth curve through the middle of its points.
    function drawSegment(ctx, pts, i) {
        const n = pts.length, p = pts[i]
        ctx.lineWidth = widthFor(p[2])
        if (n === 1) {
            ctx.beginPath(); ctx.arc(p[0], p[1], ctx.lineWidth / 2, 0, Math.PI * 2); ctx.fill()
            return
        }
        const a = i === 0 ? p : mid(pts[i - 1], p), b = i === n - 1 ? p : mid(p, pts[i + 1])
        ctx.beginPath(); ctx.moveTo(a[0], a[1]); ctx.quadraticCurveTo(p[0], p[1], b[0], b[1]); ctx.stroke()
    }
    function drawStrokes(ctx, color) {
        ctx.strokeStyle = color
        ctx.fillStyle = color
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        for (const s of strokes) for (let i = 0; i < s.length; i++) drawSegment(ctx, s, i)
    }

    // ---- reading ----
    property bool reading: false
    property int requestId: -1
    property string error: ""
    property bool again: false          // ink changed while reading: read again when the answer comes
    property bool manual: false         // the text was typed over: later readings do not replace it
    property string waiting: ""         // "confirm" / "submit" pressed while reading: do it when the answer comes

    function resetAll() {
        strokes = []; drawing = false; startedAt = Date.now(); revision = 0; readRevision = -1; exportedRevision = -1
        reading = false; requestId = -1; error = ""; again = false; manual = false; waiting = ""
        field.text = ""
        pause.stop()
        inkCanvas.requestPaint()
    }
    function clearInk() {
        strokes = []; revision++
        pause.stop(); requestId = -1; reading = false; again = false; error = ""
        manual = false; field.text = ""
        inkCanvas.requestPaint()
    }
    function undo() {
        if (drawing || strokes.length === 0) return
        strokes = strokes.slice(0, -1); revision++
        inkCanvas.requestPaint()
        if (strokes.length === 0) { clearInk(); return }
        pause.restart()
    }

    // Undo: the last stroke; with no ink in continuous mode, the last line that was delivered.
    function undoAction() {
        if (drawing) return
        if (strokes.length > 0) undo()
        else if (Handwriting.continuousActive) Handwriting.undoLine()
    }
    function setContinuous(on) {
        if (Handwriting.continuous === on) return
        Handwriting.continuous = on
        Handwriting.lines = []
        if (root.open) field.forceActiveFocus()
    }

    // Save the ink as a picture, then ask the daemon. (Never two at once: the picture file is reused.)
    function readInk() {
        pause.stop()
        if (strokes.length === 0) return
        if (reading) { again = true; return }
        const all = [].concat.apply([], strokes)   // (flat() is not in QML's JavaScript)
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
        for (const p of all) { x0 = Math.min(x0, p[0]); y0 = Math.min(y0, p[1]); x1 = Math.max(x1, p[0]); y1 = Math.max(y1, p[1]) }
        x0 -= padding; y0 -= padding; x1 += padding; y1 += padding
        reading = true
        error = ""
        shot.rev = revision
        shot.originX = x0; shot.originY = y0
        shot.width = Math.ceil((x1 - x0) * exportScale)
        shot.height = Math.ceil((y1 - y0) * exportScale)
        shot.exporting = true
        shot.requestPaint()
    }
    function exported() {
        // The picture is drawn. (Canvas.save() does not work here, so the picture comes out as a data URL and base64
        // turns it into the file.) Keep the strokes beside it for the log, then ask the daemon.
        const url = shot.toDataURL("image/png")
        const comma = url.indexOf(",")
        if (comma < 0) { reading = false; error = "Could not make the ink picture"; return }
        exportedRevision = shot.rev
        strokesFile.setText(JSON.stringify({ version: 1, canvas: { w: canvasWidth, h: canvasHeight }, strokes: strokes }))
        decoder.rev = shot.rev
        decoder.running = true
        decoder.write(url.slice(comma + 1))
        decoder.stdinEnabled = false          // closes its input: base64 sees the end
    }
    Process {
        id: decoder
        property int rev: 0
        stdinEnabled: true
        command: ["sh", "-c", 'base64 -d > "$1"', "sh", Handwriting.pngPath]
        onExited: code => {
            stdinEnabled = true
            if (code !== 0) { root.reading = false; root.error = "Could not save the ink picture"; return }
            root.readRevision = rev
            root.requestId = Handwriting.request(Handwriting.pngPath)
        }
    }
    FileView { id: strokesFile; path: Handwriting.strokesPath; printErrors: false }

    Connections {
        target: Handwriting
        function onRecognised(id, text, ms) {
            if (id !== root.requestId) return
            root.reading = false
            if (!root.manual) field.text = text
            root.next()
        }
        function onFailed(id, message) {
            if (id !== root.requestId) return
            root.reading = false
            root.error = message
            root.again = false
            // Enter was pressed while reading, and reading is not working: use what is in the field.
            if (root.waiting !== "") { const w = root.waiting; root.waiting = ""; if (field.text.trim() !== "") root.finish(w === "submit") }
        }
        function onOpenChanged() {
            if (Handwriting.open) {
                root.resetAll(); Handwriting.warm()
                root.placed = false
                cursor.running = true
            } else {
                root.requestId = -1; pause.stop()
                if (!Handwriting.deferPad) Tablet.restore()     // after typing otherwise (Handwriting.padback)
                ShellState.launcherKeepOpen = false
            }
        }
    }
    Component.onDestruction: { Tablet.restore(); ShellState.launcherKeepOpen = false }

    // After an answer: read again if the ink changed meanwhile, deliver if Enter was waiting, or (continuous) commit the line.
    function next() {
        if (again || (strokes.length > 0 && revision !== readRevision && !drawing)) { again = false; readInk(); return }
        if (waiting !== "") { const w = waiting; waiting = ""; finish(w === "submit"); return }
        if (Handwriting.continuousActive && !drawing && !manual && strokes.length > 0 && revision === readRevision && field.text.trim() !== "")
            finish(false)
    }

    Timer { id: pause; interval: Theme.handwritingPause; onTriggered: root.readInk() }

    // Confirm (enter = false) or submit (enter = true): wait for a reading that is under way or due, then deliver.
    function request(enter) {
        if (drawing || Handwriting.closing) return
        if (strokes.length > 0 && (reading || revision !== readRevision)) {
            waiting = enter ? "submit" : "confirm"
            if (!reading) readInk()
            return
        }
        finish(enter)
    }
    // Deliver what is in the field. Enter is pressed only when `enter` is true (submit).
    function finish(enter) {
        waiting = ""
        const text = field.text.trim()
        const file = strokes.length > 0 && exportedRevision === revision ? Handwriting.strokesPath : ""
        if (Handwriting.continuousActive) {
            if (text !== "") {
                Handwriting.commitLine(text, file, enter)
                clearInk()
                if (enter) Handwriting.cancel()
            } else if (enter) Handwriting.closeAndEnter()
            else Handwriting.cancel()          // nothing new to flush: the strip is done
            return
        }
        if (text === "") return
        Handwriting.confirm(text, file, enter)
    }

    // The picture for the daemon (white and black, as in the training data): not shown, painted on its own canvas and saved to a file.
    Canvas {
        id: shot
        parent: card
        visible: true
        opacity: 0
        renderStrategy: Canvas.Immediate
        renderTarget: Canvas.Image
        property bool exporting: false
        property int rev: 0
        property real originX: 0
        property real originY: 0
        onPaint: {
            if (!exporting) return
            const ctx = getContext("2d")
            ctx.setTransform(1, 0, 0, 1, 0, 0)
            ctx.fillStyle = "white"
            ctx.fillRect(0, 0, width, height)
            ctx.setTransform(root.exportScale, 0, 0, root.exportScale, -originX * root.exportScale, -originY * root.exportScale)
            root.drawStrokes(ctx, "black")
            saveSoon.restart()
        }
        // The picture is complete a moment after onPaint returns. (`painted` is not sent for an item that is not drawn.)
        Timer { id: saveSoon; interval: 20; onTriggered: if (shot.exporting) { shot.exporting = false; root.exported() } }
    }

    // ---- where the strip goes ----
    // At the pen's last position (the cursor), just below it; above it if there is no room; kept on the screen. When the
    // launcher is showing, directly under its search field (ShellState.launcherSearchRect, screen-local logical px).
    readonly property int inset: Theme.pad
    readonly property int rowHeight: Theme.handwritingButton
    readonly property int cardWidth: Theme.handwritingInkWidth + 2 * inset
    readonly property int cardHeight: inset + Theme.handwritingInkHeight + inset + rowHeight + inset
    property var placeScreen: null
    property real cardX: 0              // the card's top-left on placeScreen, logical px
    property real cardY: 0
    property bool placed: false
    property bool docked: false
    readonly property bool focusNone: Handwriting.continuousActive && Handwriting.deliver === "type"

    Process {
        id: cursor
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector { onStreamFinished: root.place(text) }
    }
    function place(text) {
        if (!root.open) return          // closed while the cursor was being looked up: do not map the pad
        let cx = NaN, cy = NaN
        try { const c = JSON.parse(text); cx = c.x; cy = c.y } catch (e) { /* no cursor: centre it */ }
        const dock = ShellState.launcherSearchRect
        const screens = Quickshell.screens
        const dockScreen = dock && dock.visible ? screens.find(s => s.name === dock.screen) : undefined
        let scr = null, x = 0, y = 0
        docked = false
        if (dockScreen) {
            scr = dockScreen
            docked = true
            x = dock.x + dock.w / 2 - cardWidth / 2
            y = dock.y + dock.h + Theme.pad
        } else {
            scr = screens.find(s => cx >= s.x && cx < s.x + s.width && cy >= s.y && cy < s.y + s.height)
                  ?? screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? ShellState.mainScreen
            if (isNaN(cx)) { x = (scr.width - cardWidth) / 2; y = (scr.height - cardHeight) / 2 }
            else {
                const lx = cx - scr.x, ly = cy - scr.y
                x = lx - cardWidth / 2
                y = ly + Theme.handwritingGap
                if (y + cardHeight > scr.height - Theme.pad) y = ly - Theme.handwritingGap - cardHeight
            }
        }
        const top = Theme.barHeight + Theme.pad
        x = Math.max(Theme.pad, Math.min(x, scr.width - cardWidth - Theme.pad))
        y = Math.max(top, Math.min(y, scr.height - cardHeight - Theme.pad))
        placeScreen = scr; cardX = Math.round(x); cardY = Math.round(y)
        placed = true
        ShellState.launcherKeepOpen = docked
        Tablet.mapToRect(scr.name, cardX, cardY, cardWidth, cardHeight)
        field.forceActiveFocus()
    }

    PanelWindow {
        id: win

        screen: root.placeScreen ?? ShellState.mainScreen
        visible: (root.open && root.placed) || card.shown > 0

        anchors { top: true; left: true }
        margins { left: root.cardX - Theme.shadowMargin; top: root.cardY - Theme.shadowMargin }
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: card.width + 2 * Theme.shadowMargin
        implicitHeight: root.cardHeight + 2 * Theme.shadowMargin
        color: "transparent"
        mask: Region { item: card }
        WlrLayershell.namespace: "quickshell-handwriting"
        WlrLayershell.layer: WlrLayer.Overlay
        // Continuous typing: no keyboard focus, so the target window keeps it and wtype types into it.
        WlrLayershell.keyboardFocus: root.open && !root.focusNone ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            // Only once the window is placed and shown: a grab on a window not yet mapped is cleared at once.
            active: root.open && root.placed && !root.docked && !root.focusNone
            windows: [win]
            onCleared: Handwriting.open = false
        }

        Card {
            id: card
            x: Theme.shadowMargin
            y: Theme.shadowMargin
            width: root.cardWidth
            open: root.open && root.placed
            contentHeight: root.cardHeight

            // ---- the writing area ----
            Rectangle {
                x: root.inset; y: root.inset
                width: Theme.handwritingInkWidth
                height: Theme.handwritingInkHeight
                radius: Theme.radiusRow
                color: Theme.hover
                border.width: 1
                border.color: Theme.border

                Canvas {
                    id: inkCanvas
                    anchors.fill: parent
                    anchors.margins: 1
                    renderTarget: Canvas.Image
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        root.drawStrokes(ctx, Theme.bright)
                    }
                    Connections { target: Theme; function onDarkChanged() { inkCanvas.requestPaint() } }
                }

                StyledText {
                    visible: root.strokes.length === 0
                    anchors.centerIn: parent
                    text: Handwriting.continuousActive ? "Write: each pause enters the line" : Tablet.present ? "Write with the pen" : "Write here"
                    color: Theme.dim
                }

                // Pen (pressure), and the mouse for trying it without a tablet.
                PointHandler {
                    id: pen
                    acceptedDevices: PointerDevice.Stylus | PointerDevice.Mouse | PointerDevice.TouchPad
                    onActiveChanged: {
                        if (active) {
                            root.drawing = true
                            pause.stop()
                            root.strokes = root.strokes.concat([[]])
                        } else if (root.drawing) {
                            root.drawing = false
                            root.revision++
                            inkCanvas.requestPaint()
                            pause.restart()
                        }
                    }
                    onPointChanged: {
                        if (!active || !root.drawing) return
                        const pos = point.position
                        const stylus = point.device.type === PointerDevice.Stylus
                        const pressure = stylus && point.pressure > 0 ? Math.min(1, point.pressure) : 0.5
                        const s = root.strokes[root.strokes.length - 1]
                        const last = s[s.length - 1]
                        const x = Math.round(pos.x * 10) / 10, y = Math.round(pos.y * 10) / 10
                        if (last && last[0] === x && last[1] === y) return
                        s.push([x, y, Math.round(pressure * 1000) / 1000, Date.now() - root.startedAt])
                        inkCanvas.requestPaint()
                    }
                }
            }

            // ---- the text and the buttons ----
            component Button: Rectangle {
                id: btn
                property alias label: txt.text
                property bool lit: false
                signal clicked()
                width: txt.implicitWidth + 2 * Theme.padContent
                height: root.rowHeight
                radius: Theme.radiusRow
                color: area.pressed ? Theme.selectedHover : lit ? Theme.selected : area.containsMouse ? Theme.selected : Theme.hover
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
                StyledText { id: txt; anchors.centerIn: parent; color: Theme.bright }
                MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
            }

            Row {
                x: root.inset
                y: root.inset + Theme.handwritingInkHeight + root.inset
                width: Theme.handwritingInkWidth
                spacing: Theme.pad - 4

                Rectangle {
                    width: parent.width - buttons.width - parent.spacing
                    height: root.rowHeight
                    radius: Theme.radiusRow
                    color: Theme.clear
                    border.width: 1
                    border.color: field.activeFocus ? Theme.accent : Theme.border

                    TextInput {
                        id: field
                        anchors { fill: parent; leftMargin: Theme.padContent - 2; rightMargin: Theme.padContent - 2 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.bright
                        selectionColor: Theme.border
                        selectedTextColor: Theme.bright
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontXL
                        clip: true
                        onTextEdited: root.manual = true

                        Keys.onPressed: event => {
                            const ctrl = event.modifiers & Qt.ControlModifier
                            if (event.key === Qt.Key_Escape) Handwriting.cancel()
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.request(!!(event.modifiers & Qt.ShiftModifier))
                            else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) Handwriting.cycleDeliver()
                            else if (ctrl && event.key === Qt.Key_Z) root.undoAction()
                            else if (ctrl && event.key === Qt.Key_Backspace) root.clearInk()
                            else return
                            event.accepted = true
                        }

                        StyledText {
                            id: placeholder
                            visible: field.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            elide: Text.ElideRight
                            text: root.error !== "" ? root.error : root.reading ? "reading..." : "Text appears here"
                            color: root.error !== "" ? Theme.err : Theme.dim
                            font.pixelSize: Theme.fontXL
                            SequentialAnimation on opacity {
                                running: root.reading
                                loops: Animation.Infinite
                                onRunningChanged: if (!running) placeholder.opacity = 1
                                NumberAnimation { to: 0.4; duration: Theme.durAmbient * 2; easing.type: Theme.easeInOut }
                                NumberAnimation { to: 1; duration: Theme.durAmbient * 2; easing.type: Theme.easeInOut }
                            }
                        }
                    }
                    // While a new reading replaces text that is already there.
                    StyledText {
                        visible: root.reading && field.text !== ""
                        anchors { right: parent.right; rightMargin: Theme.padContent - 2; verticalCenter: parent.verticalCenter }
                        text: "reading..."
                        color: Theme.dim
                        font.pixelSize: Theme.fontSmall
                    }
                }

                Row {
                    id: buttons
                    spacing: Theme.pad - 4
                    Button { label: "Undo"; onClicked: root.undoAction() }
                    Button { label: "Continuous"; lit: Handwriting.continuous; onClicked: root.setContinuous(!Handwriting.continuous) }
                    Button { label: Handwriting.deliverLabel(Handwriting.deliver); onClicked: { Handwriting.cycleDeliver(); if (root.open) field.forceActiveFocus() } }
                    Button { label: "Cancel"; onClicked: Handwriting.cancel() }
                    Button { label: "Confirm"; lit: true; onClicked: root.request(false) }
                }
            }
        }
    }
}

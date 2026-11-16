pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Handwriting input: the settings, the link to the recognition daemon (hw-ocr), and what happens to the text.
// The popup itself is handwriting/HandwritingPopup.qml (Super + Shift + W, `qs ipc call handwriting toggle`).
//
// Settings, kept in ~/.local/state/dotfiles/handwriting.json (Settings > Tablet > Handwriting):
//   deliver   "type"      type the text into the window that was focused before the popup (wtype)
//             "copy"      only put it on the clipboard
//             "launcher"  open the launcher with the text typed into its search field
//   log       (property: logging) keep each confirmed line (ink picture, strokes, final text) in ~/handwriting/usage, to retrain the model
//   continuous (property: continuousDefault) each pause commits the line to the target and keeps the strip open
//   lineEnd   "space" | "newline": what follows each continuous line (newline presses Return: opt-in)
// While the strip is open the flag file $XDG_RUNTIME_DIR/hw-popup-open exists (tablet-keys checks it).
//
// Daemon protocol: unix socket $XDG_RUNTIME_DIR/hw-ocr.sock. One line in (`warm`, or the absolute path of a PNG),
// one JSON line out (`{"ok":true}`, `{"text":"...","ms":N}` or `{"error":"..."}`).
Singleton {
    id: root

    property bool open: false
    property string deliver: "type"
    property bool logging: true
    property bool continuousDefault: false
    property string lineEnd: "space"
    property bool continuous: false         // this session's switch (starts from continuousDefault at every open)
    readonly property bool continuousActive: continuous && deliver !== "launcher"
    property var lines: []                  // continuous mode: what was committed this session, [{ text, deliver, nl }]
    readonly property var lineEnds: [ { label: "Space", value: "space" }, { label: "Newline", value: "newline" } ]
    readonly property var deliverModes: [
        { label: "Type", value: "type" },
        { label: "Copy", value: "copy" },
        { label: "Launcher", value: "launcher" }
    ]
    function deliverLabel(mode) { return (deliverModes.find(m => m.value === mode) ?? deliverModes[0]).label }
    function cycleDeliver() {
        const i = deliverModes.findIndex(m => m.value === deliver)
        set("deliver", deliverModes[(i + 1) % deliverModes.length].value)
    }

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string socketPath: runtimeDir + "/hw-ocr.sock"
    // Where the popup puts the ink it sends (a picture and the strokes), and what the log helper copies from.
    readonly property string pngPath: runtimeDir + "/hw-ink.png"
    readonly property string strokesPath: runtimeDir + "/hw-ink.json"
    readonly property string logHelper: Quickshell.env("HOME") + "/.local/bin/handwriting-log"

    // ---- settings on disk ----
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/dotfiles/handwriting.json"
    FileView { id: saved; path: root.stateFile; blockLoading: true; printErrors: false }
    Process {
        id: writer
        property string json
        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", root.stateFile, json]
    }
    function set(key, value) {
        root[key] = value
        writer.json = JSON.stringify({ deliver: deliver, log: logging, continuous: continuousDefault, lineEnd: lineEnd })
        writer.running = true
    }
    // ---- the flag file ----
    readonly property string flagPath: runtimeDir + "/hw-popup-open"
    onOpenChanged: {
        Quickshell.execDetached(["sh", "-c", root.open ? 'touch "$1"' : 'rm -f "$1"', "sh", flagPath])
        closing = false
        if (open) { lines = []; continuous = continuousDefault; targetAddress = ""; targetCursor = ""; target.running = true }
    }

    // ---- the window the text is for ----
    // The window focused when the strip opened, and where the pointer was. While the strip is open the pad covers the
    // strip, which may lie over another window; Hyprland's focus-follows-mouse would then hand focus to whatever window
    // the pen is over when the strip closes. So typing pauses follow_mouse, focuses this window, types, puts the pointer
    // back over it, and turns follow_mouse back on (guarded()).
    property string targetAddress: ""
    property string targetCursor: ""        // "x, y" as `hyprctl cursorpos` prints it
    Process {
        id: target
        command: ["sh", "-c", 'hyprctl -j activewindow | tr -d "\\n"; echo; hyprctl cursorpos']
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("\n")
                try { root.targetAddress = JSON.parse(parts[0]).address ?? "" } catch (e) { root.targetAddress = "" }
                root.targetCursor = (parts[1] ?? "").trim()
            }
        }
    }
    // Delivering text, and closing the strip, in one fixed order (guardScript), so the pointer and the focus do not jump:
    //   1. pause focus-follows-mouse and pointer warps (Hyprland's focus dispatcher otherwise moves the pointer to the
    //      middle of the window it focuses: cursor:no_warps);
    //   2. close the strip (`handwriting shut`), when closing;
    //   3. focus the window the text is for; 4. type; 5. give the pad back to the whole screen (`handwriting padback`);
    //   6. put the two settings back (always, also when a step fails). One at a time (flock), so two runs cannot
    //      take each other's paused values for the real ones.
    readonly property string guardScript:
        'a="$1"; close="$2"; shift 2; ' +
        'exec 9>"${XDG_RUNTIME_DIR:-/tmp}/hw-guard.lock"; flock 9; ' +
        'fm=$(hyprctl getoption input:follow_mouse | sed -n "s/^int: //p"); nw=$(hyprctl getoption cursor:no_warps | sed -n "s/^bool: //p"); ' +
        'back() { hyprctl eval "hl.config({ input = { follow_mouse = ${fm:-1} }, cursor = { no_warps = ${nw:-false} } })" >/dev/null; }; ' +
        'trap back EXIT; ' +
        'hyprctl eval "hl.config({ input = { follow_mouse = 0 }, cursor = { no_warps = true } })" >/dev/null; ' +
        'if [ "$close" = 1 ]; then qs ipc call handwriting shut >/dev/null; sleep 0.2; fi; ' +
        '[ -n "$a" ] && hyprctl dispatch "hl.dsp.focus({ window = \\"address:$a\\" })" >/dev/null; ' +
        '"$@"; ' +
        'if [ "$close" = 1 ]; then qs ipc call handwriting padback >/dev/null; fi'
    // Run a typing command (argv) aimed at the target window, the strip staying open (continuous mode).
    function guarded(argv) { Quickshell.execDetached(["sh", "-c", guardScript, "sh", targetAddress, "0"].concat(argv)) }
    // Close the strip, then run argv (typing, or ["true"] for nothing) aimed at the target window.
    property bool closing: false            // a close is under way: further confirms are ignored
    property bool deferPad: false           // the strip closed, the pad goes back after the typing (padback)
    function closeWith(argv) {
        if (!open || closing) return
        closing = true
        Quickshell.execDetached(["sh", "-c", guardScript, "sh", targetAddress, "1"].concat(argv))
    }
    function shut() { deferPad = true; padGuard.restart(); open = false }
    function padback() { padGuard.stop(); deferPad = false; if (!open) Tablet.restore() }
    Timer { id: padGuard; interval: 4000; onTriggered: root.padback() }     // the script died: do not leave the pad on the strip
    // Close without delivering anything; focus goes back to the window you came from.
    function cancel() {
        if (!open) return
        if (deliver === "launcher" || ShellState.launcherKeepOpen) open = false      // the launcher keeps the focus
        else closeWith(["true"])
    }
    Component.onDestruction: Quickshell.execDetached(["rm", "-f", flagPath])

    Component.onCompleted: {
        Quickshell.execDetached(["rm", "-f", flagPath])      // left over from a crashed shell
        try {
            const d = JSON.parse(saved.text())
            if (deliverModes.some(m => m.value === d.deliver)) deliver = d.deliver
            if (d.log !== undefined) logging = !!d.log
            if (d.continuous !== undefined) continuousDefault = !!d.continuous
            if (d.lineEnd === "space" || d.lineEnd === "newline") lineEnd = d.lineEnd
        } catch (e) { /* first run: the defaults */ }
    }

    // ---- the daemon ----
    // Each request gets its own short-lived connection, so a `warm` and a reading never get in each other's way.
    // `recognised(id, text)` or `failed(id, message)` answers request(); warm() needs no answer.
    property int lastId: 0
    signal recognised(int id, string text, int ms)
    signal failed(int id, string message)

    readonly property string notRunning: "The hw-ocr daemon is not running (start it, or run ./install.sh to set it up)"

    function warm() { send("warm") }
    function request(png: string): int { lastId += 1; send(png, lastId); return lastId }

    function send(line, id) {
        link.createObject(root, { path: socketPath, line: line, reqId: id ?? 0 })
    }
    Component {
        id: link
        Socket {
            id: sock
            property string line
            property int reqId: 0
            property bool answered: false
            connected: true

            // Answers are sent a moment later: a refused connection is reported while the socket is still being
            // created, before request() has returned the id.
            function finish(text, ms, error) {
                if (answered) return
                answered = true
                Qt.callLater(() => {
                    if (reqId > 0) { if (error) root.failed(reqId, error); else root.recognised(reqId, text, ms) }
                    connected = false
                    sock.destroy(100)
                })
            }
            onConnectedChanged: if (connected) { write(line + "\n"); flush() }
            parser: SplitParser {
                onRead: data => {
                    try {
                        const r = JSON.parse(data)
                        if (r.error) sock.finish("", 0, String(r.error))
                        else sock.finish(r.text ?? "", r.ms ?? 0, "")
                    } catch (e) { sock.finish("", 0, "Unreadable reply from hw-ocr") }
                }
            }
            onError: sock.finish("", 0, root.notRunning)
            // Closed without an answer.
            onConnectionStateChanged: if (!connected && !answered) sock.finish("", 0, "hw-ocr closed the connection without an answer")
            // A daemon that hangs (model still loading on a slow disk) should not leave "reading..." for ever.
            property Timer guard: Timer { running: true; interval: 30000; onTriggered: sock.finish("", 0, "hw-ocr did not answer in 30 s") }
        }
    }

    // ---- what happens to the text ----
    // Typing needs the previous window to have focus again: the popup is closed first (the caller sets open = false).
    readonly property string typeScript:
        'if command -v wtype >/dev/null; then wtype -- "$1"; [ "$2" = 1 ] && wtype -k Return; ' +
        'else wl-copy -- "$1"; notify-send -a Handwriting "Copied (wtype is not installed)" "$1"; fi; true'

    function logLine(text, strokesFile) {
        if (logging && strokesFile) Quickshell.execDetached([logHelper, pngPath, strokesFile, text])
    }

    // One line, strip closed afterwards. enter = press Return after it (submit); only submit ever does.
    function confirm(text, strokesFile, enter) {
        if (text === "") { cancel(); return }
        logLine(text, strokesFile)
        if (deliver === "copy") { Quickshell.execDetached(["wl-copy", "--", text]); closeWith(["true"]) }
        else if (deliver === "launcher") {
            open = false
            Quickshell.execDetached(["qs", "ipc", "call", "launcher", "search", text])
            if (enter) launcherEnter.restart()
        }
        else closeWith(["sh", "-c", typeScript, "sh", text, enter ? "1" : "0"])
    }
    // Submit with nothing new to deliver: close, then press Return in the window that gets focus back.
    function closeAndEnter() {
        if (deliver === "type") closeWith(["wtype", "-k", "Return"])
        else if (deliver === "launcher") { open = false; launcherEnter.restart() }
        else cancel()
    }
    Timer { id: launcherEnter; interval: 250; onTriggered: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "activate"]) }

    // Continuous mode (the strip keeps keyboard focus off the target, so typing is immediate).
    function commitLine(text, strokesFile, enter) {
        const nl = lineEnd === "newline"
        logLine(text, strokesFile)
        lines = lines.concat([{ text: text, deliver: deliver, nl: nl }])
        if (deliver === "copy") copyLines()
        else root.guarded(["sh", "-c",
            'if command -v wtype >/dev/null; then wtype -- "$1"; [ "$2" = 1 ] && wtype -k Return; else wl-copy -- "$1"; fi',
            "sh", enter || nl ? text : text + " ", enter || (nl && deliver === "type") ? "1" : "0"])
    }
    function copyLines() {
        if (lines.length === 0) Quickshell.execDetached(["wl-copy", "--clear"])
        else Quickshell.execDetached(["wl-copy", "--", lines.map(l => l.text).join(lineEnd === "newline" ? "\n" : " ")])
    }
    // Remove the last committed line from the target again.
    function undoLine() {
        if (lines.length === 0) return false
        const last = lines[lines.length - 1]
        lines = lines.slice(0, -1)
        if (last.deliver === "copy") { copyLines(); return true }
        const n = Array.from(last.text).length + 1       // the text and its space or newline
        const args = ["wtype"]
        for (let i = 0; i < n; i++) args.push("-k", "BackSpace")
        guarded(args)
        return true
    }
}

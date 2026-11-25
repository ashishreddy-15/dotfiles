import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs

// Wallpaper: one background-layer window per monitor, cross-fading when the image changes.
//   Settings > Wallpaper             pick one (a grid of thumbnails)
//   qs ipc call wallpaper next       cycle
//   qs ipc call wallpaper set <path> use any image file
//
// Images are listed from ~/.local/share/wallpapers (downloaded by ./install.sh wallpapers),
// ~/Pictures/Wallpapers (put your own images there) and any folder added in Settings > Wallpaper, all searched
// recursively. The choice is remembered in ~/.local/state/dotfiles/wallpaper, the added folders in
// ~/.local/state/dotfiles/wallpaper-folders (one path per line).
Scope {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateFile: home + "/.local/state/dotfiles/wallpaper"

    readonly property var builtinFolders: [home + "/.local/share/wallpapers", home + "/Pictures/Wallpapers"]
    property var folders: []        // folders added in Settings
    readonly property string foldersFile: home + "/.local/state/dotfiles/wallpaper-folders"
    property var files: []          // every image found, sorted
    property string current: ""     // absolute path of the wallpaper in use

    // ---- remember the choice ----
    FileView {
        id: saved
        path: root.stateFile
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: savedFolders
        path: root.foldersFile
        blockLoading: true
        printErrors: false
    }
    Process {
        id: foldersWriter
        property string value
        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", root.foldersFile, value]
    }
    function setFolders(list) {
        folders = list
        ShellState.wallpaperFolders = list
        foldersWriter.value = list.map(f => f + "\n").join("")
        foldersWriter.running = true
        rescan()
    }

    // The folder dialog (zenity, themed through ~/.config/gtk-4.0/gtk.css like the other GTK4 apps). Cancelling prints nothing.
    Process {
        id: chooser
        command: ["zenity", "--file-selection", "--directory", "--title=Add a wallpaper folder", "--filename=" + root.home + "/Pictures/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const dir = text.trim().replace(/\/+$/, "")
                if (dir !== "" && !root.builtinFolders.includes(dir) && !root.folders.includes(dir)) root.setFolders(root.folders.concat([dir]))
            }
        }
    }

    Process {
        id: save
        property string value
        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", root.stateFile, value]
    }

    // ---- brightness of the top edge (decides whether the bar needs a background) ----
    // Cached beside the state file (`<path>\t<luminance>`) so restarting with the same wallpaper skips python3 + Pillow.
    readonly property string lumFile: home + "/.local/state/dotfiles/wallpaper-luminance"
    property string cachedLumPath: ""
    property real cachedLumValue: 0
    FileView {
        id: savedLum
        path: root.lumFile
        blockLoading: true
        printErrors: false
    }
    Process {
        id: measure
        property string image
        // Mean brightness of the top 12% of the image, 0-255. Pillow is already needed by the generator.
        command: ["python3", "-I", "-c",
            "import os, sys\nfrom PIL import Image\n" +
            "img, cache = sys.argv[1], sys.argv[2]\n" +
            "im = Image.open(img); im.draft('L', (800, 800)); im = im.convert('L')\n" +
            "w, h = im.size; px = list(im.crop((0, 0, w, max(1, round(h * 0.12)))).resize((64, 4)).getdata())\n" +
            "lum = sum(px) / len(px)\n" +
            "os.makedirs(os.path.dirname(cache), exist_ok=True)\n" +
            "open(cache + '.tmp', 'w').write(f'{img}\\t{lum}\\n'); os.replace(cache + '.tmp', cache)\n" +
            "print(lum)", image, root.lumFile]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(text) || 0
                root.cachedLumPath = measure.image
                root.cachedLumValue = v
                ShellState.topLuminance = v
            }
        }
    }
    onFilesChanged: ShellState.wallpaperFiles = files
    Connections {
        target: ShellState
        function onWallpaperChosen(path) { root.set(path) }
        function onWallpaperAddFolder() { if (!chooser.running) chooser.running = true }
        function onWallpaperRemoveFolder(path) { root.setFolders(root.folders.filter(f => f !== path)) }
    }
    // The lock screen shows the same wallpaper: hyprlock.conf includes this one-line file (`source = ...`).
    readonly property string lockFile: home + "/.local/state/dotfiles/hyprlock-wallpaper.conf"
    property string lastLock: ""
    FileView {
        id: savedLock
        path: root.lockFile
        blockLoading: true
        printErrors: false
    }
    Process {
        id: lockWriter
        property string value
        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf \'$wallpaper = %s\\n\' "$2" > "$1"', "sh", root.lockFile, value]
    }

    onCurrentChanged: {
        ShellState.wallpaperCurrent = current
        if (current !== "") {
            const wantLock = "$wallpaper = " + current
            if (lastLock !== wantLock) { lastLock = wantLock; lockWriter.value = current; lockWriter.running = true }
            if (cachedLumPath === current) ShellState.topLuminance = cachedLumValue
            else { measure.image = current; measure.running = true }
        }
    }

    function set(path) {
        if (!path || path === current) return
        current = path
        save.value = path
        save.running = true
    }

    property bool pendingNext: false
    function next() {
        if (files.length === 0) { pendingNext = true; rescan(); return }
        const i = files.indexOf(current)
        set(files[(i + 1) % files.length])
    }

    // ---- thumbnails for Settings ----
    // 640 px wide copies in ~/.cache/dotfiles/wallpaper-thumbs, named by the md5 of the image's path. Only missing or
    // outdated ones are made (Pillow, JPEG draft mode: fast), and ones for images that are gone are deleted.
    readonly property string thumbDir: home + "/.cache/dotfiles/wallpaper-thumbs"
    Process {
        id: thumbs
        property var images: []
        command: ["python3", "-I", "-c",
            "import sys, os, hashlib\nfrom PIL import Image\n" +
            "d = sys.argv[1]; os.makedirs(d, exist_ok=True); keep = set()\n" +
            "for p in sys.argv[2:]:\n" +
            "    k = hashlib.md5(p.encode()).hexdigest() + '.jpg'; keep.add(k); t = os.path.join(d, k)\n" +
            "    try:\n" +
            "        if os.path.getmtime(t) >= os.path.getmtime(p): continue\n" +
            "    except OSError: pass\n" +
            "    try:\n" +
            "        im = Image.open(p); im.draft('RGB', (1280, 1280)); im = im.convert('RGB'); im.thumbnail((640, 640))\n" +
            "        im.save(t + '.tmp', 'JPEG', quality=85); os.replace(t + '.tmp', t)\n" +
            "    except Exception: pass\n" +
            "for f in os.listdir(d):\n" +
            "    if f.endswith('.jpg') and f not in keep: os.remove(os.path.join(d, f))\n" +
            "print('ok')", root.thumbDir].concat(images)
        stdout: StdioCollector { onStreamFinished: ShellState.wallpaperThumbsReady = text.trim() === "ok" }
    }

    // ---- find images ----
    // Every image under the built-in and added folders, at any depth. The folders are passed as arguments, not put
    // into the shell text, so any characters in a name are safe. A new scan waits for a running one to finish.
    property bool rescanPending: false
    function rescan() {
        if (scan.running) { rescanPending = true; return }
        scan.command = ["sh", "-c",
            'find "$@" -type f \\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \\) 2>/dev/null | sort -u',
            "sh"].concat(builtinFolders, folders)
        scan.running = true
    }
    Process {
        id: scan
        onExited: if (root.rescanPending) { root.rescanPending = false; root.rescan() }
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = text.split("\n").filter(l => l !== "")
                if (root.files.length > 0 && ShellState.settingsOpen && ShellState.settingsSection === "wallpaper" && !thumbs.running) {
                    thumbs.images = root.files; thumbs.running = true
                }
                // Nothing remembered (or the file is gone): use the first one.
                if (root.files.length > 0 && !root.files.includes(root.current)) root.current = root.files[0]
                if (root.pendingNext && root.files.length > 0) { root.pendingNext = false; root.next() }
            }
        }
    }

    Component.onCompleted: {
        ShellState.wallpaperThumbDir = thumbDir
        ShellState.wallpaperBuiltinFolders = builtinFolders
        const lumLine = savedLum.text().trim()
        const tab = lumLine.indexOf("\t")
        if (tab > 0) { cachedLumPath = lumLine.slice(0, tab); cachedLumValue = parseFloat(lumLine.slice(tab + 1)) || 0 }
        lastLock = savedLock.text().trim()
        try { current = saved.text().trim() } catch (e) { current = "" }
        folders = savedFolders.text().split("\n").filter(l => l !== "")
        ShellState.wallpaperFolders = folders
        // Defer scanning & thumbnail generation until Settings > Wallpaper opens (or first run with no saved wallpaper).
        if (current === "") rescan()
    }

    IpcHandler {
        target: "wallpaper"
        function next(): void { root.next() }
        function set(path: string): void { root.set(path) }
    }

    // Look for new images and update thumbnails only when Settings > Wallpaper is showing.
    function maybeRescan() {
        if (ShellState.settingsOpen && ShellState.settingsSection === "wallpaper") rescan()
    }
    Connections {
        target: ShellState
        function onSettingsOpenChanged() { root.maybeRescan() }
        function onSettingsSectionChanged() { root.maybeRescan() }
    }

    // ---- the wallpaper itself ----
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.bg                          // shown until the first image is ready
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell-wallpaper"

            // Two images take turns being on top, so a change cross-fades instead of flashing.
            property bool frontIsA: true
            // True while the front image is still fading in; the one behind it stays fully opaque until then.
            readonly property bool fading: (frontIsA ? picA : picB).opacity < 1

            component Pic: Image {
                required property bool isA
                readonly property bool front: win.frontIsA === isA
                anchors.fill: parent
                asynchronous: true
                cache: false                       // a regenerated file must not be shown from an old copy
                fillMode: Image.PreserveAspectCrop
                // Decode at screen size, not at the file's (possibly huge) size.
                // Both sides, so a tall image is not decoded smaller than the screen.
                sourceSize.width: Math.round(win.modelData.width * win.modelData.devicePixelRatio)
                sourceSize.height: Math.round(win.modelData.height * win.modelData.devicePixelRatio)
                // Only the incoming image fades: it fades in on top while the outgoing one stays fully opaque
                // underneath. (Fading both at once showed the background through two half-transparent images:
                // the screen dimmed by a quarter halfway through every change.)
                z: front ? 1 : 0
                opacity: front || win.fading ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.durAmbient; easing.type: Theme.easeInOut } }
                // Release the old full-resolution texture once it has gone (it drops to 0 hidden behind the new one).
                onOpacityChanged: if (opacity === 0 && !front && String(source) !== "") source = ""
                // When the one that was loading in the back is ready, bring it to the front.
                onStatusChanged: if (status === Image.Ready && !front) win.frontIsA = isA
            }
            Pic { id: picA; isA: true }
            Pic { id: picB; isA: false }

            function show() {
                if (root.current === "") return
                const url = "file://" + root.current
                const back = frontIsA ? picB : picA
                if (String(back.source) === url) {
                    // The hidden image already holds this picture (switching back and forth):
                    // it will not report "loaded" again, so bring it to the front directly.
                    if (back.status === Image.Ready) frontIsA = (back === picA)
                } else {
                    back.source = url       // brought to the front by onStatusChanged once it has loaded
                }
            }
            Component.onCompleted: show()
            Connections { target: root; function onCurrentChanged() { win.show() } }

            // The bar has no background of its own: darken the top edge a little under light text, or
            // whiten it a little under dark text (see Theme.barOnLight), so the bar stays readable on
            // mid-tone images. Barely visible on very dark or very light ones.
            Rectangle {
                z: 2                                 // above both images
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 90
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Theme.barOnLight ? Qt.rgba(1, 1, 1, Theme.wallpaperScrimLight) : Qt.rgba(0, 0, 0, Theme.wallpaperScrim)
                        Behavior on color { ColorAnimation { duration: Theme.durAmbient } }
                    }
                    GradientStop {
                        position: 1
                        color: Theme.barOnLight ? Qt.rgba(1, 1, 1, 0) : Qt.rgba(0, 0, 0, 0)
                        Behavior on color { ColorAnimation { duration: Theme.durAmbient } }
                    }
                }
            }
        }
    }
}

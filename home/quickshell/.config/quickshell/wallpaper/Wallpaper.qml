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
// Images are listed from ~/.local/share/wallpapers (downloaded by ./install.sh wallpapers) and
// ~/Pictures/Wallpapers (put your own images there). The choice is remembered in
// ~/.local/state/dotfiles/wallpaper.
Scope {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateFile: home + "/.local/state/dotfiles/wallpaper"

    property var files: []          // every image found, sorted
    property string current: ""     // absolute path of the wallpaper in use

    // ---- remember the choice ----
    FileView {
        id: saved
        path: root.stateFile
        blockLoading: true
        printErrors: false
    }

    Process {
        id: save
        property string value
        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", root.stateFile, value]
    }

    // ---- brightness of the top edge (decides whether the bar needs a background) ----
    Process {
        id: measure
        property string image
        // Mean brightness of the top 12% of the image, 0-255. Pillow is already needed by the generator.
        command: ["python3", "-I", "-c",
            "import sys\nfrom PIL import Image\n" +
            "im = Image.open(sys.argv[1]); im.draft('L', (800, 800)); im = im.convert('L')\n" +
            "w, h = im.size; px = list(im.crop((0, 0, w, max(1, round(h * 0.12)))).resize((64, 4)).getdata())\n" +
            "print(sum(px) / len(px))", image]
        stdout: StdioCollector { onStreamFinished: ShellState.topLuminance = parseFloat(text) || 0 }
    }
    onFilesChanged: ShellState.wallpaperFiles = files
    Connections {
        target: ShellState
        function onWallpaperChosen(path) { root.set(path) }
    }
    // The lock screen shows the same wallpaper: hyprlock.conf includes this one-line file (`source = ...`).
    readonly property string lockFile: home + "/.local/state/dotfiles/hyprlock-wallpaper.conf"
    Process {
        id: lockWriter
        property string value
        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf \'$wallpaper = %s\\n\' "$2" > "$1"', "sh", root.lockFile, value]
    }

    onCurrentChanged: {
        ShellState.wallpaperCurrent = current
        if (current !== "") { lockWriter.value = current; lockWriter.running = true }
        if (current !== "") { measure.image = current; measure.running = true }
    }

    function set(path) {
        if (!path || path === current) return
        current = path
        save.value = path
        save.running = true
    }

    function next() {
        if (files.length === 0) return
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
    Process {
        id: scan
        command: ["sh", "-c",
            'find "$HOME/.local/share/wallpapers" "$HOME/Pictures/Wallpapers" -maxdepth 2 -type f ' +
            '\\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \\) 2>/dev/null | sort']
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = text.split("\n").filter(l => l !== "")
                if (root.files.length > 0 && !thumbs.running) { thumbs.images = root.files; thumbs.running = true }
                // Nothing remembered (or the file is gone): use the first one.
                if (root.files.length > 0 && !root.files.includes(root.current)) root.current = root.files[0]
            }
        }
    }

    Component.onCompleted: {
        ShellState.wallpaperThumbDir = thumbDir
        try { current = saved.text().trim() } catch (e) { current = "" }
        scan.running = true
    }

    IpcHandler {
        target: "wallpaper"
        function next(): void { root.next() }
        function set(path: string): void { root.set(path) }
    }

    // Look for new images whenever Settings opens (it shows them in Settings > Wallpaper).
    Connections {
        target: ShellState
        function onSettingsOpenChanged() { if (ShellState.settingsOpen) scan.running = true }
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

            component Pic: Image {
                required property bool isA
                anchors.fill: parent
                asynchronous: true
                cache: false                       // a regenerated file must not be shown from an old copy
                fillMode: Image.PreserveAspectCrop
                // Decode at screen size, not at the file's (possibly huge) size.
                sourceSize.width: Math.round(win.modelData.width * win.modelData.devicePixelRatio)
                opacity: win.frontIsA === isA ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.durAmbient; easing.type: Theme.easeInOut } }
                // When the one that was loading in the back is ready, bring it to the front.
                onStatusChanged: if (status === Image.Ready && win.frontIsA !== isA) win.frontIsA = isA
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

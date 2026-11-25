import QtQuick
import Quickshell
import Quickshell.Io
import qs
import "../ui"

// About: what this machine is. The system and who is signed in at the top, memory and disk as two meters, then the
// software and the hardware as plain rows. Everything comes from one `fastfetch --format json` run (about 15 ms),
// repeated every few seconds while the section shows, so memory, disk and uptime stay current.
Page {
    id: root

    property var info: ({})                       // fastfetch's results by module name: info.OS, info.Memory, ...
    readonly property var disk: (info.Disk ?? []).find(d => d.mountpoint === "/") ?? null
    readonly property var gpu: (info.GPU ?? [])[0] ?? null

    Process {
        id: probe
        running: true
        command: ["fastfetch", "-c", "none", "--structure", "title:os:kernel:uptime:packages:wm:host:cpu:gpu:memory:disk", "--format", "json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const found = {}
                    for (const m of JSON.parse(text)) if (m.result) found[m.type] = m.result
                    root.info = found
                } catch (e) {}
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: probe.running = true }

    function gib(bytes) { return (bytes / 1073741824).toFixed(1) }
    function usage(part) { return part ? gib(part.used) + " / " + gib(part.total) + " GiB" : "-" }
    function fraction(part) { return part && part.total > 0 ? part.used / part.total : 0 }

    function osText() { return info.OS ? (info.OS.name + " " + info.OS.versionID).trim() : "-" }
    function userText() { return info.Title ? info.Title.userName + "@" + info.Title.hostName : "" }
    // The root filesystem's creation time is the day this system was installed.
    function installedText() {
        const t = disk?.createTime
        if (!t) return ""
        const day = new Date(Number(t.slice(0, 4)), Number(t.slice(5, 7)) - 1, Number(t.slice(8, 10)))
        const days = Math.floor((Date.now() - day.getTime()) / 86400000)
        return "Installed " + Qt.formatDate(day, "d MMM yyyy") + "  ·  " + (days <= 0 ? "today" : days === 1 ? "1 day ago" : days + " days ago")
    }
    function uptimeText() {
        if (!info.Uptime) return "-"
        const min = Math.floor(info.Uptime.uptime / 60000), d = Math.floor(min / 1440), h = Math.floor(min % 1440 / 60), m = min % 60
        return d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "m" : m + "m"
    }
    function desktopText() {
        const wm = info.WM
        return wm ? [(wm.prettyName + " " + wm.version).trim(), wm.protocolName].filter(s => s).join("  ·  ") : "-"
    }
    function packagesText() {
        const p = info.Packages
        if (!p) return "-"
        const flatpak = (p.flatpakUser ?? 0) + (p.flatpakSystem ?? 0)
        return [p.rpm ? p.rpm + " rpm" : "", flatpak ? flatpak + " flatpak" : ""].filter(s => s).join("  ·  ") || String(p.all)
    }
    function modelText() {
        const h = info.Host
        return h ? (h.version || h.family || h.name || "-") : "-"
    }
    function cpuText() {
        const c = info.CPU
        if (!c) return "-"
        const name = c.cpu.replace(/\((R|TM)\)/g, "").replace(/\s+/g, " ").trim()
        return name + (c.cores?.logical ? "  ·  " + c.cores.logical + " threads" : "")
    }
    function gpuText() { return gpu ? [gpu.vendor, gpu.name.replace(gpu.vendor, "").trim()].filter(s => s).join(" ") : "-" }

    // ---- the system, who is signed in and how old the install is ----
    Item {
        width: parent.width
        height: 88

        Rectangle {
            id: badge
            anchors.verticalCenter: parent.verticalCenter
            width: 64
            height: 64
            radius: Theme.radiusCard
            color: Theme.hover
            border.width: 1
            border.color: Theme.border
            StyledText {
                anchors.centerIn: parent
                text: Theme.glyphFedora
                color: Theme.accent
                font.pixelSize: Theme.fontIcon
            }
        }
        Column {
            anchors { left: badge.right; leftMargin: 18; right: swatches.left; rightMargin: 18; verticalCenter: parent.verticalCenter }
            spacing: 3
            StyledText { width: parent.width; text: root.osText(); color: Theme.bright; font.pixelSize: Theme.fontXL; elide: Text.ElideRight }
            StyledText { width: parent.width; text: root.userText(); elide: Text.ElideRight }
            StyledText { width: parent.width; text: root.installedText(); color: Theme.dim; font.pixelSize: Theme.fontSmall; elide: Text.ElideRight }
        }
        // The palette, as in `fastfetch`: one row of colour dots.
        Row {
            id: swatches
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 6
            Repeater {
                model: [Theme.bright, Theme.text, Theme.dim, Theme.accent, Theme.ok, Theme.warn, Theme.err]
                Rectangle {
                    required property color modelData
                    width: 10
                    height: width
                    radius: width / 2
                    color: modelData
                }
            }
        }
    }

    // ---- memory and disk ----
    component Meter: Rectangle {
        id: meter
        property string title
        property string detail                     // dim text after the title, e.g. the filesystem
        property string text
        property real value: 0                     // 0..1

        width: (parent.width - parent.spacing) / 2
        height: 78
        radius: Theme.radiusRow
        color: Theme.hover
        border.width: 1
        border.color: Theme.border

        StyledText { x: 14; y: 12; text: meter.title; color: Theme.bright }
        StyledText {
            anchors { right: parent.right; rightMargin: 14 }
            y: 12
            text: Math.round(meter.value * 100) + "%"
            color: meter.value >= 0.9 ? Theme.err : meter.value >= 0.75 ? Theme.warn : Theme.text
        }
        StyledText { x: 14; y: 32; text: meter.text + (meter.detail !== "" ? "  ·  " + meter.detail : ""); color: Theme.dim; font.pixelSize: Theme.fontSmall }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }
            height: 4
            radius: Theme.radiusSmall
            color: Theme.border
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, meter.value))
                height: parent.height
                radius: parent.radius
                color: Theme.accent
                ValueMotion on width {}
            }
        }
    }
    Row {
        width: parent.width
        spacing: 12
        Meter { title: "Memory"; text: root.usage(root.info.Memory); value: root.fraction(root.info.Memory) }
        Meter { title: "Disk"; detail: root.disk?.filesystem ?? ""; text: root.usage(root.disk?.bytes); value: root.fraction(root.disk?.bytes) }
    }

    // ---- software and hardware ----
    component Fact: SettingRow {
        id: fact
        property string text
        height: 38
        StyledText { text: fact.text }
    }

    GroupLabel { text: "System" }
    Fact { title: "Kernel"; text: root.info.Kernel?.release ?? "-" }
    Fact { title: "Desktop"; text: root.desktopText() }
    Fact { title: "Packages"; text: root.packagesText() }
    Fact { title: "Uptime"; text: root.uptimeText() }

    GroupLabel { text: "Hardware" }
    Fact { title: "Model"; text: root.modelText() }
    Fact { title: "Processor"; text: root.cpuText() }
    Fact { title: "Graphics"; text: root.gpuText() }
}

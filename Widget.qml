import QtQuick
import QtQml
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    property string command: pluginData.command ?? ""
    property real refreshInterval: normalizeRefreshInterval(pluginData.refreshInterval)
    property bool autoRefresh: pluginData.autoRefresh ?? false
    property real commandTimeout: normalizeCommandTimeout(pluginData.commandTimeout) // seconds
    property bool hasRunInitial: false
    property string output: ""
    property int rows: 0
    property int cols: 0
    property var windowRef: null
    property int fontSizePx: normalizeFontSize(pluginData.fontSize)
    property string pluginUrl: ""
    property string pluginDir: ""
    property string wrapCommandPath: ""

    FontMetrics {
        id: fontMetrics
        font.pixelSize: root.fontSizePx
        font.family: Theme.monoFontFamily
    }

    Timer {
        id: timer
        interval: root.refreshInterval
        repeat: true
        running: false
        onTriggered: runCommand()
    }

    Component.onCompleted: {
        root.windowRef = Window.window ?? null
        root.handleVisibilityChange("completed")
        const url = Qt.resolvedUrl("Widget.qml") || (typeof __qmlfile__ !== "undefined" ? __qmlfile__ : "")
        const cleanedUrl = String(url ?? "")
        const cleanedPath = cleanedUrl.startsWith("file://") ? cleanedUrl.slice("file://".length) : cleanedUrl
        const lastSlash = cleanedPath.lastIndexOf("/")
        root.pluginUrl = cleanedUrl
        root.pluginDir = lastSlash !== -1 ? cleanedPath.slice(0, lastSlash) : ""
        const resolvedWrapUrl = Qt.resolvedUrl("wrapCommand")
        const resolvedWrap = String(resolvedWrapUrl ?? "")
        root.wrapCommandPath = resolvedWrap
            ? resolvedWrap.replace(/^file:\/\//, "")
            : (root.pluginDir ? `${root.pluginDir}/wrapCommand` : "wrapCommand")
    }

    onVisibleChanged: {
        root.handleVisibilityChange("root.visible")
    }

    onWidthChanged: root.handleVisibilityChange("sizeChanged")
    onHeightChanged: root.handleVisibilityChange("sizeChanged")

    Component.onDestruction: {
        root.stopAllActivity("destruction")
    }

    onCommandChanged: {
        if (!root.isRunnable()) {
            root.hasRunInitial = false
            timer.stop()
            return
        }
        if (!root.hasRunInitial) {
            root.hasRunInitial = true
            runCommand()
            timer.running = root.autoRefresh && root.isRunnable()
        } else {
            runCommand()
            if (root.autoRefresh) {
                timer.restart()
            }
        }
    }

    onFontSizePxChanged: {
        if (!root.isRunnable()) {
            root.hasRunInitial = false
            timer.stop()
            return
        }
        if (!root.hasRunInitial) {
            root.hasRunInitial = true
            runCommand()
            timer.running = root.autoRefresh && root.isRunnable()
        } else {
            runCommand()
            if (root.autoRefresh) {
                timer.restart()
            }
        }
    }

    onAutoRefreshChanged: {
        timer.running = root.autoRefresh && root.isRunnable()
        if (root.autoRefresh && root.hasRunInitial && root.isRunnable()) {
            timer.restart()
        }
    }

    onRefreshIntervalChanged: {
        if (timer.running) {
            timer.restart()
        }
    }

    function normalizeRefreshInterval(value) {
        const parsed = Number(value)
        if (!isFinite(parsed) || parsed <= 0) {
            return 60000
        }
        return parsed * 1000
    }

    function normalizeCommandTimeout(value) {
        const parsed = Number(value)
        if (!isFinite(parsed) || parsed <= 0) {
            return 5
        }
        return parsed
    }

    function normalizeFontSize(value) {
        const parsed = parseInt(value, 10)
        if (!isFinite(parsed) || parsed <= 0) {
            return Theme.fontSizeSmall
        }
        return parsed
    }

    function isRunnable() {
        const win = root.windowRef
        const winVisible = win === null ? true : !!win.visible
        return root.visible && winVisible && root.width > 0 && root.height > 0
    }

    function handleVisibilityChange(source) {
        if (!root.isRunnable()) {
            root.stopAllActivity(source)
            return
        }
        if (!root.hasRunInitial) {
            root.hasRunInitial = true
            runCommand()
        }
        if (root.autoRefresh) {
            timer.start()
        }
    }

    function runCommand() {
        if (!root.isRunnable()) {
            console.warn(`[desktopCommand] runCommand skipped; not runnable (visible=${root.visible} winVisible=${root.windowRef ? root.windowRef.visible : "n/a"}`)
            return
        }
        if (process.running) {
            console.warn(`[desktopCommand] runCommand skipped; process already running; command="${root.command}"`)
            return
        }
        root.updateTerminalSize()
        process.command = ["sh", "-c", `"${root.wrapCommandPath}" --width=${root.cols} --height=${root.rows} --timeout=${root.commandTimeout} -- ${root.command}`]
        process.running = true
    }

    function updateTerminalSize() {
        const horizontalMargin = 0
        const verticalMargin = 0
        const availableWidth = Math.max(0, (root.widgetWidth ?? root.width) - horizontalMargin)
        const availableHeight = Math.max(0, (root.widgetHeight ?? root.height) - verticalMargin)

        root.cols = Math.max(1, Math.floor(availableWidth / Math.max(1, fontMetrics.averageCharacterWidth)))
        root.rows = Math.max(1, Math.floor(availableHeight / Math.max(1, fontMetrics.lineSpacing)))
    }

    function stopAllActivity(reason) {
        timer.stop()
        process.running = false
        root.output = ""
    }

    Process {
        id: process

        stdout: StdioCollector {
            onStreamFinished: {
                root.output = this.text
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surfaceContainer, 0.85)
        visible: root.visible

        Text {
            anchors.fill: parent
            anchors.margins: 8
            text: root.output
            textFormat: Text.RichText
            wrapMode: Text.NoWrap
            color: Theme.surfaceText
            font.pixelSize: root.fontSizePx
            font.family: Theme.monoFontFamily
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignTop
        }
    }
}

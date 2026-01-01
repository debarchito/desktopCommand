import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "desktopCommand"

    property string defaultCommand: "fastfetch --logo-type builtin"
    property int defaultFontSize: Theme.fontSizeSmall
    property string command: root.loadValue("command", defaultCommand)
    property bool autoRefresh: root.loadValue("autoRefresh", false)
    property string commandTimeout: String(root.loadValue("commandTimeout", "1"))
    property string refreshInterval: String(root.loadValue("refreshInterval", "5"))
    property string fontSize: String(root.loadValue("fontSize", defaultFontSize))

    function sanitizeIntInput(textValue, fallback) {
        const cleaned = String(textValue ?? "").replace(/[^0-9]/g, "")
        return cleaned.length > 0 ? cleaned : String(fallback)
    }

    function sanitizeDecimalInput(textValue, fallback) {
        let cleaned = String(textValue ?? "").replace(/[^0-9.]/g, "")
        const dot = cleaned.indexOf(".")
        if (dot !== -1) {
            cleaned = cleaned.slice(0, dot + 1) + cleaned.slice(dot + 1).replace(/\./g, "")
        }
        return cleaned.length > 0 ? cleaned : String(fallback)
    }

    Column {
        id: content
        spacing: Theme.spacingM
        anchors.left: parent.left
        anchors.right: parent.right

        Column {
            spacing: Theme.spacingXS
            width: parent.width

            StyledText {
                text: I18n.tr("Shell command")
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                text: I18n.tr("Shell command to run and display.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }

            DankTextField {
                id: commandField
                width: parent.width
                height: 40
                text: command
                placeholderText: defaultCommand
                backgroundColor: Theme.surfaceContainer
                textColor: Theme.surfaceText
            }
        }

        Column {
            spacing: Theme.spacingXS
            width: parent.width

            StyledText {
                text: I18n.tr("Command Timeout (seconds)")
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                text: I18n.tr("Maximum amount of time to run the command. Important when running commands taht never exit, like TUI apps.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }

            DankTextField {
                id: timeoutField
                width: parent.width
                height: 40
                text: commandTimeout
                placeholderText: "1"
                backgroundColor: Theme.surfaceContainer
                textColor: Theme.surfaceText

                onEditingFinished: {
                    commandTimeout = sanitizeDecimalInput(text, "1")
                    text = commandTimeout
                }
            }
        }

        Column {
            spacing: Theme.spacingXS
            width: parent.width

            StyledText {
                text: I18n.tr("Font Size (px)")
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                text: I18n.tr("Default monospace font is being used, but you can set a custom size.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }

            DankTextField {
                id: fontSizeField
                width: parent.width
                height: 40
                text: fontSize
                placeholderText: String(defaultFontSize)
                backgroundColor: Theme.surfaceContainer
                textColor: Theme.surfaceText

                onEditingFinished: {
                    fontSize = sanitizeIntInput(text, defaultFontSize)
                    text = fontSize
                }
            }
        }

        Column {
            spacing: Theme.spacingS
            width: parent.width

            CheckBox {
                id: autoRefreshToggle
                checked: autoRefresh

                contentItem: StyledText {
                    text: I18n.tr("Auto Refresh")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    leftPadding: autoRefreshToggle.indicator.width + 8
                    verticalAlignment: Text.AlignVCenter
                }
            }

            StyledText {
                text: I18n.tr("Automatically rerun the command on the chosen interval.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width - autoRefreshToggle.width - Theme.spacingS
            }
        }

        Column {
            spacing: Theme.spacingXS
            width: parent.width

            StyledText {
                text: I18n.tr("Refresh Interval (seconds)")
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                opacity: autoRefreshToggle.checked ? 1.0 : 0.3
            }

            StyledText {
                text: I18n.tr("How often to rerun the command (supports decimals).")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                opacity: autoRefreshToggle.checked ? 1.0 : 0.3
            }

            DankTextField {
                id: intervalField
                width: parent.width
                height: 40
                text: refreshInterval
                placeholderText: "5"
                backgroundColor: Theme.surfaceContainer
                textColor: Theme.surfaceText
                enabled: autoRefreshToggle.checked
                opacity: autoRefreshToggle.checked ? 1.0 : 0.3

                onEditingFinished: {
                    refreshInterval = sanitizeDecimalInput(text, "5")
                    text = refreshInterval
                }
            }
        }

        DankButton {
            text: I18n.tr("Save changes")
            width: parent.width
            onClicked: {
                command = commandField.text.trim()
                root.saveValue("command", command)

                root.saveValue("autoRefresh", autoRefreshToggle.checked)

                commandTimeout = sanitizeDecimalInput(timeoutField.text, "1")
                root.saveValue("commandTimeout", commandTimeout)

                refreshInterval = sanitizeDecimalInput(intervalField.text, "5")
                root.saveValue("refreshInterval", refreshInterval)

                fontSize = sanitizeIntInput(fontSizeField.text, defaultFontSize)
                root.saveValue("fontSize", fontSize)

                commandField.text = command
                timeoutField.text = commandTimeout
                intervalField.text = refreshInterval
                fontSizeField.text = fontSize
            }
        }
    }
}

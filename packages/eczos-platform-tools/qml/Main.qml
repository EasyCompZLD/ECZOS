import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    width: 1180
    height: 760
    minimumWidth: 920
    minimumHeight: 620
    visible: true
    title: pageTitle(backend.route) + " · ECZOS"
    color: "#08131f"

    property color accent: "#35bdf5"
    property color accentDark: "#147eae"
    property color panel: "#101f2e"
    property color panelRaised: "#172a3b"
    property color border: "#294156"
    property color textPrimary: "#f4f8fb"
    property color textMuted: "#aac0d1"
    property color good: "#52d273"
    property color warning: "#ffc857"
    property color danger: "#ff6b78"
    property var diagnostics: ({})
    property var gaming: ({})
    property var systemModules: []
    property var windowsApps: []
    property var recoveryDevices: []
    property var recoveryReleases: []
    property string migrationSource: ""
    property string recoveryImage: ""
    property string recoveryMode: "disk"

    function pageTitle(route) {
        const labels = {
            settings: qsTr("Settings"), system: qsTr("System settings"), windows: qsTr("Windows apps"), gaming: qsTr("Gaming"),
            migration: qsTr("Transfer files"), diagnostics: qsTr("Diagnostics"),
            recovery: qsTr("Recovery media"), support: qsTr("Support")
        }
        return labels[route] || qsTr("Settings")
    }

    function yesNo(value) { return value ? qsTr("Ready") : qsTr("Attention needed") }
    function fileName(path) {
        const decoded = decodeURIComponent(path.replace("file://", ""))
        const parts = decoded.split("/")
        return parts[parts.length - 1] || qsTr("No file selected")
    }

    component FlatButton: Button {
        id: control
        property bool primary: false
        implicitHeight: 42
        leftPadding: 20; rightPadding: 20
        font.pixelSize: 14; font.weight: Font.DemiBold
        contentItem: Text {
            text: control.text
            color: !control.enabled ? root.textMuted : control.primary ? "#05121c" : root.textPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 10
            color: control.down ? (control.primary ? "#83d8fa" : "#27455b")
                                : control.hovered ? (control.primary ? "#61cff8" : "#21394d")
                                                  : (control.primary ? root.accent : root.panelRaised)
            border.color: control.primary ? root.accent : root.border
            opacity: control.enabled ? 1 : 0.45
        }
    }

    component NavButton: Button {
        id: control
        property string routeName
        property string symbol
        Layout.fillWidth: true
        implicitHeight: 48
        leftPadding: 15
        background: Rectangle {
            radius: 10
            color: backend.route === control.routeName ? "#183b52" : control.hovered ? "#132b3d" : "transparent"
            border.color: backend.route === control.routeName ? root.accentDark : "transparent"
        }
        contentItem: RowLayout {
            spacing: 12
            Text { text: control.symbol; color: backend.route === control.routeName ? root.accent : root.textMuted; font.pixelSize: 19; Layout.preferredWidth: 24 }
            Text { text: control.text; color: root.textPrimary; font.pixelSize: 14; font.weight: backend.route === control.routeName ? Font.DemiBold : Font.Normal; Layout.fillWidth: true }
        }
        onClicked: backend.navigate(routeName)
    }

    component ChoiceRadio: RadioButton {
        id: control
        implicitHeight: 36
        spacing: 9
        indicator: Rectangle {
            implicitWidth: 18; implicitHeight: 18; radius: 9
            x: control.leftPadding; y: (control.height - height) / 2
            color: "transparent"; border.width: 2
            border.color: control.checked ? root.accent : root.textMuted
            Rectangle { anchors.centerIn: parent; width: 9; height: 9; radius: 5; color: root.accent; visible: control.checked }
        }
        contentItem: Text {
            leftPadding: control.indicator.width + control.spacing
            text: control.text; color: root.textPrimary; font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
    }

    component DarkComboBox: ComboBox {
        id: control
        property string emptyText: qsTr("No suitable device found")
        implicitHeight: 42
        leftPadding: 13; rightPadding: 34
        contentItem: Text {
            text: control.displayText || control.emptyText
            color: control.displayText ? root.textPrimary : root.textMuted
            font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
        }
        indicator: Text { text: "⌄"; color: root.textMuted; font.pixelSize: 19; rightPadding: 11; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
        background: Rectangle { radius: 9; color: root.panelRaised; border.color: control.activeFocus ? root.accent : root.border }
        delegate: ItemDelegate {
            width: control.width
            contentItem: Text { text: modelData.label || ""; color: root.textPrimary; font.pixelSize: 13; elide: Text.ElideRight }
            background: Rectangle { color: highlighted ? "#21445d" : root.panelRaised }
            highlighted: control.highlightedIndex === index
        }
        popup: Popup {
            y: control.height + 4; width: control.width; implicitHeight: Math.min(contentItem.implicitHeight + 8, 280)
            padding: 4
            contentItem: ListView { clip: true; implicitHeight: contentHeight; model: control.delegateModel; currentIndex: control.highlightedIndex; ScrollIndicator.vertical: ScrollIndicator {} }
            background: Rectangle { radius: 9; color: root.panelRaised; border.color: root.border }
        }
    }

    component ActionCard: Rectangle {
        id: card
        property string heading
        property string description
        property string symbol: "•"
        signal activated()
        implicitHeight: 132
        radius: 14
        color: mouse.containsMouse ? "#1a3043" : root.panelRaised
        border.color: mouse.containsMouse ? root.accentDark : root.border
        Behavior on color { ColorAnimation { duration: 120 } }
        RowLayout {
            anchors.fill: parent; anchors.margins: 18; spacing: 16
            Rectangle {
                Layout.preferredWidth: 48; Layout.preferredHeight: 48
                radius: 14; color: "#183d54"
                Text { anchors.centerIn: parent; text: card.symbol; color: root.accent; font.pixelSize: 22; font.weight: Font.Bold }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 6
                Text { text: card.heading; color: root.textPrimary; font.pixelSize: 17; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.Wrap }
                Text { text: card.description; color: root.textMuted; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight }
            }
            Text { text: "›"; color: root.textMuted; font.pixelSize: 28 }
        }
        MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.activated() }
    }

    component StatusCard: Rectangle {
        id: card
        property string heading
        property string detail
        property bool okay: true
        implicitHeight: 92
        radius: 12; color: root.panelRaised; border.color: root.border
        RowLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 14
            Rectangle { width: 12; height: 12; radius: 6; color: card.okay ? root.good : root.warning }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                Text { text: card.heading; color: root.textPrimary; font.pixelSize: 15; font.weight: Font.DemiBold }
                Text { text: card.detail; color: root.textMuted; font.pixelSize: 13; wrapMode: Text.Wrap; Layout.fillWidth: true }
            }
            Text { text: card.okay ? "✓" : "!"; color: card.okay ? root.good : root.warning; font.pixelSize: 20; font.weight: Font.Bold }
        }
    }

    component VisualModuleCard: Rectangle {
        id: card
        property string heading
        property string description
        property string imageSource
        property string moduleId
        implicitHeight: 154
        radius: 13
        clip: true
        color: root.panelRaised
        border.color: visualMouse.containsMouse ? root.accent : root.border
        Image {
            anchors.fill: parent
            source: card.imageSource
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 520
            sourceSize.height: 360
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.24; color: "#1608131f" }
                GradientStop { position: 1.0; color: "#f208131f" }
            }
        }
        ColumnLayout {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.margins: 14; spacing: 3
            Text { Layout.fillWidth: true; text: card.heading; color: root.textPrimary; font.pixelSize: 17; font.weight: Font.Bold }
            Text { Layout.fillWidth: true; text: card.description; color: "#d4e3ed"; font.pixelSize: 12; elide: Text.ElideRight }
        }
        MouseArea { id: visualMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: backend.launchKcm(card.moduleId) }
    }

    component PageHeading: ColumnLayout {
        property string heading
        property string subtitle
        spacing: 7
        Text { text: parent.heading; color: root.textPrimary; font.pixelSize: 31; font.weight: Font.Bold }
        Text { text: parent.subtitle; color: root.textMuted; font.pixelSize: 15; wrapMode: Text.Wrap; Layout.maximumWidth: 760 }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 238
            Layout.fillHeight: true
            color: "#0b1926"
            border.color: "#152c3e"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 17; spacing: 5
                Image {
                    source: "file:///usr/share/eczos/branding/logo/logo.png"
                    fillMode: Image.PreserveAspectFit
                    Layout.preferredWidth: 150; Layout.preferredHeight: 62
                    Layout.alignment: Qt.AlignHCenter
                }
                Item { Layout.preferredHeight: 13 }
                NavButton { routeName: "settings"; symbol: "⌂"; text: qsTr("Settings") }
                NavButton { routeName: "system"; symbol: "⚙"; text: qsTr("System settings") }
                NavButton { routeName: "windows"; symbol: "▦"; text: qsTr("Windows apps") }
                NavButton { routeName: "gaming"; symbol: "◆"; text: qsTr("Gaming") }
                NavButton { routeName: "migration"; symbol: "⇢"; text: qsTr("Transfer files") }
                NavButton { routeName: "diagnostics"; symbol: "✓"; text: qsTr("Diagnostics") }
                NavButton { routeName: "recovery"; symbol: "↻"; text: qsTr("Recovery media") }
                NavButton { routeName: "support"; symbol: "?"; text: qsTr("Support") }
                Item { Layout.fillHeight: true }
                Text { text: "EasyComp Zeeland\nOperating System"; color: "#6f8da2"; font.pixelSize: 11; lineHeight: 1.25 }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; color: root.color
            Loader {
                anchors.fill: parent
                sourceComponent: ({settings: settingsPage, system: systemPage, windows: windowsPage, gaming: gamingPage,
                                   migration: migrationPage, diagnostics: diagnosticsPage,
                                   recovery: recoveryPage, support: supportPage})[backend.route] || settingsPage
            }
        }
    }

    Component {
        id: settingsPage
        ScrollView {
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width; spacing: 20
                anchors.margins: 34
                PageHeading { heading: qsTr("Everything for your computer"); subtitle: qsTr("Clear shortcuts to apps, devices, backups, recovery and support.") }
                GridLayout {
                    Layout.fillWidth: true; columns: width > 760 ? 3 : 2; columnSpacing: 14; rowSpacing: 14
                    ActionCard { Layout.fillWidth: true; heading: qsTr("Apps"); description: qsTr("Install and update applications"); symbol: "+"; onActivated: backend.launch("apps") }
                    ActionCard { Layout.fillWidth: true; heading: qsTr("Windows apps"); description: qsTr("Manage installed Windows programs"); symbol: "▦"; onActivated: backend.navigate("windows") }
                    ActionCard { Layout.fillWidth: true; heading: qsTr("Gaming"); description: qsTr("Check Steam and gaming support"); symbol: "◆"; onActivated: backend.navigate("gaming") }
                    ActionCard { Layout.fillWidth: true; heading: qsTr("System settings"); description: qsTr("Appearance, displays, sound, network and devices"); symbol: "⚙"; onActivated: backend.navigate("system") }
                    ActionCard { Layout.fillWidth: true; heading: qsTr("Backup"); description: qsTr("Protect your personal files"); symbol: "◴"; onActivated: backend.launch("backup") }
                    ActionCard { Layout.fillWidth: true; heading: qsTr("Recovery media"); description: qsTr("Create a bootable USB drive, SD card or DVD"); symbol: "↻"; onActivated: backend.navigate("recovery") }
                    ActionCard { Layout.fillWidth: true; heading: qsTr("Phone"); description: qsTr("Connect your phone to ECZOS"); symbol: "▯"; onActivated: backend.launch("phone") }
                    ActionCard { Layout.fillWidth: true; heading: qsTr("Migration"); description: qsTr("Bring files over from a Windows profile"); symbol: "⇢"; onActivated: backend.navigate("migration") }
                    ActionCard { Layout.fillWidth: true; heading: qsTr("Diagnostics"); description: qsTr("Quickly check important components"); symbol: "✓"; onActivated: backend.navigate("diagnostics") }
                    ActionCard { Layout.fillWidth: true; heading: qsTr("Support"); description: qsTr("Create a privacy-conscious support report"); symbol: "?"; onActivated: backend.navigate("support") }
                    ActionCard { Layout.fillWidth: true; heading: qsTr("About this computer"); description: qsTr("View hardware and system information"); symbol: "i"; onActivated: backend.launch("about") }
                }
                Item { Layout.preferredHeight: 30 }
            }
        }
    }

    Component {
        id: systemPage
        Item {
            property string query: systemSearch.text.toLowerCase()
            property var filteredModules: systemModules.filter(function(item) {
                return !query || item.name.toLowerCase().indexOf(query) >= 0 || item.category.toLowerCase().indexOf(query) >= 0 || item.id.toLowerCase().indexOf(query) >= 0
            })
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 34; spacing: 18
                RowLayout {
                    Layout.fillWidth: true
                    PageHeading { Layout.fillWidth: true; heading: qsTr("System settings"); subtitle: qsTr("All available KDE settings, grouped and searchable from ECZOS.") }
                    FlatButton { text: qsTr("Refresh modules"); onClicked: backend.refresh("system") }
                }
                TextField {
                    id: systemSearch
                    Layout.fillWidth: true; implicitHeight: 46
                    placeholderText: qsTr("Search for displays, mouse, Wi-Fi, appearance or users…")
                    color: root.textPrimary; placeholderTextColor: root.textMuted
                    leftPadding: 15; rightPadding: 15; font.pixelSize: 14
                    background: Rectangle { radius: 10; color: root.panelRaised; border.color: systemSearch.activeFocus ? root.accent : root.border }
                }
                GridLayout {
                    Layout.fillWidth: true; columns: 3; columnSpacing: 12
                    VisualModuleCard {
                        Layout.fillWidth: true
                        heading: qsTr("Appearance")
                        description: qsTr("Theme, colours, icons and fonts")
                        imageSource: "file:///usr/share/eczos/branding/screenshots/system-appearance.png"
                        moduleId: "kcm_lookandfeel"
                    }
                    VisualModuleCard {
                        Layout.fillWidth: true
                        heading: qsTr("Displays")
                        description: qsTr("Resolution, position, scale and refresh rate")
                        imageSource: "file:///usr/share/eczos/branding/screenshots/system-display.png"
                        moduleId: "kcm_kscreen"
                    }
                    VisualModuleCard {
                        Layout.fillWidth: true
                        heading: qsTr("Network")
                        description: qsTr("Wi-Fi, wired connections, IP and security")
                        imageSource: "file:///usr/share/eczos/branding/screenshots/system-network.png"
                        moduleId: "kcm_networkmanagement"
                    }
                }
                Text { text: qsTr("%1 of %2 modules").arg(filteredModules.length).arg(systemModules.length); color: root.textMuted; font.pixelSize: 13 }
                ScrollView {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true; contentWidth: availableWidth
                    GridLayout {
                        width: parent.width; columns: width > 700 ? 2 : 1; columnSpacing: 12; rowSpacing: 12
                        Repeater {
                            model: filteredModules
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; implicitHeight: 88; radius: 12; color: moduleMouse.containsMouse ? "#1a3043" : root.panelRaised; border.color: moduleMouse.containsMouse ? root.accentDark : root.border
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15; spacing: 13
                                    Rectangle { width: 42; height: 42; radius: 11; color: "#183d54"; Text { anchors.centerIn: parent; text: "⚙"; color: root.accent; font.pixelSize: 18 } }
                                    ColumnLayout { Layout.fillWidth: true; spacing: 3
                                        Text { Layout.fillWidth: true; text: modelData.name; color: root.textPrimary; font.pixelSize: 15; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                        Text { Layout.fillWidth: true; text: modelData.category; color: root.textMuted; font.pixelSize: 12; elide: Text.ElideRight }
                                    }
                                    Text { text: "›"; color: root.textMuted; font.pixelSize: 25 }
                                }
                                MouseArea { id: moduleMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: backend.launchKcm(modelData.id) }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: backend.status; color: root.textMuted; font.pixelSize: 13 }
                    FlatButton { text: qsTr("Open KDE overview"); onClicked: backend.launch("devices") }
                }
            }
        }
    }

    Component {
        id: diagnosticsPage
        ScrollView {
            clip: true; contentWidth: availableWidth
            ColumnLayout {
                width: parent.width; spacing: 20; anchors.margins: 34
                RowLayout {
                    Layout.fillWidth: true
                    PageHeading { Layout.fillWidth: true; heading: qsTr("Diagnostics"); subtitle: qsTr("A plain-language overview. This check does not change your computer.") }
                    FlatButton { text: qsTr("Check again"); onClicked: backend.refresh("diagnostics") }
                }
                GridLayout {
                    Layout.fillWidth: true; columns: width > 700 ? 2 : 1; columnSpacing: 14; rowSpacing: 14
                    StatusCard { Layout.fillWidth: true; heading: qsTr("Windows apps"); okay: diagnostics.windows === true; detail: yesNo(okay) }
                    StatusCard { Layout.fillWidth: true; heading: qsTr("Gaming"); okay: diagnostics.gaming === "ready"; detail: diagnostics.gaming === "ready" ? qsTr("Ready for Proton games") : qsTr("Check the Gaming page") }
                    StatusCard { Layout.fillWidth: true; heading: qsTr("Apps and Flatpak"); okay: diagnostics.applications && diagnostics.applications.discover && diagnostics.applications.flatpak; detail: yesNo(okay) }
                    StatusCard { Layout.fillWidth: true; heading: qsTr("Backup"); okay: diagnostics.backup === true; detail: yesNo(okay) }
                    StatusCard { Layout.fillWidth: true; heading: qsTr("Phone connection"); okay: diagnostics.phone === true; detail: yesNo(okay) }
                    StatusCard { Layout.fillWidth: true; heading: qsTr("Printers and scanners"); okay: diagnostics.devices && diagnostics.devices.printer && diagnostics.devices.scanner; detail: yesNo(okay) }
                    StatusCard { Layout.fillWidth: true; heading: qsTr("System services"); okay: Number(diagnostics.failedUnits || 0) === 0; detail: okay ? qsTr("No errors found") : qsTr("%1 service(s) need attention").arg(diagnostics.failedUnits) }
                    StatusCard { Layout.fillWidth: true; heading: "FreeOffice"; okay: diagnostics.office === "installed"; detail: okay ? qsTr("Installed") : qsTr("Not installed") }
                }
                BusyIndicator { running: backend.busy; visible: running; Layout.alignment: Qt.AlignHCenter }
            }
        }
    }

    Component {
        id: gamingPage
        ScrollView {
            clip: true; contentWidth: availableWidth
            ColumnLayout {
                width: parent.width; spacing: 20; anchors.margins: 34
                RowLayout {
                    Layout.fillWidth: true
                    PageHeading { Layout.fillWidth: true; heading: "ECZ Gaming"; subtitle: qsTr("See at a glance whether this computer is ready for Steam and Windows games.") }
                    FlatButton { text: qsTr("Open Steam"); primary: true; onClicked: backend.launch("steam") }
                }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 150; radius: 16
                    color: gaming.verdict === "ready" ? "#123d31" : root.panelRaised
                    border.color: gaming.verdict === "ready" ? root.good : root.warning
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 22; spacing: 9
                        Text { text: gaming.verdict === "ready" ? qsTr("Ready to play") : qsTr("Check required"); color: root.textPrimary; font.pixelSize: 25; font.weight: Font.Bold }
                        Text { text: gaming.summary || qsTr("Checking the hardware…"); color: root.textMuted; font.pixelSize: 15; wrapMode: Text.Wrap; Layout.fillWidth: true }
                    }
                }
                StatusCard { Layout.fillWidth: true; heading: qsTr("Graphics card"); okay: gaming.vulkan && gaming.vulkan.hardware; detail: gaming.gpu || qsTr("Checking…") }
                StatusCard { Layout.fillWidth: true; heading: qsTr("32-bit Vulkan driver"); okay: gaming.vulkan && gaming.vulkan.driver32Bit; detail: okay ? qsTr("Available for older and Windows games") : qsTr("Missing") }
                StatusCard { Layout.fillWidth: true; heading: qsTr("UMU/Proton support"); okay: gaming.runtime && gaming.runtime.umu; detail: okay ? qsTr("Installed") : qsTr("Missing") }
                StatusCard { Layout.fillWidth: true; heading: "GameMode"; okay: gaming.runtime && gaming.runtime.gameMode; detail: okay ? qsTr("Installed") : qsTr("Missing") }
                ProgressBar { Layout.fillWidth: true; from: 0; to: 1; value: backend.progress; visible: backend.busy && backend.progress > 0 }
                Text { Layout.fillWidth: true; visible: backend.status.length > 0; text: backend.status; color: root.textMuted; font.pixelSize: 14; wrapMode: Text.Wrap }
                RowLayout {
                    Layout.fillWidth: true
                    FlatButton { text: qsTr("Install missing components"); primary: true; visible: gaming.verdict === "setup-required"; enabled: !backend.busy; onClicked: backend.repairGaming() }
                    FlatButton { text: qsTr("Check again"); onClicked: backend.refresh("gaming") }
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }

    Component {
        id: windowsPage
        ScrollView {
            clip: true; contentWidth: availableWidth
            ColumnLayout {
                width: parent.width; spacing: 20; anchors.margins: 34
                RowLayout {
                    Layout.fillWidth: true
                    PageHeading { Layout.fillWidth: true; heading: qsTr("Windows apps"); subtitle: qsTr("Windows programs that ECZOS manages separately and safely for you.") }
                    FlatButton { text: qsTr("Refresh list"); onClicked: backend.refresh("windows") }
                }
                Rectangle {
                    visible: windowsApps.length === 0 && !backend.busy
                    Layout.fillWidth: true; implicitHeight: 150; radius: 14; color: root.panelRaised; border.color: root.border
                    ColumnLayout { anchors.centerIn: parent; spacing: 8
                        Text { Layout.alignment: Qt.AlignHCenter; text: qsTr("No Windows apps yet"); color: root.textPrimary; font.pixelSize: 20; font.weight: Font.DemiBold }
                        Text { text: qsTr("Open an .exe or .msi file to add an app."); color: root.textMuted; font.pixelSize: 14 }
                    }
                }
                Repeater {
                    model: windowsApps
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; implicitHeight: 118; radius: 14; color: root.panelRaised; border.color: root.border
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 18; spacing: 15
                            Rectangle { width: 48; height: 48; radius: 12; color: "#183d54"; Text { anchors.centerIn: parent; text: "▦"; color: root.accent; font.pixelSize: 23 } }
                            ColumnLayout { Layout.fillWidth: true; spacing: 5
                                Text { text: modelData.name || modelData.id; color: root.textPrimary; font.pixelSize: 17; font.weight: Font.DemiBold }
                                Text { text: modelData.status === "installed" ? qsTr("Installed and ready") : qsTr("Status: %1").arg(modelData.status); color: modelData.status === "installed" ? root.good : root.warning; font.pixelSize: 13 }
                            }
                            FlatButton { text: qsTr("Start"); primary: true; enabled: modelData.status === "installed"; onClicked: backend.windowsAction(modelData.id, "run") }
                            FlatButton { text: qsTr("Search again"); onClicked: backend.windowsAction(modelData.id, "rescan") }
                            FlatButton { text: qsTr("Repair"); onClicked: backend.windowsAction(modelData.id, "repair") }
                            FlatButton { text: qsTr("Remove"); onClicked: { removeDialog.appId = modelData.id; removeDialog.appName = modelData.name || modelData.id; removeDialog.open() } }
                        }
                    }
                }
            }
            Dialog {
                id: removeDialog
                property string appId
                property string appName
                anchors.centerIn: parent; modal: true; title: qsTr("Remove Windows app")
                standardButtons: Dialog.Cancel | Dialog.Ok
                onAccepted: backend.windowsAction(appId, "remove")
                Label { text: qsTr("‘%1’ and its separate Windows environment will be removed.").arg(removeDialog.appName); wrapMode: Text.Wrap; width: 420 }
            }
        }
    }

    Component {
        id: migrationPage
        Item {
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 34; spacing: 22
                PageHeading { heading: qsTr("Transfer files"); subtitle: qsTr("Bring documents, photos, music and other personal files over from a Windows profile. Existing files are not overwritten.") }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 150; radius: 14; color: root.panelRaised; border.color: root.border
                    RowLayout { anchors.fill: parent; anchors.margins: 20; spacing: 18
                        Rectangle { width: 54; height: 54; radius: 14; color: "#183d54"; Text { anchors.centerIn: parent; text: "⇢"; color: root.accent; font.pixelSize: 25 } }
                        ColumnLayout { Layout.fillWidth: true; spacing: 7
                            Text { text: migrationSource ? fileName(migrationSource) : qsTr("No Windows user folder selected yet"); color: root.textPrimary; font.pixelSize: 17; font.weight: Font.DemiBold }
                            Text { text: migrationSource || qsTr("For example, select %1 on a mounted Windows drive.").arg("C:\\Users\\yourname"); color: root.textMuted; font.pixelSize: 13; wrapMode: Text.Wrap; Layout.fillWidth: true }
                        }
                        FlatButton { text: qsTr("Select folder"); primary: true; onClicked: migrationFolder.open() }
                    }
                }
                RowLayout {
                    spacing: 12
                    FlatButton { text: qsTr("Preview first"); enabled: migrationSource && !backend.busy; onClicked: backend.migrate(migrationSource, false) }
                    FlatButton { text: qsTr("Transfer files"); primary: true; enabled: migrationSource && !backend.busy; onClicked: migrateConfirm.open() }
                }
                Text { visible: backend.status; text: backend.status; color: root.textMuted; font.pixelSize: 14; wrapMode: Text.Wrap; Layout.fillWidth: true }
                BusyIndicator { running: backend.busy; visible: running }
                Item { Layout.fillHeight: true }
            }
            FolderDialog { id: migrationFolder; title: qsTr("Select the Windows user folder"); onAccepted: migrationSource = selectedFolder.toString() }
            Dialog { id: migrateConfirm; anchors.centerIn: parent; modal: true; title: qsTr("Transfer files"); standardButtons: Dialog.Cancel | Dialog.Ok; onAccepted: backend.migrate(migrationSource, true); Label { width: 420; wrapMode: Text.Wrap; text: qsTr("ECZOS copies known personal folders. Existing files are preserved. Continue?") } }
        }
    }

    Component {
        id: recoveryPage
        Item {
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 34; spacing: 20
                PageHeading { heading: qsTr("Create recovery media"); subtitle: qsTr("Write an ECZOS installation image to a USB drive, SD card or DVD. Progress remains visible in this window.") }
                GridLayout {
                    Layout.fillWidth: true; columns: 2; columnSpacing: 14; rowSpacing: 14
                    Label { text: qsTr("1  Installation image"); color: root.textPrimary; font.pixelSize: 15; font.weight: Font.DemiBold }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 9
                        RowLayout { Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: recoveryImage ? fileName(recoveryImage) : qsTr("No ISO or IMG selected"); color: root.textMuted; elide: Text.ElideMiddle }
                            FlatButton { text: qsTr("Select local file"); onClicked: recoveryFile.open() }
                        }
                        RowLayout { Layout.fillWidth: true
                            DarkComboBox { id: releaseBox; Layout.fillWidth: true; emptyText: qsTr("Load the available ECZOS versions first"); model: recoveryReleases; textRole: "label"; valueRole: "version" }
                            FlatButton { text: recoveryReleases.length ? qsTr("Download") : qsTr("Load online versions"); onClicked: { if (recoveryReleases.length && releaseBox.currentIndex >= 0) { const item = recoveryReleases[releaseBox.currentIndex]; backend.downloadRecovery(item.version, item.url, item.sha256) } else backend.loadRecoveryCatalog() } }
                        }
                    }
                    Label { text: qsTr("2  Media type"); color: root.textPrimary; font.pixelSize: 15; font.weight: Font.DemiBold }
                    RowLayout {
                        ChoiceRadio { text: qsTr("USB drive or SD card"); checked: recoveryMode === "disk"; onClicked: { recoveryMode = "disk"; backend.refresh("recovery") } }
                        ChoiceRadio { text: qsTr("DVD or Blu-ray"); checked: recoveryMode === "dvd"; onClicked: { recoveryMode = "dvd"; backend.refresh("recovery") } }
                    }
                    Label { text: qsTr("3  Target device"); color: root.textPrimary; font.pixelSize: 15; font.weight: Font.DemiBold }
                    RowLayout { Layout.fillWidth: true
                        DarkComboBox { id: targetBox; Layout.fillWidth: true; model: recoveryDevices.filter(function(d) { return recoveryMode === "dvd" ? d.type === "rom" : d.type === "disk" }); textRole: "label"; valueRole: "name" }
                        FlatButton { text: qsTr("Refresh"); onClicked: backend.refresh("recovery") }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 96; radius: 12
                    color: "#342a16"; border.color: "#6d5420"
                    RowLayout { anchors.fill: parent; anchors.margins: 17; spacing: 14
                        Text { text: "!"; color: root.warning; font.pixelSize: 24; font.weight: Font.Bold }
                        Text { Layout.fillWidth: true; text: qsTr("All data on the selected medium will be erased. The internal system drive is always blocked."); color: "#ffe4a8"; font.pixelSize: 14; wrapMode: Text.Wrap }
                    }
                }
                ProgressBar { Layout.fillWidth: true; from: 0; to: 1; value: backend.progress; visible: backend.busy || backend.progress > 0 }
                RowLayout { Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: backend.status || qsTr("Ready to begin"); color: root.textMuted; font.pixelSize: 14; wrapMode: Text.Wrap }
                    FlatButton { text: qsTr("Create media"); primary: true; enabled: recoveryImage && targetBox.currentValue && !backend.busy; onClicked: recoveryConfirm.open() }
                }
                Item { Layout.fillHeight: true }
            }
            FileDialog { id: recoveryFile; title: qsTr("Select an ECZOS ISO or IMG file"); nameFilters: [qsTr("Installation images (*.iso *.img)")]; onAccepted: recoveryImage = selectedFile.toString() }
            Dialog {
                id: recoveryConfirm; anchors.centerIn: parent; modal: true; title: qsTr("Erase the entire medium?")
                standardButtons: Dialog.Cancel | Dialog.Ok
                onAccepted: backend.writeRecovery(recoveryMode, recoveryImage, targetBox.currentValue)
                Label { width: 440; wrapMode: Text.Wrap; text: qsTr("All data on %1 will be erased. This cannot be undone.").arg(targetBox.currentText || qsTr("the selected medium")) }
            }
        }
    }

    Component {
        id: supportPage
        Item {
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 34; spacing: 22
                PageHeading { heading: qsTr("Support"); subtitle: qsTr("Create a technical report that you can give to EasyComp Zeeland when you need help.") }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 210; radius: 16; color: root.panelRaised; border.color: root.border
                    ColumnLayout { anchors.fill: parent; anchors.margins: 22; spacing: 13
                        Text { text: qsTr("You stay in control"); color: root.textPrimary; font.pixelSize: 22; font.weight: Font.Bold }
                        Text { Layout.fillWidth: true; text: qsTr("The report contains system information, hardware, storage and failed services. Personal documents, passwords and browser history are not included."); color: root.textMuted; font.pixelSize: 14; wrapMode: Text.Wrap }
                        Text { Layout.fillWidth: true; text: qsTr("The file is stored locally and is never sent automatically."); color: root.good; font.pixelSize: 14; font.weight: Font.DemiBold; wrapMode: Text.Wrap }
                    }
                }
                RowLayout { Layout.fillWidth: true
                    FlatButton { text: qsTr("Create support report"); primary: true; enabled: !backend.busy; onClicked: backend.createSupportReport() }
                    BusyIndicator { running: backend.busy; visible: running }
                    Text { Layout.fillWidth: true; text: backend.status; color: root.textMuted; font.pixelSize: 14; wrapMode: Text.Wrap }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }

    Connections {
        target: backend
        function onDataReady(kind, payload) {
            try {
                const value = JSON.parse(payload)
                if (kind === "diagnostics") diagnostics = value
                else if (kind === "gaming") gaming = value
                else if (kind === "system") systemModules = value.modules || []
                else if (kind === "windows") windowsApps = value.apps || []
                else if (kind === "recovery-devices") recoveryDevices = value.devices || []
                else if (kind === "recovery-releases") recoveryReleases = value.releases || []
                else if (kind === "recovery-download") recoveryImage = "file://" + value.path
            } catch (error) {
                console.warn("ECZOS interface kon gegevens niet verwerken:", error)
            }
        }
    }

    Component.onCompleted: backend.refresh(backend.route)
}

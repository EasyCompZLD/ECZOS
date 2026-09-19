pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtQuick.Window

ApplicationWindow {
    id: window
    visible: true
    visibility: Window.FullScreen
    title: qsTr("Welcome to ECZOS")
    color: "#030812"

    property int page: 0
    property string selectedTheme: "auto"
    property int pageCount: 10
    property bool musicEnabled: true
    property string selectedBrowser: "firefox"

    ButtonGroup { id: browserGroup }

    MediaPlayer {
        id: backgroundVideo
        source: "file:///usr/share/eczos/oobe/assets/ambient-loop.mp4"
        videoOutput: videoOutput
        loops: MediaPlayer.Infinite
        Component.onCompleted: play()
    }

    AudioOutput {
        id: musicOutput
        volume: 0.32
        muted: !window.musicEnabled
    }

    MediaPlayer {
        id: introMusic
        source: "file:///usr/share/eczos/oobe/assets/new-dawn.m4a"
        audioOutput: musicOutput
        loops: MediaPlayer.Infinite
        Component.onCompleted: play()
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        color: "#061321"
        opacity: 0.70
    }

    OobeButton {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 22
        z: 4
        text: window.musicEnabled ? qsTr("Turn music off") : qsTr("Turn music on")
        icon.name: window.musicEnabled ? "audio-volume-high" : "audio-volume-muted"
        Accessible.name: text
        onClicked: window.musicEnabled = !window.musicEnabled
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(38, Math.min(window.width, window.height) * 0.065)
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            Image {
                source: "file:///usr/share/eczos/branding/logo/logo.png"
                sourceSize.width: 62
                sourceSize.height: 62
            }

            ColumnLayout {
                Label {
                    text: "EasyComp Zeeland Operating System"
                    color: "white"
                    font.pixelSize: 23
                    font.weight: Font.DemiBold
                }
                Label {
                    text: qsTr("Initial setup")
                    color: "#a9c7dc"
                    font.pixelSize: 15
                }
            }

            Item { Layout.fillWidth: true }
        }

        StackLayout {
            currentIndex: window.page
            Layout.fillWidth: true
            Layout.fillHeight: true

            OobePage {
                heading: qsTr("Welcome to ECZOS")
                body: qsTr("Your computer is ready. We will guide you through the most important choices and features.")
                detail: qsTr("You can always change these choices later in ECZOS Settings.")
                visual: "file:///usr/share/eczos/branding/screenshots/settings.png"
            }

            OobePage {
                heading: qsTr("Connect to a network")
                body: qsTr("An internet connection is needed for updates, new apps, browsers and online services.")
                detail: qsTr("Manage Wi-Fi and wired connections from the network icon or System Settings.")
                visual: "file:///usr/share/eczos/branding/screenshots/system-network.png"
                OobeButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Open network settings")
                    onClicked: oobe.openNetworkSettings()
                }
            }

            OobePage {
                heading: qsTr("Make ECZOS yours")
                body: qsTr("Choose a light, dark or automatic appearance. Wallpapers, icons, power management and accessibility are available in System Settings.")
                visual: window.selectedTheme === "dark"
                    ? "file:///usr/share/eczos/branding/screenshots/desktop-dark.png"
                    : "file:///usr/share/eczos/branding/screenshots/desktop-light.png"
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16
                    OobeButton { text: qsTr("Automatic"); checkable: true; checked: window.selectedTheme === "auto"; onClicked: { window.selectedTheme = "auto"; oobe.setTheme("auto") } }
                    OobeButton { text: qsTr("Light"); checkable: true; checked: window.selectedTheme === "light"; onClicked: { window.selectedTheme = "light"; oobe.setTheme("light") } }
                    OobeButton { text: qsTr("Dark"); checkable: true; checked: window.selectedTheme === "dark"; onClicked: { window.selectedTheme = "dark"; oobe.setTheme("dark") } }
                    OobeButton { text: qsTr("More settings"); onClicked: oobe.openSystemSettings() }
                }
            }

            OobePage {
                heading: qsTr("Choose your browser")
                body: qsTr("Select which browser should open web pages by default.")
                detail: window.selectedBrowser === "chrome"
                    ? qsTr("If Chrome is not installed yet, ECZOS will open the official download page when setup is complete.")
                    : window.selectedBrowser === "edge-windows"
                      ? qsTr("ECZOS will open the official Edge download and then ECZ Windows to manage the Windows installer.")
                      : qsTr("This browser is already included with the ECZOS desktop.")
                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 2
                    columnSpacing: 18
                    rowSpacing: 14

                    OobeButton {
                        text: "Firefox"
                        checkable: true
                        checked: window.selectedBrowser === "firefox"
                        ButtonGroup.group: browserGroup
                        onClicked: window.selectedBrowser = "firefox"
                    }
                    OobeButton {
                        text: "Google Chrome"
                        checkable: true
                        checked: window.selectedBrowser === "chrome"
                        ButtonGroup.group: browserGroup
                        onClicked: window.selectedBrowser = "chrome"
                    }
                    OobeButton {
                        text: qsTr("Microsoft Edge through ECZ Windows")
                        checkable: true
                        checked: window.selectedBrowser === "edge-windows"
                        ButtonGroup.group: browserGroup
                        onClicked: window.selectedBrowser = "edge-windows"
                    }
                    OobeButton {
                        text: "Konqueror"
                        checkable: true
                        checked: window.selectedBrowser === "konqueror"
                        ButtonGroup.group: browserGroup
                        onClicked: window.selectedBrowser = "konqueror"
                    }
                }
            }

            OobePage {
                heading: qsTr("Find apps with Discover")
                body: qsTr("Discover brings apps, games, system updates and firmware together in one place. Search by name and select Install.")
                detail: qsTr("ECZOS supports regular Debian packages and Flatpak apps.")
                visual: "file:///usr/share/eczos/branding/screenshots/application-menu.png"
                OobeButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Open Discover")
                    onClicked: oobe.openDiscover()
                }
            }

            OobePage {
                heading: qsTr("Keep your files safe")
                body: qsTr("Plasma Vaults lets you create encrypted vaults for private files.")
                detail: qsTr("Use the Start menu search to quickly find apps and files. Manage backups and recovery media in ECZOS Settings.")
                visual: "file:///usr/share/eczos/branding/screenshots/desktop-clean.png"
            }

            OobePage {
                heading: qsTr("Bring your files with you")
                body: qsTr("The migration assistant can transfer Documents, Pictures, Music and other personal folders from a Windows drive.")
                detail: qsTr("A preview is shown first. Nothing is copied without your confirmation.")
                visual: "file:///usr/share/eczos/branding/screenshots/migration.png"
                OobeButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Open migration assistant")
                    onClicked: oobe.openMigration()
                }
            }

            OobePage {
                heading: qsTr("Windows apps and games")
                body: qsTr("Open .exe and .msi files with ECZ Windows. Gaming checks help with Vulkan, controllers and Windows games.")
                detail: qsTr("Each managed Windows app gets its own environment and then appears in the Start menu.")
                visual: "file:///usr/share/eczos/branding/screenshots/game-running.png"
                OobeButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Open ECZOS Settings")
                    onClicked: oobe.openControlCenter()
                }
            }

            OobePage {
                heading: qsTr("Privacy and community")
                body: qsTr("ECZOS never sends a support report automatically. You decide what to share and when.")
                detail: qsTr("ECZOS uses the free KDE Plasma desktop. Support is available when you need help or want to report a problem.")
                visual: "file:///usr/share/eczos/branding/screenshots/about-system.png"
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16
                    OobeButton { text: qsTr("Privacy settings"); onClicked: oobe.openPrivacySettings() }
                    OobeButton { text: qsTr("About KDE Plasma"); onClicked: oobe.openKdeInformation() }
                }
            }

            OobePage {
                heading: qsTr("Everything is ready")
                body: qsTr("Welcome to ECZOS. Select Get started to apply your browser choice and finish setup.")
                detail: qsTr("The ECZOS welcome assistant remains available from the Start menu.")
                visual: "file:///usr/share/eczos/branding/screenshots/desktop-dark.png"
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: qsTr("%1 of %2").arg(window.page + 1).arg(window.pageCount)
                color: "#a9c7dc"
            }

            Repeater {
                model: window.pageCount
                delegate: Rectangle {
                    required property int index
                    width: index === window.page ? 28 : 9
                    height: 9
                    radius: 5
                    color: index === window.page ? "#36a9e1" : "#688094"
                    Behavior on width { NumberAnimation { duration: 150 } }
                }
            }

            Item { Layout.fillWidth: true }

            OobeButton {
                text: qsTr("Back")
                enabled: window.page > 0
                onClicked: window.page--
            }

            OobeButton {
                text: window.page === window.pageCount - 1 ? qsTr("Get started") : qsTr("Next")
                highlighted: true
                onClicked: {
                    if (window.page === window.pageCount - 1)
                        oobe.finish(window.selectedBrowser)
                    else
                        window.page++
                }
            }
        }
    }

    component OobePage: ColumnLayout {
        id: pageLayout
        property string heading
        property string body
        property string detail: ""
        property url visual: ""
        spacing: 22

        Item { Layout.fillHeight: true }
        Label {
            Layout.fillWidth: true
            text: pageLayout.heading
            color: "white"
            font.pixelSize: 40
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        Label {
            Layout.fillWidth: true
            Layout.maximumWidth: 880
            Layout.alignment: Qt.AlignHCenter
            text: pageLayout.body
            color: "#e3eef6"
            font.pixelSize: 21
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        Label {
            visible: pageLayout.detail.length > 0
            Layout.fillWidth: true
            Layout.maximumWidth: 840
            Layout.alignment: Qt.AlignHCenter
            text: pageLayout.detail
            color: "#a9c7dc"
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        Rectangle {
            visible: pageLayout.visual.toString().length > 0
            Layout.preferredWidth: Math.min(980, window.width * 0.72)
            Layout.preferredHeight: Math.min(410, window.height * 0.37)
            Layout.alignment: Qt.AlignHCenter
            radius: 14
            color: "#d9071829"
            border.color: "#47718e"
            clip: true
            Image {
                anchors.fill: parent
                anchors.margins: 7
                source: pageLayout.visual
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }
        Item { Layout.fillHeight: true }
    }

    component OobeButton: Button {
        id: control
        implicitHeight: 44
        leftPadding: 20
        rightPadding: 20
        font.pixelSize: 14
        font.weight: Font.DemiBold
        contentItem: Text {
            text: control.text
            color: control.enabled ? (control.highlighted || control.checked ? "#04121c" : "white") : "#7791a4"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 10
            color: control.down ? "#77d6fa"
                                : control.highlighted || control.checked ? "#36bdf4"
                                : control.hovered ? "#24475e" : "#132b3c"
            border.color: control.highlighted || control.checked ? "#78d8fb" : "#42647b"
            opacity: control.enabled ? 1 : 0.5
        }
    }
}

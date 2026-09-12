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
    title: "Welkom bij ECZOS"
    color: "#030812"

    property int page: 0
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

    ToolButton {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 22
        z: 4
        text: window.musicEnabled ? "Muziek uitzetten" : "Muziek aanzetten"
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
                    text: "Eerste configuratie"
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
                heading: "Welkom bij ECZOS"
                body: "Je computer is klaar. We lopen samen de belangrijkste keuzes en mogelijkheden langs."
                detail: "Je kunt deze instellingen later altijd wijzigen via het ECZOS Configuratiecentrum."
            }

            OobePage {
                heading: "Maak verbinding"
                body: "Internet is nodig voor updates, nieuwe apps, browsers en online diensten."
                detail: "Wifi en bekabelde verbindingen beheer je vanuit het netwerkicoon of Systeeminstellingen."
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Netwerkinstellingen openen"
                    onClicked: oobe.openNetworkSettings()
                }
            }

            OobePage {
                heading: "Maak ECZOS van jou"
                body: "Kies een lichte, donkere of automatisch wisselende weergave. Achtergronden, pictogrammen, energiebeheer en toegankelijkheid vind je in Systeeminstellingen."
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16
                    Button { text: "Automatisch"; onClicked: oobe.setTheme("auto") }
                    Button { text: "Licht"; onClicked: oobe.setTheme("light") }
                    Button { text: "Donker"; onClicked: oobe.setTheme("dark") }
                    Button { text: "Meer instellingen"; onClicked: oobe.openSystemSettings() }
                }
            }

            OobePage {
                heading: "Kies je browser"
                body: "Selecteer waarmee webpagina's standaard worden geopend."
                detail: window.selectedBrowser === "chrome"
                    ? "Chrome wordt na de configuratie via de officiële downloadpagina aangeboden."
                    : window.selectedBrowser === "edge-windows"
                      ? "Edge voor Windows wordt na de configuratie via ECZ Windows voorbereid."
                      : "Deze browser is al onderdeel van de ECZOS-desktop."
                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 2
                    columnSpacing: 18
                    rowSpacing: 14

                    Button {
                        text: "Firefox"
                        checkable: true
                        checked: window.selectedBrowser === "firefox"
                        ButtonGroup.group: browserGroup
                        onClicked: window.selectedBrowser = "firefox"
                    }
                    Button {
                        text: "Google Chrome"
                        checkable: true
                        checked: window.selectedBrowser === "chrome"
                        ButtonGroup.group: browserGroup
                        onClicked: window.selectedBrowser = "chrome"
                    }
                    Button {
                        text: "Microsoft Edge via ECZ Windows"
                        checkable: true
                        checked: window.selectedBrowser === "edge-windows"
                        ButtonGroup.group: browserGroup
                        onClicked: window.selectedBrowser = "edge-windows"
                    }
                    Button {
                        text: "Konqueror"
                        checkable: true
                        checked: window.selectedBrowser === "konqueror"
                        ButtonGroup.group: browserGroup
                        onClicked: window.selectedBrowser = "konqueror"
                    }
                }
            }

            OobePage {
                heading: "Apps vinden met Ontdekken"
                body: "In Ontdekken vind je programma's, games, systeemupdates en firmware op één plek."
                detail: "ECZOS ondersteunt normale Debian-pakketten en Flatpak-apps."
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Ontdekken openen"
                    onClicked: oobe.openDiscover()
                }
            }

            OobePage {
                heading: "Bestanden veilig bewaren"
                body: "Met Plasma Vaults kun je versleutelde kluizen voor privébestanden maken."
                detail: "Open het pijltje bij de systeemvakpictogrammen en kies Kluizen. Back-ups beheer je via het ECZOS Configuratiecentrum."
            }

            OobePage {
                heading: "Neem je bestanden mee"
                body: "De migratie-assistent kan Documenten, Afbeeldingen, Muziek en andere persoonlijke mappen vanaf een Windows-schijf overzetten."
                detail: "Er wordt eerst een voorbeeld getoond. Zonder jouw bevestiging wordt niets gekopieerd."
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Migratie-assistent openen"
                    onClicked: oobe.openMigration()
                }
            }

            OobePage {
                heading: "Windows-apps en games"
                body: "Open .exe- en .msi-bestanden met ECZ Windows. Gamingcontroles helpen met Vulkan, controllers en Windows-games."
                detail: "Iedere beheerde Windows-app krijgt een eigen omgeving en verschijnt daarna in het startmenu."
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Configuratiecentrum bekijken"
                    onClicked: oobe.openControlCenter()
                }
            }

            OobePage {
                heading: "Privacy en gemeenschap"
                body: "ECZOS verstuurt niet automatisch een supportrapport. Jij bepaalt wat je deelt en wanneer."
                detail: "ECZOS gebruikt de vrije KDE Plasma-desktop. Via ondersteuning kun je hulp krijgen en problemen melden."
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16
                    Button { text: "Privacy-instellingen"; onClicked: oobe.openPrivacySettings() }
                    Button { text: "Over KDE Plasma"; onClicked: oobe.openKdeInformation() }
                }
            }

            OobePage {
                heading: "Alles staat klaar"
                body: "Welkom bij ECZOS. Klik op Aan de slag om je browserkeuze toe te passen en de configuratie af te ronden."
                detail: "De ECZOS-welkomstassistent blijft beschikbaar in het startmenu."
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: (window.page + 1) + " van " + window.pageCount
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

            Button {
                text: "Vorige"
                enabled: window.page > 0
                onClicked: window.page--
            }

            Button {
                text: window.page === window.pageCount - 1 ? "Aan de slag" : "Volgende"
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
        Item { Layout.fillHeight: true }
    }
}

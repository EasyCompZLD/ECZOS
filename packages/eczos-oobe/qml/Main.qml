import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia

ApplicationWindow {
    id: window
    width: 1120
    height: 720
    minimumWidth: 900
    minimumHeight: 600
    visible: true
    title: "Welkom bij ECZOS"
    color: "#030812"

    property int page: 0
    property int pageCount: 5
    property bool musicEnabled: true

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
        opacity: 0.64
    }

    ToolButton {
        id: musicButton
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
        anchors.margins: 54
        spacing: 24

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
                body: "Je computer is klaar. In een paar korte stappen laten we de belangrijkste functies zien en kies je hoe ECZOS eruitziet."
                detail: "Windows-apps, games, updates, herstel en migratie zijn vanuit één vertrouwde desktop bereikbaar."
            }

            OobePage {
                heading: "Kies je uiterlijk"
                body: "Je kunt dit later altijd wijzigen via het ECZOS Configuratiecentrum."
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16
                    Button { text: "Automatisch"; onClicked: oobe.setTheme("auto") }
                    Button { text: "Licht"; onClicked: oobe.setTheme("light") }
                    Button { text: "Donker"; onClicked: oobe.setTheme("dark") }
                }
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
                heading: "Privacy en ondersteuning"
                body: "ECZOS verstuurt niet automatisch een supportrapport. Jij kiest zelf wanneer je diagnostische gegevens verzamelt en deelt."
                detail: "Het Configuratiecentrum geeft toegang tot apps, Windows-integratie, gaming, herstelmedia, hardwarecontrole en ondersteuning."
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Configuratiecentrum bekijken"
                    onClicked: oobe.openControlCenter()
                }
            }

            OobePage {
                heading: "Alles staat klaar"
                body: "Welkom bij ECZOS. Je kunt meteen aan de slag."
                detail: "De welkomstassistent blijft beschikbaar in het startmenu als je hem later opnieuw wilt bekijken."
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Repeater {
                model: window.pageCount
                Rectangle {
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
                        oobe.finish()
                    else
                        window.page++
                }
            }
        }
    }

    component OobePage: ColumnLayout {
        property string heading
        property string body
        property string detail: ""
        spacing: 22

        Item { Layout.fillHeight: true }
        Label {
            Layout.fillWidth: true
            text: heading
            color: "white"
            font.pixelSize: 38
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        Label {
            Layout.fillWidth: true
            Layout.maximumWidth: 780
            Layout.alignment: Qt.AlignHCenter
            text: body
            color: "#e3eef6"
            font.pixelSize: 21
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        Label {
            visible: detail.length > 0
            Layout.fillWidth: true
            Layout.maximumWidth: 760
            Layout.alignment: Qt.AlignHCenter
            text: detail
            color: "#a9c7dc"
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        Item { Layout.fillHeight: true }
    }
}

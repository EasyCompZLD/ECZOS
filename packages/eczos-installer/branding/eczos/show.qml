import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 12000
        repeat: true
        running: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Image { anchors.fill: parent; source: "eczos-welcome.png"; fillMode: Image.PreserveAspectCrop }
        Rectangle {
            anchors.centerIn: parent; width: parent.width * 0.82; height: parent.height * 0.58
            radius: 20; color: "#e6071829"
            Text {
                anchors.fill: parent; anchors.margins: 34
                text: qsTr("Welkom bij ECZOS\n\nEen vertrouwde desktop van EasyComp Zeeland. Alles wat je dagelijks nodig hebt staat straks voor je klaar.")
                color: "white"; font.pixelSize: 24; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Slide {
        Image { anchors.fill: parent; source: "eczos-welcome.png"; fillMode: Image.PreserveAspectCrop }
        Rectangle {
            anchors.centerIn: parent; width: parent.width * 0.82; height: parent.height * 0.58
            radius: 20; color: "#e6071829"
            Text {
                anchors.fill: parent; anchors.margins: 34
                text: qsTr("Je vertrouwde programma's\n\nOpen veel .exe- en .msi-bestanden gewoon via ECZ Windows. Geïnstalleerde programma's verschijnen in je startmenu.")
                color: "white"; font.pixelSize: 24; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Slide {
        Image { anchors.fill: parent; source: "eczos-welcome.png"; fillMode: Image.PreserveAspectCrop }
        Rectangle {
            anchors.centerIn: parent; width: parent.width * 0.82; height: parent.height * 0.58
            radius: 20; color: "#e6071829"
            Text {
                anchors.fill: parent; anchors.margins: 34
                text: qsTr("Klaar voor werk en school\n\nFreeOffice, Firefox, e-mail, video en handige bestandsprogramma's maken ECZOS direct bruikbaar.")
                color: "white"; font.pixelSize: 24; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Slide {
        Image { anchors.fill: parent; source: "eczos-welcome.png"; fillMode: Image.PreserveAspectCrop }
        Rectangle {
            anchors.centerIn: parent; width: parent.width * 0.82; height: parent.height * 0.58
            radius: 20; color: "#e6071829"
            Text {
                anchors.fill: parent; anchors.margins: 34
                text: qsTr("Ook voor games\n\nSteam en ondersteuning voor veel Windows-games zijn voorbereid. ECZOS helpt je hardware en controllers controleren.")
                color: "white"; font.pixelSize: 24; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Slide {
        Image { anchors.fill: parent; source: "eczos-welcome.png"; fillMode: Image.PreserveAspectCrop }
        Rectangle {
            anchors.centerIn: parent; width: parent.width * 0.82; height: parent.height * 0.58
            radius: 20; color: "#e6071829"
            Text {
                anchors.fill: parent; anchors.margins: 34
                text: qsTr("Neem je bestanden mee\n\nNa de installatie helpt de migratie-assistent je persoonlijke mappen vanaf een Windows-schijf overzetten. Je ziet altijd eerst wat er gebeurt.")
                color: "white"; font.pixelSize: 24; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Slide {
        Image { anchors.fill: parent; source: "eczos-welcome.png"; fillMode: Image.PreserveAspectCrop }
        Rectangle {
            anchors.centerIn: parent; width: parent.width * 0.82; height: parent.height * 0.58
            radius: 20; color: "#e6071829"
            Text {
                anchors.fill: parent; anchors.margins: 34
                text: qsTr("Jij houdt de controle\n\nMaak herstelmedia wanneer je wilt. ECZOS deelt geen supportrapport zonder jouw keuze.")
                color: "white"; font.pixelSize: 24; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }
}

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
            radius: 20; color: "#f2071829"
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
            radius: 20; color: "#f2071829"
            Text {
                anchors.fill: parent; anchors.margins: 34
                text: qsTr("Je vertrouwde programma's\n\nOpen veel Windows-programma's gewoon via ECZ Windows. Na installatie vind je ze terug in je startmenu.")
                color: "white"; font.pixelSize: 24; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Slide {
        Image { anchors.fill: parent; source: "eczos-welcome.png"; fillMode: Image.PreserveAspectCrop }
        Rectangle {
            anchors.centerIn: parent; width: parent.width * 0.82; height: parent.height * 0.58
            radius: 20; color: "#f2071829"
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
            radius: 20; color: "#f2071829"
            Text {
                anchors.fill: parent; anchors.margins: 34
                text: qsTr("Ook voor games\n\nSteam staat voor je klaar. Veel Windows-games werken via de ingebouwde compatibiliteitslaag.")
                color: "white"; font.pixelSize: 24; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Slide {
        Image { anchors.fill: parent; source: "eczos-welcome.png"; fillMode: Image.PreserveAspectCrop }
        Rectangle {
            anchors.centerIn: parent; width: parent.width * 0.82; height: parent.height * 0.58
            radius: 20; color: "#f2071829"
            Text {
                anchors.fill: parent; anchors.margins: 34
                text: qsTr("Neem je bestanden mee\n\nDe migratie-assistent helpt je documenten, foto's en muziek vanaf een Windows-schijf overzetten. Je ziet altijd eerst wat er gebeurt.")
                color: "white"; font.pixelSize: 24; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Slide {
        Image { anchors.fill: parent; source: "eczos-welcome.png"; fillMode: Image.PreserveAspectCrop }
        Rectangle {
            anchors.centerIn: parent; width: parent.width * 0.82; height: parent.height * 0.58
            radius: 20; color: "#f2071829"
            Text {
                anchors.fill: parent; anchors.margins: 34
                text: qsTr("Jij houdt de controle\n\nMaak herstelmedia wanneer je wilt. ECZOS deelt geen supportrapport zonder jouw keuze.")
                color: "white"; font.pixelSize: 24; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }
}

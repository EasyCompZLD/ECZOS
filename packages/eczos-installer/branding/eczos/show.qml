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
        Image {
            anchors.fill: parent
            source: "eczos-welcome.png"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.32
        }
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.78
            text: qsTr("Welkom bij ECZOS\n\nEen vertrouwde, snelle desktop van EasyComp Zeeland.")
            color: "white"
            font.pixelSize: 24
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Slide {
        Image {
            anchors.fill: parent
            source: "eczos-welcome.png"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.25
        }
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.78
            text: qsTr("Windows-apps zonder gedoe\n\nOpen .exe- en .msi-bestanden rechtstreeks. ECZOS houdt iedere Windows-app in een eigen, beheerde omgeving.")
            color: "white"
            font.pixelSize: 24
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Slide {
        Image {
            anchors.fill: parent
            source: "eczos-welcome.png"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.25
        }
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.78
            text: qsTr("Klaar voor games\n\nSteam, controllers, Vulkan-controle en Gaming Mode zijn ingebouwd. ECZOS kiest een passende Windows-runtime per game.")
            color: "white"
            font.pixelSize: 24
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Slide {
        Image {
            anchors.fill: parent
            source: "eczos-welcome.png"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.25
        }
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.78
            text: qsTr("Alles op één plek\n\nInstalleer en update Linux-apps, Flatpaks en firmware via Ontdekken. FreeOffice, Firefox, VLC en handige KDE-apps staan voor je klaar.")
            color: "white"
            font.pixelSize: 24
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Slide {
        Image {
            anchors.fill: parent
            source: "eczos-welcome.png"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.25
        }
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.78
            text: qsTr("Stap eenvoudig over\n\nDe migratie-assistent helpt persoonlijke mappen vanaf een Windows-schijf veilig over te zetten, met een controle vóórdat er iets wordt gekopieerd.")
            color: "white"
            font.pixelSize: 24
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Slide {
        Image {
            anchors.fill: parent
            source: "eczos-welcome.png"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.25
        }
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.78
            text: qsTr("Herstel en ondersteuning ingebouwd\n\nMaak herstelmedia, controleer hardware en stel een privacybewust supportrapport samen wanneer hulp nodig is.")
            color: "white"
            font.pixelSize: 24
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Slide {
        Image {
            anchors.fill: parent
            source: "eczos-welcome.png"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.25
        }
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.78
            text: qsTr("Jouw computer, jouw gegevens\n\nECZOS verstuurt niet automatisch een supportrapport. Jij bepaalt wat je deelt en wanneer.")
            color: "white"
            font.pixelSize: 24
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Slide {
        Image {
            anchors.fill: parent
            source: "eczos-welcome.png"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.25
        }
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.78
            text: qsTr("Bijna klaar\n\nNa de eerste aanmelding helpt de ECZOS-welkomstassistent met uiterlijk, migratie en de belangrijkste functies.")
            color: "white"
            font.pixelSize: 24
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}

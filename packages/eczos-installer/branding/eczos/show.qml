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

    component Feature: Item {
        id: feature
        property string heading
        property string body
        property url screenshot

        Image { anchors.fill: parent; source: "eczos-welcome.png"; fillMode: Image.PreserveAspectCrop }
        Rectangle { anchors.fill: parent; color: "#b005101c" }
        Rectangle {
            x: parent.width * 0.04
            y: parent.height * 0.15
            width: parent.width * 0.36
            height: parent.height * 0.70
            radius: 18
            color: "#f2071829"
            border.color: "#496b83"
            Text {
                anchors.fill: parent
                anchors.margins: 28
                text: qsTr(feature.heading + "\n\n" + feature.body)
                color: "white"
                font.pixelSize: 22
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }
        }
        Image {
            x: parent.width * 0.43
            y: parent.height * 0.09
            width: parent.width * 0.54
            height: parent.height * 0.82
            source: feature.screenshot
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    Slide {
        Feature {
            anchors.fill: parent
            heading: "Welkom bij ECZOS"
            body: "Een vertrouwde desktop van EasyComp Zeeland. Alles wat je dagelijks nodig hebt staat straks voor je klaar."
            screenshot: "file:///usr/share/eczos/branding/screenshots/settings.png"
        }
    }
    Slide {
        Feature {
            anchors.fill: parent
            heading: "Je vertrouwde programma's"
            body: "Open veel Windows-programma's gewoon via ECZ Windows. Na installatie vind je ze terug in je startmenu."
            screenshot: "file:///usr/share/eczos/branding/screenshots/windows-apps.png"
        }
    }
    Slide {
        Feature {
            anchors.fill: parent
            heading: "Klaar voor werk en school"
            body: "FreeOffice, Firefox, e-mail, video en handige bestandsprogramma's maken ECZOS direct bruikbaar."
            screenshot: "file:///usr/share/eczos/branding/screenshots/diagnostics.png"
        }
    }
    Slide {
        Feature {
            anchors.fill: parent
            heading: "Ook voor games"
            body: "Steam staat voor je klaar. Veel Windows-games werken via de ingebouwde compatibiliteitslaag."
            screenshot: "file:///usr/share/eczos/branding/screenshots/gaming.png"
        }
    }
    Slide {
        Feature {
            anchors.fill: parent
            heading: "Neem je bestanden mee"
            body: "De migratie-assistent helpt je documenten, foto's en muziek vanaf een Windows-schijf overzetten. Je ziet altijd eerst wat er gebeurt."
            screenshot: "file:///usr/share/eczos/branding/screenshots/migration.png"
        }
    }
    Slide {
        Feature {
            anchors.fill: parent
            heading: "Jij houdt de controle"
            body: "Maak herstelmedia wanneer je wilt. ECZOS deelt geen supportrapport zonder jouw keuze."
            screenshot: "file:///usr/share/eczos/branding/screenshots/recovery.png"
        }
    }
}

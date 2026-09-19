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
                text: feature.heading + "\n\n" + feature.body
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
            heading: qsTr("Welcome to ECZOS")
            body: qsTr("A familiar desktop from EasyComp Zeeland. Everything you need every day will be ready for you.")
            screenshot: "file:///usr/share/eczos/branding/screenshots/oobe-welcome.png"
        }
    }
    Slide {
        Feature {
            anchors.fill: parent
            heading: qsTr("Your familiar applications")
            body: qsTr("Open many Windows applications with ECZ Windows. After installation, you will find them in the Start menu.")
            screenshot: "file:///usr/share/eczos/branding/screenshots/windows-apps.png"
        }
    }
    Slide {
        Feature {
            anchors.fill: parent
            heading: qsTr("Ready for work and school")
            body: qsTr("FreeOffice, Firefox, email, video and useful file utilities make ECZOS ready to use.")
            screenshot: "file:///usr/share/eczos/branding/screenshots/application-menu.png"
        }
    }
    Slide {
        Feature {
            anchors.fill: parent
            heading: qsTr("Made for gaming too")
            body: qsTr("Steam is ready for you. Many Windows games work through the built-in compatibility layer.")
            screenshot: "file:///usr/share/eczos/branding/screenshots/steam-library-content.png"
        }
    }
    Slide {
        Feature {
            anchors.fill: parent
            heading: qsTr("Bring your files with you")
            body: qsTr("The migration assistant helps transfer documents, photos and music from a Windows drive. You always see what will happen first.")
            screenshot: "file:///usr/share/eczos/branding/screenshots/migration.png"
        }
    }
    Slide {
        Feature {
            anchors.fill: parent
            heading: qsTr("You stay in control")
            body: qsTr("Create recovery media whenever you want. ECZOS never shares a support report without your choice.")
            screenshot: "file:///usr/share/eczos/branding/screenshots/recovery.png"
        }
    }
}

import QtQuick
import QtMultimedia

Rectangle {
    id: root
    color: "#020713"

    property int stage

    Image {
        anchors.fill: parent
        source: "file:///usr/share/eczos/branding/wallpapers/eczoswallpaper-dark.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    MediaPlayer {
        id: startupAnimation
        source: Qt.resolvedUrl("eczos-startup.mp4")
        videoOutput: videoOutput
        loops: MediaPlayer.Infinite
        Component.onCompleted: play()
    }

    Rectangle {
        anchors.fill: parent
        color: "#020713"
        opacity: startupAnimation.error === MediaPlayer.NoError ? 0 : 0.18
    }
}

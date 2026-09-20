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

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("eczos-startup-poster.png")
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
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
        playbackRate: 2.0
        loops: 1

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia) {
                position = 4000
                play()
            }
        }

        onPositionChanged: {
            if (startupAnimation.position >= 9000)
                pause()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#020713"
        opacity: startupAnimation.error === MediaPlayer.NoError ? 0 : 0.18
    }
}

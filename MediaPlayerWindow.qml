import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Wayland
import QtQuick.Controls
import QtQuick.Effects

PopupWindow {
  id: musicPanel

  property bool open: true

  color: '#c8000000'
  anchor.window: toplevel
  property real padding: 20
  implicitWidth: 300 + padding * 2
  implicitHeight: musicPanelContents.implicitHeight + padding * 2
  anchor.rect.x: toplevel.width - this.width - 20
  anchor.rect.y: toplevel.height - this.height - 20
  visible: open
  /*
  mask: Region {
    item: Rectangle {
      width: 0
      height: 0
    }
  }*/

  ColumnLayout {
    id: musicPanelContents
    implicitWidth: 300
    anchors.fill: parent
    anchors.margins: musicPanel.padding
    spacing: 0

    Item {
      Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
      Layout.fillWidth: true
      Layout.preferredHeight: 30
      Layout.bottomMargin: 15
      Rectangle {
        id: titleTextContainer
        anchors.fill: parent
        clip: true
        anchors.horizontalCenter: parent.horizontalCenter

        color: "transparent"

        Text {
          id: titleText

          property bool isScrolling: titleTextMetrics.width > titleTextContainer.width
          property real scrollTextPos: 0
          property string scrollText: (MediaState.title + " ".repeat(5)).repeat(3)

          font.pixelSize: parent.height * .8
          anchors.fill: parent
          horizontalAlignment: isScrolling ? Text.AlignLeft : Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: isScrolling ? scrollText : MediaState.title
          font.italic: !MediaState.mediaExists
          color: "white"

          TextMetrics {
            id: scrollTitleWrapMetrics

            font: titleText.font
            text: MediaState.title + " ".repeat(5)
          }

          TextMetrics {
            id: titleTextMetrics

            font: titleText.font
            text: MediaState.title
          }

          transform: Translate {
            x: titleText.isScrolling ? titleText.scrollTextPos : 0
            y: 0
          }
        }

        FrameAnimation {
          running: titleText.isScrolling
          onTriggered: {
            if (titleText.scrollTextPos < -scrollTitleWrapMetrics.width) {
              titleText.scrollTextPos = -(titleText.scrollTextPos + scrollTitleWrapMetrics.width);
            } else {
              titleText.scrollTextPos -= 80 * frameTime;
            }
          }
        }
      }
    }
    Canvas {
      id: audioVis
      Layout.alignment: Qt.AlignHCenter
      Layout.fillWidth: true
      Layout.preferredHeight: 50
      Layout.bottomMargin: 5
      onPaint: {
        drawAudioVis()
      }
      function drawAudioVis() {
        var ctx = getContext("2d");
        ctx.fillStyle = Qt.rgba(.3, .8, .5, 1);
    
        for (let i = 0; i < 300; i++) {
          ctx.ellipse(i / 300 * width, Math.abs(AudioVisData.data[i]) * 10, 3, 3);
          if (i === 67) {
            console.info(i / 300 * width, Math.abs(AudioVisData.data[i]) * 10)
          }
        }
        ctx.fill()
      }
    }
    FrameAnimation {
      running: true
      onTriggered: {
        audioVis.drawAudioVis()
      }
    }
    Item {
      id: mediaProgressBar
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredHeight: 5
      Layout.fillWidth: true

      property real seekAreaWidth: mediaProgressBar.width - seekCursor.width
      property bool isSeeking: false
      property real seekProgress

      MouseArea {
        property real padding: 5
        width: parent.width + this.padding * 2
        height: parent.height + this.padding * 2
        anchors.centerIn: parent
        cursorShape: Qt.SplitHCursor
        onPressed: mouse => {
          mediaProgressBar.isSeeking = true;
          mediaProgressBar.seekProgress = Math.max(Math.min(mouse.x / mediaProgressBar.seekAreaWidth, 1), 0);
        }
        onMouseXChanged: mouse => {
          mediaProgressBar.seekProgress = Math.max(Math.min(mouse.x / mediaProgressBar.seekAreaWidth, 1), 0);
        }
        onReleased: {
          MediaState.seek(MediaState.length * mediaProgressBar.seekProgress);
          mediaProgressBar.isSeeking = false;
        }
      }
      Rectangle {
        implicitHeight: 5
        width: parent.width
        anchors.centerIn: parent
        color: "red"
      }
      Rectangle {
        id: seekCursor
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 5
        x: mediaProgressBar.isSeeking ? mediaProgressBar.seekProgress * mediaProgressBar.seekAreaWidth : MediaState.currentPos / MediaState.length * mediaProgressBar.seekAreaWidth
      }
      Text {
        x: 0
        anchors.top: mediaProgressBar.bottom
        text: `${Utils.formatTime(MediaState.currentPos)} / ${Utils.formatTime(MediaState.length)}`
        color: Qt.rgba(1, 1, 1, 1)
      }
    }

    RowLayout {
      Layout.preferredHeight: 30
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignHCenter
      Layout.topMargin: 5

      spacing: 10
      GButton {
        iconSource: Qt.resolvedUrl("./assets/prev.svg")
        onPressed: {
          MediaState.previous();
        }
      }
      GButton {
        iconSource: MediaState.isPlaying ? Qt.resolvedUrl("./assets/pause.svg") : Qt.resolvedUrl("./assets/play.svg")
        onPressed: {
          MediaState.togglePlaying();
        }
      }
      GButton {
        iconSource: Qt.resolvedUrl("./assets/next.svg")
        onPressed: {
          MediaState.next();
        }
      }
    }
  }

  // overlay items
  Item {
    Rectangle {
      id: seekCursorLabel
      opacity: mediaProgressBar.isSeeking ? 1 : 0
      Behavior on opacity {
        NumberAnimation {
          duration: 160
        }
      }
      x: 0
      y: 0
      property real padding: 3
      height: seekProgressLabel.implicitHeight + padding * 2
      width: seekProgressLabel.implicitWidth + padding * 2
      z: 100
      color: '#d3000000'
      Text {
        id: seekProgressLabel
        anchors.centerIn: parent
        text: Utils.formatTime(mediaProgressBar.seekProgress * MediaState.length)
        color: "white"
      }
      Connections {
        target: seekCursor

        function onXChanged() {
          seekCursorLabel.x = seekCursor.mapToItem(null, 0, 0).x - seekCursorLabel.width / 2;
          seekCursorLabel.y = seekCursor.mapToItem(null, 0, 0).y + seekCursor.height;
        }
      }
    }
  }

  IpcHandler {
    function setOpen(open: bool) {
      musicPanel.open = open;
    }

    function isOpen(): bool {
      return musicPanel.open;
    }

    function toggleOpen() {
      musicPanel.open = !musicPanel.open;
    }

    target: "musicPanel"
  }
}

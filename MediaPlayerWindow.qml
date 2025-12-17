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

  color: '#b1000000'
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
  FontLoader {
    id: notoSansFont
    source: "https://fonts.gstatic.com/s/nunito/v32/XRXV3I6Li01BKofINeaB.woff2"
  }
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
      Layout.bottomMargin: 5
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

          font.family: "Noto Sans"
          font.pixelSize: parent.height * .8
          font.italic: !MediaState.mediaExists
          font.weight: Font.Normal
          anchors.fill: parent
          horizontalAlignment: isScrolling ? Text.AlignLeft : Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: isScrolling ? scrollText : MediaState.title
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
      id: audioVisDisplay
      Layout.alignment: Qt.AlignHCenter
      Layout.fillWidth: true
      Layout.preferredHeight: 60
      Layout.bottomMargin: 10
      property var ctx
      property real ft_sample_count: 200
      onPaint: {
        if (!Function.__audioVis)
          return;
        let audioVis = Function.__audioVis;
        if (!audioVisDisplay.ctx)
          audioVisDisplay.ctx = getContext("2d");
        let ctx = audioVisDisplay.ctx;

  

        ctx.reset();
        ctx.beginPath();

        let maxVisualizerHeight = 25;
        let minBaseHeight = 1;
        let maxBaseHeight = audioVisDisplay.height / 2 - maxVisualizerHeight;
        let visualizerHeightRamp = 12;
        let baseHeightRamp = 15;
        for (let i = 0; i < audioVisDisplay.ft_sample_count; i++) {
          let val = audioVis.data1[i];

          let visualizerScale = (maxVisualizerHeight * audioVis.volume1 ** 2) / (audioVis.volume1 ** 2 + visualizerHeightRamp);
          let baseScale = (audioVis.volume1 ** 2) / (audioVis.volume1 ** 2 + baseHeightRamp);
          ctx.lineTo(i / (audioVisDisplay.ft_sample_count - 1) * audioVisDisplay.width, val * visualizerScale + audioVisDisplay.height / 2 + minBaseHeight + (maxBaseHeight - minBaseHeight) * baseScale);
        }
        for (let i = audioVisDisplay.ft_sample_count - 1; i >= 0; i--) {
          let val = audioVis.data0[i];
          let visualizerScale = (maxVisualizerHeight * audioVis.volume0 ** 2) / (audioVis.volume0 ** 2 + visualizerHeightRamp);
          let baseScale = (audioVis.volume0 ** 2) / (audioVis.volume0 ** 2 + baseHeightRamp);
          ctx.lineTo(i / (audioVisDisplay.ft_sample_count - 1) * audioVisDisplay.width, audioVisDisplay.height / 2 - val * visualizerScale - minBaseHeight - (maxBaseHeight - minBaseHeight) * baseScale);
        }

        ctx.closePath();
        let col = (Date.now() * 1 / 3 % 1000) / 1000
        ctx.fillStyle = Qt.hsla(col, 1, .95, 1);
        ctx.strokeStyle = Qt.hsla(col, 1, .5, 1)
        ctx.strokeWidth = 2
        ctx.fill();
        ctx.stroke();
      }

      Process {
        running: true
        // 10 mel is around 20hz, 1500 is around 2000
        command: ["~/.config/quickshell/audiowiz/audiowiz", "10", "1500", audioVisDisplay.ft_sample_count]

        stdout: SplitParser {
          onRead: text => {
            // global obj prop because theres a memory leak if normal qml properties are used
            if (!Function.__audioVis)
              Function.__audioVis = {
                data0: Array(audioVisDisplay.ft_sample_count),
                data1: Array(audioVisDisplay.ft_sample_count),
                volume0: 0,
                volume1: 0,
              };
            Function.__audioVis.lastUpdate = Date.now()
            let [dft0, dft1, volume0, volume1] = text.trim().split("|");
            dft0.split(" ").forEach((n, i) => {
              Function.__audioVis.data0[i] = +n;
            });
            dft1.split(" ").forEach((n, i) => {
              Function.__audioVis.data1[i] = +n;
            });
            Function.__audioVis.volume0 = +volume0;
            Function.__audioVis.volume1 = +volume1;
            audioVisDisplay.requestPaint();
          }
        }
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
        font.family: "Noto Sans"
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
      Layout.topMargin: 8

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

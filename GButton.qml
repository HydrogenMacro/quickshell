import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
  id: root
  property string iconSource
  signal pressed

  color: "transparent"
  width: 30
  height: 30
  MouseArea {
    enabled: true
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      root.pressed();
    }
  }
  Image {
    anchors.centerIn: parent
    source: root.iconSource
    width: 20
    height: 20
  }
}

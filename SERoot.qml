import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Scope {
  Variants {
    model: Quickshell.screens
    delegate: Component {
      Item {
        id: root
        property var modelData

        PanelWindow {
          id: toplevel
          color: "transparent"
          mask: Region {
            item: null
          }
          
          anchors {
            bottom: true
            right: true
            left: true
            top: true
          }
          visible: true
          
          screen: root.modelData
          
          MediaPlayerWindow {}
        }
      }
    }
  }
}

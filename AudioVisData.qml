pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  property list<real> data
  Process {
    running: true
    command: ["/home/hydro/.config/quickshell/audiowiz/audiowiz"]
    
    stdout: SplitParser {
      onRead: (text) => {
        data = text.trim().split(" ").map(a => +a)
      }
    }
  }
}

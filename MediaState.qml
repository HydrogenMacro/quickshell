pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Services.Mpris

Singleton {
  property bool mediaExists: Mpris.players.values[0] || false
  property bool isPlaying: Mpris.players.values[0]?.isPlaying || false
  property string title: Mpris.players.values[0]?.trackTitle || "No Media Playing"
  property string artist: Mpris.players.values[0]?.trackArtist || "Unknown"
  property real currentPos: Mpris.players.values[0]?.position || 0
  property real length: Mpris.players.values[0]?.length || 0
  function updateCurrentPos() {
    currentPos = Mpris.players.values[0]?.position || 0;

    // fix when currentPos sometimes adds the track length to itself
    if (currentPos > length) {
        currentPos -= length
    }
  }
  function togglePlaying() {
    Mpris.players.values[0].togglePlaying();
  }
  function play() {
    Mpris.players.values[0].play();
  }
  function pause() {
    Mpris.players.values[0].pause();
  }
  function next() {
    Mpris.players.values[0].next();
  }
  function previous() {
    Mpris.players.values[0].previous();
  }
  function seek(pos: real) {
    Mpris.players.values[0].position = pos
    this.currentPos = pos
  }
  Timer {
    running: MediaState.isPlaying
    interval: 1000
    repeat: true
    onTriggered: MediaState.updateCurrentPos()
  }
}

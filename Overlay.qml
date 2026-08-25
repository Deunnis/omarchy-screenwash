import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: panel

  property string mode: "wash"
  property color washColor: "red"
  property real dimOpacity: 0

  visible: false
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  color: "transparent"

  WlrLayershell.namespace: "omarchy-screenwash"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  mask: Region {}

  Rectangle {
    anchors.fill: parent
    visible: panel.mode === "wash"
    color: panel.washColor
    opacity: 1.0
  }

  Rectangle {
    anchors.fill: parent
    visible: panel.mode === "dim"
    color: "black"
    opacity: panel.dimOpacity
  }
}

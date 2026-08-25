// Screen Wash toggle button
import QtQuick
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "daan.screenwash"

  readonly property var washService: bar && bar.shell ? bar.shell.serviceFor("daan.screenwash") : null
  readonly property bool active: washService ? washService.enabled : false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍹"
    active: root.active
    dimmed: !root.active
    tooltipText: root.active ? "Screen Wash: ON (click to disable)" : "Screen Wash: OFF (click to enable)"
    slotSize: Style.bar.statusSlot

    onPressed: function() {
      if (root.washService) root.washService.toggle()
    }
  }
}

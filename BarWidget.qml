import QtQuick
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "daan.screenwash"

  readonly property var washService: bar && bar.shell ? bar.shell.serviceFor("daan.screenwash") : null
  readonly property bool serviceEnabled: washService ? washService.enabled : false

  property bool popupEnabled: serviceEnabled

  readonly property int settingInterval: clampInt(setting("intervalMinutes", 30), 30, 5, 240)
  readonly property int settingDuration: clampInt(setting("durationMs", 1500), 1500, 500, 10000)
  readonly property string settingMode: setting("mode", "wash") === "dim" ? "dim" : "wash"
  readonly property bool settingSkipFs: typeof setting("skipWhenFullscreen", true) === "boolean"
    ? setting("skipWhenFullscreen", true) : true

  property int liveInterval: settingInterval
  property int liveDuration: settingDuration
  property string liveMode: settingMode
  property bool liveSkipFs: settingSkipFs

  property bool popupOpen: false
  property bool settingsDirty: false

  function clampInt(val, fallback, min, max) {
    var n = parseInt(val)
    if (isNaN(n)) return fallback
    return Math.max(min, Math.min(max, n))
  }

  function persist(key, value) {
    var entry = { id: root.moduleName }
    for (var k in root.settings) {
      if (k !== "id") entry[k] = root.settings[k]
    }
    entry[key] = value
    root.settings = entry
    root.settingsDirty = true
  }

  function flushSettings() {
    if (!root.settingsDirty) return
    root.settingsDirty = false
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, root.settings)
  }

  function applyToService() {
    if (washService) {
      washService.applySettings({
        intervalMinutes: liveInterval,
        durationMs: liveDuration,
        mode: liveMode,
        skipWhenFullscreen: liveSkipFs
      })
    }
  }

  onPopupOpenChanged: {
    if (!popupOpen) {
      flushSettings()
      applyToService()
    }
  }

  Connections {
    target: root.washService
    function onEnabledChanged() {
      root.popupEnabled = root.washService.enabled
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍹"
    active: root.serviceEnabled
    dimmed: !root.serviceEnabled
    tooltipText: root.serviceEnabled ? "Screen Wash: ON" : "Screen Wash: OFF"
    slotSize: Style.bar.statusSlot

    onPressed: function() {
      root.popupOpen = !root.popupOpen
    }
  }

  PopupCard {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(260))
    contentHeight: popup.fittedContentHeight(Math.max(contentCol.childrenRect.height + Style.space(32), Style.space(200)))

    onOpenChanged: {
      if (!bar) return
      if (open) bar.requestPopout(root)
      else if (bar.activePopout === root) bar.releasePopout(root)
    }

    function close() { root.popupOpen = false }

    Column {
      id: contentCol
      anchors.fill: parent
      anchors.margins: Style.space(16)
      spacing: Style.space(12)

      // Title + toggle
      Row {
        width: parent.width
        spacing: Style.space(8)

        Text {
          text: "Screen Wash"
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
          color: Color.popups.text
          anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
          width: 44; height: 24; radius: 12
          color: root.popupEnabled ? Color.accent : Color.muted
          anchors.verticalCenter: parent.verticalCenter

          Rectangle {
            x: root.popupEnabled ? 22 : 2; y: 2; width: 20; height: 20; radius: 10
            color: "white"
          }

          MouseArea {
            anchors.fill: parent
            onClicked: {
              root.popupEnabled = !root.popupEnabled
              if (root.washService) root.washService.toggle()
            }
          }
        }
      }

      PanelSeparator { width: parent.width }

      // Mode
      Column {
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: "Mode"
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          color: Color.muted
        }

        Row {
          spacing: Style.space(6)
          Repeater {
            model: ["wash", "dim"]
            delegate: Rectangle {
              width: 56; height: 28; radius: 6
              color: root.liveMode === modelData ? Color.accent : Color.popups.background
              border.width: 1; border.color: root.liveMode === modelData ? Color.accent : Color.popups.border

              Text {
                anchors.centerIn: parent
                text: modelData === "wash" ? "Wash" : "Dim"
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                color: root.liveMode === modelData ? "white" : Color.popups.text
              }

              MouseArea {
                anchors.fill: parent
                onClicked: {
                  root.liveMode = modelData
                  root.persist("mode", modelData)
                }
              }
            }
          }
        }
      }

      // Interval
      Column {
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: "Interval"
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          color: Color.muted
        }

        Row {
          spacing: Style.space(6)
          anchors.horizontalCenter: parent.horizontalCenter

          Repeater {
            model: [15, 30, 60, 120]
            delegate: Rectangle {
              width: 44; height: 28; radius: 6
              color: root.liveInterval === modelData ? Color.accent : Color.popups.background
              border.width: 1; border.color: root.liveInterval === modelData ? Color.accent : Color.popups.border

              Text {
                anchors.centerIn: parent
                text: modelData + "m"
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                color: root.liveInterval === modelData ? "white" : Color.popups.text
              }

              MouseArea {
                anchors.fill: parent
                onClicked: {
                  root.liveInterval = modelData
                  root.persist("intervalMinutes", modelData)
                }
              }
            }
          }
        }
      }

      // Duration
      Column {
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: "Duration"
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          color: Color.muted
        }

        Row {
          spacing: Style.space(6)
          anchors.horizontalCenter: parent.horizontalCenter

          Repeater {
            model: [500, 1000, 1500, 3000]
            delegate: Rectangle {
              width: 48; height: 28; radius: 6
              color: root.liveDuration === modelData ? Color.accent : Color.popups.background
              border.width: 1; border.color: root.liveDuration === modelData ? Color.accent : Color.popups.border

              Text {
                anchors.centerIn: parent
                text: modelData >= 1000 ? (modelData / 1000) + "s" : modelData + "ms"
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                color: root.liveDuration === modelData ? "white" : Color.popups.text
              }

              MouseArea {
                anchors.fill: parent
                onClicked: {
                  root.liveDuration = modelData
                  root.persist("durationMs", modelData)
                }
              }
            }
          }
        }
      }

      // Skip when fullscreen
      Row {
        width: parent.width
        spacing: Style.space(8)

        Text {
          text: "Skip if fullscreen"
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          color: Color.popups.text
          anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
          width: 44; height: 24; radius: 12
          color: root.liveSkipFs ? Color.accent : Color.muted
          anchors.verticalCenter: parent.verticalCenter

          Rectangle {
            x: root.liveSkipFs ? 22 : 2; y: 2; width: 20; height: 20; radius: 10
            color: "white"
          }

          MouseArea {
            anchors.fill: parent
            onClicked: {
              root.liveSkipFs = !root.liveSkipFs
              root.persist("skipWhenFullscreen", root.liveSkipFs)
            }
          }
        }
      }
    }
  }
}

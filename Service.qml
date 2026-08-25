import QtQuick
import Quickshell
import Quickshell.Io
import "ScreenWashModel.js" as ScreenWashModel

Item {
  id: root

  property var shell: null
  property var manifest: null

  property int intervalMinutes: 30
  property int durationMs: 1500
  property string mode: "wash"
  property bool skipWhenFullscreen: true

  property bool enabled: true
  property bool isWashing: false
  property bool isFullscreen: false
  property real washProgress: 0.0

  PersistentProperties {
    id: persisted
    reloadableId: "omarchy-screenwash"
    property bool enabled: true
  }

  function applySettings(settings) {
    if (!settings) return
    var changed = false
    var newInterval = clampInt(settings.intervalMinutes, intervalMinutes, 5, 240)
    var newDuration = clampInt(settings.durationMs, durationMs, 500, 10000)
    if (newInterval !== intervalMinutes) { intervalMinutes = newInterval; changed = true }
    if (newDuration !== durationMs) { durationMs = newDuration; changed = true }
    if (settings.mode === "wash" || settings.mode === "dim") {
      if (settings.mode !== mode) { mode = settings.mode; changed = true }
    }
    if (typeof settings.skipWhenFullscreen === "boolean") {
      if (settings.skipWhenFullscreen !== skipWhenFullscreen) {
        skipWhenFullscreen = settings.skipWhenFullscreen; changed = true
      }
    }
    if (changed) washTimer.interval = intervalMinutes * 60 * 1000
  }

  function clampInt(val, fallback, min, max) {
    var n = parseInt(val)
    if (isNaN(n)) return fallback
    return Math.max(min, Math.min(max, n))
  }

  Component.onCompleted: {
    enabled = persisted.enabled
    if (manifest && manifest.service && manifest.service.defaults) {
      applySettings(manifest.service.defaults)
    }
  }

  function toggle() {
    enabled = !enabled
    persisted.enabled = enabled
  }

  Timer {
    id: washTimer
    interval: root.intervalMinutes * 60 * 1000
    running: root.enabled
    repeat: true
    triggeredOnStart: root.enabled
    onTriggered: root.startWash()
  }

  Process {
    id: fullscreenCheck
    command: ["hyprctl", "activewindow", "-j"]
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var data = JSON.parse(line)
          root.isFullscreen = (data.fullscreen === true || data.fullscreen === 1)
        } catch(e) {
          root.isFullscreen = false
        }
      }
    }
    onExited: {
      if (root.skipWhenFullscreen && root.isFullscreen) {
        return
      }
      root.beginOverlay()
    }
  }

  function startWash() {
    if (isWashing || !enabled) return
    if (skipWhenFullscreen) {
      fullscreenCheck.running = true
    } else {
      beginOverlay()
    }
  }

  function beginOverlay() {
    isWashing = true
    washProgress = 0.0
    washDurationTimer.restart()
  }

  function forceTrigger() {
    isFullscreen = false
    beginOverlay()
  }

  Timer {
    id: washDurationTimer
    interval: 16
    repeat: true
    onTriggered: {
      root.washProgress += 16.0 / root.durationMs
      if (root.washProgress >= 1.0) {
        root.washProgress = 1.0
        root.stopWash()
      }
    }
  }

  function stopWash() {
    washDurationTimer.stop()
    isWashing = false
    washProgress = 0.0
  }

  function getWashColor(progress) {
    return ScreenWashModel.getWashColor(progress)
  }

  function getDimOpacity(progress) {
    return Math.sin(progress * Math.PI) * 0.85
  }

  IpcHandler {
    target: "daan.screenwash"

    function trigger(): string {
      root.forceTrigger()
      return JSON.stringify({ status: "triggered" })
    }

    function status(): string {
      return JSON.stringify({
        enabled: root.enabled,
        isWashing: root.isWashing,
        isFullscreen: root.isFullscreen,
        mode: root.mode,
        intervalMinutes: root.intervalMinutes,
        durationMs: root.durationMs,
        skipWhenFullscreen: root.skipWhenFullscreen,
        washProgress: root.washProgress
      })
    }
  }

  Overlay {
    id: overlay
    visible: root.isWashing
    mode: root.mode
    washColor: root.mode === "wash" ? root.getWashColor(root.washProgress) : "black"
    dimOpacity: root.mode === "dim" ? root.getDimOpacity(root.washProgress) : 0
  }
}

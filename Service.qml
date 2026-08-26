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

  // hyprctl's activewindow JSON can, in principle, embed a window title/class
  // of attacker-influenced length (e.g. a hostile page setting its tab title).
  // Piping through `head -c` bounds how many bytes can ever reach
  // StdioCollector's buffer - a JS-side length check after the fact would run
  // too late, since the collector already buffers everything before onExited
  // (and any parsing) ever fires. fullscreenCheckDeadline guards the other
  // failure mode: if hyprctl itself hangs, nothing else would ever time it
  // out, and since startWash() won't re-issue a check while one is still
  // "running", a single hang would silently disable the periodic fullscreen
  // check (and therefore this plugin's whole anti-burn-in purpose) until the
  // shell restarts.
  property int maxFullscreenCheckBytes: 65536

  Process {
    id: fullscreenCheck
    // Set once the deadline timer below has already force-killed and acted
    // on this run - onExited still fires later once the kill lands, and
    // without this flag it would call beginOverlay() a second time on top
    // of the one the deadline timer already triggered.
    property bool timedOut: false
    command: ["bash", "-c", "exec hyprctl activewindow -j | head -c " + root.maxFullscreenCheckBytes]
    // `hyprctl -j` output is pretty-printed, real multi-line JSON (confirmed
    // directly - a single activewindow response is ~35+ lines) - a single
    // line is never valid JSON on its own, so this needs the whole output
    // collected before parsing, not SplitParser's one-line-at-a-time onRead.
    stdout: StdioCollector {
      id: fullscreenCheckOut
      waitForEnd: true
    }
    onRunningChanged: {
      if (running) {
        timedOut = false
        fullscreenCheckDeadline.restart()
      } else {
        fullscreenCheckDeadline.stop()
      }
    }
    onExited: {
      if (timedOut) return // already handled by fullscreenCheckDeadline
      try {
        var data = JSON.parse(fullscreenCheckOut.text)
        root.isFullscreen = (data.fullscreen === true || data.fullscreen === 1)
      } catch (e) {
        // Truncated by the byte cap above, or otherwise malformed - fail
        // open (see fullscreenCheckDeadline's onTriggered for why).
        root.isFullscreen = false
      }
      if (root.skipWhenFullscreen && root.isFullscreen) {
        return
      }
      root.beginOverlay()
    }
  }

  // Process.running = false (and even the documented .signal()) don't
  // reliably terminate a still-running process on this Quickshell build -
  // confirmed the hard way while hardening a different plugin. Killing by
  // PID via an external `kill` is the only approach that actually works.
  Timer {
    id: fullscreenCheckDeadline
    interval: 2000
    repeat: false
    onTriggered: {
      if (!fullscreenCheck.running) return
      fullscreenCheck.timedOut = true
      killFullscreenCheckProc.command = ["kill", String(fullscreenCheck.processId)]
      killFullscreenCheckProc.running = true
      // Don't wait on the kill to land before deciding: fail open (treat as
      // "not fullscreen") rather than leaving the wash blocked indefinitely
      // on a command that has already proven it might hang.
      root.isFullscreen = false
      root.beginOverlay()
    }
  }

  Process { id: killFullscreenCheckProc }

  function startWash() {
    if (isWashing || !enabled) return
    if (skipWhenFullscreen) {
      // Reassigning running=true while a previous invocation hasn't exited
      // yet doesn't wait for or replace it - it can orphan the still-running
      // process while a second one starts, defeating the deadline/kill
      // tracking below (which only knows about the most recent one).
      if (fullscreenCheck.running) return
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

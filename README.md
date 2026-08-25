# Screen Wash — Omarchy Burn-In Prevention Plugin

Periodically washes the screen with cycling solid colors or dims it to prevent burn-in during long sessions.

<!-- Add a preview.png screenshot here -->
<!-- ![Screen Wash Preview](preview.png) -->

## Features

- Two wash modes: **wash** (cycles through R/G/B/white) and **dim** (fades a black overlay)
- Configurable interval, duration, and behavior
- Automatically skips wash when a fullscreen window is active
- Toggle on/off from the bar widget
- IPC commands for manual triggering and status checks
- Persistent enabled/disabled state across restarts

## Installation

**Via Omarchy plugin manager:**

```
omarchy plugin add Deunnis/omarchy-screenwash
```

**Manual installation:**

1. Clone this repository into the plugins directory:
   ```
   git clone https://github.com/Deunnis/omarchy-screenwash.git ~/.config/omarchy/plugins/daan.screenwash
   ```
2. Add `{ "id": "daan.screenwash" }` to the `plugins` array in `~/.config/omarchy/shell.json`.
3. Add `{ "id": "daan.screenwash" }` to the bar layout in your Omarchy bar config.

## Removal

**Via Omarchy plugin manager:**

```
omarchy plugin remove daan.screenwash
```

**Manual removal:**

1. Remove `{ "id": "daan.screenwash" }` from the `plugins` array in `~/.config/omarchy/shell.json`.
2. Remove `{ "id": "daan.screenwash" }` from the bar layout in your Omarchy bar config.
3. Delete the plugin folder:
   ```
   rm -rf ~/.config/omarchy/plugins/daan.screenwash
   ```

## Settings

All settings can be configured through the Omarchy service UI or in the manifest.

| Setting | Type | Default | Description |
|---|---|---|---|
| `intervalMinutes` | integer (5–240) | 30 | Minutes between screen washes |
| `durationMs` | integer (500–10000) | 1500 | How long the wash overlay stays visible (ms) |
| `mode` | `wash` \| `dim` | `wash` | `wash` cycles solid colors; `dim` fades a black overlay |
| `skipWhenFullscreen` | boolean | true | Skip the wash if a fullscreen window is active |

## IPC Commands

Trigger a wash manually:

```
qs ipc call daan.screenwash trigger
```

Check status:

```
qs ipc call daan.screenwash status
```

## License

MIT — see [LICENSE](LICENSE).

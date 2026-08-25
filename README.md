# Screen Wash — Omarchy Burn-In Prevention Plugin

Periodically washes the screen with cycling solid colors or dims it to prevent burn-in during long sessions.

![Screen Wash Preview](preview.gif)

## Install / Remove

```
omarchy plugin add Deunnis/omarchy-screenwash
```

```
omarchy plugin remove daan.screenwash
```

## Features

- Two wash modes: **wash** (cycles through R→G→B→white) and **dim** (fades a black overlay)
- Toggle on/off from the bar widget (monitor icon 󰍹)
- Automatically skips wash when a fullscreen window is active
- Configurable interval, duration, and behavior
- Persistent enabled/disabled state across restarts

## Settings

| Setting | Type | Default | Description |
|---|---|---|---|
| `intervalMinutes` | integer (5–240) | 30 | Minutes between screen washes |
| `durationMs` | integer (500–10000) | 1500 | How long the wash overlay stays visible (ms) |
| `mode` | `wash` \| `dim` | `wash` | `wash` cycles solid colors; `dim` fades a black overlay |
| `skipWhenFullscreen` | boolean | true | Skip the wash if a fullscreen window is active |

## IPC Commands

```
omarchy shell daan.screenwash trigger
```

```
omarchy shell daan.screenwash status
```

## Manual Installation

```bash
git clone https://github.com/Deunnis/omarchy-screenwash.git ~/.config/omarchy/plugins/daan.screenwash
```

Then add `{ "id": "daan.screenwash" }` to both the `plugins` array and the bar layout in `~/.config/omarchy/shell.json`.

## Manual Removal

```bash
rm -rf ~/.config/omarchy/plugins/daan.screenwash
```

Then remove `{ "id": "daan.screenwash" }` from the `plugins` array and bar layout in `~/.config/omarchy/shell.json`.

## License

MIT — see [LICENSE](LICENSE).

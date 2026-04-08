# PromptPixel

**One hotkey. Screenshot to clipboard. Paste into any AI.**

PromptPixel is a tiny Windows tool that captures your screen with a single keystroke and drops the image straight onto your clipboard — ready to paste into Claude, ChatGPT, Gemini, Antigravity, VS Code's Claude Code panel, or any app that accepts images.

No Claude Desktop required. No browser extension. No two-step "snip then paste" workflow. Just press the hotkey and paste.

---

## Why PromptPixel exists

Every AI chat tool wants screenshots, but Windows makes it a chore:

- **Win+Shift+S** → snip → switch window → Ctrl+V (4 steps)
- **Claude Desktop's screenshot feature** → only works if you run Claude Desktop
- **VS Code Claude Code panel** → image paste on Windows is [famously broken](https://github.com/anthropics/claude-code/issues/26679)
- **LazyScreenshots** → Mac only

PromptPixel fills the gap: **Windows + AI-focused + works with any app + free + open source.**

---

## Features

- **Single-hotkey capture** (default `Ctrl+Alt+S`, fully rebindable)
- **Captures the monitor your mouse is on** — multi-monitor friendly
- **Auto-focuses your target app** before pasting (VS Code, any active window, or a custom app)
- **Optional auto-typed label** after pasting (e.g. "See Image")
- **Tray icon** with Settings, Pause, and Capture Now
- **Settings GUI** — no editing config files required
- **Tiny single .exe** — no Python, no installer, no dependencies
- **Open source** — MIT licensed, hack it freely

---

## Quick Start (for users)

1. Download `PromptPixel.exe` from the [latest release](https://github.com/russellsailors-hub/PromptPixel/releases/latest)
2. Double-click to run — a tray icon appears
3. Press **Ctrl+Alt+S** anywhere to capture your screen
4. Switch to your AI tool of choice and press **Ctrl+V** to paste

To change the hotkey or target app, right-click the tray icon → **Settings**.

To launch on Windows startup, drop a shortcut to `PromptPixel.exe` into your Startup folder (`Win+R` → `shell:startup` → Enter).

---

## Build from source (for developers)

PromptPixel is written in [AutoHotkey v2](https://www.autohotkey.com/). To build the `.exe` yourself:

1. Install [AutoHotkey v2](https://www.autohotkey.com/download/)
2. Clone this repo
3. Run [`build.bat`](build.bat) — produces `PromptPixel.exe` next to the script

The build script uses `Ahk2Exe.exe` from the AutoHotkey install directory.

---

## How it works

PromptPixel uses GDI+ (via the bundled `Gdip_All.ahk` library) to capture the monitor under the mouse cursor, places the bitmap directly on the Windows clipboard, focuses the target window, and sends `Ctrl+V`. That's it. ~250 lines of AutoHotkey.

---

## Roadmap

- [x] Windows v1 — single hotkey, multi-monitor, configurable target
- [ ] Region select mode (drag a box)
- [ ] Recent screenshots history (re-paste last N)
- [ ] Mac port (contributions welcome — see [issues](https://github.com/russellsailors-hub/PromptPixel/issues))
- [ ] Linux port (Wayland/X11 — likely community-driven)

---

## Contributing

PRs welcome. Especially:

- Mac port (no Mac in the dev environment)
- Linux port
- Bug reports with reproducible steps
- New target-app integrations

Open an [issue](https://github.com/russellsailors-hub/PromptPixel/issues) before large changes.

---

## License

[MIT](LICENSE) — do whatever you want, just keep the copyright notice. No warranty.

---

## Credits

- Built by [Russell Sailors](https://github.com/russellsailors-hub) / [Makologics](https://makologics.com)
- GDI+ wrapper: [Gdip_All.ahk](https://github.com/buliasz/AHKv2-Gdip) (LGPL)
- Built with [AutoHotkey v2](https://www.autohotkey.com/)

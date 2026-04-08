# PromptPixel

**One hotkey. Screenshot to clipboard. Paste into any AI.**

[![VirusTotal](https://img.shields.io/badge/VirusTotal-0%2F72_clean-brightgreen?logo=virustotal)](https://www.virustotal.com/gui/file/35309aecb044687834e4af1df903c9fd3c31c6157f5477909da950de918de707/detection)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows)](https://github.com/russellsailors-hub/PromptPixel/releases/latest)

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

## Antivirus & Trust

**PromptPixel scans clean on VirusTotal: [0 / 72 engines flagged](https://www.virustotal.com/gui/file/35309aecb044687834e4af1df903c9fd3c31c6157f5477909da950de918de707/detection).**

Some antivirus tools occasionally flag AutoHotkey-compiled `.exe` files as a precaution because the same compilation technique is used by certain malware families. PromptPixel is open source — every line of source code is in this repository, and you can build the `.exe` yourself with the included [`build.bat`](build.bat) to verify it byte-for-byte.

If your AV ever does flag PromptPixel:

1. View the live [VirusTotal scan](https://www.virustotal.com/gui/file/35309aecb044687834e4af1df903c9fd3c31c6157f5477909da950de918de707/detection) to confirm the current state
2. Read the source: [`PromptPixel.ahk`](PromptPixel.ahk) — about 300 lines, no obfuscation
3. Build it yourself from source if you want a binary you compiled with your own toolchain

---

## Credits

- Built by [Russell Sailors](https://github.com/russellsailors-hub) / [Makologics](https://makologics.com)
- GDI+ wrapper: [Gdip_All.ahk](https://github.com/buliasz/AHKv2-Gdip) (LGPL)
- Built with [AutoHotkey v2](https://www.autohotkey.com/)

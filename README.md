# macOS Apps

A collection of lightweight macOS menubar apps built for everyday productivity.

## Apps

| # | App | Description | Tech |
|---|-----|-------------|------|
| 01 | [Claude Code Usage Monitor](01_ClaudeCode_Status/) | Battery-style indicator showing Claude Code API usage remaining | Swift + SwiftUI |
| 02 | [Keep Awake](02_Keep_Awake/) | Prevent Mac from sleeping with periodic mouse movement | Python + rumps |

## Why

Small, focused utilities that solve real problems while using a Mac — things that should exist but don't, or cost money when they shouldn't.

Each app lives in the menubar, stays out of the way, and does one thing well.

## Quick Start

### Claude Code Usage Monitor

```bash
cd 01_ClaudeCode_Status/ClaudeUsage
./build.sh
open build/ClaudeUsage.app
```

### Keep Awake

```bash
cd 02_Keep_Awake
pip install rumps pyautogui
python keep_awake_app.py
```

See each app's README for detailed build and install instructions.

## Contributing

Found a bug or have an idea for a new macOS utility? Open an issue or submit a PR.

## License

MIT

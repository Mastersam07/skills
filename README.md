# Your Next User Is an Agent: Shipping Skills With Your SDK

Workshop materials for teaching AI coding agents to use your Dart package correctly, by shipping an Agent Skill with it and installing it with the Dart [`skills`](https://pub.dev/packages/skills) CLI.

**Attendees: open [WORKBOOK.md](WORKBOOK.md) and follow it step by step.**

## What's inside

| Folder | What it is |
| --- | --- |
| `starter/mosho_topup` | MoshoTopUp, a tiny data top-up SDK with a fake offline backend |
| `starter/sample_app` | A Flutter app that depends on the SDK. You point your agent here |
| `finished/` | The same, plus the completed skill and the reference buy data screen |
| `WORKBOOK.md` | The step-by-step guide |

## Requirements

- Flutter with Dart 3.13 or later
- One AI coding agent: Claude Code, Cursor, GitHub Copilot, Antigravity, Codex, Cline or OpenCode

## Quick check

```bash
cd starter/mosho_topup
dart test

cd ../sample_app
flutter run
```

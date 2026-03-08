# Approval Notifier (WIP)

Approve or deny Claude Code tool requests from macOS notifications — no need to switch between terminal windows.

## Problem

When running multiple Claude Code sessions simultaneously, each session may request tool approval (file edits, Bash commands, etc.). You have to switch to each terminal window to approve. This is slow and disruptive.

## Solution

A macOS menu bar app + PreToolUse hook that:
1. Intercepts tool approval requests from all Claude Code sessions
2. Shows macOS notifications with Allow/Deny buttons
3. Sends the response back to the correct session

## Architecture

```
[Claude Code Session 1] → PreToolUse Hook → HTTP POST → [macOS Menu Bar App]
[Claude Code Session 2] → PreToolUse Hook → HTTP POST →        ↓
[Claude Code Session 3] → PreToolUse Hook → HTTP POST →   Notification
                                                              ↓
                          exit 0 (allow) ←──────────── User clicks Allow
                          exit 2 (deny)  ←──────────── User clicks Deny
```

## Status

**Work in progress** — See [docs/claude-approval-notifier-prompt.md](docs/claude-approval-notifier-prompt.md) for the full design document.

## Tech Stack

- PreToolUse Hook (Claude Code hooks system)
- Python + rumps (macOS menu bar)
- localhost HTTP server for hook ↔ app communication
- macOS UserNotifications

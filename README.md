# Claude Code Statusline

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Shell](https://img.shields.io/badge/shell-bash%204.0%2B-121011.svg?logo=gnu-bash&logoColor=white)
![For](https://img.shields.io/badge/for-Claude%20Code-d97757.svg)

A customizable, informative status bar for the [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI. Pure Bash + `jq` — no daemons, no dependencies beyond what you already have.

*Magyar verzio lentebb / [Hungarian version below](#claude-code-statusline-magyar)*

**Single line** (default):

```
🤖 Opus 5 ⚡FAST 📋 PLAN │ $0.51 │ [████░░░░░░░░░░░░░░░░] 24% (240k/1000k) │ ⏱ 6m51s │ 📡 5 │ +12/-3 │ 🌿 main │ 📁 my-project
```

**Two lines** (`STATUSLINE_LAYOUT=2`) — identity on top, metrics below:

```
🤖 Opus 5 ⚡FAST 📋 PLAN │ 🌿 main │ 📁 my-project
$0.51 │ [████░░░░░░░░░░░░░░░░] 24% (240k/1000k) │ ⏱ 6m51s │ 📡 5 │ +12/-3
```

## Table of contents

- [What it shows](#what-it-shows)
- [Colors](#colors)
- [Profiles](#profiles)
- [Layout](#layout)
- [Segment visibility matrix](#segment-visibility-matrix)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Features](#features)
- [How it works (architecture)](#how-it-works-architecture)
- [Icons & Logic](#icons--logic)
- [Customization](#customization)
- [Development & Contributing](#development--contributing)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)
- [Changelog](#changelog)
- [License](#license)

## What it shows

| Indicator | Description |
|-----------|-------------|
| 🤖 Model | Current model, colored by tier — Fable/Mythos gold, Opus magenta, Sonnet blue, Haiku green (Fable 5, Opus 5, Sonnet 5, etc.) |
| ⚡FAST / STD | Fast mode indicator |
| 📋 PLAN / 🚀 AUTO / ✅ EDIT / ⚠️ YOLO | Permission mode (read from transcript — `default` is silent) |
| 🎨 style | Output style (when not default) |
| 🤝 agent | Active subagent name |
| 📛 name | Custom session name (set via `--name` / `/rename`) |
| ⚠️ 200k+ / 📚 long-ctx | Token threshold crossed: red `⚠️ 200k+` on 200k models like Haiku 4.5 (at the ceiling), cyan `📚 long-ctx` on 1M-context models — Fable 5, Opus 5/4.x, Sonnet 5/4.6 (informational) |
| $X.XX | Session cost (API users: actual cost, Pro/Max: $0.00) |
| [████░░] X% | Context window usage with color-coded progress bar |
| (Xk/200k) | Token usage (used/total) |
| ⏱ Xm | Session duration |
| 📡 N | Number of API calls in this session |
| 📊 5h:X% 7d:Y% | Claude.ai Pro/Max rate limit usage |
| +X/-Y | Lines added/removed |
| 🌿 branch | Current git branch (* = uncommitted changes) |
| 📁 folder | Current project folder |
| 🌳 worktree | Active git worktree name |
| ⌨ NORMAL | Vim mode when enabled |

## Colors

### Context window colors

The progress bar changes color with usage:

- 🟢 Green: < 50% used
- 🟡 Yellow: 50–75% used
- 🔴 Red: > 75% used

### Model tier colors

The 🤖 model name is colored by tier so you can tell at a glance which model (and price point) you're on:

- 🟡 Gold (bold): **Fable / Mythos** — frontier tier (e.g. Fable 5)
- 🟣 Magenta (bold): **Opus** — premium tier (e.g. Opus 5, Opus 4.8)
- 🔵 Blue: **Sonnet**
- 🟢 Green: **Haiku**

Matching is case-insensitive on the tier word in `model.display_name`, so new versions are colored automatically with no code change.

## Profiles

The `STATUSLINE_PROFILE` env var controls how much is shown. Default is `full`.

| Profile | Includes |
|---------|----------|
| `minimal` | Base fields + permission mode (single line by design) |
| `standard` | + speed, output style, agent, session name, API count, lines |
| `full` (default) | + rate limits, worktree, vim mode, 200k+ / long-ctx |

Set it in `~/.claude/settings.json`:

```json
{ "statusLine": { "type": "command", "command": "STATUSLINE_PROFILE=standard ~/.claude/statusline.sh" } }
```

## Layout

The `STATUSLINE_LAYOUT` env var controls line count:

- `1` (default) — single line
- `2` — two lines. **Row 1** (identity): model, speed, permission mode, output style, agent, session name, git branch, project folder, worktree, vim. **Row 2** (metrics): cost, context bar + tokens, duration, API count, rate limits, 200k+ / long-ctx, lines changed.

Recommended with the `full` profile to avoid horizontal wrapping on narrow terminals. The `minimal` profile ignores this setting and stays one line by design.

```json
{ "statusLine": { "type": "command", "command": "STATUSLINE_LAYOUT=2 ~/.claude/statusline.sh" } }
```

Combine with a profile if you want both:

```json
{ "statusLine": { "type": "command", "command": "STATUSLINE_LAYOUT=2 STATUSLINE_PROFILE=standard ~/.claude/statusline.sh" } }
```

## Segment visibility matrix

Which segments appear in each profile. Segments also self-hide when their data is absent (e.g. `🌳 worktree` only shows inside a worktree session, `📊 rate limits` only for Pro/Max).

| Segment | `minimal` | `standard` | `full` |
|---------|:---------:|:----------:|:------:|
| 🤖 model (tier-colored) | ✅ | ✅ | ✅ |
| ⚡FAST / STD speed | ➖ | ✅ | ✅ |
| 📋/🚀/✅/⚠️ permission mode | ✅ | ✅ | ✅ |
| 🎨 output style | ➖ | ✅ | ✅ |
| 🤝 agent | ➖ | ✅ | ✅ |
| 📛 session name | ➖ | ✅ | ✅ |
| $ cost | ✅ | ✅ | ✅ |
| [███] context bar + % | ✅ | ✅ | ✅ |
| (Xk/Yk) token detail | ➖ | ✅ | ✅ |
| ⏱ duration | ✅ | ✅ | ✅ |
| 📡 API count | ➖ | ✅ | ✅ |
| +X/-Y lines | ➖ | ✅ | ✅ |
| 🌿 git branch | ✅ | ✅ | ✅ |
| 📁 folder | ✅ | ✅ | ✅ |
| 📊 rate limits | ➖ | ➖ | ✅ |
| 🌳 worktree | ➖ | ➖ | ✅ |
| ⌨ vim mode | ➖ | ➖ | ✅ |
| ⚠️ 200k+ / 📚 long-ctx | ➖ | ➖ | ✅ |

✅ = shown when data is present · ➖ = not shown in this profile

## Requirements

- **bash** 4.0+
- **jq** (JSON processor)
- **git** (optional, for branch info)
- **Claude Code** CLI
- A terminal with **ANSI 256-color** support (any modern terminal)

## Installation

### One-liner install

```bash
git clone https://github.com/kalmarr/claude-code-statusline.git /tmp/claude-code-statusline && /tmp/claude-code-statusline/install.sh && rm -rf /tmp/claude-code-statusline
```

### Install via Claude Code prompt

Paste this into Claude Code and it will install the statusline for you:

> Install the Claude Code statusline from https://github.com/kalmarr/claude-code-statusline — clone to /tmp, run install.sh, then clean up. Restart Claude Code when done.

### Claude Code slash command

For repeated use, copy `commands/install-statusline.md` to `~/.claude/commands/`, then run `/install-statusline` inside Claude Code anytime.

### Quick install

```bash
git clone https://github.com/kalmarr/claude-code-statusline.git
cd claude-code-statusline
./install.sh
```

The installer asks whether to enable the **two-line layout** (recommended) and writes the matching `settings.json` config for you.

### Manual install

1. Copy the script:
```bash
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

2. Add to your Claude Code settings (`~/.claude/settings.json`). Recommended config — two-line layout with a 2-second refresh so Shift+Tab mode switches are reflected quickly:

```json
{
  "statusLine": {
    "type": "command",
    "command": "STATUSLINE_LAYOUT=2 ~/.claude/statusline.sh",
    "padding": 0,
    "refreshInterval": 2
  }
}
```

Minimal single-line version (compact, no refreshInterval):

```json
{
  "statusLine": {
    "type": "command",
    "command": "STATUSLINE_PROFILE=minimal ~/.claude/statusline.sh"
  }
}
```

3. Restart Claude Code.

> **Global / multi-project:** the `statusLine` block lives in your **user-level** `~/.claude/settings.json`, so a single install applies to **every project** for that user on that machine. To roll out to several dev servers, copy `~/.claude/statusline.sh` to each one — the user `settings.json` already points every project at it.

## Configuration

### Environment variables

Toggled by prepending them to the `command` in `~/.claude/settings.json`.

| Option | Values | Default | Effect |
|--------|--------|---------|--------|
| `STATUSLINE_LAYOUT` | `1` / `2` | `1` | Single line vs. two lines |
| `STATUSLINE_PROFILE` | `minimal` / `standard` / `full` | `full` | How many fields to show |
| `DEBUG` | `0` / `1` | `0` | When `1`, saves the raw stdin JSON to `~/.claude/debug_status.json` on every update |

### `statusLine` settings.json fields

| Field | Type | Notes |
|-------|------|-------|
| `type` | string | Always `"command"` |
| `command` | string | The shell command to run (with any env vars prepended) |
| `padding` | integer | Horizontal padding around the bar; `0` for edge-to-edge |
| `refreshInterval` | seconds (≥1) | Re-runs the command on a timer so Shift+Tab mode switches show without waiting for a new assistant message |

### Debug mode

To inspect exactly what Claude Code sends, start it with:

```bash
DEBUG=1 claude
```

This saves the raw JSON input to `~/.claude/debug_status.json` on every update. The file is git-ignored, so it never gets committed.

## Features

### Fast mode indicator

When you toggle `/fast` in Claude Code, the statusline shows `⚡FAST` in yellow next to the model name. It reads the transcript file for the last `Fast mode ON/OFF` event, falling back to the `"speed"` field. `/fast` is available on Opus 5 and Opus 4.8 (it was removed from Opus 4.7).

### Permission mode indicator

The Claude Code stdin JSON does **not** include the current permission mode — only `vim.mode`, `output_style.name`, and `agent.name` are exposed. The statusline reads the last `{"type":"permission-mode","permissionMode":"..."}` entry from the transcript JSONL to detect the active mode:

- 📋 **PLAN** (yellow) — read-only planning mode (Shift+Tab)
- 🚀 **AUTO** (blue) — autonomous execution mode
- ✅ **EDIT** (cyan) — auto-accept edits
- ⚠️ **YOLO** (red) — `bypassPermissions`
- `default` mode is silent (no icon) to keep the bar clean

The bar updates after each assistant message, after a permission-mode change, and on the configured `refreshInterval` (default 2s) — so Shift+Tab mode switches are reflected within a couple of seconds even without a new assistant response.

### Context window progress bar

A 20-character progress bar (10 in the `minimal` profile) that changes color based on usage: green under 50%, yellow 50–75%, red above 75%. The `(Xk/Yk)` token count is **derived** from `used_percentage × context_window_size`, so it always stays consistent with the bar.

### 1M-context awareness (Claude 5 family)

All current models — Fable 5, Opus 5/4.8/4.7/4.6, Sonnet 5, Sonnet 4.6 — have a 1M-token context window, where crossing 200k tokens is routine, not a warning — so the bar shows an informational cyan `📚 long-ctx` badge. On 200k-context models (Haiku 4.5), crossing 200k is the real ceiling and stays a red `⚠️ 200k+`. The distinction is data-driven (`context_window_size > 200000`), so it works for future models automatically.

### Git integration

Shows the current branch name and a `*` suffix when there are uncommitted changes. Works with any git repository in the current working directory.

### Lines changed

Tracks total lines added and removed during the session. Shows `±0` when no changes have been made.

### Rate limits (Pro/Max only)

Displays your Claude.ai 5-hour and 7-day rate limit consumption (`📊 5h:42% 7d:87%`) when the `rate_limits` field is present in the JSON input. Only shown in the `full` profile.

### Worktree & agent indicators

- `🌳 name` appears when working inside a `git worktree` or a `--worktree` session.
- `🤝 name` shows the active subagent when one is running.
- `📛 name` shows a custom session name set via `--name` or `/rename`.
- `🎨 name` shows the output style when it's not `default`.
- `⌨ NORMAL` / `⌨ INSERT` appears when vim mode is enabled.

## How it works (architecture)

Claude Code runs the `statusLine.command` on **every status update** and pipes a JSON object to its **stdin**. The script reads that JSON, gathers a few extra facts the JSON doesn't carry, and prints one (or two) ANSI-colored lines.

```
Claude Code  ── pipes JSON on stdin ──▶  statusline.sh
                                              │
   1. data=$(cat)                  read entire stdin into $data
   2. one jq call                  extract model, cost, ctx %, sizes, dirs, flags …
   3. read transcript JSONL        permission mode, fast mode, API call count
   4. compute locally              git branch + dirty flag, duration, colors, bar
   5. assemble per profile/layout  build the ANSI string(s)
                                              │
                                              ▼
                                   status bar line(s) ──▶ rendered by Claude Code
```

**One `jq` call.** All stdin fields are extracted in a single `jq -r` invocation using `@sh` quoting, then `eval`'d into shell variables. `@sh` shell-quotes every interpolated value, so even though stdin is untrusted, the `eval` is injection-safe.

**Why it reads the transcript.** The stdin JSON does not expose the **permission mode**, the **fast-mode** state, or the **API call count**. The script tails the session transcript JSONL (`transcript_path`) for:

- the last `{"type":"permission-mode","permissionMode":"..."}` entry → permission mode
- the last `Fast mode ON/OFF` event (fallback: `"speed":"fast"`) → fast mode
- the count of `"type":"assistant"` entries → API call count

**Refresh triggers.** The bar re-renders after each assistant message, on a permission-mode or vim-mode change, and every `refreshInterval` seconds. Each run does a couple of `tac | grep` reads over the transcript plus `git` calls — cheap, but it does run on the timer, so keep `refreshInterval` at 2s or higher.

### stdin JSON fields used

- `model.display_name` — current model name (drives the tier color)
- `cost.total_cost_usd` — session cost
- `cost.total_duration_ms` — session duration
- `cost.total_lines_added` / `cost.total_lines_removed` — code changes
- `context_window.used_percentage` — context usage % (float — floored with `jq | floor`)
- `context_window.context_window_size` — max context tokens (200k default, 1M for extended-context models)
- `exceeds_200k_tokens` — whether the session crossed 200k tokens
- `rate_limits.{five_hour,seven_day}.used_percentage` — Pro/Max rate-limit usage
- `output_style.name` — active output style
- `agent.name` — active subagent (when running with `--agent`)
- `session_name` — custom name set via `--name` / `/rename`
- `workspace.current_dir` / `workspace.git_worktree` — working dir and worktree
- `worktree.{name,path,branch}` — active worktree info (in `--worktree` sessions)
- `vim.mode` — vim editor mode
- `transcript_path` — path to the session transcript (JSONL)

## Icons & Logic

| Icon | Meaning | Source / Logic |
|------|---------|---------------|
| 🤖 | Model name | `model.display_name` from Claude Code JSON input — colored by tier: Fable/Mythos = gold (frontier), Opus = magenta (premium), Sonnet = blue, Haiku = green |
| ⚡FAST | Fast mode active (yellow) | Reads transcript JSONL: first checks for `Fast mode ON/OFF` toggle, falls back to `"speed":"fast"` field |
| STD | Standard speed (gray) | Same as above, shown when not in fast mode |
| 📋 PLAN / 🚀 AUTO / ✅ EDIT / ⚠️ YOLO | Permission mode | Reads last `{"type":"permission-mode","permissionMode":"..."}` entry in transcript JSONL; `default` is silent |
| 🎨 style | Output style | `output_style.name` — shown only when ≠ `default` (standard/full profile) |
| 🤝 agent | Active subagent | `agent.name` — present only during `--agent` sessions (standard/full profile) |
| 📛 name | Custom session name | `session_name` — shown only when set via `--name` / `/rename` (standard/full profile) |
| ⚠️ 200k+ / 📚 long-ctx | Over 200k tokens | `exceeds_200k_tokens` — red `⚠️ 200k+` when `context_window_size` ≤ 200k (at the ceiling), cyan `📚 long-ctx` when > 200k like the 1M Claude 5 models (informational); full profile |
| $X.XX | Session cost | `cost.total_cost_usd` — actual API cost (Pro/Max users see $0.00) |
| [████░░] X% | Context window usage | `context_window.used_percentage` — 20-char progress bar, color-coded: 🟢 <50%, 🟡 50-75%, 🔴 >75% |
| (Xk/Xk) | Tokens used/total | Derived from `used_percentage * context_window_size` / `context_window_size` |
| ⏱ | Session duration | `cost.total_duration_ms` — auto-formats: Xs, XmXs, or XhXm |
| 📡 N | API call count | Counts `"type":"assistant"` entries in transcript JSONL |
| 📊 5h:X% 7d:Y% | Rate limits | `rate_limits.five_hour` / `rate_limits.seven_day` — Pro/Max only (full profile) |
| +X/-Y | Lines changed | `cost.total_lines_added` / `cost.total_lines_removed` — green/red colored |
| 🌿 | Git branch | `git branch --show-current` in workspace dir, `*` suffix = uncommitted changes |
| 📁 | Project folder | `basename` of `workspace.current_dir` |
| 🌳 | Git worktree | `worktree.name` or `workspace.git_worktree` (full profile) |
| ⌨ | Vim mode | `vim.mode` — `NORMAL` / `INSERT` (full profile) |
| │ | Separator | Visual divider between sections |

## Customization

You can modify `statusline.sh` to change:

- **Progress bar width**: change `bar_len=20` in the context-window section
- **Color thresholds**: adjust the percentage checks in the context-window section
- **Model tier colors**: edit the `case "${model,,}"` block (the `MODEL TIER COLOR` section)
- **Output format**: modify the output-assembly block at the bottom
- **Remove sections**: comment out or delete any segment you don't need

See `examples/minimal.sh` for a stripped-down version showing only model, cost, and context percentage.

## Development & Contributing

### Test locally without Claude Code

The script reads a single JSON object on stdin, so you can feed it sample input directly:

```bash
echo '{"model":{"display_name":"Fable 5"},"context_window":{"used_percentage":25,"context_window_size":1000000},"exceeds_200k_tokens":true,"cost":{"total_cost_usd":1.2},"workspace":{"current_dir":"'"$PWD"'"}}' \
  | STATUSLINE_LAYOUT=2 STATUSLINE_PROFILE=full ./statusline.sh
```

Swap `display_name` to `Opus 5` / `Sonnet 5` / `Haiku 4.5` to see the tier colors, or set `context_window_size` to `200000` to see the red `⚠️ 200k+` instead of `📚 long-ctx`.

### Capture real input

```bash
DEBUG=1 claude
# then inspect:
cat ~/.claude/debug_status.json | jq .
```

### Code layout (`statusline.sh`)

The script is organized into clearly-commented sections: a single `jq` extraction block, then per-feature blocks (model tier color, context window, duration, transcript data, lines, git), profile-gated extras, and finally the output-assembly block with three branches (`minimal`, two-line, single-line).

### Adding a segment

1. Extract any new stdin field in the `jq` block (`@sh "var=\(.path // default)"`).
2. Compute its display string (gate it by profile if needed).
3. Append it to the relevant output branch(es) with the `[ -n "$x" ] && output="${output} │ ${x}"` pattern.
4. Document it in the **What it shows**, **Icons & Logic**, and **Segment visibility matrix** tables.

### Pull requests

Keep changes POSIX-friendly where possible, run `bash -n statusline.sh` before committing, and verify with a few sample JSON inputs across profiles. An active feature branch (`feat/permission-mode-and-layouts`) exists on the remote for in-progress work.

## FAQ

**Why does the model show `?`** — The `model.display_name` field is briefly absent during the initial loading phase. It resolves after the first update. If it persists, run `DEBUG=1 claude` and check the JSON.

**Colors aren't showing / I see raw `\033[…` codes** — Your terminal (or the surrounding tool) isn't interpreting ANSI escapes. Use a modern terminal; the script emits standard ANSI color codes.

**Cost shows `$0.00`** — That's expected for Claude.ai Pro/Max users — billing isn't per-request. API-key users see the real cost. Pro/Max users get the `📊` rate-limit segment instead.

**The `📚 long-ctx` badge replaced my `⚠️ 200k+`** — Intentional on 1M-context models (Fable 5, Opus 5/4.x, Sonnet 5/4.6): crossing 200k is normal there, so it's informational (cyan), not a warning (red). 200k models like Haiku 4.5 still show the red warning.

**How do I hide a segment?** — Switch to a smaller profile (`STATUSLINE_PROFILE=minimal`/`standard`), or edit the output-assembly block in `statusline.sh`.

**Does it slow Claude Code down?** — No noticeable impact. Each run is a couple of `grep`/`git` calls. With `refreshInterval: 2` it runs about every 2 seconds.

**Permission mode lags after Shift+Tab** — Add `"refreshInterval": 2` to your `statusLine` config (the recommended install does this). See Troubleshooting.

## Troubleshooting

### Statusline not appearing
- Verify `~/.claude/settings.json` has the `statusLine` config
- Check that `~/.claude/statusline.sh` exists and is executable (`chmod +x`)
- Restart Claude Code after making changes

### Shows "?" for model name
- This is normal during the initial loading phase
- If it persists, run `DEBUG=1 claude` and check `~/.claude/debug_status.json`

### jq errors
- Ensure `jq` is installed: `which jq`
- Install via: `apt install jq` / `brew install jq` / `pacman -S jq`

### Git branch not showing
- The current directory must be inside a git repository
- Ensure `git` is installed and in PATH

### Fast mode not detected
- Toggle `/fast` and send at least one message
- The speed field appears in the transcript after the first API response in that mode

### Permission mode doesn't refresh after Shift+Tab
- Claude Code re-runs the statusline only after each assistant message, permission-mode change, or vim-mode toggle
- Add `"refreshInterval": 2` to your `statusLine` config so the bar refreshes every 2 seconds (the recommended default install does this)
- If still stuck, verify `transcript_path` points to a readable file (`DEBUG=1 claude`)

## Uninstall

1. Remove (or edit) the `statusLine` block from `~/.claude/settings.json`.
2. Optionally delete the script: `rm ~/.claude/statusline.sh`.
3. Restart Claude Code.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full version history.

## License

MIT — see [LICENSE](LICENSE)

---

# Claude Code Statusline (Magyar)

Testreszabhato, informativ status bar a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI-hez. Tiszta Bash + `jq` — nincs daemon, nincs kulon fuggoseg.

**Egysoros** (alapertelmezett):

```
🤖 Opus 5 ⚡FAST 📋 PLAN │ $0.51 │ [████░░░░░░░░░░░░░░░░] 24% (240k/1000k) │ ⏱ 6m51s │ 📡 5 │ +12/-3 │ 🌿 main │ 📁 my-project
```

**Ketsoros** (`STATUSLINE_LAYOUT=2`) — identitas felul, metrikak alul:

```
🤖 Opus 5 ⚡FAST 📋 PLAN │ 🌿 main │ 📁 my-project
$0.51 │ [████░░░░░░░░░░░░░░░░] 24% (240k/1000k) │ ⏱ 6m51s │ 📡 5 │ +12/-3
```

## Tartalom

- [Mit mutat](#mit-mutat)
- [Szinek](#szinek)
- [Profilok](#profilok)
- [Elrendezes](#elrendezes)
- [Szegmens-lathatosagi matrix](#szegmens-lathatosagi-matrix)
- [Kovetelmenyek](#kovetelmenyek)
- [Telepites](#telepites)
- [Konfiguracio](#konfiguracio)
- [Funkciok](#funkciok)
- [Hogyan mukodik (architektura)](#hogyan-mukodik-architektura)
- [Ikonok es logika](#ikonok-es-logika)
- [Testreszabas](#testreszabas)
- [Fejlesztes es hozzajarulas](#fejlesztes-es-hozzajarulas)
- [GYIK](#gyik)
- [Hibaelharitas](#hibaelharitas)
- [Eltavolitas](#eltavolitas)
- [Valtozasok](#valtozasok)
- [Licenc](#licenc)

## Mit mutat

| Jelzo | Leiras |
|-------|--------|
| 🤖 Model | Aktualis modell, tier szerint szinezve — Fable/Mythos arany, Opus magenta, Sonnet kek, Haiku zold (Fable 5, Opus 5, Sonnet 5, stb.) |
| ⚡FAST / STD | Fast mode jelzo |
| 📋 PLAN / 🚀 AUTO / ✅ EDIT / ⚠️ YOLO | Permission mode (transcriptbol olvasva — `default` nem latszik) |
| 🎨 style | Output style (ha nem default) |
| 🤝 agent | Aktiv subagent neve |
| 📛 name | Egyedi session nev (`--name` / `/rename`) |
| ⚠️ 200k+ / 📚 long-ctx | 200k token atlepve: piros `⚠️ 200k+` 200k modellnel mint a Haiku 4.5 (plafon), cyan `📚 long-ctx` 1M-context modellnel — Fable 5, Opus 5/4.x, Sonnet 5/4.6 (informativ) |
| $X.XX | Session koltseg (API: tenyleges koltseg, Pro/Max: $0.00) |
| [████░░] X% | Context ablak hasznalat szin-kodolt progress barral |
| (Xk/200k) | Token hasznalat (felhasznalt/osszes) |
| ⏱ Xm | Session idotartam |
| 📡 N | API hivasok szama a sessionben |
| 📊 5h:X% 7d:Y% | Claude.ai Pro/Max rate limit hasznalat |
| +X/-Y | Hozzaadott/torolt sorok |
| 🌿 branch | Aktualis git branch (* = nem commitolt valtozasok) |
| 📁 folder | Aktualis projekt mappa |
| 🌳 worktree | Aktiv git worktree neve |
| ⌨ NORMAL | Vim mode, ha aktiv |

## Szinek

### Context ablak szinek

A progress bar szine a hasznalattal valtozik:

- 🟢 Zold: < 50% hasznalat
- 🟡 Sarga: 50–75% hasznalat
- 🔴 Piros: > 75% hasznalat

### Modell tier szinek

A 🤖 modellnev tier szerint szinezve, hogy egy pillantasra lasd, melyik modellen (es araron) vagy:

- 🟡 Arany (felkover): **Fable / Mythos** — frontier tier (pl. Fable 5)
- 🟣 Magenta (felkover): **Opus** — premium tier (pl. Opus 5, Opus 4.8)
- 🔵 Kek: **Sonnet**
- 🟢 Zold: **Haiku**

A talalat kis/nagybetu-fuggetlenul a `model.display_name` tier-szavara megy, igy az uj verziok kodmodositas nelkul szinezodnek.

## Profilok

A `STATUSLINE_PROFILE` kornyezeti valtozo szabalyozza, mennyi latszik. Alapertelmezett: `full`.

| Profil | Tartalmaz |
|--------|-----------|
| `minimal` | Alap mezok + permission mode (mindig egy soros) |
| `standard` | + sebesseg, output style, agent, session nev, API szam, sorok |
| `full` (default) | + rate limits, worktree, vim mode, 200k+ / long-ctx |

Allitsd be a `~/.claude/settings.json`-ban:

```json
{ "statusLine": { "type": "command", "command": "STATUSLINE_PROFILE=standard ~/.claude/statusline.sh" } }
```

## Elrendezes

A `STATUSLINE_LAYOUT` kornyezeti valtozo a sorok szamat szabalyozza:

- `1` (alapertelmezett) — egy sor
- `2` — ket sor. **1. sor** (identitas): modell, sebesseg, permission mode, output style, agent, session nev, git branch, projekt mappa, worktree, vim. **2. sor** (metrikak): koltseg, context bar + tokenek, duration, API szam, rate limits, 200k+ / long-ctx, sorok valtozasa.

Ajanlott a `full` profillal, hogy ne csusszon le a bar keskeny terminalon. A `minimal` profil figyelmen kivul hagyja ezt a beallitast (mindig egy soros marad).

```json
{ "statusLine": { "type": "command", "command": "STATUSLINE_LAYOUT=2 ~/.claude/statusline.sh" } }
```

Profillal kombinalhato:

```json
{ "statusLine": { "type": "command", "command": "STATUSLINE_LAYOUT=2 STATUSLINE_PROFILE=standard ~/.claude/statusline.sh" } }
```

## Szegmens-lathatosagi matrix

Melyik szegmens melyik profilban jelenik meg. A szegmensek akkor is elrejtoznek, ha nincs adat (pl. `🌳 worktree` csak worktree sessionben, `📊 rate limits` csak Pro/Max eseten).

| Szegmens | `minimal` | `standard` | `full` |
|----------|:---------:|:----------:|:------:|
| 🤖 modell (tier-szin) | ✅ | ✅ | ✅ |
| ⚡FAST / STD sebesseg | ➖ | ✅ | ✅ |
| 📋/🚀/✅/⚠️ permission mode | ✅ | ✅ | ✅ |
| 🎨 output style | ➖ | ✅ | ✅ |
| 🤝 agent | ➖ | ✅ | ✅ |
| 📛 session nev | ➖ | ✅ | ✅ |
| $ koltseg | ✅ | ✅ | ✅ |
| [███] context bar + % | ✅ | ✅ | ✅ |
| (Xk/Yk) token reszlet | ➖ | ✅ | ✅ |
| ⏱ idotartam | ✅ | ✅ | ✅ |
| 📡 API szam | ➖ | ✅ | ✅ |
| +X/-Y sorok | ➖ | ✅ | ✅ |
| 🌿 git branch | ✅ | ✅ | ✅ |
| 📁 mappa | ✅ | ✅ | ✅ |
| 📊 rate limits | ➖ | ➖ | ✅ |
| 🌳 worktree | ➖ | ➖ | ✅ |
| ⌨ vim mode | ➖ | ➖ | ✅ |
| ⚠️ 200k+ / 📚 long-ctx | ➖ | ➖ | ✅ |

✅ = megjelenik, ha van adat · ➖ = ebben a profilban nem latszik

## Kovetelmenyek

- **bash** 4.0+
- **jq** (JSON feldolgozo)
- **git** (opcionalis, branch infohoz)
- **Claude Code** CLI
- **ANSI 256-szines** terminal (barmely modern terminal)

## Telepites

### Egyvonalas telepites

```bash
git clone https://github.com/kalmarr/claude-code-statusline.git /tmp/claude-code-statusline && /tmp/claude-code-statusline/install.sh && rm -rf /tmp/claude-code-statusline
```

### Telepites Claude Code prompttal

Ird be ezt a Claude Code-ba, es elvegzi a telepitest:

> Telepitsd a Claude Code statusline-t a https://github.com/kalmarr/claude-code-statusline repobol — klonozd /tmp-be, futtasd az install.sh-t, majd takarits. Inditsd ujra a Claude Code-ot ha kesz.

### Claude Code slash parancs

Ismetelt hasznalathoz masold a `commands/install-statusline.md` fajlt a `~/.claude/commands/` mappaba, majd futtasd az `/install-statusline` parancsot barmikor.

### Gyors telepites

```bash
git clone https://github.com/kalmarr/claude-code-statusline.git
cd claude-code-statusline
./install.sh
```

A telepito megkerdezi, hogy kapcsolja-e be a **ketsoros elrendezest** (ajanlott), es a megfelelo `settings.json` konfigot is beirja.

### Kezzel

1. Masold a scriptet:
```bash
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

2. Add hozza a Claude Code beallitasokhoz (`~/.claude/settings.json`). Ajanlott: ketsoros elrendezes 2 mp-es frissitessel, igy a Shift+Tab modvaltas gyorsan latszik:

```json
{
  "statusLine": {
    "type": "command",
    "command": "STATUSLINE_LAYOUT=2 ~/.claude/statusline.sh",
    "padding": 0,
    "refreshInterval": 2
  }
}
```

Tomor egysoros valtozat (minimal profil):

```json
{
  "statusLine": {
    "type": "command",
    "command": "STATUSLINE_PROFILE=minimal ~/.claude/statusline.sh"
  }
}
```

3. Inditsd ujra a Claude Code-ot.

> **Globalis / tobb projekt:** a `statusLine` blokk a **felhasznalo-szintu** `~/.claude/settings.json`-ban van, igy egyetlen telepites **minden projektre** ervenyes az adott gepen. Tobb dev szerverre: masold a `~/.claude/statusline.sh`-t mindegyikre — a felhasznaloi `settings.json` mar mindegyik projektet erre iranyitja.

## Konfiguracio

### Kornyezeti valtozok

A `command` ele toldva a `~/.claude/settings.json`-ban.

| Opcio | Ertekek | Default | Hatas |
|-------|---------|---------|-------|
| `STATUSLINE_LAYOUT` | `1` / `2` | `1` | Egysoros vagy ketsoros kimenet |
| `STATUSLINE_PROFILE` | `minimal` / `standard` / `full` | `full` | Mennyi mezo latszik |
| `DEBUG` | `0` / `1` | `0` | `1` eseten elmenti a nyers stdin JSON-t a `~/.claude/debug_status.json`-ba minden frissiteskor |

### `statusLine` settings.json mezok

| Mezo | Tipus | Megjegyzes |
|------|-------|------------|
| `type` | string | Mindig `"command"` |
| `command` | string | A futtatando parancs (env-valtozokkal elotoldva) |
| `padding` | egesz | Vizszintes margo; `0` a szelig |
| `refreshInterval` | mp (≥1) | Ido alapjan ujrafuttat, igy a Shift+Tab modvaltas uj asszisztens valasz nelkul is latszik |

### Debug mod

Ahhoz, hogy lasd, pontosan mit kuld a Claude Code, inditsd igy:

```bash
DEBUG=1 claude
```

Ez minden frissiteskor elmenti a nyers JSON bemenetet a `~/.claude/debug_status.json` fajlba. A fajl git-ignored, igy soha nem kerul commitba.

## Funkciok

### Fast mode jelzo

A `/fast` valtaskor a statusline `⚡FAST`-ot mutat sargaban a modellnev mellett. A transcriptbol olvassa az utolso `Fast mode ON/OFF` esemenyt, fallback a `"speed"` mezo. A `/fast` elerheto Opus 5-on es Opus 4.8-on (az Opus 4.7-rol eltavolitottak).

### Permission mode jelzo

A Claude Code stdin JSON **nem** tartalmazza a permission modot — csak a `vim.mode`, `output_style.name` es `agent.name` van benne. A statusline a transcript JSONL utolso `{"type":"permission-mode","permissionMode":"..."}` bejegyzesebol olvassa ki:

- 📋 **PLAN** (sarga) — read-only tervezesi mod (Shift+Tab)
- 🚀 **AUTO** (kek) — autonom vegrehajtas
- ✅ **EDIT** (cyan) — auto-accept szerkesztesek
- ⚠️ **YOLO** (piros) — `bypassPermissions`
- a `default` mod nem latszik (tiszta bar)

A bar frissul minden asszisztens uzenet utan, permission-mode valtaskor, es a beallitott `refreshInterval` (alap 2 mp) szerint.

### Context ablak progress bar

20 karakteres bar (a `minimal` profilban 10), ami szint valt: zold 50% alatt, sarga 50–75%, piros 75% folott. A `(Xk/Yk)` token-szam a `used_percentage × context_window_size`-bol **szarmaztatva**, igy mindig konzisztens a barral.

### 1M-context tudatossag (Claude 5 csalad)

Minden aktualis modell — Fable 5, Opus 5/4.8/4.7/4.6, Sonnet 5, Sonnet 4.6 — 1M tokenes context ablakkal fut, ahol a 200k atlepese rutinszeru, nem figyelmeztetes — ezert informativ cyan `📚 long-ctx` jelet mutat. A 200k-s modelleknel (Haiku 4.5) a 200k a valodi plafon, ott marad a piros `⚠️ 200k+`. A megkulonboztetes adat-vezerelt (`context_window_size > 200000`), igy a jovobeli modellekkel is automatikusan mukodik.

### Git integracio

Az aktualis branch nevet mutatja, `*` utotaggal ha vannak nem commitolt valtozasok.

### Sorok valtozasa

A sessionben hozzaadott/torolt sorok osszege. `±0` ha nincs valtozas.

### Rate limits (csak Pro/Max)

A Claude.ai 5 oras es 7 napos rate limit hasznalatot mutatja (`📊 5h:42% 7d:87%`), ha a `rate_limits` mezo jelen van. Csak a `full` profilban.

### Worktree es agent jelzok

- `🌳 name` worktree / `--worktree` sessionben.
- `🤝 name` az aktiv subagent.
- `📛 name` egyedi session nev (`--name` / `/rename`).
- `🎨 name` output style, ha nem `default`.
- `⌨ NORMAL` / `⌨ INSERT` vim mode eseten.

## Hogyan mukodik (architektura)

A Claude Code minden statusz-frissiteskor lefuttatja a `statusLine.command`-ot, es egy JSON objektumot pipe-ol a **stdin**-jere. A script kiolvassa ezt, osszegyujt par tovabbi tenyt amit a JSON nem hordoz, es kiir egy (vagy ket) ANSI-szines sort.

```
Claude Code  ── JSON a stdin-en ──▶  statusline.sh
                                          │
   1. data=$(cat)              teljes stdin a $data-ba
   2. egy jq hivas             modell, koltseg, ctx %, meretek, mappak, flagek …
   3. transcript JSONL         permission mode, fast mode, API hivasszam
   4. helyi szamitas           git branch + dirty, idotartam, szinek, bar
   5. profil/layout szerint    az ANSI sztring(ek) osszeallitasa
                                          │
                                          ▼
                               status bar sor(ok) ──▶ a Claude Code rendereli
```

**Egy `jq` hivas.** Minden stdin mezo egyetlen `jq -r` hivasban jon ki `@sh` idezessel, majd `eval`-lal valtozokba. Az `@sh` minden erteket shell-idez, igy a megbizhatatlan stdin ellenere az `eval` injekcio-biztos.

**Miert olvassa a transcriptet.** A stdin JSON nem teszi kozze a **permission modot**, a **fast mode** allapotot, sem az **API hivasszamot**. A script a transcript JSONL-t (`transcript_path`) olvassa:

- utolso `{"type":"permission-mode","permissionMode":"..."}` → permission mode
- utolso `Fast mode ON/OFF` (fallback `"speed":"fast"`) → fast mode
- `"type":"assistant"` bejegyzesek szama → API hivasszam

**Frissitesi triggerek.** A bar ujrarenderel minden asszisztens uzenet utan, permission-mode vagy vim-mode valtaskor, es `refreshInterval` masodpercenkent. Minden futas par `tac | grep` olvasas a transcripten plusz `git` hivasok — olcso, de fut a timeren is, igy tartsd a `refreshInterval`-t 2 mp-en vagy folotte.

## Ikonok es logika

| Ikon | Jelentes | Forras / Logika |
|------|----------|-----------------|
| 🤖 | Modell neve | `model.display_name` a Claude Code JSON bemenetbol — tier szerint szinezve: Fable/Mythos = arany (frontier), Opus = magenta (premium), Sonnet = kek, Haiku = zold |
| ⚡FAST | Fast mod aktiv (sarga) | Transcript JSONL-bol: eloszor `Fast mode ON/OFF` toggle-t keres, fallback: `"speed":"fast"` |
| STD | Standard sebesseg (szurke) | Ugyanaz, mint fent — ha nincs fast mod |
| 📋 PLAN / 🚀 AUTO / ✅ EDIT / ⚠️ YOLO | Permission mode | Transcript JSONL utolso `{"type":"permission-mode","permissionMode":"..."}` bejegyzese; `default` eseten nincs kijelzes |
| 🎨 style | Output style | `output_style.name` — csak ha ≠ `default` (standard/full profil) |
| 🤝 agent | Aktiv subagent | `agent.name` — csak `--agent` sessionben (standard/full profil) |
| 📛 name | Egyedi session nev | `session_name` — csak `--name` / `/rename` eseten (standard/full profil) |
| ⚠️ 200k+ / 📚 long-ctx | 200k token folott | `exceeds_200k_tokens` — piros `⚠️ 200k+` ha `context_window_size` ≤ 200k (plafon), cyan `📚 long-ctx` ha > 200k mint az 1M-es Claude 5 modellek (informativ); full profil |
| $X.XX | Session koltseg | `cost.total_cost_usd` — valos API koltseg (Pro/Max: $0.00) |
| [████░░] X% | Context ablak hasznalat | `context_window.used_percentage` — 20 karakteres progress bar, szin: 🟢 <50%, 🟡 50-75%, 🔴 >75% |
| (Xk/Xk) | Tokenek (hasznalt/osszes) | `used_percentage * context_window_size` / `context_window_size` |
| ⏱ | Session idotartam | `cost.total_duration_ms` — formatum: Xs, XmXs, vagy XhXm |
| 📡 N | API hivasok szama | `"type":"assistant"` bejegyzesek szama a transcript JSONL-ben |
| 📊 5h:X% 7d:Y% | Rate limits | `rate_limits.five_hour` / `rate_limits.seven_day` — csak Pro/Max (full profil) |
| +X/-Y | Sorok valtozasa | `cost.total_lines_added` / `cost.total_lines_removed` — zold/piros |
| 🌿 | Git branch | `git branch --show-current`, `*` = nem commitolt valtozasok |
| 📁 | Projekt mappa | `basename` a `workspace.current_dir`-bol |
| 🌳 | Git worktree | `worktree.name` vagy `workspace.git_worktree` (full profil) |
| ⌨ | Vim mode | `vim.mode` — `NORMAL` / `INSERT` (full profil) |
| │ | Elvalaszto | Vizualis hatarolo a szekciok kozott |

## Testreszabas

A `statusline.sh`-ban modosithatod:

- **Progress bar szelesseg**: `bar_len=20` a context-window szekcioban
- **Szin-kuszobok**: a szazalek-ellenorzesek a context-window szekcioban
- **Modell tier szinek**: a `case "$model"` blokk (a `MODEL TIER COLOR` szekcio)
- **Kimeneti formatum**: a lenti output-osszeallito blokk
- **Szekciok eltavolitasa**: kommenteld ki vagy torold a nem kello szegmenst

Lasd az `examples/minimal.sh`-t egy lecsupasztott valtozathoz.

## Fejlesztes es hozzajarulas

### Helyi teszt Claude Code nelkul

A script egyetlen JSON objektumot olvas stdin-en, igy kozvetlenul etethetsz minta-bemenetet:

```bash
echo '{"model":{"display_name":"Fable 5"},"context_window":{"used_percentage":25,"context_window_size":1000000},"exceeds_200k_tokens":true,"cost":{"total_cost_usd":1.2},"workspace":{"current_dir":"'"$PWD"'"}}' \
  | STATUSLINE_LAYOUT=2 STATUSLINE_PROFILE=full ./statusline.sh
```

Csereld a `display_name`-t `Opus 5` / `Sonnet 5` / `Haiku 4.5`-re a tier szinekhez, vagy allitsd a `context_window_size`-t `200000`-re a piros `⚠️ 200k+`-hoz a `📚 long-ctx` helyett.

### Valos bemenet rogzitese

```bash
DEBUG=1 claude
# majd:
cat ~/.claude/debug_status.json | jq .
```

### Kodszerkezet (`statusline.sh`)

A script jol kommentezett szekciokra van bontva: egy `jq` kinyero blokk, majd funkcio-blokkok (modell tier szin, context window, idotartam, transcript adat, sorok, git), profil-gateelt extrak, vegul az output-osszeallito blokk harom aggal (`minimal`, ketsoros, egysoros).

### Uj szegmens hozzaadasa

1. Nyerd ki az uj stdin mezot a `jq` blokkban (`@sh "var=\(.path // default)"`).
2. Szamitsd ki a megjelenitendo sztringet (profil szerint gateelve, ha kell).
3. Fuzd hozza a megfelelo output aghoz a `[ -n "$x" ] && output="${output} │ ${x}"` mintaval.
4. Dokumentald a **Mit mutat**, **Ikonok es logika** es **Szegmens-lathatosagi matrix** tablakban.

### Pull requestek

Tartsd a valtoztatasokat lehetoleg POSIX-baratnak, futtasd a `bash -n statusline.sh`-t commit elott, es ellenorizd par minta JSON-nal a profilok kozott. A remote-on van egy aktiv feature branch (`feat/permission-mode-and-layouts`) a folyamatban levo munkahoz.

## GYIK

**Miert `?` a modell?** — A `model.display_name` rovid ideig hianyzik a kezdeti betoltesnel. Az elso frissites utan megjon. Ha tartos, `DEBUG=1 claude` es nezd meg a JSON-t.

**Nem latszanak a szinek / nyers `\033[…` kodokat latok** — A terminalod nem ertelmezi az ANSI escape-eket. Hasznalj modern terminalt.

**A koltseg `$0.00`** — Ez varhato Claude.ai Pro/Max felhasznaloknak — nincs per-keres szamlazas. API-kulcsos felhasznalok latjak a valos koltseget. Pro/Max felhasznalok a `📊` rate-limit szegmenst kapjak helyette.

**A `📚 long-ctx` lecserelte a `⚠️ 200k+`-t** — Szandekos az 1M-context modelleknel (Fable 5, Opus 5/4.x, Sonnet 5/4.6): ott a 200k atlepese normalis, ezert informativ (cyan), nem figyelmeztetes (piros). A 200k-s modellek mint a Haiku 4.5 tovabbra is a piros figyelmeztetest mutatjak.

**Hogyan rejtsek el egy szegmenst?** — Valts kisebb profilra (`minimal`/`standard`), vagy szerkeszd az output-osszeallito blokkot a `statusline.sh`-ban.

**Lassitja a Claude Code-ot?** — Nincs erezheto hatas. Minden futas par `grep`/`git` hivas. `refreshInterval: 2` eseten kb. 2 mp-enkent fut.

**A permission mode keslekedik Shift+Tab utan** — Add hozza a `"refreshInterval": 2`-t a confighoz (az ajanlott telepito ezt teszi). Lasd Hibaelharitas.

## Hibaelharitas

### A statusline nem jelenik meg
- Ellenorizd, hogy a `~/.claude/settings.json`-ban van `statusLine` config
- Ellenorizd, hogy a `~/.claude/statusline.sh` letezik es futtathato (`chmod +x`)
- Inditsd ujra a Claude Code-ot

### "?" a modellnevnel
- Ez normalis a kezdeti betoltesnel
- Ha tartos, `DEBUG=1 claude` es nezd meg a `~/.claude/debug_status.json`-t

### jq hibak
- Ellenorizd, hogy a `jq` telepitve van: `which jq`
- Telepites: `apt install jq` / `brew install jq` / `pacman -S jq`

### A git branch nem latszik
- A jelenlegi mappanak git repon belul kell lennie
- A `git` legyen telepitve es a PATH-ban

### A fast mode nem detektalodik
- Valts `/fast`-ot es kuldj legalabb egy uzenetet
- A speed mezo az elso API valasz utan jelenik meg a transcriptben

### A permission mode nem frissul Shift+Tab utan
- A Claude Code csak uj asszisztens uzenet, permission-mode valtozas, vagy vim-mode valtas utan futtatja a statusline-t
- Adj hozza `"refreshInterval": 2` mezot a `statusLine` configodhoz, igy 2 masodpercenkent frissul (az ajanlott telepito ezt teszi)
- Ha meg igy is beragad, ellenorizd, hogy a `transcript_path` olvashato fajlra mutat (`DEBUG=1 claude`)

## Eltavolitas

1. Tavolitsd el (vagy szerkeszd) a `statusLine` blokkot a `~/.claude/settings.json`-bol.
2. Opcionalisan tarold a scriptet: `rm ~/.claude/statusline.sh`.
3. Inditsd ujra a Claude Code-ot.

## Valtozasok

A teljes verziotortenet a [CHANGELOG.md](CHANGELOG.md)-ben.

## Licenc

MIT — lasd [LICENSE](LICENSE)

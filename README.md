# Claude Code Statusline

A customizable, informative status bar for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI.

*Magyar verzio lentebb / Hungarian version below*

**Single line** (default):

```
🤖 Opus 4.8 ⚡FAST 📋 PLAN │ $0.51 │ [████░░░░░░░░░░░░░░░░] 24% (22k/200k) │ ⏱ 6m51s │ 📡 5 │ +12/-3 │ 🌿 main │ 📁 my-project
```

**Two lines** (`STATUSLINE_LAYOUT=2`) — identity on top, metrics below:

```
🤖 Opus 4.8 ⚡FAST 📋 PLAN │ 🌿 main │ 📁 my-project
$0.51 │ [████░░░░░░░░░░░░░░░░] 24% (22k/200k) │ ⏱ 6m51s │ 📡 5 │ +12/-3
```

## What it shows

| Indicator | Description |
|-----------|-------------|
| 🤖 Model | Current model, colored by tier — Opus magenta, Sonnet blue, Haiku green (Opus 4.8, Sonnet 4.6, etc.) |
| ⚡FAST / STD | Fast mode indicator |
| 📋 PLAN / 🚀 AUTO / ✅ EDIT / ⚠️ YOLO | Permission mode (read from transcript — `default` is silent) |
| 🎨 style | Output style (when not default) |
| 🤝 agent | Active subagent name |
| 📛 name | Custom session name (set via `--name` / `/rename`) |
| ⚠️ 200k+ / 📚 long-ctx | Token threshold crossed: red `⚠️ 200k+` on classic 200k models (at the ceiling), cyan `📚 long-ctx` on 1M-context models like Opus 4.8 (informational) |
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

### Context window colors

- 🟢 Green: < 50% used
- 🟡 Yellow: 50-75% used
- 🔴 Red: > 75% used

### Model tier colors

The 🤖 model name is colored by tier so you can tell at a glance which model (and price point) you're on:

- 🟣 Magenta (bold): **Opus** — premium tier (e.g. Opus 4.8)
- 🔵 Blue: **Sonnet**
- 🟢 Green: **Haiku**

Matching is on the tier word in `model.display_name`, so new versions are colored automatically with no code change.

### Profile (`STATUSLINE_PROFILE` env var)

Control how much is shown. Default is `full`.

| Profile | Includes |
|---------|----------|
| `minimal` | Base fields + permission mode + fast mode |
| `standard` | + output style, agent, session name |
| `full` (default) | + rate limits, worktree, vim mode, 200k+ warning |

Set it in `~/.claude/settings.json`:

```json
{ "statusLine": { "type": "command", "command": "STATUSLINE_PROFILE=standard ~/.claude/statusline.sh" } }
```

### Layout (`STATUSLINE_LAYOUT` env var)

- `1` (default) — single line
- `2` — two lines. **Row 1** (identity): model, permission mode, output style, agent, session name, git branch, project folder, worktree, vim. **Row 2** (metrics): cost, context bar + tokens, duration, API count, rate limits, 200k+ warning, lines changed.

Recommended with `full` profile to avoid horizontal wrapping on narrow terminals. The `minimal` profile ignores this setting and stays one line by design.

```json
{ "statusLine": { "type": "command", "command": "STATUSLINE_LAYOUT=2 ~/.claude/statusline.sh" } }
```

Combine with profile if you want both:

```json
{ "statusLine": { "type": "command", "command": "STATUSLINE_LAYOUT=2 STATUSLINE_PROFILE=standard ~/.claude/statusline.sh" } }
```

## Requirements

- **bash** 4.0+
- **jq** (JSON processor)
- **git** (optional, for branch info)
- **Claude Code** CLI

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

## Configuration

All options are toggled via environment variables prepended to the command in `~/.claude/settings.json`. `refreshInterval` is a top-level `statusLine` field.

| Option | Values | Default | Effect |
|--------|--------|---------|--------|
| `STATUSLINE_LAYOUT` | `1` / `2` | `1` | Single line vs. two lines |
| `STATUSLINE_PROFILE` | `minimal` / `standard` / `full` | `full` | How many fields to show |
| `refreshInterval` (JSON field) | seconds (≥1) | unset | Re-run the command on a timer so mode changes show without waiting for a new assistant message |

### Debug mode

To debug the statusline input data, start Claude Code with:

```bash
DEBUG=1 claude
```

This saves the raw JSON input to `~/.claude/debug_status.json` on every update.

## Features

### Fast mode indicator

When you toggle `/fast` in Claude Code, the statusline shows `⚡FAST` in yellow next to the model name. This works by reading the transcript file for the last `Fast mode ON/OFF` event, falling back to the `"speed"` field.

### Permission mode indicator

The Claude Code stdin JSON does **not** include the current permission mode — only `vim.mode`, `output_style.name`, and `agent.name` are exposed. The statusline reads the last `{"type":"permission-mode","permissionMode":"..."}` entry from the transcript JSONL to detect the active mode:

- 📋 **PLAN** (yellow) — read-only planning mode (Shift+Tab)
- 🚀 **AUTO** (blue) — autonomous execution mode
- ✅ **EDIT** (cyan) — auto-accept edits
- ⚠️ **YOLO** (red) — `bypassPermissions`
- `default` mode is silent (no icon) to keep the bar clean

The bar updates after each assistant message, after a permission-mode change, and on the configured `refreshInterval` (default 2s in this project's settings) — so Shift+Tab mode switches are reflected within a couple of seconds even without a new assistant response.

### Context window progress bar

A 20-character wide progress bar that changes color based on usage:
- Green when under 50%
- Yellow between 50-75%
- Red above 75%

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
- `⚠️ 200k+` / `📚 long-ctx` marks crossing 200k tokens — red warning on classic 200k models (at the ceiling), cyan informational badge on 1M-context models like Opus 4.8.
- `⌨ NORMAL` / `⌨ INSERT` appears when vim mode is enabled.

## Customization

You can modify `statusline.sh` to change:

- **Progress bar width**: Change `bar_len=20` (line ~51)
- **Color thresholds**: Adjust the percentage checks in the context window section
- **Output format**: Modify the output assembly section at the bottom
- **Remove sections**: Comment out or delete any section you don't need

See `examples/minimal.sh` for a stripped-down version showing only model, cost, and context percentage.

## How it works

Claude Code pipes a JSON object to the statusline command's stdin on every update (after each assistant message, when the permission mode changes, or when vim mode toggles). The JSON contains:

- `model.display_name` — Current model name
- `cost.total_cost_usd` — Session cost
- `cost.total_duration_ms` — Session duration
- `cost.total_lines_added` / `cost.total_lines_removed` — Code changes
- `context_window.used_percentage` — Context usage percentage (can be a float — cast to integer with `jq | floor`)
- `context_window.context_window_size` — Max context tokens (200k default, 1M for extended-context models)
- `exceeds_200k_tokens` — Whether the session crossed 200k tokens
- `rate_limits.{five_hour,seven_day}.used_percentage` — Pro/Max rate-limit usage
- `output_style.name` — Active output style
- `agent.name` — Active subagent name (when running with `--agent`)
- `session_name` — Custom name set via `--name` / `/rename`
- `workspace.current_dir` / `workspace.git_worktree` — Working directory and worktree
- `worktree.{name,path,branch}` — Active worktree info (in `--worktree` sessions)
- `vim.mode` — Vim editor mode
- `transcript_path` — Path to session transcript (JSONL file)

The permission mode (`plan` / `auto` / `acceptEdits` / `bypassPermissions` / `default`) is **not** exposed in the stdin JSON — the script reads it from the transcript JSONL (`{"type":"permission-mode","permissionMode":"..."}`).

The script extracts all fields in a single `jq` call, then assembles the output string with ANSI color codes.

## Icons & Logic

| Icon | Meaning | Source / Logic |
|------|---------|---------------|
| 🤖 | Model name | `model.display_name` from Claude Code JSON input — colored by tier: Opus = magenta (premium), Sonnet = blue, Haiku = green |
| ⚡FAST | Fast mode active (yellow) | Reads transcript JSONL: first checks for `Fast mode ON/OFF` toggle, falls back to `"speed":"fast"` field |
| STD | Standard speed (gray) | Same as above, shown when not in fast mode |
| 📋 PLAN / 🚀 AUTO / ✅ EDIT / ⚠️ YOLO | Permission mode | Reads last `{"type":"permission-mode","permissionMode":"..."}` entry in transcript JSONL; `default` is silent |
| 🎨 style | Output style | `output_style.name` — shown only when ≠ `default` (standard/full profile) |
| 🤝 agent | Active subagent | `agent.name` — present only during `--agent` sessions (standard/full profile) |
| 📛 name | Custom session name | `session_name` — shown only when set via `--name` / `/rename` (standard/full profile) |
| ⚠️ 200k+ / 📚 long-ctx | Over 200k tokens | `exceeds_200k_tokens` — red `⚠️ 200k+` when `context_window_size` ≤ 200k (at the ceiling), cyan `📚 long-ctx` when > 200k like Opus 4.8 1M (informational); full profile |
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

## License

MIT - see [LICENSE](LICENSE)

---

# Claude Code Statusline (Magyar)

Testreszabhato, informativ status bar a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI-hez.

**Egysoros** (alapertelmezett):

```
🤖 Opus 4.8 ⚡FAST 📋 PLAN │ $0.51 │ [████░░░░░░░░░░░░░░░░] 24% (22k/200k) │ ⏱ 6m51s │ 📡 5 │ +12/-3 │ 🌿 main │ 📁 my-project
```

**Ketsoros** (`STATUSLINE_LAYOUT=2`) — identitas felul, metrikak alul:

```
🤖 Opus 4.8 ⚡FAST 📋 PLAN │ 🌿 main │ 📁 my-project
$0.51 │ [████░░░░░░░░░░░░░░░░] 24% (22k/200k) │ ⏱ 6m51s │ 📡 5 │ +12/-3
```

## Mit mutat

| Jelzo | Leiras |
|-------|--------|
| 🤖 Model | Aktualis modell, tier szerint szinezve — Opus magenta, Sonnet kek, Haiku zold (Opus 4.8, Sonnet 4.6, stb.) |
| ⚡FAST / STD | Fast mode jelzo |
| 📋 PLAN / 🚀 AUTO / ✅ EDIT / ⚠️ YOLO | Permission mode (transcriptbol olvasva — `default` nem latszik) |
| 🎨 style | Output style (ha nem default) |
| 🤝 agent | Aktiv subagent neve |
| 📛 name | Egyedi session nev (`--name` / `/rename`) |
| ⚠️ 200k+ / 📚 long-ctx | 200k token atlepve: piros `⚠️ 200k+` klasszikus 200k modellnel (plafon), cyan `📚 long-ctx` 1M-context modellnel mint Opus 4.8 (informativ) |
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

### Context ablak szinek

- 🟢 Zold: < 50% hasznalat
- 🟡 Sarga: 50-75% hasznalat
- 🔴 Piros: > 75% hasznalat

### Modell tier szinek

A 🤖 modellnev tier szerint szinezve, hogy egy pillantasra lasd, melyik modellen (es araron) vagy:

- 🟣 Magenta (felkover): **Opus** — premium tier (pl. Opus 4.8)
- 🔵 Kek: **Sonnet**
- 🟢 Zold: **Haiku**

A talalat a `model.display_name` tier-szavara megy, igy az uj verziok kodmodositas nelkul szinezodnek.

### Profil (`STATUSLINE_PROFILE` kornyezeti valtozo)

Szabalyozza, hogy mennyi mezot lass. Alapertelmezett: `full`.

| Profil | Tartalmaz |
|--------|-----------|
| `minimal` | Alap mezok + permission mode + fast mode |
| `standard` | + output style, agent, session nev |
| `full` (default) | + rate limits, worktree, vim mode, 200k+ figyelmeztetes |

Allitsd be a `~/.claude/settings.json`-ban:

```json
{ "statusLine": { "type": "command", "command": "STATUSLINE_PROFILE=standard ~/.claude/statusline.sh" } }
```

### Elrendezes (`STATUSLINE_LAYOUT` kornyezeti valtozo)

- `1` (alapertelmezett) — egy sor
- `2` — ket sor. **1. sor** (identitas): modell, permission mode, output style, agent, session nev, git branch, projekt mappa, worktree, vim. **2. sor** (metrikak): koltseg, context bar + tokenek, duration, API szam, rate limits, 200k+ figyelmeztetes, sorok valtozasa.

Ajanlott a `full` profillal, hogy ne csusszon le a bar keskeny terminalon. A `minimal` profil figyelmen kivul hagyja ezt a beallitast (mindig egy soros marad).

```json
{ "statusLine": { "type": "command", "command": "STATUSLINE_LAYOUT=2 ~/.claude/statusline.sh" } }
```

Profillal kombinalhato:

```json
{ "statusLine": { "type": "command", "command": "STATUSLINE_LAYOUT=2 STATUSLINE_PROFILE=standard ~/.claude/statusline.sh" } }
```

## Kovetelmenyek

- **bash** 4.0+
- **jq** (JSON feldolgozo)
- **git** (opcionalis, branch infohoz)
- **Claude Code** CLI

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

## Konfiguracio

Minden beallitas a `~/.claude/settings.json`-ban van, a `command` ele toldott kornyezeti valtozokkal. A `refreshInterval` a `statusLine` objektum top-level mezoje.

| Opcio | Ertekek | Default | Hatas |
|-------|---------|---------|-------|
| `STATUSLINE_LAYOUT` | `1` / `2` | `1` | Egysoros vagy ketsoros kimenet |
| `STATUSLINE_PROFILE` | `minimal` / `standard` / `full` | `full` | Mennyi mezo latszik |
| `refreshInterval` (JSON mezo) | masodperc (≥1) | nincs | Ido alapjan ujrafuttatja a parancsot, igy a modvaltas uj asszisztens valasz nelkul is latszik |

## Debug mod

A statusline bemenet debugolasahoz inditsd igy a Claude Code-ot:

```bash
DEBUG=1 claude
```

Ez minden frissiteskor elmenti a nyers JSON bemenetet a `~/.claude/debug_status.json` fajlba.

## Hogyan mukodik

A Claude Code minden frissiteskor egy JSON objektumot pipe-ol a statusline parancs stdin-jere (asszisztens uzenet utan, permission mode valtaskor, vagy vim mode valtaskor). A script egyetlen `jq` hivassal kiolvassa az osszes mezot, majd ANSI szinkodokkal osszeallitja a kimenetet.

**Fontos**: a permission mode (`plan` / `auto` / `acceptEdits` / `bypassPermissions` / `default`) **nem szerepel** a stdin JSON-ben — a script a transcript JSONL-bol olvassa ki (`{"type":"permission-mode","permissionMode":"..."}` bejegyzesek), az utolso valtozast veszi. A fast mode allapotot szinten a transcriptbol olvassa (`Fast mode ON/OFF` toggle, fallback `"speed":"fast"`).

A bar akkor frissul, amikor uj asszisztens uzenet erkezik, permission-mode valtozik, vagy a beallitott `refreshInterval` (e projektnel 2 mp) lejar — igy a Shift+Tab valtas par masodpercen belul lathato, akkor is, ha meg nincs uj asszisztens valasz.

## Ikonok es logika

| Ikon | Jelentes | Forras / Logika |
|------|----------|-----------------|
| 🤖 | Modell neve | `model.display_name` a Claude Code JSON bemenetbol — tier szerint szinezve: Opus = magenta (premium), Sonnet = kek, Haiku = zold |
| ⚡FAST | Fast mod aktiv (sarga) | Transcript JSONL-bol: eloszor `Fast mode ON/OFF` toggle-t keres, fallback: `"speed":"fast"` |
| STD | Standard sebesseg (szurke) | Ugyanaz, mint fent — ha nincs fast mod |
| 📋 PLAN / 🚀 AUTO / ✅ EDIT / ⚠️ YOLO | Permission mode | Transcript JSONL utolso `{"type":"permission-mode","permissionMode":"..."}` bejegyzese; `default` eseten nincs kijelzes |
| 🎨 style | Output style | `output_style.name` — csak ha ≠ `default` (standard/full profil) |
| 🤝 agent | Aktiv subagent | `agent.name` — csak `--agent` sessionben (standard/full profil) |
| 📛 name | Egyedi session nev | `session_name` — csak `--name` / `/rename` eseten (standard/full profil) |
| ⚠️ 200k+ / 📚 long-ctx | 200k token folott | `exceeds_200k_tokens` — piros `⚠️ 200k+` ha `context_window_size` ≤ 200k (plafon), cyan `📚 long-ctx` ha > 200k mint az Opus 4.8 1M (informativ); full profil |
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

## Hibaelharitas

### A permission mode nem frissul Shift+Tab utan
- A Claude Code csak uj asszisztens uzenet, permission-mode valtozas, vagy vim-mode valtas utan futtatja a statusline-t
- Adj hozza `"refreshInterval": 2` mezot a `statusLine` configodhoz, igy 2 masodpercenkent frissul (az ajanlott telepito ezt teszi)
- Ha meg igy is beragad, ellenorizd, hogy a `transcript_path` olvashato fajlra mutat (`DEBUG=1 claude`)

## Licenc

MIT - lasd [LICENSE](LICENSE)

# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.5.0]

Makes the quota segments answer the question they were silently raising: *how
much is left, and until when?* Claude Code 2.1.259 ships `resets_at` and
`expires_at` timestamps that the statusline was not reading.

### Added
- **Rate-limit reset countdown** — `📊 5h:13% ↻28m 7d:25% ↻2d23h`. The dim `↻`
  is the time until that window rolls over, from
  `rate_limits.{five_hour,seven_day}.resets_at`. Format adapts to the distance:
  `2d23h` / `4h12m` / `28m` / `<1m`. Silent when the field is absent (older
  Claude Code) or already in the past — a stale reset time is worse than none.
- **Prompt-cache TTL countdown** — `💾 99% ↻58m` from `prompt_cache.expires_at`:
  how long before the cache goes cold and the next request re-writes the whole
  prefix. Not shown on an already-cold cache, which keeps its dim `💾 cold`.
- **Blinking red rate limit at ≥95% used** — under 5% of the window left is the
  one state worth interrupting for, so it blinks (`SGR 5`) in bold red instead
  of sharing the plain red of the 80–94% band. Terminals that ignore blink
  still show the bold red.

### Changed
- The `📊` docs now state explicitly that the percentage is the share **used**,
  not the share remaining (`5h:13%` = 13% consumed, 87% still available) — the
  most common misreading of the segment.

### Notes
- Timestamps are compared against `printf '%(%s)T'` with a `date +%s` fallback,
  so no extra process is forked per render on bash 4.2+.

## [0.4.0]

Adapts the statusline to the Claude Code stdin fields that arrived with the
Claude 5 family — the Fable 5.1 / Mythos 5.1 tier colors already worked
(version-independent glob), this release surfaces what those models actually
expose.

### Added
- **`🧠 effort` segment** — live reasoning-effort level from the `effort.level`
  stdin field (`low` / `medium` / `high` / `xhigh` / `max`), colored by cost:
  `max` bold red, `xhigh` bold magenta, `high` plain, `medium`/`low` dim.
  Follows `/effort` changes mid-session. Shown in every profile, because on
  Fable 5.1 / Mythos 5.1 (thinking always on) effort is the only tuning knob.
  Hidden when the model doesn't support the effort parameter.
- **`💾 cache` segment** (full profile) — prompt-cache hit ratio from the
  `prompt_cache` stdin field: green ≥80%, yellow ≥50%, red below; dim
  `💾 cold` once the 1-hour cache TTL has expired.
- **`🔀 PR` badge** (full profile) — open pull request on the current branch
  from the `pr` stdin field, colored by review state (green approved, red
  changes requested, dim draft). GitLab merge requests show as `!N`.
- Docs refreshed for Fable 5.1 / Mythos 5.1 (`claude-fable-5-1`); test snippets
  now include the new fields.

### Changed
- **Fast mode** now reads the native `fast_mode` stdin field instead of
  grepping the transcript for `Fast mode ON/OFF` / `"speed"` events.
- The transcript is now read only for the API call count and the permission
  mode (still absent from stdin).

### Removed
- The gray **`STD`** badge. `⚡FAST` is shown only when fast mode is on; "not
  fast" carried no information, and most models (Fable, Mythos, Sonnet, Haiku)
  have no fast mode at all.
- Transcript-based fast-mode detection (`tac | grep` on `Fast mode ON/OFF`
  and `"speed":"fast"`).

### Docs
- **Screenshots** — the README now opens with a rendered shot of the full
  profile, plus a `Screenshots` section comparing the three profiles, the
  two-line layout, and the model-tier / permission-mode / warning states.
  Every image is the real script output rendered from sample stdin JSON.

## [0.3.0]

### Added
- **`--version` flag** — the script now carries its own version
  (`STATUSLINE_VERSION`) and `statusline.sh --version` prints it without
  needing stdin, so you can tell at a glance which version is deployed on
  any machine.
- **Claude Code version segment** — `⚙ vX.Y.Z` (dim gray, full profile),
  read from the `version` field of the stdin JSON.
- **Rate-limit coloring** — the `📊 5h:X% 7d:Y%` values turn yellow at ≥60%
  and red at ≥80%, so approaching a limit is visible before hitting it.
- **Fable/Mythos tier color** — the new Claude 5 frontier tier (Fable 5,
  Mythos 5) is shown in bold gold, above Opus's magenta.
- **Model-tier coloring** for the `🤖` model name — Opus is bold magenta (premium
  tier), Sonnet blue, Haiku green. Matching is on the tier word in
  `model.display_name`, so new model versions are colored with no code change.
- **`📚 long-ctx` badge** — on models whose `context_window_size` exceeds 200k
  (e.g. the 1M-window Claude 5 models), crossing 200k tokens now shows an
  informational cyan `📚 long-ctx` badge instead of the red `⚠️ 200k+` warning.
- Comprehensive documentation: architecture deep-dive, configuration & segment
  visibility matrix, Development/Contributing guide, FAQ, and this changelog.

### Changed
- Tier detection now falls back to **`model.id`** (e.g. `claude-fable-5`)
  when the tier word isn't found in `model.display_name` — more robust
  against display-name changes.
- Model-tier matching is now truly **case-insensitive** (`${model,,}` +
  lowercase glob patterns), as the comment always promised.
- Docs updated to the Claude 5 family: 1M context is now standard on Fable 5,
  Opus 5/4.8/4.7/4.6, Sonnet 5, and Sonnet 4.6 (Haiku 4.5 stays 200k); fast
  mode availability corrected to Opus 5 / Opus 4.8 (removed from Opus 4.7);
  README examples and test snippets refreshed (English + Hungarian).
- `⚠️ 200k+` now only shows red (the ceiling warning) on classic 200k-context
  models; on 1M-context models the cyan `📚 long-ctx` badge is shown instead.

### Fixed
- Corrected a repository URL typo in `install.sh` (`kalmarr-dev` → `kalmarr`).

## [0.2.0]

### Added
- **Permission mode indicator** — reads the last `permissionMode` entry from the
  transcript JSONL: `📋 PLAN`, `🚀 AUTO`, `✅ EDIT`, `⚠️ YOLO` (`default` is silent).
- **Two-line layout** (`STATUSLINE_LAYOUT=2`) — identity row on top, metrics below.
- **Feature profiles** (`STATUSLINE_PROFILE`): `minimal`, `standard`, `full`.
- Output style, active subagent, custom session name, worktree, vim mode,
  `exceeds_200k_tokens`, and Pro/Max rate-limit indicators.
- Installer now prompts to enable the two-line layout.

## [0.1.1]

### Fixed
- Context token display now derives the used-token count from `used_percentage`
  instead of cumulative session totals, so the count stays consistent with the
  progress bar.

## [0.1.0]

### Added
- Initial release: model, cost, context-window meter, session duration, API call
  count, fast-mode indicator, lines changed, git branch, and project folder.
- `install.sh`, `/install-statusline` slash command, and Icons & Logic docs.

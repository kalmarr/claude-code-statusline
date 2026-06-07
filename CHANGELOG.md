# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- **Model-tier coloring** for the `🤖` model name — Opus is bold magenta (premium
  tier), Sonnet blue, Haiku green. Matching is on the tier word in
  `model.display_name`, so new model versions are colored with no code change.
- **`📚 long-ctx` badge** — on models whose `context_window_size` exceeds 200k
  (e.g. Opus 4.8 with a 1M window), crossing 200k tokens now shows an
  informational cyan `📚 long-ctx` badge instead of the red `⚠️ 200k+` warning.
- Comprehensive documentation: architecture deep-dive, configuration & segment
  visibility matrix, Development/Contributing guide, FAQ, and this changelog.

### Changed
- `⚠️ 200k+` now only shows red (the ceiling warning) on classic 200k-context
  models; on 1M-context models the cyan `📚 long-ctx` badge is shown instead.
- README examples and tables updated to Opus 4.8 (English + Hungarian).

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

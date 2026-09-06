#!/bin/bash

# Claude Code Statusline - Informative status bar for Claude Code CLI
# https://github.com/kalmarr/claude-code-statusline
#
# Shows: Model, Effort Level, Permission Mode, Cost, Context Window, Duration,
#        API Calls, Fast Mode, Prompt Cache, Rate Limits (with reset countdown),
#        PR, Lines Changed, Git Branch, Project Folder, and more.
#
# Config via env vars:
#   DEBUG=1                       Save raw JSON input to ~/.claude/debug_status.json
#   STATUSLINE_PROFILE=minimal    Only effort + permission mode + base fields
#   STATUSLINE_PROFILE=standard   + output_style, agent, session_name
#   STATUSLINE_PROFILE=full       + rate_limits, worktree, vim, exceeds_200k,
#                                   prompt_cache, pr (default)
#   STATUSLINE_LAYOUT=1           Single line (default)
#   STATUSLINE_LAYOUT=2           Two lines: identity row + metrics row
#
# CLI: statusline.sh --version    Print the deployed script version and exit

# Force C locale for consistent number formatting
export LC_ALL=C

STATUSLINE_VERSION="0.5.0"

# --version: print version and exit — must run before reading stdin,
# so it works from a plain shell without piped input.
if [ "${1:-}" = "--version" ] || [ "${1:-}" = "-v" ]; then
    echo "claude-code-statusline v${STATUSLINE_VERSION}"
    exit 0
fi

# Feature profile (minimal | standard | full)
STATUSLINE_PROFILE="${STATUSLINE_PROFILE:-full}"

# Layout: 1 = single line (default), 2 = two lines
STATUSLINE_LAYOUT="${STATUSLINE_LAYOUT:-1}"

data=$(cat)

# Optional debug: set DEBUG=1 to save raw JSON input
# Usage: DEBUG=1 claude
[ "${DEBUG:-0}" = "1" ] && echo "$data" > ~/.claude/debug_status.json

# === EXTRACT ALL DATA IN ONE JQ CALL ===
eval "$(echo "$data" | jq -r '
  @sh "model=\(.model.display_name // "?")",
  @sh "model_id=\(.model.id // "")",
  @sh "cc_version=\(.version // "")",
  @sh "cost=\(.cost.total_cost_usd // 0)",
  @sh "duration_ms=\(.cost.total_duration_ms // 0)",
  @sh "lines_added=\(.cost.total_lines_added // 0)",
  @sh "lines_removed=\(.cost.total_lines_removed // 0)",
  @sh "ctx_pct=\(.context_window.used_percentage // 0 | floor)",
  @sh "ctx_size=\(.context_window.context_window_size // 200000)",
  @sh "cwd=\(.workspace.current_dir // "")",
  @sh "transcript=\(.transcript_path // "")",
  @sh "output_style=\(.output_style.name // "default")",
  @sh "agent_name=\(.agent.name // "")",
  @sh "session_name=\(.session_name // "")",
  @sh "worktree_name=\(.worktree.name // .workspace.git_worktree // "")",
  @sh "vim_mode=\(.vim.mode // "")",
  @sh "exceeds_200k=\(.exceeds_200k_tokens // false)",
  @sh "rate_5h=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "rate_7d=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "rate_5h_reset=\(.rate_limits.five_hour.resets_at // "")",
  @sh "rate_7d_reset=\(.rate_limits.seven_day.resets_at // "")",
  @sh "fast_mode=\(.fast_mode // false)",
  @sh "effort=\(.effort.level // "")",
  @sh "cache_warm=\(.prompt_cache.warm // "")",
  @sh "cache_hit=\(if .prompt_cache.hit_ratio == null then "" else (.prompt_cache.hit_ratio * 100 | round) end)",
  @sh "cache_req=\(.prompt_cache.requests // 0)",
  @sh "cache_expires=\(.prompt_cache.expires_at // "")",
  @sh "pr_number=\(.pr.number // "")",
  @sh "pr_state=\(.pr.review_state // "")",
  @sh "pr_kind=\(.pr.kind // "")"
')"

# === MODEL TIER COLOR ===
# Fable/Mythos = frontier ($10/$50), Opus = premium ($5/$25),
# Sonnet = balanced ($3/$15), Haiku = fast/cheap ($1/$5).
# Matched case-insensitively on the tier word in model.display_name
# (e.g. "Fable 5", "Opus 5"), with model.id (e.g. "claude-fable-5") as
# fallback — so future versions and renamed display names colorize
# without code changes.
case "${model,,} ${model_id,,}" in
    *fable*|*mythos*) model_colored="\033[1;33m${model}\033[0m" ;;  # bold gold (frontier)
    *opus*)           model_colored="\033[1;35m${model}\033[0m" ;;  # bold magenta (premium)
    *sonnet*)         model_colored="\033[34m${model}\033[0m"   ;;  # blue
    *haiku*)          model_colored="\033[32m${model}\033[0m"   ;;  # green
    *)                model_colored="${model}"                  ;;  # unknown → no color
esac

# === EFFORT LEVEL ===
# effort.level is the live session value (follows /effort). It is absent when
# the model doesn't support the effort parameter, so nothing is shown then.
# On Fable/Mythos thinking is always on and effort is the only tuning knob,
# which makes this the most useful model-level indicator there.
effort_info=""
case "$effort" in
    max)    effort_info="\033[1;31m🧠 max\033[0m"    ;;  # bold red — maximum spend
    xhigh)  effort_info="\033[1;35m🧠 xhigh\033[0m"  ;;  # bold magenta — agentic sweet spot
    high)   effort_info="🧠 high"                    ;;  # plain — default
    medium) effort_info="\033[90m🧠 medium\033[0m"   ;;  # dim
    low)    effort_info="\033[90m🧠 low\033[0m"      ;;  # dim
    "")     effort_info=""                           ;;  # not supported by model → silent
    *)      effort_info="🧠 ${effort}"               ;;  # unknown level → show as-is
esac

# === FAST MODE ===
# Native stdin field. Only Opus 5 / Opus 4.8 support /fast; on every other
# model (Fable, Mythos, Sonnet, Haiku) the badge is simply absent.
speed_info=""
[ "$fast_mode" = "true" ] && speed_info="\033[33m⚡FAST\033[0m"

# === PROJECT FOLDER ===
project_dir=$(basename "$cwd" 2>/dev/null)

# === COST FORMAT ===
cost_formatted=$(printf "\$%.2f" "$cost")

# === CONTEXT WINDOW ===
ctx_pct=${ctx_pct:-0}
ctx_size=${ctx_size:-200000}

# Cap percentage at 100
[ "$ctx_pct" -gt 100 ] && ctx_pct=100

# Colored progress bar (10 chars in minimal profile, 20 chars otherwise)
if [ "$STATUSLINE_PROFILE" = "minimal" ]; then
    bar_len=10
else
    bar_len=20
fi
filled=$((ctx_pct * bar_len / 100))
empty=$((bar_len - filled))

if [ "$ctx_pct" -lt 50 ]; then
    color="\033[32m"  # Green
elif [ "$ctx_pct" -lt 75 ]; then
    color="\033[33m"  # Yellow
else
    color="\033[31m"  # Red
fi

bar="${color}["
for ((i=0; i<filled; i++)); do bar+="█"; done
for ((i=0; i<empty; i++)); do bar+="░"; done
bar+="]\033[0m"

# Format token counts. In minimal profile we drop the "(Xk/Xk)" detail for compactness.
if [ "$STATUSLINE_PROFILE" = "minimal" ]; then
    tokens_info=$(printf "%b %d%%" "$bar" "$ctx_pct")
else
    ctx_used=$((ctx_pct * ctx_size / 100))
    ctx_used_k=$((ctx_used / 1000))
    ctx_size_k=$((ctx_size / 1000))
    tokens_info=$(printf "%b %d%% (%dk/%dk)" "$bar" "$ctx_pct" "$ctx_used_k" "$ctx_size_k")
fi

# === SESSION DURATION ===
duration_ms=${duration_ms:-0}
total_secs=$((duration_ms / 1000))
if [ "$total_secs" -ge 3600 ]; then
    hours=$((total_secs / 3600))
    mins=$(( (total_secs % 3600) / 60 ))
    duration_str="⏱ ${hours}h${mins}m"
elif [ "$total_secs" -ge 60 ]; then
    mins=$((total_secs / 60))
    secs=$((total_secs % 60))
    duration_str="⏱ ${mins}m${secs}s"
else
    duration_str="⏱ ${total_secs}s"
fi

# === TRANSCRIPT DATA (API calls + Permission mode) ===
api_info=""
perm_info=""
if [ -f "$transcript" ]; then
    api_count=$(grep -c '"type":"assistant"' "$transcript" 2>/dev/null)
    api_count=${api_count:-0}
    [ "$api_count" -gt 0 ] && api_info="📡 ${api_count}"

    # Permission mode: stdin JSON doesn't carry it, so read the last change
    # from the transcript. Claude Code logs both "plan" entries and the
    # subsequent "auto" entry after ExitPlanMode, so the tail of the file
    # reflects the true current mode.
    perm_mode=$(tac "$transcript" | grep -m1 -oP '"permissionMode":"\K[^"]*' 2>/dev/null)
    case "$perm_mode" in
        plan)              perm_info="\033[33m📋 PLAN\033[0m" ;;
        auto)              perm_info="\033[34m🚀 AUTO\033[0m" ;;
        acceptEdits)       perm_info="\033[36m✅ EDIT\033[0m" ;;
        bypassPermissions) perm_info="\033[31m⚠️  YOLO\033[0m" ;;
        *)                 perm_info="" ;;  # default / unknown → silent
    esac
fi

# === LINES ADDED/REMOVED ===
lines_added=${lines_added:-0}
lines_removed=${lines_removed:-0}
if [ "$lines_added" -eq 0 ] && [ "$lines_removed" -eq 0 ]; then
    lines_info="±0"
else
    lines_info="\033[32m+${lines_added}\033[0m/\033[31m-${lines_removed}\033[0m"
fi

# === GIT BRANCH ===
git_info=""
if [ -n "$cwd" ] && { [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; }; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        dirty=""
        [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ] && dirty="*"
        git_info="${branch}${dirty}"
    fi
fi

# === PROFILE-GATED EXTRAS ===
style_info=""
agent_info=""
sess_info=""
wt_info=""
vim_info=""
warn_info=""
rate_info=""
ccv_info=""
cache_info=""
pr_info=""

# Rate-limit % coloring. The value is the share *used*, so the thresholds run
# upward: ≥95 (under 5% of the quota left) blinking bold red — the one state
# worth interrupting you for — then red ≥80, yellow ≥60, plain below.
# Blink is SGR 5; terminals that ignore it still show the bold red.
rl_pct() {
    if [ "$1" -ge 95 ]; then printf '\033[5;1;31m%d%%\033[0m' "$1"
    elif [ "$1" -ge 80 ]; then printf '\033[31m%d%%\033[0m' "$1"
    elif [ "$1" -ge 60 ]; then printf '\033[33m%d%%\033[0m' "$1"
    else printf '%d%%' "$1"; fi
}

# Countdown to a unix timestamp, rendered dim: " ↻2d23h" / " ↻4h12m" / " ↻28m".
# ↻ is U+21BB, which DejaVu Sans Mono and the usual terminal fonts cover — U+27F3
# (⟳) looks nicer but is missing from most monospace fonts and renders as tofu.
# Prints nothing when the field is absent (older Claude Code), non-numeric, or
# already in the past — a stale timestamp is worse than no timestamp.
now_ts=$(printf '%(%s)T' -1 2>/dev/null)
[ -z "$now_ts" ] && now_ts=$(date +%s)
until_str() {
    case "$1" in ''|*[!0-9]*) return ;; esac
    local left=$(( $1 - now_ts ))
    [ "$left" -le 0 ] && return
    if   [ "$left" -ge 86400 ]; then printf ' \033[90m↻%dd%dh\033[0m' $((left/86400)) $(((left%86400)/3600))
    elif [ "$left" -ge 3600 ];  then printf ' \033[90m↻%dh%dm\033[0m' $((left/3600))  $(((left%3600)/60))
    elif [ "$left" -ge 60 ];    then printf ' \033[90m↻%dm\033[0m'    $((left/60))
    else                             printf ' \033[90m↻<1m\033[0m'; fi
}

# Prompt-cache hit-ratio coloring (inverse of rl_pct): green ≥80, yellow ≥50, red below
cache_pct() {
    if [ "$1" -ge 80 ]; then printf '\033[32m%d%%\033[0m' "$1"
    elif [ "$1" -ge 50 ]; then printf '\033[33m%d%%\033[0m' "$1"
    else printf '\033[31m%d%%\033[0m' "$1"; fi
}

if [ "$STATUSLINE_PROFILE" = "standard" ] || [ "$STATUSLINE_PROFILE" = "full" ]; then
    [ "$output_style" != "default" ] && [ -n "$output_style" ] && style_info="🎨 ${output_style}"
    [ -n "$agent_name" ]    && agent_info="🤝 ${agent_name}"
    [ -n "$session_name" ]  && sess_info="📛 ${session_name}"
fi

if [ "$STATUSLINE_PROFILE" = "full" ]; then
    [ -n "$worktree_name" ] && wt_info="🌳 ${worktree_name}"
    [ -n "$vim_mode" ]      && vim_info="⌨ ${vim_mode}"
    # On 1M-context models (Fable 5, Opus 5/4.x, Sonnet 5/4.6) crossing 200k is
    # routine, not an alarm — cyan info badge. Haiku 4.5 (200k) hits the real ceiling.
    if [ "$exceeds_200k" = "true" ]; then
        if [ "$ctx_size" -gt 200000 ]; then
            warn_info="\033[36m📚 long-ctx\033[0m"   # cyan — informational (1M models)
        else
            warn_info="\033[31m⚠️  200k+\033[0m"       # red — at the 200k ceiling
        fi
    fi

    # Percentages are *used*, not remaining; the ↻ countdown says when the
    # window rolls over and the used share drops back to zero.
    rl_parts=""
    [ -n "$rate_5h" ] && rl_parts="5h:$(rl_pct "$(printf '%.0f' "$rate_5h")")$(until_str "$rate_5h_reset")"
    [ -n "$rate_7d" ] && rl_parts="${rl_parts:+$rl_parts }7d:$(rl_pct "$(printf '%.0f' "$rate_7d")")$(until_str "$rate_7d_reset")"
    [ -n "$rl_parts" ] && rate_info="📊 ${rl_parts}"

    # Claude Code version — dim gray so it doesn't compete for attention
    [ -n "$cc_version" ] && ccv_info="\033[90m⚙ v${cc_version}\033[0m"

    # Prompt cache: hit ratio of the main conversation. "cold" when the cache
    # has expired (1h TTL) — the next request will re-write the whole prefix.
    if [ -n "$cache_hit" ] && [ "${cache_req:-0}" -gt 0 ]; then
        if [ "$cache_warm" = "true" ]; then
            # cache_hit is already 0–100 (rounded in jq); ↻ is the TTL left
            cache_info="💾 $(cache_pct "$cache_hit")$(until_str "$cache_expires")"
        else
            cache_info="\033[90m💾 cold\033[0m"
        fi
    fi

    # Open PR / MR on the current branch, colored by review state.
    # GitLab merge requests use the "!" prefix, GitHub PRs "#".
    if [ -n "$pr_number" ]; then
        pr_prefix="#"
        [ "$pr_kind" = "mr" ] && pr_prefix="!"
        case "$pr_state" in
            approved)          pr_info="\033[32m🔀 ${pr_prefix}${pr_number}\033[0m" ;;  # green
            changes_requested) pr_info="\033[31m🔀 ${pr_prefix}${pr_number}\033[0m" ;;  # red
            draft)             pr_info="\033[90m🔀 ${pr_prefix}${pr_number}\033[0m" ;;  # dim
            *)                 pr_info="🔀 ${pr_prefix}${pr_number}"                ;;  # pending / unknown
        esac
    fi
fi

# === OUTPUT ===

if [ "$STATUSLINE_PROFILE" = "minimal" ]; then
    # Compact single line: model + effort + permission mode + cost + bar% + duration + git + folder.
    # Drop speed (FAST), API count, line diff, and token detail for space.
    # LAYOUT=2 is ignored here — minimal is always one line by design.
    output="🤖 ${model_colored}"
    [ -n "$effort_info" ] && output="${output} ${effort_info}"
    [ -n "$perm_info" ]   && output="${output} ${perm_info}"
    output="${output} │ ${cost_formatted} │ ${tokens_info} │ ${duration_str}"
    output="${output} │ 🌿 ${git_info} │ 📁 ${project_dir}"
    printf "%b" "$output"
elif [ "$STATUSLINE_LAYOUT" = "2" ]; then
    # Two-line layout — identity on row 1, metrics on row 2.
    row1="🤖 ${model_colored}"
    [ -n "$speed_info" ]  && row1="${row1} ${speed_info}"
    [ -n "$effort_info" ] && row1="${row1} ${effort_info}"
    [ -n "$perm_info" ]   && row1="${row1} ${perm_info}"
    [ -n "$style_info" ]  && row1="${row1} │ ${style_info}"
    [ -n "$agent_info" ]  && row1="${row1} │ ${agent_info}"
    [ -n "$sess_info" ]   && row1="${row1} │ ${sess_info}"
    row1="${row1} │ 🌿 ${git_info}"
    [ -n "$pr_info" ]     && row1="${row1} ${pr_info}"
    row1="${row1} │ 📁 ${project_dir}"
    [ -n "$wt_info" ]     && row1="${row1} │ ${wt_info}"
    [ -n "$vim_info" ]    && row1="${row1} │ ${vim_info}"
    [ -n "$ccv_info" ]    && row1="${row1} │ ${ccv_info}"

    row2="${cost_formatted} │ ${tokens_info} │ ${duration_str}"
    [ -n "$api_info" ]    && row2="${row2} │ ${api_info}"
    [ -n "$cache_info" ]  && row2="${row2} │ ${cache_info}"
    [ -n "$rate_info" ]   && row2="${row2} │ ${rate_info}"
    [ -n "$warn_info" ]  && row2="${row2} │ ${warn_info}"
    row2="${row2} │ ${lines_info}"

    printf "%b\n%b" "$row1" "$row2"
else
    # Single-line layout (default, backward-compatible)
    output="🤖 ${model_colored}"
    [ -n "$speed_info" ]  && output="${output} ${speed_info}"
    [ -n "$effort_info" ] && output="${output} ${effort_info}"
    [ -n "$perm_info" ]   && output="${output} ${perm_info}"
    [ -n "$style_info" ]  && output="${output} │ ${style_info}"
    [ -n "$agent_info" ]  && output="${output} │ ${agent_info}"
    [ -n "$sess_info" ]   && output="${output} │ ${sess_info}"
    [ -n "$warn_info" ]   && output="${output} │ ${warn_info}"

    output="${output} │ ${cost_formatted} │ ${tokens_info} │ ${duration_str}"

    [ -n "$api_info" ]    && output="${output} │ ${api_info}"
    [ -n "$cache_info" ]  && output="${output} │ ${cache_info}"
    [ -n "$rate_info" ]   && output="${output} │ ${rate_info}"

    output="${output} │ ${lines_info} │ 🌿 ${git_info}"
    [ -n "$pr_info" ]     && output="${output} ${pr_info}"
    output="${output} │ 📁 ${project_dir}"

    [ -n "$wt_info" ]  && output="${output} │ ${wt_info}"
    [ -n "$vim_info" ] && output="${output} │ ${vim_info}"
    [ -n "$ccv_info" ] && output="${output} │ ${ccv_info}"

    printf "%b" "$output"
fi

#!/bin/bash

# Claude Code Statusline - Informative status bar for Claude Code CLI
# https://github.com/kalmarr/claude-code-statusline
#
# Shows: Model, Permission Mode, Cost, Context Window, Duration, API Calls,
#        Fast Mode, Lines Changed, Git Branch, Project Folder, and more.
#
# Config via env vars:
#   DEBUG=1                       Save raw JSON input to ~/.claude/debug_status.json
#   STATUSLINE_PROFILE=minimal    Only permission mode + base fields
#   STATUSLINE_PROFILE=standard   + output_style, agent, session_name
#   STATUSLINE_PROFILE=full       + rate_limits, worktree, vim, exceeds_200k (default)
#   STATUSLINE_LAYOUT=1           Single line (default)
#   STATUSLINE_LAYOUT=2           Two lines: identity row + metrics row

# Force C locale for consistent number formatting
export LC_ALL=C

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
  @sh "rate_7d=\(.rate_limits.seven_day.used_percentage // "")"
')"

# === MODEL TIER COLOR ===
# Fable/Mythos = frontier ($10/$50), Opus = premium ($5/$25),
# Sonnet = balanced ($3/$15), Haiku = fast/cheap ($1/$5).
# model is model.display_name (e.g. "Fable 5", "Opus 5") — matched
# case-insensitively on the tier word, so future versions colorize
# without code changes.
case "${model,,}" in
    *fable*|*mythos*) model_colored="\033[1;33m${model}\033[0m" ;;  # bold gold (frontier)
    *opus*)           model_colored="\033[1;35m${model}\033[0m" ;;  # bold magenta (premium)
    *sonnet*)         model_colored="\033[34m${model}\033[0m"   ;;  # blue
    *haiku*)          model_colored="\033[32m${model}\033[0m"   ;;  # green
    *)                model_colored="${model}"                  ;;  # unknown → no color
esac

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

# === TRANSCRIPT DATA (API calls + Fast mode + Permission mode) ===
api_info=""
speed_info=""
perm_info=""
if [ -f "$transcript" ]; then
    api_count=$(grep -c '"type":"assistant"' "$transcript" 2>/dev/null)
    api_count=${api_count:-0}
    [ "$api_count" -gt 0 ] && api_info="📡 ${api_count}"

    # Fast mode: check /fast toggle event (primary), speed field (fallback)
    fast_toggle=$(tac "$transcript" | grep -m1 -oP 'Fast mode \K(ON|OFF)' 2>/dev/null)
    if [ "$fast_toggle" = "ON" ]; then
        speed_info="\033[33m⚡FAST\033[0m"
    elif [ "$fast_toggle" = "OFF" ]; then
        speed_info="\033[90mSTD\033[0m"
    else
        # No toggle found → fallback to API speed field
        speed_mode=$(tac "$transcript" | grep -m1 -oP '"speed"\s*:\s*"\K[^"]*' 2>/dev/null)
        if [ "$speed_mode" = "fast" ]; then
            speed_info="\033[33m⚡FAST\033[0m"
        else
            speed_info="\033[90mSTD\033[0m"
        fi
    fi

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

    rl_parts=""
    [ -n "$rate_5h" ] && rl_parts="5h:$(printf '%.0f' "$rate_5h")%"
    [ -n "$rate_7d" ] && rl_parts="${rl_parts:+$rl_parts }7d:$(printf '%.0f' "$rate_7d")%"
    [ -n "$rl_parts" ] && rate_info="📊 ${rl_parts}"
fi

# === OUTPUT ===

if [ "$STATUSLINE_PROFILE" = "minimal" ]; then
    # Compact single line: model + permission mode + cost + bar% + duration + git + folder.
    # Drop speed (FAST/STD), API count, line diff, and token detail for space.
    # LAYOUT=2 is ignored here — minimal is always one line by design.
    output="🤖 ${model_colored}"
    [ -n "$perm_info" ] && output="${output} ${perm_info}"
    output="${output} │ ${cost_formatted} │ ${tokens_info} │ ${duration_str}"
    output="${output} │ 🌿 ${git_info} │ 📁 ${project_dir}"
    printf "%b" "$output"
elif [ "$STATUSLINE_LAYOUT" = "2" ]; then
    # Two-line layout — identity on row 1, metrics on row 2.
    row1="🤖 ${model_colored}"
    [ -n "$speed_info" ] && row1="${row1} ${speed_info}"
    [ -n "$perm_info" ]  && row1="${row1} ${perm_info}"
    [ -n "$style_info" ] && row1="${row1} │ ${style_info}"
    [ -n "$agent_info" ] && row1="${row1} │ ${agent_info}"
    [ -n "$sess_info" ]  && row1="${row1} │ ${sess_info}"
    row1="${row1} │ 🌿 ${git_info} │ 📁 ${project_dir}"
    [ -n "$wt_info" ]    && row1="${row1} │ ${wt_info}"
    [ -n "$vim_info" ]   && row1="${row1} │ ${vim_info}"

    row2="${cost_formatted} │ ${tokens_info} │ ${duration_str}"
    [ -n "$api_info" ]   && row2="${row2} │ ${api_info}"
    [ -n "$rate_info" ]  && row2="${row2} │ ${rate_info}"
    [ -n "$warn_info" ]  && row2="${row2} │ ${warn_info}"
    row2="${row2} │ ${lines_info}"

    printf "%b\n%b" "$row1" "$row2"
else
    # Single-line layout (default, backward-compatible)
    output="🤖 ${model_colored}"
    [ -n "$speed_info" ] && output="${output} ${speed_info}"
    [ -n "$perm_info" ]  && output="${output} ${perm_info}"
    [ -n "$style_info" ] && output="${output} │ ${style_info}"
    [ -n "$agent_info" ] && output="${output} │ ${agent_info}"
    [ -n "$sess_info" ]  && output="${output} │ ${sess_info}"
    [ -n "$warn_info" ]  && output="${output} │ ${warn_info}"

    output="${output} │ ${cost_formatted} │ ${tokens_info} │ ${duration_str}"

    [ -n "$api_info" ]  && output="${output} │ ${api_info}"
    [ -n "$rate_info" ] && output="${output} │ ${rate_info}"

    output="${output} │ ${lines_info} │ 🌿 ${git_info} │ 📁 ${project_dir}"

    [ -n "$wt_info" ]  && output="${output} │ ${wt_info}"
    [ -n "$vim_info" ] && output="${output} │ ${vim_info}"

    printf "%b" "$output"
fi

source /usr/share/cachyos-fish-config/cachyos-config.fish

# ── Git Functions ────────────────────────

function git_branch
    git branch --show-current 2>/dev/null
end

function git_status
    git status --porcelain 2>/dev/null
end

function git_ahead_behind
    git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null
end

# ── Directory Shortening ────────────────────────
function prompt_path
    if test (count $argv) -gt 0
        set path $argv[1]
    else
        set path (prompt_pwd)
    end

    # Get the actual terminal width.
    set terminal_width (tput cols)

    # Leave room for username, hostname, Git information,
    # duration, and prompt decorations.
    set reserved_width 50
    set max_width (math "$terminal_width - $reserved_width")

    if test $max_width -lt 20
        set max_width 20
    end

    # Path already fits.
    if test (string length -- "$path") -le $max_width
        echo "$path"
        return
    end

    set parts (string split / -- "$path")
    set count (count $parts)

    # Always preserve the home marker and current directory.
    set last $parts[$count]
    set result "~/…/"$last

    # Add parent directories from the end while they fit.
    for i in (seq (math "$count - 1") -1 2)
        set candidate "~/…/"$parts[$i]"/"$last

        if test (string length -- "$candidate") -le $max_width
            set last $parts[$i]"/"$last
        else
            break
        end
    end

    echo "~/…/"$last
end

# ── Command Time Elapsed ────────────────────────
function fish_preexec --on-event fish_preexec
    set -g command_start_time (date +%s%3N)
end

function fish_postexec --on-event fish_postexec
    set -l command_end_time (date +%s%3N)

    if test -n "$command_start_time"
        set -g command_duration (math $command_end_time - $command_start_time)
    else
        set -g command_duration 0
    end
end

function fish_prompt
    set last_status $status
    set is_ssh 0

    if test -n "$SSH_CONNECTION"
        set is_ssh 1
    end

    # ── First line: identity and location ────────────────────────
    set_color brblack
    echo -n "╭─ "

    set_color normal
    echo -n (whoami)

    set_color brblue
    echo -n "@"
    echo -n (hostname -s)

    if test $is_ssh -eq 1
        set_color yellow
        echo -n "  󰢹 SSH"
    end

    set_color normal
    echo -n "  "

    set_color blue
    echo -n (prompt_path)

    # ── Second line: Git information ─────────────────────────────
    set branch (git_branch)

    if test -n "$branch"
        echo
        set_color brblack
        echo -n "│  "

        set_color yellow
        echo -n "󰊢 $branch"

        set git_info (git_status)

        if test -z "$git_info"
            set_color green
            echo -n " ✓"
        else
            set staged 0
            set modified 0
            set untracked 0

            for line in $git_info
                set index_status (string sub -s 1 -l 1 -- $line)
                set worktree_status (string sub -s 2 -l 1 -- $line)

                if test "$index_status" = "?"
                    set untracked (math $untracked + 1)
                else
                    if test "$index_status" != " "
                        set staged (math $staged + 1)
                    end

                    if test "$worktree_status" != " "
                        set modified (math $modified + 1)
                    end
                end
            end

            if test $staged -gt 0
                set_color green
                echo -n " +$staged"
            end

            if test $modified -gt 0
                set_color red
                echo -n " ~$modified"
            end

            if test $untracked -gt 0
                set_color magenta
                echo -n " ?$untracked"
            end
        end

        # ── Ahead / behind ───────────────────────────────────────
        set remote_counts (git_ahead_behind | string split \t)

        if test (count $remote_counts) -ge 2
            set ahead $remote_counts[1]
            set behind $remote_counts[2]

            if test "$ahead" -gt 0
                set_color cyan
                echo -n " ↑$ahead"
            end

            if test "$behind" -gt 0
                set_color blue
                echo -n " ↓$behind"
            end
        end
    end

    # ── Python virtual environment ──────────────────────────────
    if test -n "$VIRTUAL_ENV"
        set_color brblack
        echo -n "  "

        set_color cyan
        echo -n "󰌠 "

        set_color brblack
        echo -n (basename "$VIRTUAL_ENV")
    end

    # ── Third line: command input ────────────────────────────────
    echo
    set_color brblack
    echo -n "╰─"

    if test $last_status -ne 0
        set_color red
        echo -n "✗ $last_status"
        set_color normal
        echo -n " "
    end
if test -n "$command_duration"; and test "$command_duration" -ge 4
    set duration_ms $command_duration

    if test $duration_ms -lt 1000
        set_color brblack
        echo -n "  "$duration_ms"ms"

    else if test $duration_ms -lt 60000
        set duration_seconds (math "floor($duration_ms / 1000)")
        set milliseconds (math "$duration_ms % 1000")

        set_color brblack
        echo -n "  "$duration_seconds"."(string pad -w 3 -c 0 -- $milliseconds)"s"

    else if test $duration_ms -lt 3600000
        set duration_minutes (math "floor($duration_ms / 60000)")
        set remaining_seconds (math "floor(($duration_ms % 60000) / 1000)")

        set_color brblack
        echo -n "  "$duration_minutes"m"

        if test $remaining_seconds -gt 0
            echo -n " "$remaining_seconds"s"
        end

    else
        set duration_hours (math "floor($duration_ms / 3600000)")
        set duration_minutes (math "floor(($duration_ms % 3600000) / 60000)")
        set remaining_seconds (math "floor(($duration_ms % 60000) / 1000)")

        set_color brblack
        echo -n "  "$duration_hours"h"

        if test $duration_minutes -gt 0
            echo -n " "$duration_minutes"m"
        end

        if test $remaining_seconds -gt 0
            echo -n " "$remaining_seconds"s"
        end
    end

    set_color cyan
    echo -n "  ❯ "
else
    set_color cyan
    echo -n "❯ "
end
end

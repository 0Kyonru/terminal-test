source /usr/share/cachyos-fish-config/cachyos-config.fish

function git_branch
    git branch --show-current 2>/dev/null
end

function git_status
    git status --porcelain 2>/dev/null
end

function git_ahead_behind
    git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null
end

function fish_prompt
    set last_status $status

    set_color cyan
    echo -n "╭─ "

    set_color normal
    echo -n (whoami)

    set_color brblue
    echo -n "@"
    echo -n (hostname -s)

    set_color normal
    echo -n "  "

    set_color blue
    echo -n (prompt_pwd)

    set branch (git_branch)

    if test -n "$branch"
        set_color yellow
        echo -n "  󰊢 $branch"

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

    set_color normal
    echo

    set_color cyan
    echo -n "╰─"

    if test $last_status -ne 0
        set_color red
        echo -n "✗ $last_status"
        set_color normal
        echo -n " "
    end

    set_color normal
    echo -n "❯ "
end

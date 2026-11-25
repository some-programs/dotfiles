# -*- mode: bash -*-

__dotfiles_repos()
{
    local rdir="${1:-${DOTFILES_REPOS:-$HOME/src/dotfiles}}"
    if [[ -d "$rdir" ]]; then
        local d name
        for d in "$rdir"/*/; do
            [[ -d "$d" ]] || continue
            name="${d%/}"
            name="${name##*/}"
            [[ "$name" == .* ]] && continue
            echo "$name"
        done
        return 0
    fi
    if type dotfiles &>/dev/null; then
        if [[ -n "$1" ]]; then
            dotfiles -repos "$1" repos 2>/dev/null | awk 'NR>1 {print $1}'
        else
            dotfiles repos 2>/dev/null | awk 'NR>1 {print $1}'
        fi
    fi
}

__dotfiles_theme_variants()
{
    local rdir="${1:-${DOTFILES_REPOS:-$HOME/src/dotfiles}}"
    local themes=""
    if [[ -d "$rdir/base/config-base/themes" ]]; then
        local tdir tname vfile vname
        for tdir in "$rdir/base/config-base/themes"/*; do
            if [[ -d "$tdir/variants" ]]; then
                tname="${tdir##*/}"
                for vfile in "$tdir/variants"/*.toml; do
                    if [[ -f "$vfile" ]]; then
                        vname="${vfile##*/}"
                        vname="${vname%.toml}"
                        themes="${themes:+$themes }$tname:$vname"
                    fi
                done
            fi
        done
    elif type dotfiles &>/dev/null; then
        if [[ -n "$1" ]]; then
            themes="$(dotfiles -repos "$1" theme list -names 2>/dev/null)"
        else
            themes="$(dotfiles theme list -names 2>/dev/null)"
        fi
    fi
    local seen=" "
    local short_variants=""
    local t
    for t in $themes; do
        local v=":${t#*:}"
        if [[ "$seen" != *" $v "* ]]; then
            seen="$seen$v "
            short_variants="$short_variants $v"
        fi
    done
    echo "dark light $themes$short_variants"
}

__dotfiles_ltrim_colon()
{
    if type __ltrim_colon_completions &>/dev/null; then
        __ltrim_colon_completions "$1"
    elif [[ "$1" == *:* && "$COMP_WORDBREAKS" == *:* ]]; then
        local colon_prefix="${1%"${1##*:}"}"
        local i
        for i in "${!COMPREPLY[@]}"; do
            COMPREPLY[i]="${COMPREPLY[i]#"$colon_prefix"}"
        done
    fi
}

__dotfiles_init_completion()
{
    if type _get_comp_words_by_ref &>/dev/null; then
        _get_comp_words_by_ref -n : cur prev words cword
    else
        cword=$COMP_CWORD
        words=("${COMP_WORDS[@]}")
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        if [[ -n "${COMP_LINE:-}" ]]; then
            local line="${COMP_LINE:0:COMP_POINT}"
            cur="${line##* }"
            local line_before="${line%"$cur"}"
            line_before="${line_before%"${line_before##*[! ]}"}"
            prev="${line_before##* }"
        elif [[ "$COMP_WORDBREAKS" == *:* ]]; then
            if [[ "$prev" == ":" && $cword -ge 2 ]]; then
                local prefix=""
                if [[ $cword -ge 3 && "${COMP_WORDS[cword-2]}" != [[:space:]]* ]]; then
                    prefix="${COMP_WORDS[cword-2]}"
                fi
                cur="${prefix}:${cur}"
                prev="${COMP_WORDS[cword-3]}"
            fi
        fi
    fi
}

# __dotfiles_pathenv completes the arguments of dotfiles pathenv, or of the
# pathenv function of bash/init, which start at words[$1].
__dotfiles_pathenv()
{
    local offset="${1:-1}"
    local i sub=""
    for (( i = offset; i < cword; i++ )); do
        case "${words[i]}" in
            -C|--C|-shell|--shell)
                ((i++))
                ;;
            --)
                if [[ "$sub" == exec ]]; then
                    if type _command_offset &>/dev/null; then
                        _command_offset $((i + 1))
                    else
                        COMPREPLY=( $(compgen -c -- "$cur") )
                    fi
                    return 0
                fi
                ;;
            -*)
                ;;
            *)
                [[ -z "$sub" ]] && sub="${words[i]}"
                ;;
        esac
    done

    case "$prev" in
        -C|--C)
            if type _filedir &>/dev/null; then
                _filedir -d
            else
                compopt -o filenames 2>/dev/null
                COMPREPLY=( $(compgen -d -- "$cur") )
            fi
            return 0
            ;;
        -shell|--shell)
            COMPREPLY=( $(compgen -W "bash" -- "$cur") )
            return 0
            ;;
    esac

    case "$sub" in
        "")
            if [[ "$cur" == -* ]]; then
                local opts="-C --C -n --n -q --q -shell --shell -h --help"
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            else
                local subcmds="reload exec status help"
                COMPREPLY=( $(compgen -W "${subcmds}" -- "${cur}") )
            fi
            ;;
        exec)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "-C --C --" -- "${cur}") )
            else
                if type _command_offset &>/dev/null; then
                    _command_offset $((offset + 1))
                else
                    COMPREPLY=( $(compgen -c -- "$cur") )
                fi
            fi
            ;;
        status)
            COMPREPLY=( $(compgen -W "-C --C -json --json" -- "${cur}") )
            ;;
        *)
            return 0
            ;;
    esac
}

_dotfiles()
{
    COMPREPLY=()
    local cur prev words cword
    __dotfiles_init_completion

    local cmd="" cmd_index=0 subcmd="" i=1 skip_next=0 repos_dir_arg=""

    while [[ $i -lt $cword ]]; do
        local w="${words[i]}"
        if [[ $skip_next -eq 1 ]]; then
            skip_next=0
            ((i++))
            continue
        fi

        case "$w" in
            -dst|--dst|-format|--format)
                skip_next=1
                ;;
            -n|--n)
                [[ "$cmd" == log ]] && skip_next=1
                ;;
            -repos|--repos)
                repos_dir_arg="${words[i+1]}"
                skip_next=1
                ;;
            -repository|--repository)
                skip_next=1
                ;;
            -theme|--theme)
                skip_next=1
                ;;
            -*)
                ;;
            *)
                if [[ -z "$cmd" ]]; then
                    cmd="$w"
                    cmd_index=$i
                    [[ "$cmd" == pathenv ]] && break
                elif [[ -z "$subcmd" ]]; then
                    subcmd="$w"
                fi
                ;;
        esac
        ((i++))
    done

    case "$prev" in
        -dst|--dst|-repos|--repos)
            if type _filedir &>/dev/null; then
                _filedir -d
            else
                compopt -o filenames 2>/dev/null
                COMPREPLY=( $(compgen -d -- "$cur") )
            fi
            return 0
            ;;
        -repository|--repository)
            local repos
            repos="$(__dotfiles_repos "$repos_dir_arg")"
            if [[ "$cur" == *,* ]]; then
                local prefix="${cur%,*}"
                local word="${cur##*,}"
                COMPREPLY=( $(compgen -W "$repos" -P "${prefix}," -- "$word") )
            else
                COMPREPLY=( $(compgen -W "$repos" -- "$cur") )
            fi
            return 0
            ;;
        -theme|--theme)
            local variants
            variants="$(__dotfiles_theme_variants "$repos_dir_arg")"
            COMPREPLY=( $(compgen -W "$variants" -- "$cur") )
            __dotfiles_ltrim_colon "$cur"
            return 0
            ;;
        -format|--format)
            COMPREPLY=( $(compgen -W "hex raw 0x rgb" -- "$cur") )
            return 0
            ;;
        -n|--n)
            [[ "$cmd" == log ]] && return 0
            ;;
    esac

    if [[ -z "$cmd" ]]; then
        if [[ "$cur" == -* ]]; then
            local global_opts="-copy --copy -dry-run --dry-run -dst --dst -f -overwrite-skipped --overwrite-skipped -repos --repos -repository --repository -theme --theme -v -h --help"
            COMPREPLY=( $(compgen -W "${global_opts}" -- "${cur}") )
        else
            local commands="install i plan which push publish pull status s diff d magit log repos theme pathenv lint doc self-update version completion"
            COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
        fi
        return 0
    fi

    case "$cmd" in
        pathenv)
            __dotfiles_pathenv $((cmd_index + 1))
            return 0
            ;;
        pull)
            local pull_opts="-no-install --no-install -h --help"
            COMPREPLY=( $(compgen -W "${pull_opts}" -- "${cur}") )
            return 0
            ;;
        log)
            local log_opts="-short --short -patch --patch -textconv --textconv -n --n -h --help"
            COMPREPLY=( $(compgen -W "${log_opts}" -- "${cur}") )
            return 0
            ;;
        repos)
            case "$subcmd" in
                "")
                    local subcmds="status s fix clone"
                    COMPREPLY=( $(compgen -W "${subcmds}" -- "${cur}") )
                    return 0
                    ;;
                clone)
                    local repos
                    repos="$(__dotfiles_repos "$repos_dir_arg")"
                    COMPREPLY=( $(compgen -W "${repos}" -- "${cur}") )
                    return 0
                    ;;
                status|s|fix)
                    return 0
                    ;;
            esac
            ;;
        theme)
            case "$subcmd" in
                "")
                    local subcmds="show list preview lint color set toggle apply background-image"
                    COMPREPLY=( $(compgen -W "${subcmds}" -- "${cur}") )
                    return 0
                    ;;
                list)
                    local list_opts="-names --names -json --json -h --help"
                    COMPREPLY=( $(compgen -W "${list_opts}" -- "${cur}") )
                    return 0
                    ;;
                preview)
                    if [[ "$cur" == -* ]]; then
                        local preview_opts="-all --all -all.dark --all.dark -all.light --all.light -hide --hide -show --show -theme --theme -h --help"
                        COMPREPLY=( $(compgen -W "${preview_opts}" -- "${cur}") )
                    else
                        local variants
                        variants="$(__dotfiles_theme_variants "$repos_dir_arg")"
                        COMPREPLY=( $(compgen -W "${variants}" -- "${cur}") )
                        __dotfiles_ltrim_colon "$cur"
                    fi
                    return 0
                    ;;
                lint)
                    if [[ "$cur" == -* ]]; then
                        local lint_opts="-all --all -theme --theme -ignore --ignore -suppress --suppress -h --help"
                        COMPREPLY=( $(compgen -W "${lint_opts}" -- "${cur}") )
                    else
                        local variants
                        variants="$(__dotfiles_theme_variants "$repos_dir_arg")"
                        COMPREPLY=( $(compgen -W "${variants}" -- "${cur}") )
                        __dotfiles_ltrim_colon "$cur"
                    fi
                    return 0
                    ;;
                color)
                    if [[ "$cur" == -* ]]; then
                        local color_opts="-0x -format --format -raw --raw -rgb --rgb -theme --theme -h --help"
                        COMPREPLY=( $(compgen -W "${color_opts}" -- "${cur}") )
                    else
                        local colors="bg_0 bg_1 bg_2 dim_0 dim_1 fg_0 fg_1 yellow orange red magenta violet blue cyan green br_yellow br_orange br_red br_magenta br_violet br_blue br_cyan br_green br_black br_white"
                        COMPREPLY=( $(compgen -W "${colors}" -- "${cur}") )
                    fi
                    return 0
                    ;;
                set)
                    local variants
                    variants="$(__dotfiles_theme_variants "$repos_dir_arg")"
                    COMPREPLY=( $(compgen -W "${variants}" -- "${cur}") )
                    __dotfiles_ltrim_colon "$cur"
                    return 0
                    ;;
                background-image)
                    local bg_opts="-expr --expr -e -all --all -h --help"
                    COMPREPLY=( $(compgen -W "${bg_opts}" -- "${cur}") )
                    return 0
                    ;;
                show|toggle|apply)
                    return 0
                    ;;
            esac
            ;;
        doc)
            local topics="toc theme pathenv repositories vars git template starlark script appendices options"
            COMPREPLY=( $(compgen -W "${topics}" -- "${cur}") )
            return 0
            ;;
        plan)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "-diff --diff -h --help" -- "${cur}") )
            else
                local repos
                repos="$(__dotfiles_repos "$repos_dir_arg")"
                compopt -o filenames 2>/dev/null
                COMPREPLY=( $(compgen -W "${repos}" -- "${cur}") $(compgen -f -- "${cur}") )
            fi
            return 0
            ;;
        install|i)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "-h --help" -- "${cur}") )
            else
                local repos
                repos="$(__dotfiles_repos "$repos_dir_arg")"
                compopt -o filenames 2>/dev/null
                COMPREPLY=( $(compgen -W "${repos}" -- "${cur}") $(compgen -f -- "${cur}") )
            fi
            return 0
            ;;
        which)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "-v -h --help" -- "${cur}") )
            else
                compopt -o filenames 2>/dev/null
                COMPREPLY=( $(compgen -f -- "${cur}") )
            fi
            return 0
            ;;
        lint)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "-h --help" -- "${cur}") )
            else
                local repos
                repos="$(__dotfiles_repos "$repos_dir_arg")"
                COMPREPLY=( $(compgen -W "${repos}" -- "${cur}") )
            fi
            return 0
            ;;
        completion)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "-h --help" -- "${cur}") )
            else
                COMPREPLY=( $(compgen -W "bash" -- "${cur}") )
            fi
            return 0
            ;;
        self-update)
            COMPREPLY=( $(compgen -W "-h --help" -- "${cur}") )
            return 0
            ;;
        version)
            COMPREPLY=( $(compgen -W "-all --all -h --help" -- "${cur}") )
            return 0
            ;;
        push|publish|status|s|diff|d|magit)
            return 0
            ;;
    esac
}

complete -F _dotfiles dotfiles

_pathenv()
{
    COMPREPLY=()
    local cur prev words cword
    __dotfiles_init_completion
    __dotfiles_pathenv 1
}

complete -F _pathenv pathenv

# Material Shell Theme for Oh My Zsh
# Based on the original materialshell theme with enhancements

red=$fg[red]
green=$fg[green]
yellow=$fg[yellow]
blue=$fg[blue]
magenta=$fg[magenta]
cyan=$fg[cyan]
white=$fg[white]
grey=$fg[grey]

# Función mejorada para detectar y mostrar el entorno virtual de Python
function virtualenv_info {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        # Extraemos solo el nombre del entorno virtual
        local env_name=$(basename "$VIRTUAL_ENV")
        echo "%{$red%}🔥%{$reset_color%}%{$cyan%}$env_name%{$reset_color%} "
    fi
}

# Función para mostrar la versión de Node.js cuando está en un proyecto Node
function node_version_info {
    if [[ -f package.json || -d node_modules ]]; then
        local node_version=$(node -v 2>/dev/null)
        if [[ -n "$node_version" ]]; then
            echo "%{$green%}⬢ $node_version%{$reset_color%} "
        fi
    fi
}

# Función para mostrar el estado de la batería (solo en sistemas compatibles)
function battery_status {
    if (( $+commands[acpi] )); then
        local battery_info=$(acpi -b 2>/dev/null)
        if [[ -n "$battery_info" ]]; then
            local percentage=$(echo $battery_info | grep -o '[0-9]\+%')
            local charging=$(echo $battery_info | grep -q "Charging" && echo "⚡" || echo "")
            echo "%{$yellow%}$charging$percentage%{$reset_color%} "
        fi
    fi
}

# Función para mostrar el tiempo de ejecución de comandos largos
function cmd_exec_time {
    if [[ -n "$ZSH_COMMAND_TIME" ]]; then
        if [[ $ZSH_COMMAND_TIME -ge 5 ]]; then
            local minutes=$((ZSH_COMMAND_TIME / 60))
            local seconds=$((ZSH_COMMAND_TIME % 60))
            if [[ $minutes -gt 0 ]]; then
                echo "%{$yellow%}${minutes}m${seconds}s%{$reset_color%} "
            else
                echo "%{$yellow%}${seconds}s%{$reset_color%} "
            fi
        fi
    fi
}

# Función para detectar contexto de Docker/Kubernetes
function docker_context {
    if (( $+commands[docker] )); then
        if [[ -f Dockerfile || -f docker-compose.yml ]]; then
            echo "%{$blue%}🐳%{$reset_color%} "
        fi
    fi
    
    if (( $+commands[kubectl] )); then
        local k8s_context=$(kubectl config current-context 2>/dev/null)
        if [[ -n "$k8s_context" ]]; then
            echo "%{$blue%}☸️ $k8s_context%{$reset_color%} "
        fi
    fi
}

# Modificación del PROMPT para incluir todas las nuevas funcionalidades
PROMPT='$(virtualenv_info)$(node_version_info)$(docker_context)$(_user_host)${_current_dir}$(git_prompt_info)
%{$white%}>%{$reset_color%} '
PROMPT2='%{$grey%}◀%{$reset_color%} '
RPROMPT='$(_vi_status)%{$(echotc UP 1)%}$(git_remote_status) $(git_prompt_short_sha) ${_return_status} $(battery_status)$(cmd_exec_time)%{$white%}%T%{$(echotc DO 1)%}%{$reset_color%}'

# Cambiado para mostrar la ruta relativa al $HOME en lugar de solo el directorio actual
local _current_dir="%{$green%}%~%{$reset_color%} "
local _return_status="%{$red%}%(?..×)%{$reset_color%}"

function _user_host() {
  echo "%{$red%}%n%{$reset_color%}%{$white%} at %{$yellow%}%m%{$reset_color%} %{$white%}in "
}

function _vi_status() {
  if {echo $fpath | grep -q "plugins/vi-mode"}; then
    echo "$(vi_mode_prompt_info)"
  fi
}

if [[ $USER == "root" ]]; then
  CARETCOLOR="$red"
else
  CARETCOLOR="$white"
fi

# Corregido el error de sintaxis en MODE_INDICATOR
MODE_INDICATOR="%{$bold$yellow%}❮%{$reset_color%}%{$yellow%}❮❮%{$reset_color%}"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$white%}on %{$blue%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "

ZSH_THEME_GIT_PROMPT_DIRTY=" %{$red%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$green%}✔%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE="%{$red%}⬇%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE="%{$green%}⬆%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE="%{$yellow%}⬌%{$reset_color%}"

# Format for git_prompt_long_sha() and git_prompt_short_sha()
ZSH_THEME_GIT_PROMPT_SHA_BEFORE="%{$reset_color%}[%{$yellow%}"
ZSH_THEME_GIT_PROMPT_SHA_AFTER="%{$reset_color%}]"

# Añadido soporte para mostrar el tiempo de ejecución de comandos
# Requiere el plugin zsh-command-time o similar
ZSH_COMMAND_TIME_MIN_SECONDS=5
ZSH_COMMAND_TIME_MSG="Took %s"

# LS colors, made with http://geoff.greer.fm/lscolors/
export LSCOLORS="exfxcxdxbxegedabagacad"
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=0;42:ow=0;43:'
export GREP_COLOR='1;33'

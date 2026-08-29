# Homebrew — must come before oh-my-posh (and any other brew-installed tool)
if [[ "$(uname)" == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

# Oh My Posh
# https://ohmyposh.dev/docs/installation/prompt
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:$HOME/Documents/external_packages/llama.cpp/build/bin
# 머신별 테마 분기 — 맥은 star, 리눅스 서버는 catppuccin_mocha(호스트명 상시 표시)
if [[ "$(uname)" == "Darwin" ]]; then
  _omp_config="$HOME/dotfiles/zsh/star.omp.json"
else
  _omp_config="$HOME/dotfiles/zsh/catppuccin_mocha.omp.json"
fi
eval "$(oh-my-posh init zsh --config "$_omp_config")"
# Avoid baking the absolute binary path into precmd hooks — re-resolve via PATH each call
# so brew/dnf upgrades don't break live sessions when the binary path changes.
_omp_executable=oh-my-posh

# Zinit
# https://github.com/zdharma-continuum/zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
# fzf plugin
zinit light Aloxaf/fzf-tab

# Load completions
fpath+=~/.zfunc
autoload -Uz compinit && compinit

# Keybindings
# https://quickref.me/emacs.html
bindkey -e

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# Completion styling
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# ignore Capitalized character
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always --all --long --git --no-filesize --icons=always --no-time --no-user --no-permissions $realpath'
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# fzf-catppuccin
# https://github.com/catppuccin/fzf
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--multi"
# Aliases
alias l='eza --color=always --all --long --git --no-filesize --icons=always --no-time --no-user'
alias lt='eza --tree --level=2 --color=always --all --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'
# llama.cpp local LLM server (GEM12 only — script absent elsewhere)
[[ -x "$HOME/dotfiles/commands/llamacpp/run-qcnext-server.sh" ]] && alias qcnext-server="$HOME/dotfiles/commands/llamacpp/run-qcnext-server.sh"
# Muse Glimmer 30B — 백그라운드로 띄우고(glimmer-up) 내리고(glimmer-down) 상태를 본다(glimmer-status).
# 로그는 /tmp 에 남기고, 모델 적재에 20 초 남짓 걸리므로 up 은 health 가 뜰 때까지 기다린다.
if [[ -x "$HOME/dotfiles/commands/llamacpp/run-muse-glimmer-server.sh" ]]; then
  function glimmer-up {
    if curl -sf --max-time 2 http://127.0.0.1:8081/health >/dev/null 2>&1; then
      echo "이미 실행 중 (http://127.0.0.1:8081)"
      return 0
    fi
    local log=/tmp/muse-glimmer.log
    setsid nohup "$HOME/dotfiles/commands/llamacpp/run-muse-glimmer-server.sh" >"$log" 2>&1 </dev/null &
    printf '적재 중'
    for _ in {1..60}; do
      curl -sf --max-time 2 http://127.0.0.1:8081/health >/dev/null 2>&1 && {
        printf '\n준비 완료 — http://127.0.0.1:8081 (로그: %s)\n' "$log"
        return 0
      }
      printf '.'; sleep 1
    done
    printf '\n60초 안에 뜨지 않았다. 로그를 확인하라: %s\n' "$log"
    return 1
  }
  function glimmer-down {
    if fuser -k 8081/tcp >/dev/null 2>&1; then
      echo "중지됨"
    else
      echo "실행 중이 아니다"
    fi
  }
  function glimmer-status {
    if curl -sf --max-time 2 http://127.0.0.1:8081/health >/dev/null 2>&1; then
      local used total
      used=$(( $(cat /sys/class/drm/card1/device/mem_info_vram_used 2>/dev/null || echo 0) / 1048576 ))
      total=$(( $(cat /sys/class/drm/card1/device/mem_info_vram_total 2>/dev/null || echo 0) / 1048576 ))
      echo "실행 중 — http://127.0.0.1:8081"
      (( total > 0 )) && echo "VRAM ${used}MiB / ${total}MiB (여유 $((total - used))MiB)"
    else
      echo "중지 상태"
    fi
  }
fi
function yt-wall {
  local sort="res:2160,hdr:sdr,vcodec:vp9"
  local -a extra=()
  if [[ "$(uname)" == "Darwin" ]]; then
    sort="res:2160,hdr:sdr,ext:mp4"
    extra=(--merge-output-format mp4)
  fi
  yt-dlp --cookies-from-browser vivaldi --remote-components ejs:github -S "$sort" "${extra[@]}" -o "$HOME/Videos/Wallpapers/%(title)s.%(ext)s" "https://www.youtube.com/watch?v=$1"
}

# Shell integrations
# fzf
eval "$(fzf --zsh)"

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "`fnm env --use-on-cd --shell zsh`"
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# 1password ssh agent
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '$HOME/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '$HOME/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '$HOME/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '$HOME/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

if command -v ngrok &>/dev/null; then
  eval "$(ngrok completion)"
fi

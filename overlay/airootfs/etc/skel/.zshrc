# ~/.zshrc —— nanbu 用户默认 zsh 配置（无 oh-my-zsh，保持轻量稳定）

# 基础选项
setopt AUTO_CD
setopt EXTENDED_GLOB
setopt HIST_IGNORE_DUPS
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# 补全
autoload -Uz compinit && compinit

# 别名
alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -la'
alias grep='grep --color=auto'

# 提示符（含 git 分支，简单实现）
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%F{magenta}(%b)%f'
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f${vcs_info_msg_0_}%# '

export EDITOR=nano
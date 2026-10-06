#
# ~/.bashrc —— nanbu 用户默认 shell 配置
#

# 若没有交互式运行，直接返回
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -la'
alias grep='grep --color=auto'
alias df='df -h'
alias free='free -h'

# 历史设置
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# 提示符
PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

# 常用路径
export EDITOR=nano
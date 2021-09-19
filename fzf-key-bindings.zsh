#     ____      ____
#    / __/___  / __/
#   / /_/_  / / /_
#  / __/ / /_/ __/
# /_/   /___/_/ key-bindings.zsh
#
# - $FZF_TMUX_OPTS
# - $FZF_CTRL_T_COMMAND
# - $FZF_CTRL_T_OPTS
# - $FZF_CTRL_R_OPTS
# - $FZF_ALT_C_COMMAND
# - $FZF_ALT_C_OPTS

# Key bindings
# ------------

# The code at the top and the bottom of this file is the same as in completion.zsh.
# Refer to that file for explanation.
if 'zmodload' 'zsh/parameter' 2>'/dev/null' && (( ${+options} )); then
  __fzf_key_bindings_options="options=(${(j: :)${(kv)options[@]}})"
else
  () {
    __fzf_key_bindings_options="setopt"
    'local' '__fzf_opt'
    for __fzf_opt in "${(@)${(@f)$(set -o)}%% *}"; do
      if [[ -o "$__fzf_opt" ]]; then
        __fzf_key_bindings_options+=" -o $__fzf_opt"
      else
        __fzf_key_bindings_options+=" +o $__fzf_opt"
      fi
    done
  }
fi

'emulate' 'zsh' '-o' 'no_aliases'

{

[[ -o interactive ]] || return 0

# CTRL-T - Paste the selected file path(s) into the command line
__fsel() {
  local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type f -print \
    -o -type d -print \
    -o -type l -print 2> /dev/null | cut -b3-"}"
  setopt localoptions pipefail no_aliases 2> /dev/null
  local item
  eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m "$@" | while read item; do
    echo -n "${(q)item} "
  done
  local ret=$?
  echo
  return $ret
}

__fzfcmd() {
  [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
    echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

fzf-file-widget() {
  LBUFFER="${LBUFFER}$(__fsel)"
  local ret=$?
  zle reset-prompt
  return $ret
}
zle     -N   fzf-file-widget
bindkey '^T' fzf-file-widget

# ALT-C - cd into the selected directory
fzf-cd-widget() {
  local cmd="${FZF_ALT_C_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type d -print 2> /dev/null | cut -b3-"}"
  setopt localoptions pipefail no_aliases 2> /dev/null
  local dir="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" $(__fzfcmd) +m)"
  if [[ -z "$dir" ]]; then
    zle redisplay
    return 0
  fi
  zle push-line # Clear buffer. Auto-restored on next prompt.
  BUFFER="cd ${(q)dir}"
  zle accept-line
  local ret=$?
  unset dir # ensure this doesn't end up appearing in prompt expansion
  zle reset-prompt
  return $ret
}
zle     -N    fzf-cd-widget
bindkey '\ec' fzf-cd-widget

# CTRL-R - Paste the selected command from history into the command line
fzf-history-widget() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
  selected=( $(fc -rl 1 | perl -ne 'print if !$seen{(/^\s*[0-9]+\**\s+(.*)/, $1)}++' |
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort,ctrl-z:ignore $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
  local ret=$?
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle reset-prompt
  return $ret
}

zle     -N   fzf-history-widget
bindkey '^R' fzf-history-widget

__fzf_sfdx_flags(){
  local selected="$1"
  local fullcmd=""
  for i in "${@:2}"
  do fullcmd+=" $i"
  done
  local ret=`cat ~/.sfdxcommands.json | jq -r ".[] | select(.id==\"$selected\") | .flags | keys[]" | $(__fzfcmd) -m --bind='ctrl-z:ignore,alt-j:preview-down,alt-k:preview-up' --preview='cat ~/.sfdxcommands.json | jq -r ".[] | select(.id==\"'$selected'\") | .flags | to_entries[] | select (.key==\""{}"\") | [\"Command:\n'"$fullcmd"'\n\",\"Flag Description:\",.value][]"' --preview-window='right:wrap'`
  echo "${ret//$'\n'/ --}"
}


fzf-sfdx(){
  local fullcmd="$LBUFFER"
  local cmd="$(echo $fullcmd | awk '{print $1}')"
  local subcmd="$(echo $fullcmd | awk '{print $2}')"
  local match="$(cat ~/.sfdxcommands.json | jq -r '.[] | select(.id=="'$subcmd'")')"
  if [[ "$cmd" = "sfdx" && "$match" != "" ]]
  then
    local flag="$(__fzf_sfdx_flags $subcmd $fullcmd)"
    if [[ "$flag" != "" ]]
    then
      LBUFFER="${LBUFFER:0:$CURSOR} --$flag${LBUFFER:$CURSOR}"
    fi
  elif [[ "$cmd" == "sfdx" || "$cmd" == "" ]]
  then
    local querystr=""
    if [[ "$subcmd" != "" ]]; then
     querystr="--query $subcmd" 
    fi
    local selected="$(cat ~/.sfdxcommands.json | jq -r '.[].id' | $(__fzfcmd) +m --bind=ctrl-z:ignore,alt-j:preview-down,alt-k:preview-up --preview='cat ~/.sfdxcommands.json | jq -r ".[] | select (.id==\""{}"\") | [\"\nDescription:\n \"+.description,\"\nUsage:\n \"+select(has(\"usage\")).usage, \"\nExamples:\n \"+(select(has(\"examples\")).examples|join(\"\n\"))][]"' --preview-window='right:wrap' $querystr)"
    if [[ "$selected" != "" ]]; then
      LBUFFER="sfdx $selected"
    fi
  fi
  local ret=$?
  zle reset-prompt
  return $ret
}
zle -N fzf-sfdx{,}
bindkey "^e" fzf-sfdx

} always {
  eval $__fzf_key_bindings_options
  'unset' '__fzf_key_bindings_options'
}


__fzf_sfdx_flags__(){
  local selected="$1"
  local ret=`cat ~/.sfdxcommands.json | jq -r ".[] | select(.id==\"$selected\") | .flags | keys[]" | $(__fzfcmd) -m --bind 'ctrl-z:ignore,alt-j:preview-down,alt-k:preview-up' --preview='cat ~/.sfdxcommands.json | jq -r ".[] | select(.id==\"'$selected'\") | .flags | to_entries[] | select (.key==\""{}"\") | [\"Command: '"$selected"'\n\",.value][]"' --preview-window='right:wrap'`
  echo $ret
}

__fzf_sfdx__(){
  local fullcmd="$READLINE_LINE"
  local cmd="$(echo $fullcmd | awk '{print $1}')"
  local subcmd="$(echo $fullcmd | awk '{print $2}')"
  local match="$(cat ~/.sfdxcommands.json | jq -r '.[] | select(.id=="'$subcmd'")')"
  if [[ "$cmd" = "sfdx" && "$match" != "" ]]
  then
    local flag="$(__fzf_sfdx_flags__ $subcmd)"
    if [[ "$flag" != "" ]]
    then
      READLINE_LINE="$fullcmd --$flag"
      READLINE_POINT=$(( ${#fullcmd} + ${#flag} + 3 ))
    fi
  else
    local selected="$(cat ~/.sfdxcommands.json | jq -r '.[].id' | $(__fzfcmd) +m --bind 'ctrl-z:ignore,alt-j:preview-down,alt-k:preview-up' --preview='cat ~/.sfdxcommands.json | jq -r ".[] | select (.id==\""{}"\") | [\"\nDescription:\n \"+.description,\"\nUsage:\n \"+select(has(\"usage\")).usage, \"\nExamples:\n \"+(select(has(\"examples\")).examples|join(\"\n\"))][]"' --preview-window='right:wrap')"
    if [[ "$selected" != "" ]]; then
      READLINE_LINE="sfdx $selected"
      READLINE_POINT=$(( 5 + ${#selected} ))
    fi
  fi
}


if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then

  # CTRL-K - Search through sfdx commands
  bind -m emacs-standard '"\C-k": "\C-e \C-u\C-y\ey\C-u"$(__fzf_sfdx__)"\e\C-e\er"'
  bind -m vi-command '"\C-k": "\C-z\C-k\C-z"'
  bind -m vi-insert '"\C-k": "\C-z\C-k\C-z"'

else

  # CTRL-K - Search through sfdx commands
  bind -m emacs-standard -x '"\C-k": __fzf_sfdx__'
  bind -m vi-command -x '"\C-k": __fzf_sfdx__'
  bind -m vi-insert -x '"\C-k": __fzf_sfdx__'

fi

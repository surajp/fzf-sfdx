
__fzf_sfdx_flags__(){
  local selected="$1"
  local fullcmd=""
  for i in "${@:2}"
  do fullcmd+=" $i"
  done
  local ret=`cat ~/.sfdxcommands.json | jq -r ".[] | select(.id==\"$selected\") | .flags | keys[]" | $(__fzfcmd) -m --bind 'ctrl-z:ignore,alt-j:preview-down,alt-k:preview-up' --preview='cat ~/.sfdxcommands.json | jq -r ".[] | select(.id==\"'$selected'\") | .flags | to_entries[] | select (.key==\""{}"\") | [\"Command:\n'"$fullcmd"'\n\",\"Flag Description:\",.value][]"' --preview-window='right:wrap'`
  echo "${ret//$'\n'/ --}"
}

__fzf_sfdx__(){
  local fullcmd="$READLINE_LINE"
  local cmd="$(echo $fullcmd | awk '{print $1}')"
  local subcmd="$(echo $fullcmd | awk '{print $2}')"
  local match="$(cat ~/.sfdxcommands.json | jq -r '.[] | select(.id=="'$subcmd'")')"
  if [[ "$cmd" = "sfdx" && "$match" != "" ]]
  then
    local flag="$(__fzf_sfdx_flags__ $subcmd $fullcmd)"
    if [[ "$flag" != "" ]]
    then
      READLINE_LINE="$fullcmd --$flag"
      READLINE_POINT=$(( ${#fullcmd} + ${#flag} + 3 ))
    fi
  elif [[ "$mcd" == "sfdx" || "$cmd" == "" ]]
  then
    local querystr=""
    if [[ "$subcmd" != "" ]]; then
     querystr="--query $subcmd" 
    fi
    local selected="$(cat ~/.sfdxcommands.json | jq -r '.[].id' | $(__fzfcmd) +m --bind 'ctrl-z:ignore,alt-j:preview-down,alt-k:preview-up' --preview='cat ~/.sfdxcommands.json | jq -r ".[] | select (.id==\""{}"\") | [\"\nDescription:\n \"+.description,\"\nUsage:\n \"+select(has(\"usage\")).usage, \"\nExamples:\n \"+(select(has(\"examples\")).examples|join(\"\n\"))][]"' --preview-window='right:wrap' $querystr)"
    if [[ "$selected" != "" ]]; then
      READLINE_LINE="sfdx $selected"
      READLINE_POINT=$(( 5 + ${#selected} ))
    fi
  fi
}


if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then

  # CTRL-K - Search through sfdx commands
  bind -m vi-command '"\C-e": "\C-z\C-e\C-z"'
  bind -m vi-insert '"\C-e": "\C-z\C-e\C-z"'

else

  # CTRL-K - Search through sfdx commands
  bind -m emacs-standard -x '"\C-e": __fzf_sfdx__'
  bind -m vi-command -x '"\C-e": __fzf_sfdx__'
  bind -m vi-insert -x '"\C-e": __fzf_sfdx__'

fi

## Supercharge your Salesforce CLI game with FZF! (For Bash and Zsh)

Fuzzy find Salesforce CLI commands and flags as you type, with live previews of what each command and flag does. No more typos, switching to the browser or running `help` to lookup commands and associated options. Autocomplete doesn't get any better than this!

See it in action below

![](./assets/recording.gif)

#### Pre-Requisites

- [FZF](https://github.com/junegunn/fzf)
  (If you use the cli more than the average user, do yourself and favor and install fzf. Seriously, even if you don't plan
  on using this sfdx script, install FZF. It will change your life.)
- [jq](https://stedolan.github.io/jq/download/)
- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) (the npm version installed using `npm i -g sfdx-cli`)
- Bash or Zsh shell

#### Setup

##### Bash

- Copy [fzf-key-bindings.bash](./fzf-key-bindings.bash) to a directory on your machine.
- Replace the path to the `key-bindings.bash` file in `$HOME/.fzf.bash` with the path to the file above.
- Run the following command `sfdx commands --json > ~/.sfdxcommands.json`. (You can add it your `.bashrc`
  file to run it automatically every time you login. Note that this could add a noticeable delay to launching a new terminal).
- Restart your shell or run `source $HOME/.bashrc`.

##### Zsh

- Copy [fzf-key-bindings.zsh](./fzf-key-bindings.zsh) to a directory on your machine.
- Replace the path to the `key-bindings.zsh` file in `$HOME/.fzf.zsh` with the path to the file above.
- Run the following command `sfdx commands --json > ~/.sfdxcommands.json`. (You can add it your `.zshrc`
  file to run it automatically every time you login. Note that this could add a noticeable delay to launching a new terminal).
- Restart your shell or run `source $HOME/.zshrc`.

#### Usage

- Type `Ctrl-e` on a new line to bring up the list of commands to fuzzy search through. The preview window shows up to
  the right with the command description and examples. Use arrow keys or `Ctrl-k` and `Ctrl-J` to move up and down through the list of commands. Use `Alt-K` and `Alt-J` to move the preview window up and down, which can be useful for commands with long previews. Hit `Enter` to select a command and print it out onto the terminal.
- Once a command is selected, or if you have typed an `sfdx` command in manually (without fzf), hitting `Ctrl-e` again will bring
  up the list of flags associated with the command. As you scroll through the list of flags, the preview window will show a description of the flag and some of its properties. Hit `Enter` to select the flag and print it out onto the terminal.

#### Notes

- This script only works when `sfdx` is the only command on a line (i.e. doesn't work if you are trying to pipe the output of another command to sfdx, for example)
- If you don't end up adding `sfdx commands --json > ~/.sfdxcommands.json` to your `.profile` or `.bashrc` file, run the command manually from time to time to keep up with updates to the CLI
- The script binds `Ctrl-e` to bring up sfdx commands. If you'd like to change the mapping, you can change it [here](./fzf-key-bindings.bash#L130) (for bash) or [here](./fzf-key-bindings.zsh#L151) (for zsh)
- If you'd like to use this in VS Code's integrated terminal, you'd need to prevent `Ctrl-e` from being hijacked by VSC to quick open files and have it be sent to the shell itself. This can be accomplished by adding the following line to `settings.json`. Note the hyphen(`-`) before the setting name to unbind the action.

```json
  "terminal.integrated.commandsToSkipShell": [
        "-workbench.action.quickOpen"
        ]
```

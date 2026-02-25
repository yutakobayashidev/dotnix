# Session Context

## User Prompts

### Prompt 1

差分みてコミットして

### Prompt 2

push

### Prompt 3

alias grepush='git recommit && git push -f'
alias gsp='git stash && git pull && git stash pop'
alias gpgp='git pull && git push' alias gpu='git pull' これエイリアス追加しておいて

### Prompt 4

alias grepush='git recommit && git push -f'
  alias gsp='git stash && git pull && git stash pop'
  alias gpgp='git pull && git push' alias gpu='git pull'
  これエイリアス追加しておいて

### Prompt 5

continuesのエイリアスも

### Prompt 6

コミットして

### Prompt 7

git recommitなんてあるっけ

### Prompt 8

git recommitなんてあるっけ

### Prompt 9

[Request interrupted by user for tool use]

### Prompt 10

uncommit = reset HEAD^
    recommit = commit -c ORIG_HEAD

### Prompt 11

[Request interrupted by user for tool use]

### Prompt 12

programs/git
/aliases

### Prompt 13

[Request interrupted by user for tool use]

### Prompt 14

programs/git/aliases

### Prompt 15

init.defaultBranch = "main";

### Prompt 16

push = {
        default = "simple";
        autoSetupRemote = true;
        useForceIfIncludes = true;
      };

      commit.verbose = true;
 解説

### Prompt 17

うん

### Prompt 18

column.ui = "auto";

      branch.sort = "-committerdate";

      help.autocorrect = "prompt";

      rerere = {
        enabled = true;
        autoupdate = true;
      };

      wt.remover = "trash";

### Prompt 19

して

### Prompt 20

rebase = {
        autoStash = true;
        autoSquash = true;
        updateRefs = true;
      };

      merge = {
        ff = false;
        conflictstyle = "zdiff3";
      };

      pull.rebase = true;

### Prompt 21

fetch = {
        writeCommitGraph = true;
        prune = true;
        pruneTags = true;
        all = true;
      };

### Prompt 22

これはzshのエイリアスに追加ッシテ   ; Open the repository in a web browser
  browse = !gh repo view --web
  ; Open the pull request in a web browser
  browse-pr = !gh pr view --web
  ; Get the commit URL for the current HEAD
  brc = !"echo $(gh repo view --json url  --jq .url)/commit/$(git rev-parse HEAD)"

### Prompt 23

root = rev-parse --show-toplevel

### Prompt 24

; View an issue selected with fzf from the issue list
  isv = !gh issue list| fzf-tmux --prompt \"issue preview>\" --preview \"echo {} | awk '{print \\$1}' | xargs gh issue view -p\" | xargs gh issue view
  ; View a PR selected with fzf from the PR list
  prv = !gh pr list| fzf-tmux --prompt \"pr preview>\" --preview \"echo {} | awk '{print \\$1}' | xargs gh pr view -p\" | xargs gh pr view
　これもzsh

### Prompt 25

logg = log --graph --abbrev-commit --pretty=format:\"%C(yellow)%h%C(reset) - %C(cyan)%ad%C(reset) %C(green)(%ar)%C(reset)%C(auto)%d%C(reset)%n          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%n\"
 なにこれ

### Prompt 26

うん

### Prompt 27

; Switch to a remote branch selected with fzf
  swor = "!f() { local -r ref=$(git branch -r | fzf); git sw \"${1:-${ref#*/}}\" $ref; }; f"
  ; Switch to a branch (local or remote) selected with fzf
  swf =!git branch -a | fzf | xargs git switch
 これ追加して関連するzsh function消して

### Prompt 28

; Show git status for all submodules
  sms = submodule foreach \"git status\"

### Prompt 29

コミットしておいて


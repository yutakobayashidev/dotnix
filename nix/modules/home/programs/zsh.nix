{ config, pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    shellAliases = {
      rebuild = "nh os switch && source ~/.zshrc";
      cc = "claude";
      p = "pnpm";
      ls = "lsd -1A";
      ll = "lsd -l";
      la = "lsd -la";
      lt = "lsd --tree";
      cat = "bat";
      prw = "gh pr view --web";
      gundo = "git reset --soft HEAD~1";
      cpd = "pwd | wl-copy";
      rmswap = "find . -type f -name \"*.swp\" -delete && find . -type f -name \".*.swp\" -delete";
    };
    initContent = ''
            eval "$(direnv hook zsh)"
            eval "$(zoxide init zsh)"

            # oh-my-zsh gitプラグインのエイリアスを解除
            unalias g 2>/dev/null
            unalias gb 2>/dev/null

            # gh-q: ghq + fzf でリポジトリ選択・clone
            # https://github.com/ryoppippi/dotfiles/blob/5a0a1f1d68b66a89c2c916c9e97c0129251ca467/fish/functions/gh-q.fish
            # 使い方: gh-q [-o] [owner]  (ownerを省略すると自分のrepo、-oでGitHubを開く)
            function gh-q() {
              local open_github=false
              if [[ "$1" == "-o" ]]; then
                open_github=true
                shift
              fi

              local owner="$1"
              if [[ -z "$owner" ]]; then
                owner=$(gh api user -q .login)
              fi

              local query='
      query ($owner: String!, $endCursor: String) {
        repositoryOwner(login: $owner) {
          repositories(first: 30, after: $endCursor) {
            pageInfo { hasNextPage endCursor }
            nodes { nameWithOwner }
          }
        }
      }'

              local REPO=$(gh api graphql \
                --paginate \
                --field owner="$owner" \
                -f query="$query" \
                --jq '.data.repositoryOwner.repositories.nodes[].nameWithOwner' \
              | fzf)

              if [[ -z "$REPO" ]]; then
                return
              fi

              if $open_github; then
                xdg-open "https://github.com/$REPO"
              else
                ghq get "$REPO"
                cd "$(ghq root)/github.com/$REPO"
              fi
            }

            # gb: git branchをfuzzy検索して移動
            function gb() {
              local branch=$(git branch --all | grep -v HEAD | sed 's/^[* ]*//' | sed 's#remotes/origin/##' | sort -u | fzf --prompt="git branch > ")
              if [[ -n "$branch" ]]; then
                git checkout "$branch"
              fi
            }

            # jb: jj bookmarkをfuzzy検索して移動
            function jb() {
              local bookmark=$(jj bookmark list | fzf --prompt="jj bookmark > " | awk '{print $1}')
              if [[ -n "$bookmark" ]]; then
                jj new "$bookmark"
              fi
            }

            # g: 引数なし→ghq+pecoでcd、引数あり→gitに転送
            function g () {
              if [[ $# -eq 0 ]]; then
                local selected_dir=$(ghq list -p | peco --prompt="repositories >")
                if [ -n "$selected_dir" ]; then
                  cd "$selected_dir"
                fi
              else
                git "$@"
              fi
            }

            # Alt+Up で親ディレクトリに移動
            function cd-up () {
              cd ..
              zle reset-prompt
            }
            zle -N cd-up
            bindkey '^[[1;3A' cd-up
    '';
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
      }
    ];
    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git"
        "docker"
        "kubectl"
        "history"
        "sudo"
        "bgnotify"
      ];
    };
  };
}

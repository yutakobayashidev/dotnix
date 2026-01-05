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
      rebuild = "nh os switch";
      ls = "lsd";
      ll = "lsd -l";
      la = "lsd -la";
      lt = "lsd --tree";
      cat = "bat";
    };
    initContent = ''
      eval "$(direnv hook zsh)"
      eval "$(zoxide init zsh)"

      # oh-my-zsh gitプラグインのgエイリアスを解除
      unalias g 2>/dev/null

      # gh-q: ghq + fzf でリポジトリ選択・clone
      # https://github.com/ryoppippi/dotfiles/blob/5a0a1f1d68b66a89c2c916c9e97c0129251ca467/fish/functions/gh-q.fish
      # 使い方: gh-q [owner]  (ownerを省略すると自分のrepo)
      function gh-q() {
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

        ghq get "$REPO"
        cd "$(ghq root)/github.com/$REPO"
      }

      # g: ghqリポジトリをpecoで選択してcd
      function g () {
        local selected_dir=$(ghq list -p | peco --prompt="repositories >" --query "$1")
        if [ -n "$selected_dir" ]; then
          cd "$selected_dir"
        fi
      }
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

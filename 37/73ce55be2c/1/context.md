# Session Context

## User Prompts

### Prompt 1

nrnみたいにashibanix flake init -t github:yutakobayashidev/ashiba#<name>みたいにしてほしい

### Prompt 2

コミットして

### Prompt 3

yuta@M2-MacBook-Air  ~/ghq/github.com/yutakobayashidev/dotnix   main  ssh yuta@100.91.91.87
# Tailscale SSH requires an additional check.
# To authenticate, visit: https://login.tailscale.com/a/lfa773db366a17
# Authentication checked with Tailscale SSH.
# Time since last authentication: 1s
 yuta@UM790-Pro  ~  ashiba
error: path '«github:yutakobayashidev/ashiba/82b5444510db78eaa50264bd56b06996c8e99616»/flake.nix' does not exist
 ✘ yuta@UM790-Pro  ~  ashiba next
error: ...

### Prompt 4

[Request interrupted by user]

### Prompt 5

hmm

### Prompt 6

これどこに作られるんだっけ

### Prompt 7

今のディレクトリで作られてしまったので、onasite

### Prompt 8

[Request interrupted by user]

### Prompt 9

今のディレクトリで作られてしまったので、mainにcheckoutいste

### Prompt 10

ghq createと一緒にいい感じにできるようなコマンドにしたいな対話型でrepo nameを効くようにする、ただ、gitを初期化したくない時もあるからいい感じに設計して

### Prompt 11

[Request interrupted by user for tool use]

### Prompt 12

もう少し対話プロンプト綺麗にかけるツールないんだっけ

### Prompt 13

どれが1番star多いの？

### Prompt 14

gumをninい入れて

### Prompt 15

[Request interrupted by user]

### Prompt 16

gumをnixに入れて

### Prompt 17

うん

### Prompt 18

x どうやって使うの？

### Prompt 19

ashibaの引数は？

### Prompt 20

error: flake 'github:yutakobayashidev/ashiba' does not provide attribute 'templates.default' or 'defaultTemplate'

### Prompt 21

テンプレート選択fzfにしてくれ

### Prompt 22

tnix   main ±✚  source ~/.zshrc
(eval):23: parse error near `local'
/home/yuta/.oh-my-zsh/oh-my-zsh.sh:17: parse error near `done'
/home/yuta/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh:223: parse error near `done'
Usage:  docker container COMMAND

Manage containers

Commands:
  attach      Attach local standard input, output, and error streams to a running container
  commit      Create a new image from a container's changes
  cp          Copy files/folders between a co...

### Prompt 23

yuta@UM790-Pro  ~/ghq/github.com/yutakobayashidev/dotnix   main ±✚  source ~/.zshrc
(eval):23: parse error near `local'
/home/yuta/.oh-my-zsh/oh-my-zsh.sh:17: parse error near `done'
/home/yuta/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh:223: parse error near `done'
 yuta@UM790-Pro  ~/ghq/github.com/yutakobayashidev/dotnix   main ±✚ 

### Prompt 24

いい感じだが、--localを明示しない限りgit initされるかたちでいい

### Prompt 25

nameも明示するようにして

### Prompt 26

コミットして

### Prompt 27

コミlッツ推して

### Prompt 28

いいんだけど、任意のテンプレートをfuzzyしたいのでもう少し抽象化したいな

### Prompt 29

[Request interrupted by user]

### Prompt 30

ただ、ashibaはashibaのまま、その中でさらに抽象化した関数を呼ぶようにしたい

### Prompt 31

うん、そんな感じで

### Prompt 32

ashiba,もっと薄くできる気が

### Prompt 33

nfiはfuzzyに集中したいな、やっぱり、nameは受け取らない前提

### Prompt 34

unix哲学に従って、ashibaがまだ太すぎる気がする

### Prompt 35

REAMDE更新してコミットして

### Prompt 36

[Request interrupted by user for tool use]

### Prompt 37

ashibaは廃止して、nfiのただのエイリアスにしたい

### Prompt 38

なんで関数にしてるの？

### Prompt 39

ンsんで引数転送する必要がないの？

### Prompt 40

nrnはなぜ関数⁉︎

### Prompt 41

コミットして

### Prompt 42

https://github.com/the-nix-way/dev-templates これもよく使う

### Prompt 43

ndtにしよう

### Prompt 44

コミットして

### Prompt 45

土居やって使うんだって、nfi

### Prompt 46

gコマンドみたいにtemplates:って

### Prompt 47

pecoとfzfってどっちがいいんだっけ


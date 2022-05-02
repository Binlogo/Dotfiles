set fish_greeting ""

set -gx TERM xterm-256color

# Alias
alias ls "ls -p -G"
alias la "ls -A"
alias ll "ls -l"
alias lla "ll -A"
alias g git
command -qv nvim && alias vim nvim && alias vi nvim

if type -q exa
  alias ll "exa -l -g --icons"
  alias lla "ll -a"
end

set -gx EDITOR nvim

# PATH
set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH

# Rust & Cargo
set -gx PATH ~/.cargo/bin:$PATH

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Starship prompt
starship init fish | source

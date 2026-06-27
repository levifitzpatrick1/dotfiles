if status is-interactive
    # Disable the default welcoming greeting
    set -g fish_greeting ""

    # Initialize the Starship prompt
    starship init fish | source

    # Initialize zoxide
    zoxide init fish | source

    # Convenient aliases
    alias l="ls -lh"
    alias la="ls -la"
    alias ll="ls -l"
    alias g="git"
end

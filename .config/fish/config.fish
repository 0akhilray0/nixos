if status is-interactive
    # Commands to run in interactive sessions can go here
end
alias ll 'ls -la'
#alias yazi 'sudo yazi'
alias cls 'clear'
#DUAL BOOT WINDOWS COMMAND
alias windows 'sudo efibootmgr -n 0001; sudo reboot'


alias nrs 'sudo nixos-rebuild switch'
alias nrc ' sudo nvim /etc/nixos/configuration.nix'
alias nrd 'sudo nixos-rebuild dry-build'
alias hyprc 'sudo nvim .config/hypr/hyprland.conf'
# Add these lines:
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERMINAL ghostty


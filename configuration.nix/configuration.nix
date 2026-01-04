# ============================================================
# NixOS System Configuration - FINAL VERSION
# ============================================================
# Hostname  : bleach
# User      : akhil
# Desktop   : Hyprland (Wayland compositor)
# NixOS     : 25.11 (Warbler)
#
# ALL PACKAGE NAMES VERIFIED FOR NIXOS 25.11
#
# HOW TO REBUILD:
#   sudo nixos-rebuild switch
#
# HOW TO ROLLBACK IF SOMETHING BREAKS:
#   sudo nixos-rebuild switch --rollback
# ============================================================

{ config, pkgs, lib, ... }:

{
  ############################################################
  # NIXPKGS CONFIGURATION
  ############################################################
  # Allow installation of proprietary software
  # Examples: NVIDIA drivers, VS Code, Discord, etc.
  nixpkgs.config.allowUnfree = true;

  ############################################################
  # IMPORTS
  ############################################################
  # Import hardware-specific configuration
  # This file is auto-generated during installation
  # Contains: filesystems, boot devices, kernel modules
  imports = [
    ./hardware-configuration.nix
  ];

  ############################################################
  # STORAGE & FILESYSTEM SUPPORT
  ############################################################
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.devmon.enable = true;


  boot.supportedFilesystems = [ "ntfs" ];


  ############################################################
  # BOOTLOADER
  ############################################################
  # Using GRUB with UEFI support
  boot.loader.grub = {
    enable = true;
    device = "nodev";              # "nodev" for UEFI systems
    efiSupport = true;             # Enable UEFI booting
      };
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };
 
  ############################################################
  # NETWORKING
  ############################################################
  networking = {
    hostName = "bleach";           # Your computer's name on network
    networkmanager.enable = true;  # GUI for WiFi/Ethernet management
  };

  ############################################################
  # BLUETOOTH
  ############################################################
  hardware.bluetooth = {
    enable = true;                 # Enable Bluetooth support
    powerOnBoot = true;            # Turn on Bluetooth on startup
  };
  
  # Blueman: GUI Bluetooth manager (system tray applet)
  services.blueman.enable = true;

  ############################################################
  # LOCALIZATION
  ############################################################
  # Set your timezone (critical for correct time display)
  time.timeZone = "Asia/Kolkata";
  
  # Use default locale (en_US.UTF-8)
  # en_IN.UTF-8 is not available in NixOS

  ############################################################
  # SHELL
  ############################################################
  # Enable Fish shell system-wide
  programs.fish.enable = true;

  ############################################################
  # DISPLAY SERVER & WINDOW MANAGER
  ############################################################
  # Enable X11 for XWayland compatibility
  services.xserver = {
    enable = false;
    
    # Keyboard layout
    xkb = {
      layout = "us";               # US keyboard layout
    };
    
    # Exclude xterm (we don't want it as fallback)
    excludePackages = [ pkgs.xterm ];
  };
  
  # Hyprland: Modern Wayland compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;        # Enable XWayland for legacy X11 apps
  };

  ############################################################
  # LOGIN MANAGER (DISPLAY MANAGER)
  ############################################################
  # greetd: Lightweight login manager
  # tuigreet: Terminal UI greeter (minimal, fast)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd Hyprland";
      };
    };
  };

  ############################################################
  # AUDIO
  ############################################################
  # PipeWire: Modern audio/video server
  services.pipewire = {
    enable = true;
    pulse.enable = true;           # PulseAudio compatibility
    alsa = {
      enable = true;
      support32Bit = true;         # Support for 32-bit audio apps
    };
  };

  ############################################################
  # POLKIT (AUTHENTICATION)
  ############################################################
  # Polkit: System-wide authentication framework
  # Required for apps that need elevated privileges
  security.polkit.enable = true;

  ############################################################
  # POLKIT GNOME AGENT (SYSTEMD SERVICE)
  ############################################################
  # Properly initialize polkit-gnome as a systemd user service
  # This ensures Thunar and other apps can prompt for authentication
  # Started manually from Hyprland autostart (more reliable than targets)
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ ];
    wants = [ ];
    after = [ ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  ############################################################
  # DCONF (GNOME SETTINGS DAEMON)
  ############################################################
  # dconf: Required for GTK apps to save settings
  # Used by: Thunar, Firefox, nwg-look, most GTK apps
  programs.dconf.enable = true;

  ############################################################
  # USER ACCOUNTS
  ############################################################
  users.users.akhil = {
    isNormalUser = true;           # Regular user (not system user)
    description = "Akhil";         # Full name
    shell = pkgs.fish;             # Default shell
    
    # Groups give your user special permissions:
    # - wheel: sudo access
    # - networkmanager: manage WiFi without sudo
    # - video: access webcam, brightness control
    # - audio: access audio devices
    extraGroups = [ 
      "wheel" 
      "networkmanager" 
      "video" 
      "audio" 
    ];
    
    # User-specific packages
    packages = with pkgs; [ 
      tree                         # Directory tree viewer
    ];
  };

  ############################################################
  # ENVIRONMENT VARIABLES
  ############################################################
  # Set for ALL users at login
  environment.sessionVariables = {
    # Cursor theme settings (MUST be environment variables for Wayland)
    XCURSOR_THEME = "Vanilla-DMZ";
    XCURSOR_SIZE = "24";
    
    # Tell Electron/Chromium apps to use Wayland
    # Affects: VS Code, Discord, Slack, Chrome, etc.
    NIXOS_OZONE_WL = "1";
    
    # Default terminal emulator
    # This tells all apps (Thunar, Yazi, etc.) to use Ghostty
    TERMINAL = "ghostty";
  };

  ############################################################
  # SYSTEM-WIDE PROGRAMS
  ############################################################
  # Firefox: Enable with Wayland support (automatic in NixOS)
  programs.firefox.enable = true;

  ############################################################
  # FONTS
  ############################################################
  # System-wide font installation
  fonts = {
    enableDefaultPackages = true;
    
    packages = with pkgs; [
      # Base fonts
      noto-fonts                   # Google's font family
      noto-fonts-color-emoji       # Color emoji support 😊
      fira-code                    # Monospace with ligatures
      
      # CRITICAL: Nerd Fonts for Waybar icons
      nerd-fonts.fira-code         # FiraCode with icons
      nerd-fonts.jetbrains-mono    # JetBrains Mono with icons
      nerd-fonts.iosevka           # Iosevka with icons
      
      # Icon font
      font-awesome                 # Popular icon font
    ];
    
    # Font rendering configuration
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "FiraCode Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  ############################################################
  # SYSTEM PACKAGES
  ############################################################
  # Software available to ALL users
  environment.systemPackages = with pkgs; [
    
    # =========== TERMINAL UTILITIES ===========
    neovim                         # Modern Vim (text editor)
    git                            # Version control
    wget                           # Download files
    curl                           # Transfer data with URLs
    btop                           # System monitor
    fastfetch                      # System info display
    tree                           # Directory structure viewer
    efibootmgr                     # EFI boot manager
    
    # =========== SYSTEM TOOLS ===========
    brightnessctl                  # Control screen brightness
    networkmanagerapplet           # Network manager system tray
    
    # =========== TERMINAL EMULATOR ===========
    ghostty                        # Modern GPU-accelerated terminal
    
    # =========== LOGIN MANAGER ===========
    tuigreet                       # TUI greeter for greetd
    
    # =========== GTK THEMES ===========
    # These control the appearance of windows/buttons/menus
    adw-gtk3                       # Adwaita GTK3 theme
    
    # =========== ICON THEMES ===========
    # These control how file/folder icons look
    windows10-icons                # Windows-like icon theme

    # =========== CURSOR THEMES ===========
    vanilla-dmz                    # Simple, clean cursor
    
    # =========== THEME MANAGER ===========
    nwg-look                       # GTK theme switcher (GUI)
    
    # =========== AUTHENTICATION ===========
    polkit_gnome                   # GUI password prompts for polkit
    
    # =========== WAYLAND TOOLS ===========
    waybar                         # Status bar
    rofi                           # Application launcher
    waypaper                       # Wallpaper setter
    swww                           # Animated wallpaper daemon
    yazi                           # Terminal file manager
    wl-clipboard                   # Clipboard for Wayland
    
    # =========== SCREENSHOT TOOLS ===========
    grim                           # Screenshot tool
    slurp                          # Region selector
    # Usage: grim -g "$(slurp)" screenshot.png
    
    # =========== NOTIFICATIONS ===========
    dunst                          # Notification daemon
    libnotify                      # Send notifications from terminal
    
    
    # =========== FILE MANAGER (Thunar) ===========
    xfce.thunar                    # Main file manager
    xfce.thunar-volman             # Removable media management
    xfce.thunar-archive-plugin     # Archive support
    xfce.thunar-media-tags-plugin  # Audio/video tag editor
    
    # Thunar dependencies
    xfce.tumbler                   # Thumbnail generator
    ffmpegthumbnailer              # Video thumbnails
    libgsf                         # ODF thumbnails
    
    # Archive managers
    xarchiver                      # GUI archive manager
    unzip                          # ZIP extraction
    zip                            # ZIP creation
    p7zip                          # 7z support
  ];

  ############################################################
  # SYSTEM SERVICES
  ############################################################
  
  # Automatic SSD TRIM (maintains SSD performance)
  # Runs weekly - DO NOT disable if you have SSD!
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  ############################################################
  # NIX SETTINGS (PACKAGE MANAGER CONFIGURATION)
  ############################################################
  nix.settings = {
    # Automatic optimization (deduplicate files in /nix/store)
    auto-optimise-store = true;
    
    # Enable experimental features (flakes, nix command)
    experimental-features = [ "nix-command" "flakes" ];
  };
  
  # Automatic garbage collection
  nix.gc = {
    automatic = true;              # Enable automatic cleanup
    dates = "weekly";              # Run every week
    options = "--delete-older-than 30d";  # Keep last 30 days
  };

  ############################################################
  # SYSTEM STATE VERSION
  ############################################################
  # WARNING: NEVER CHANGE THIS AFTER INSTALLATION!
  # This ensures system upgrades don't break your config
  system.stateVersion = "25.11";
}

# ============================================================
# END OF CONFIGURATION
# ============================================================
#
# QUICK REFERENCE:
#
# Apply changes:          sudo nixos-rebuild switch
# Test without saving:    sudo nixos-rebuild test
# Rollback if broken:     sudo nixos-rebuild switch --rollback
# Change GTK theme:       nwg-look
# Clean old generations:  sudo nix-collect-garbage -d
#
# TROUBLESHOOTING:
#
# Waybar icons missing:   Use Nerd Font in waybar config
# GTK theme not working:  Run nwg-look
# Black screen on login:  Ctrl+Alt+F2, sudo systemctl restart greetd
# No audio:               nix-shell -p pavucontrol (then check audio)
# Thunar permission denied: Check systemctl --user status polkit-gnome-authentication-agent-1
#
# ============================================================


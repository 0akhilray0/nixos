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
  # GRAPHICS HARDWARE
  ############################################################
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # Critical for Wine/Proton games
  };

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
  # PLYMOUTH BOOT SPLASH
  ############################################################
  # Plymouth replaces systemd boot messages with a graphical
  # boot animation/logo during startup and shutdown.
  #
  # Current theme: abstract_ring (animated ring)
  # Theme source: adi1090x collection (80+ themes available)
  # Browse themes: https://github.com/adi1090x/plymouth-themes
  #
  # To switch themes:
  # 1. Change the "theme" line below
  # 2. Add new theme name to "selected_themes" list
  # 3. Run: nrs
  ############################################################
  
  boot.plymouth = {
    enable = true;                    # Enable Plymouth boot splash
    theme = "cross_hud";          # Active theme name
    themePackages = with pkgs; [
      (adi1090x-plymouth-themes.override {
        selected_themes = [ "cross_hud" ];  # Only download these themes
      })
    ];
  };

  ############################################################
  # SILENT BOOT CONFIGURATION
  ############################################################
  # Hides systemd messages and boot logs to show only the
  # Plymouth animation for a clean boot experience.
  ############################################################
  
  boot.consoleLogLevel = 0;           # Suppress kernel messages
  boot.initrd.verbose = false;        # Hide initrd messages
  
  # Graphics driver for Plymouth (Intel UHD 605 on D330)
  boot.initrd.kernelModules = [ "i915" ];
  
  # Kernel parameters for silent boot
  boot.kernelParams = [
    "quiet"                           # Suppress most messages
    "splash"                          # Enable splash screen
    "boot.shell_on_fail"              # Emergency shell if boot fails
    "udev.log_level=0"                # Suppress udev messages
    "rd.systemd.show_status=auto"     # Hide systemd status
    "rd.udev.log_level=3"             # Minimal udev logging
  ];
  
  ############################################################
  # END PLYMOUTH CONFIGURATION
  ############################################################


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
  # HYPRLAND - PRIMARY DESKTOP (ALWAYS ENABLED)
  ############################################################
  # Hyprland: Modern Wayland tiling compositor
  # This is your main daily driver desktop environment
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;        # Enable XWayland for legacy X11 apps
  };

  ############################################################
  # DISPLAY MANAGER - GREETD (FOR HYPRLAND)
  ############################################################
  # greetd: Lightweight login manager
  # tuigreet: Terminal UI greeter (minimal, fast)
  # NOTE: Comment this out when testing other desktops below
  services.greetd = {
    enable = false;
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
    XCURSOR_THEME = "Adwaita";
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
    fzf                            # A very good listing tool for terminal
    wget                           # Download files
    curl                           # Transfer data with URLs
    btop                           # System monitor
    fastfetch                      # System info display
    tree                           # Directory structure viewer
    efibootmgr                     # EFI boot manager
    unrar                          # archive manager
    ttyper                         # Typing test like experience
    
    # =========== SYSTEM TOOLS ===========
    brightnessctl                  # Control screen brightness
    networkmanagerapplet           # Network manager system tray
    
    # =========== TERMINAL EMULATOR ===========
    ghostty                        # Modern GPU-accelerated terminal

    # =========== GAME SPECEFICS TWEAKS ===========
    vulkan-tools                   # tool for testing vulkan
    lutris                         # Open Source gaming platform for GNU/Linux
    protonup-qt                    # Install and manage Proton-GE and Luxtorpeda for Steam and Wine-GE for Lutris 

    # =========== The apps that I want to use ===========
    pomodoro-gtk                   # pomodoro app
    motrix                         # Download manager
    cava                           # Audio visualizer
    mpv                            # Video player
    
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
    libnotify                      # Send notifications from terminal
    swaynotificationcenter         # Notification demon for hyprland and my desktop
    
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
  # DESKTOP ENVIRONMENTS - EXPERIMENT AREA
  ############################################################
  # Uncomment desktops below to test them alongside Hyprland
  # HOW TO USE:
  #   1. Comment out the greetd section above (line 147-155)
  #   2. Uncomment services.xserver.enable and SDDM below
  #   3. Uncomment any desktop(s) you want to try
  #   4. Run: sudo nixos-rebuild switch
  #   5. SDDM will show all enabled desktops in session menu
  #
  # CONFLICTS TO AVOID:
  #   - Don't enable GNOME + Pantheon together (conflict)
  #   - Don't enable multiple display managers (choose one: greetd OR sddm OR gdm)
  #
  # Source: https://wiki.nixos.org/wiki/Category:Desktop_environment
  ############################################################

  # X Server (required for X11 desktops, enable when testing DEs)
 services.xserver.enable = true;
 services.xserver.xkb.layout = "us";  # Keyboard layout

  # Display Manager - SDDM (works with all DEs, uncomment when testing)
   services.displayManager.gdm.enable = true;

  # ===== WAYLAND DESKTOPS =====

  # KDE Plasma 6 (modern, feature-rich, Wayland/X11)
  # services.desktopManager.plasma6.enable = true;

  # GNOME (modern, clean, primarily Wayland)
  # services.xserver.desktopManager.gnome.enable = true;


  # COSMIC (PopOS new DE - experimental, requires flakes)
  # Currently not in stable NixOS 25.11
  # services.desktopManager.cosmic.enable = true;

  # ===== X11 DESKTOPS (LIGHTWEIGHT) =====

  # XFCE (lightweight, stable, Windows-like - RECOMMENDED for 4GB RAM)
  # services.xserver.desktopManager.xfce.enable = true;

  # LXQt (ultra-lightweight Qt-based)
  # services.xserver.desktopManager.lxqt.enable = true;

  # MATE (classic GNOME 2 fork, lightweight)
  # services.xserver.desktopManager.mate.enable = true;


  # ===== X11 DESKTOPS (MODERN) =====

  # Cinnamon (Linux Mint default, Windows-like)
  # services.xserver.desktopManager.cinnamon.enable = true;

  # Budgie (modern, elegant, similar to GNOME)
  # services.xserver.desktopManager.budgie.enable = true;


  # Pantheon (elementary OS default, macOS-like)
  # WARNING: Conflicts with GNOME! Don't enable both.
  # services.xserver.desktopManager.pantheon.enable = true;




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
# TESTING DESKTOPS:
#
# (recommended first):
#   1. Comment out greetd section (lines 147-155)
#   2. Uncomment: services.xserver.enable (line 522)
#   3. Uncomment: services.displayManager.sddm.enable (line 526)
#   4. Uncomment: services.xserver.desktopManager.xfce.enable (line 545)
#   5. sudo nixos-rebuild switch
#   6. SDDM will show: Hyprland + XFCE in session menu
#
# ============================================================


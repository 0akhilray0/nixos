# ============================================================
# NixOS System Configuration - FINAL VERSION
# ============================================================
# Hostname  : bleach
# User      : akhil
# Desktop   : Niri (Wayland compositor)
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
  # CPU CLOCK SPEED CHANGE FROM HERE 
  ############################################################
  powerManagement.cpuFreqGovernor = "performance";

  services.tlp.enable = true;
  services.tlp.settings.CPU_SCALING_GOVERNOR_ON_AC = "performance";
  services.tlp.settings.CPU_SCALING_GOVERNOR_ON_BAT = "performance";
  services.tlp.settings.CPU_BOOST_ON_AC = 1;
  services.tlp.settings.CPU_BOOST_ON_BAT = 1;
  services.tlp.settings.CPU_HWP_DYN_BOOST_ON_AC = 1;
  services.tlp.settings.CPU_HWP_DYN_BOOST_ON_BAT = 1;

  programs.gamemode.enable = true;

  # Udev things i dont know what is this thing but for controller support i am adding it
  services.udev.packages = [ pkgs.game-devices-udev-rules ];

  # STEAM CONTROLLER SUPPORT
  hardware.steam-hardware.enable = true;


  ############################################################
  # STORAGE & FILESYSTEM SUPPORT
  ############################################################
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.devmon.enable = true;
  
  # Expanded filesystem support
  boot.supportedFilesystems = [ "ntfs-3g" "exfat" "btrfs"];


  ############################################################
  # BOOTLOADER
  ############################################################
  # Using systemd-boot with UEFI support
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 1;          # The timeout belongs here!
  
  
  boot.loader.grub = {
    enable = false;
    efiSupport = true;      # CRITICAL: Tells GRUB you are on a modern UEFI system
    theme = pkgs.catppuccin-grub;  # Grub theme
    device = "nodev";       # CRITICAL: Skips the legacy BIOS/MBR installation step
    # useOSProber = true;   # Uncomment this line if you are dual-booting Windows!
    # MAGIC BLOCK TO BOOT THE ARCH ISO INTO RAM
   };
  
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  ############################################################
  # KERNAL TO USE 
  ############################################################

  # 1. This tells the bootloader to ACTUALLY RUN the Zen kernel and its drivers
  boot.kernelPackages = pkgs.linuxPackages_zen;
  

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
    theme = "hexagon_dots";          # Active theme name
    themePackages = with pkgs; [
      (adi1090x-plymouth-themes.override {
        selected_themes = [ "hexagon_dots" ];  # Only download these themes
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
    hostName = "BLEACH";           # Your computer's name on network
    networkmanager.enable = true;  # GUI for WiFi/Ethernet management
  };

  ############################################################
  # BLUETOOTH
  ############################################################
  hardware.bluetooth = {
    enable = true;                 # Enable Bluetooth support
    powerOnBoot = true;            # Turn on Bluetooth on startup
    settings = {
      General = {
        Experimental = true;       # Enables extra features like battery reporting
      };
    };
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
  # NIRI - PRIMARY DESKTOP (ALWAYS ENABLED)
  ############################################################
  # Niri: Scrollable-tiling Wayland compositor
  # This is your main daily driver desktop environment
  programs.niri.enable = true;

 
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
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "niri.service" ]; # Attach directly to niri startup
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
      "input"
    ];
    
    # User-specific packages
    packages = with pkgs; [ 
      tree                         # Directory tree viewer
    ];
  };

  ############################################################
  # Pasword Feedback
  ############################################################
  security.sudo.extraConfig = ''Defaults pwfeedback'';

  ############################################################
  # ENVIRONMENT VARIABLES
  ############################################################
  # Set for ALL users at login
  environment.sessionVariables = {
    # Cursor theme settings (MUST be environment variables for Wayland)
    
    # Tell Electron/Chromium apps to use Wayland
    # Affects: VS Code, Discord, Slack, Chrome, etc.
    NIXOS_OZONE_WL = "1";
    
    # Default terminal emulator
    # This tells all apps (Thunar, Yazi, etc.) to use Ghostty
    TERMINAL = "kitty";
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
      nerd-fonts.jetbrains-mono    # JetBrains Mono with icons
      
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
    neovim                                                                      # Modern Vim (text editor)
    fzf                                                                         # A very good listing tool for terminal
    wget                                                                        # Download files
    curl                                                                        # Transfer data with URLs
    btop                                                                        # System monitor
    gdu                                                                         # Very Usefull storage utility
    fastfetch                                                                   # System info display
    tree                                                                        # Directory structure viewer
    efibootmgr                                                                  # EFI boot manager
    unrar                                                                       # archive manager
    terminal-typeracer                                                          # Typing test like experience
    grim                                                                        # Pictures
    bluez                                                                       # for bluetooth
    bluez-tools                                                                 # for Bluetooth
    slurp                                                                       # Screenshots
    imagemagick                                                                 # Something RELATED TO IMAGEING NEEDED TO SHOW FETCH IMAGE
    matugen                                                                     # Colors Generater Material U
    pywal16                                                                     # Colors GEnerater 
    pywalfox-native                                                             # Color changing browser
    config.boot.kernelPackages.cpupower                                         # Cpupower 

    # =========== SYSTEM TOOLS ===========
    brightnessctl                  # Control screen brightness
    gammastep                      # night mode
    networkmanagerapplet           # Network manager system tray
    
    # =========== TERMINAL EMULATOR ===========
    kitty                        # Modern GPU-accelerated terminal

    # =========== GAME SPECEFICS TWEAKS ===========
    xwayland-satellite         
    lutris
    protonup-qt
    mangohud
    motrix


    # =========== The apps that I want to use ===========
    cava                           # Audio visualizer
    mpv                            # Video player
    telegram-desktop               # Desktop Telegram Client
    evince                         # PDF VIEWER
    
    
    # =========== GTK THEMES ===========
    # These control the appearance of windows/buttons/menus
    adw-gtk3                       # Adwaita GTK3 theme
    
    # =========== ICON THEMES ===========
    # These control how file/folder icons look
    whitesur-icon-theme            # MacOS Big Sur style icon theme for Linux desktops

    # =========== CURSOR THEMES ===========
    bibata-cursors                    # Simple, clean cursor
    
    # =========== THEME MANAGER ===========
    nwg-look                       # GTK theme switcher (GUI)
    
    # =========== AUTHENTICATION ===========
    polkit_gnome                   # GUI password prompts for polkit
    
    # =========== WAYLAND TOOLS ===========
    waybar                         # Status bar
    rofi                           # Application launcher
    swww                           # Animated wallpaper daemon
    yazi                           # Terminal file manager
    wl-clipboard                   # Clipboard for Wayland

    # =========== SCREENSHOT TOOLS ===========
    grim                           # Screenshot tool
    slurp                          # Region selector
    # Usage: grim -g "$(slurp)" screenshot.png
    
    # =========== NOTIFICATIONS ===========
    libnotify                      # Send notifications from terminal
    swaynotificationcenter         # Notification demon for Niri and my desktop
    
    # =========== FILE MANAGER ===========
    exfatprogs                     # Essential for exFAT SD cards and USBs
    nemo                           # File Manager
    gparted                        # Disk handing 

   
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
  # FLATPAK SUPPORT
  ############################################################
  #services.flatpak.enable = true;


  ############################################################
  # APP IMAGES
  ############################################################
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = [ pkgs.fuse2 ];

  ############################################################
  # GITHUB CONFIGURATION
  ############################################################
  programs.git.enable = true;
  programs.git.config.user.name = "0akhilray0";
  programs.git.config.user.email = "0akhilray0@gmail.com";
  programs.git.config.credential.helper = "store"; 
  


  


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
    options = "--delete-older-than 5d";  # Keep last 30 days
  };

  ############################################################
  # DESKTOP ENVIRONMENTS - EXPERIMENT AREA
  ############################################################
  # Uncomment desktops below to test them alongside Niri
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

  # Display Manager - Ly
  services.displayManager.gdm.enable = true;
#  services.displayManager.ly.settings = {
#    animation = "none";
#    battery_id = "BAT0";
#    bigclock = "en";
#    blank_box = false;
#    bigclock_12hr = true;
#    clear_password = true;
#    hide_key_hints = false;
#    bigclock_seconds = true;
#
#  };

  # THE CORRECT NIXOS WAY TO AUTO-LOGIN
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "akhil";

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

# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];
  #GRUB
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
  };
  nixpkgs.config.allowUnfree = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.useOSProber = true;
  #bootloader,wifi
  boot.loader.systemd-boot.enable = false;
  boot.blacklistedKernelModules = [ "bitland_mifs_wmi" ];
  hardware.enableRedistributableFirmware = true;
  boot.kernelPackages = pkgs.linuxPackages_zen;
  hardware.firmware = [ pkgs.linux-firmware ];
  #networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;
  #time
  time.timeZone = "Asia/Shanghai";
  networking.nameservers = [ "114.114.114.114" "8.8.8.8" ];
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-gtk
      ];
    };
  };  
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = " ";
    };
  };
  # 登录管理器改用 greetd + noctalia-greeter(见 noctalia-umbriel.nix)
  # services.displayManager.gdm.enable = true;
  services.desktopManager = {
    gnome.enable = true;
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # print documents.
  services.printing.enable = true;

  # sound.
 # services.pulseaudio.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  #user

  users.users.demo = {
    isNormalUser = true;
    description = "lingxi";
    extraGroups = [ "networkManager" "wheel" ];
    packages = with pkgs; [
       thunderbird
    ];
  };

  # touchpad support
  services.libinput.enable = true;

  #packages
  programs.firefox.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  environment.systemPackages = with pkgs; [
    vim 
    wget
    git
    curl
    htop
    fastfetch
    pciutils
    opencode
    gnomeExtensions.kimpanel
    neovim
    qq
    nodejs
    go
    pacman
    cc-switch
    codex
    lutris
    vscodium
    ncspot
    go-musicfox
    gnome-tweaks
    pnpm
    uv
    python3
    go
    conda
    jetbrains.idea
    openjdk17
    kotlin
    kotlin-native
  ];
  programs.clash-verge = {
    enable = true;
    package = pkgs.clash-verge-rev;
    serviceMode = true;
    autoStart = true;
  };
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # OpenSSH daemon.
  services.linyaps.enable = true;
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  nix.settings.experimental-features = [
    "nix-command" 
    "flakes" 
  ];
  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ]; 
  system.stateVersion = "26.05"; # Did you read the comment?

}


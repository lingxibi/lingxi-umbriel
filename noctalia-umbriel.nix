# Umbriel compositor + Noctalia shell 集成模块
# 经 GDM 登录时选择 "Umbriel" 会话;GNOME 保留可用。
{ pkgs, inputs, lib, ... }:

{
  imports = [
    inputs.noctalia.nixosModules.default
    inputs.umbriel.nixosModules.default
    inputs.noctalia-greeter.nixosModules.default
  ];

  # 主机名供 flake 按名定位这台机器
  networking.hostName = lib.mkDefault "nixos";

  programs.noctalia = {
    enable = true;
    # 用 nixpkgs 缓存二进制,避免本地编译
    package = pkgs.noctalia;
    recommendedServices.enable = true; # NetworkManager/蓝牙/UPower 供 Noctalia 面板用
  };

  programs.umbriel = {
    enable = true;
    package = pkgs.umbriel;
    portalPackage = pkgs.xdg-desktop-portal-umbriel;
  };

  # 登录管理器:greetd + Noctalia Greeter(与 Shell 同风格)
  programs.noctalia-greeter = {
    enable = true;
    package = pkgs.noctalia-greeter;
    settings = {
      # 默认进 Umbriel 会话
      session.default = "Umbriel";
      cursor.theme = "Bibata-Modern-Ice";
      cursor.size = 24;
    };
  };

  # Umbriel 默认配置里的 `spawn:kitty` 与 Xwayland 依赖
  # mpvpaper/mpv/ffmpeg: Noctalia 视频壁纸插件依赖
  environment.systemPackages = with pkgs; [
    kitty
    xwayland-satellite
    mpvpaper
    mpv
    ffmpeg
    bibata-cursors   # 光标主题
  ];

  # Noctalia 默认字体
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  # 光标主题(Bibata 现代冰蓝,全局含 X11 应用)
  environment.variables.XCURSOR_THEME = "Bibata-Modern-Ice";
  environment.variables.XCURSOR_SIZE = "24";

  # 系统级默认配置(对所有用户生效,低于 ~/.config)
  environment.etc."xdg/umbriel/config.toml".source = ./umbriel.toml;
  environment.etc."xdg/noctalia/config.toml".source = ./noctalia.toml;
}

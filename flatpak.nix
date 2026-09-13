# Flatpak 支持 + flathub 源
# 用户级(--user)的 flathub 源由 pkgs 脚本首次使用时自动添加
{ pkgs, ... }: {
  services.flatpak.enable = true;

  # 系统级 flathub 源(幂等)
  system.activationScripts.flatpak-flathub.text = ''
    ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
  '';
}

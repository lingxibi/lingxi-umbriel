# pkgs — nixpkgs + flatpak 双源搜索/交互安装工具,脚本见 scripts/pkgs.sh
{ pkgs, ... }: {
  environment.systemPackages = [
    pkgs.jq
    (pkgs.writeShellScriptBin "pkgs" (builtins.readFile ./scripts/pkgs.sh))
  ];
}

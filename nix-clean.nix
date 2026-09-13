# nix-clean 清理工具(全局/分步),脚本见 scripts/nix-clean.sh
{ pkgs, ... }: {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nix-clean" (builtins.readFile ./scripts/nix-clean.sh))
  ];
}

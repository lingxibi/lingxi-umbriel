#!/usr/bin/env bash
# pkgs — nixpkgs + flathub 双源搜索,flatpak 交互式安装
# 用法:
#   pkgs <关键词>      双源搜索:nix 仅按包名匹配,给出声明式写法(手动写入);flatpak 可交互安装
#   pkgs -n <关键词>   只搜 nixpkgs(按包名)
#   pkgs -f <关键词>   只搜 flathub(可交互安装)
#   pkgs list          列出已装(nix profile + flatpak)
#   pkgs rm            交互卸载
#   pkgs update        更新 nix profile + flatpak
# 说明:nix 包不自动安装——nix profile 对 unfree 包(如 wpsoffice-cn)校验无法通过,
#      请按提示手动写入声明配置(environment.systemPackages)后 nixos-rebuild。

set -uo pipefail

B='\033[1;34m'; G='\033[1;32m'; Y='\033[1;33m'; RD='\033[1;31m'; R='\033[0m'
say()  { printf "${B}==>${R} %s\n" "$*"; }
ok()   { printf " ${G}✓${R} %s\n" "$*"; }
warn() { printf " ${Y}!${R} %s\n" "$*"; }
die()  { printf " ${RD}✗${R} %s\n" "$*"; exit 1; }

command -v nix    >/dev/null || die "缺少 nix"
command -v jq     >/dev/null || die "缺少 jq"
command -v flatpak >/dev/null || die "未启用 flatpak(flatpak.nix)"

FLATHUB_REPO="https://flathub.org/repo/flathub.flatpakrepo"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

usage() { sed -n '3,10p' "$0" | sed 's/^# \{0,1\}//'; }

ensure_user_remote() {
  flatpak remotes --user 2>/dev/null | grep -q flathub \
    || flatpak remote-add --if-not-exists --user flathub "$FLATHUB_REPO"
}

# 搜索结果写入 TSV: nix   |attr    |version|desc
#                   flatpak|appid  |version|branch|remote|desc
search_nix() {
  say "搜索 nixpkgs 包名「$1」(首次较慢,之后有缓存)..."
  # 只保留包名(attr/pname)包含关键词的结果,过滤描述误命中
  nix search nixpkgs "$1" --json 2>/dev/null \
    | jq -r --arg q "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" '
        to_entries[]
        | select(
            (.key | split(".") | last | ascii_downcase | contains($q))
            or ((.value.pname // "") | ascii_downcase | contains($q)))
        | [(.key | split(".") | last),
           (.value.version // "?"),
           ((.value.description // "") | split("\n")[0] | .[0:64])]
        | @tsv' \
    | awk -v OFS='\t' '{print "nix", $0}' > "$TMP/nix.tsv" || true
}

search_flatpak() {
  say "搜索 flathub「$1」..."
  ensure_user_remote
  flatpak search "$1" --columns=application,version,branch,remotes,description 2>/dev/null \
    | awk -F'\t' -v OFS='\t' '{print "flatpak", $0}' > "$TMP/flat.tsv" || true
}

pick_install() { # $1=关键词 $2=both|nix|flatpak
  local q="$1" src="$2"
  : > "$TMP/all.tsv"
  [ "$src" = nix -o "$src" = both ] && { search_nix "$q"; cat "$TMP/nix.tsv" >> "$TMP/all.tsv"; }
  [ "$src" = flatpak -o "$src" = both ] && { search_flatpak "$q"; cat "$TMP/flat.tsv" >> "$TMP/all.tsv"; }

  local total; total=$(wc -l < "$TMP/all.tsv")
  [ "$total" -eq 0 ] && { warn "无结果"; return; }

  echo
  local i=0 tag a b c d e
  while IFS=$'\t' read -r tag a b c d e; do
    i=$((i+1))
    if [ "$tag" = nix ]; then
      printf "%3d) [N] %-26s %-14s %s\n" "$i" "$a" "$b" "$c"
    else
      printf "%3d) [F] %-40s %-9s %s\n" "$i" "$a" "$d" "$e"
    fi
  done < "$TMP/all.tsv"
  printf "    ${Y}[N]=nixpkgs 仅按包名匹配,选中后给声明式写法;[F]=flathub 交互安装${R}\n"

  local picks
  echo
  read -r -p "输入编号(多个用空格分隔,回车退出): " picks
  [ -z "$picks" ] && return
  local p line
  for p in $picks; do
    line=$(sed -n "${p}p" "$TMP/all.tsv"); [ -z "$line" ] && continue
    IFS=$'\t' read -r tag a b c d e <<< "$line"
    if [ "$tag" = nix ]; then
      # nix profile 对 unfree 包校验无法通过,改为给声明式写法手动写入
      echo
      printf "  ${Y}请手动写入声明配置${R}(如 /etc/nixos/noctalia-umbriel.nix 的 environment.systemPackages):\n"
      printf "      %s\n" "$a"
      printf "  防止非开源软件校验无法通过;写入后执行 nixos-rebuild switch --flake /etc/nixos#nixos\n"
    else
      say "flatpak install --user $d $a"
      flatpak install --user -y "$d" "$a" && ok "$a 已安装(flatpak 用户级)"
    fi
  done
}

cmd_list() {
  say "Nix 用户 profile:"
  nix profile list 2>/dev/null | grep '^Name:' | sed 's/^Name: */  - /' || echo "  (空)"
  say "Flatpak 应用(--user):"
  flatpak list --app --user --columns=application,version 2>/dev/null | sed 's/^/  - /' || echo "  (空)"
  say "Flatpak 应用(--system):"
  flatpak list --app --system --columns=application,version 2>/dev/null | sed 's/^/  - /' || echo "  (空)"
}

cmd_rm() {
  : > "$TMP/inst.tsv"
  while IFS= read -r l; do echo "nix"$'\t'"$l" >> "$TMP/inst.tsv"; done \
    < <(nix profile list 2>/dev/null | grep '^Name:' | sed 's/^Name: *//')
  ensure_user_remote
  while IFS=$'\t' read -r app ver; do
    [ -n "$app" ] && echo "flatpak-user"$'\t'"$app" >> "$TMP/inst.tsv"
  done < <(flatpak list --app --user --columns=application,version 2>/dev/null)
  while IFS=$'\t' read -r app ver; do
    [ -n "$app" ] && echo "flatpak-system"$'\t'"$app" >> "$TMP/inst.tsv"
  done < <(flatpak list --app --system --columns=application,version 2>/dev/null)

  local total; total=$(wc -l < "$TMP/inst.tsv")
  [ "$total" -eq 0 ] && { warn "没有可卸载的包"; return; }
  echo
  local i=0 tag a
  while IFS=$'\t' read -r tag a; do
    i=$((i+1)); printf "%3d) %-14s %s\n" "$i" "[$tag]" "$a"
  done < "$TMP/inst.tsv"

  local pick
  echo
  read -r -p "输入要卸载的编号(回车退出): " pick
  [ -z "$pick" ] && return
  local line; line=$(sed -n "${pick}p" "$TMP/inst.tsv"); [ -z "$line" ] && { warn "无效编号"; return; }
  IFS=$'\t' read -r tag a <<< "$line"
  read -r -p "确认卸载 $a ? [y/N] " c
  [[ "$c" =~ ^[Yy] ]] || return
  case "$tag" in
    nix)            nix profile remove "$a"          && ok "$a 已卸载" ;;
    flatpak-user)   flatpak uninstall --user -y "$a"  && ok "$a 已卸载(user)" ;;
    flatpak-system) sudo flatpak uninstall -y "$a"    && ok "$a 已卸载(system)" ;;
  esac
}

cmd_update() {
  say "更新 nix 用户 profile..."
  nix profile upgrade '.*' 2>/dev/null && ok "nix profile 已更新"
  ensure_user_remote
  say "更新 flatpak 用户级..."
  flatpak update --user -y 2>&1 | tail -2 && ok "flatpak(user) 已更新"
  say "更新 flatpak 系统级(需 sudo)..."
  sudo flatpak update -y 2>&1 | tail -2 && ok "flatpak(system) 已更新"
}

case "${1:-}" in
  "")            usage ;;
  -h|--help)     usage ;;
  list)          cmd_list ;;
  rm|remove)     cmd_rm ;;
  update|up)     cmd_update ;;
  -n) [ -n "${2:-}" ] || die "缺少关键词"; pick_install "$2" nix ;;
  -f) [ -n "${2:-}" ] || die "缺少关键词"; pick_install "$2" flatpak ;;
  -*)            die "未知选项 $1" ;;
  *)             pick_install "$1" both ;;
esac

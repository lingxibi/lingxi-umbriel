#!/usr/bin/env bash
# nix-clean — NixOS 清理工具:全局清理 / 分步清理 / 磁盘报告
# 用法:
#   nix-clean              交互菜单
#   nix-clean all          全部清理(不含去重)
#   nix-clean gens         只清旧 generations
#   nix-clean gc           只跑 Nix 垃圾回收
#   nix-clean journal      只压缩系统日志
#   nix-clean caches       只清用户可再生缓存
#   nix-clean flatpak      只清 Flatpak 未用运行时
#   nix-clean optimise     Store 去重(慢)
#   nix-clean report       只看磁盘占用报告
# 环境变量: KEEP_DAYS=14(保留天数) JOURNAL_DAYS=14 JOURNAL_SIZE=500M

set -uo pipefail

B='\033[1;34m'; G='\033[1;32m'; Y='\033[1;33m'; RD='\033[1;31m'; R='\033[0m'
say()  { printf "${B}==>${R} %s\n" "$*"; }
ok()   { printf " ${G}✓${R} %s\n" "$*"; }
warn() { printf " ${Y}!${R} %s\n" "$*"; }
die()  { printf " ${RD}✗${R} %s\n" "$*"; exit 1; }

command -v nix-collect-garbage >/dev/null || die "这不是 NixOS?"
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"
nix_do() { if [ -z "$SUDO" ]; then "$@"; else "$SUDO" "$@"; fi; }

KEEP_DAYS="${KEEP_DAYS:-14}"
JOURNAL_DAYS="${JOURNAL_DAYS:-14}"
JOURNAL_SIZE="${JOURNAL_SIZE:-500M}"

usage() { sed -n '3,14p' "$0" | sed 's/^# \{0,2\}//'; }
confirm() { read -r -p "确认执行? [y/N] " a; [[ "$a" =~ ^[Yy] ]]; }

# ── ① 旧 generations ─────────────────────────────────────────────
step_generations() {
  say "删除 ${KEEP_DAYS} 天前的系统 generations(可回滚的旧系统)"
  nix_do nix-env -p /nix/var/nix/profiles/system \
    --delete-generations-old-than "${KEEP_DAYS}d" 2>/dev/null \
    || warn "系统 generations 清理失败(忽略)"
  if [ -e /nix/var/nix/profiles/per-user/root/channels ]; then
    nix_do nix-env -p /nix/var/nix/profiles/per-user/root/channels \
      --delete-generations-old-than "${KEEP_DAYS}d" 2>/dev/null || true
  fi
  ok "generations 清理完成"
}

# ── ② 垃圾回收 ───────────────────────────────────────────────────
step_gc() {
  say "Nix 垃圾回收(root 执行,覆盖所有用户 profile,耗时视 store 大小)"
  nix_do nix-collect-garbage --delete-older-than "${KEEP_DAYS}d"
  ok "垃圾回收完成"
}

# ── ③ 日志压缩 ───────────────────────────────────────────────────
step_journal() {
  say "压缩系统日志(保留 ${JOURNAL_DAYS} 天 / 上限 ${JOURNAL_SIZE})"
  nix_do journalctl --vacuum-time="${JOURNAL_DAYS}d" --vacuum-size="${JOURNAL_SIZE}" 2>&1 | tail -1
  ok "日志压缩完成"
}

# ── ④ 用户缓存(可再生) ──────────────────────────────────────────
step_caches() {
  say "清理用户可再生缓存(缩略图/着色器/字体缓存,删后首次启动略慢)"
  local total=0 home rel p sz
  for home in /home/*; do
    [ -d "$home" ] || continue
    for rel in .cache/thumbnails .cache/mesa_shader_cache .cache/mesa_shader_cache_db .cache/fontconfig; do
      p="$home/$rel"
      if [ -d "$p" ]; then
        sz=$(du -sm "$p" 2>/dev/null | cut -f1) || sz=0
        rm -rf "$p" && total=$((total + sz))
      fi
    done
  done
  ok "缓存清理完成,约释放 ${total} MiB"
}

# ── ⑤ Flatpak ────────────────────────────────────────────────────
step_flatpak() {
  command -v flatpak >/dev/null || { warn "未安装 flatpak,跳过"; return 0; }
  say "卸载 Flatpak 未引用运行时"
  nix_do flatpak uninstall --unused --noninteractive 2>&1 | grep -v "^$" | tail -3 || true
  ok "Flatpak 清理完成"
}

# ── ⑥ Store 去重 ─────────────────────────────────────────────────
step_optimise() {
  say "Store 硬链接去重(大 store 会较久,可随时 Ctrl+C)"
  nix_do nix store optimise
  ok "去重完成"
}

# ── ⑦ 报告 ───────────────────────────────────────────────────────
step_report() {
  say "磁盘占用报告"
  df -h / /nix 2>/dev/null | sed 's/^/    /'
  local store_sz=""
  store_sz=$(timeout 60 du -sh /nix/store 2>/dev/null | cut -f1) || true
  [ -n "$store_sz" ] && printf "    /nix/store 总大小: %s\n" "$store_sz"
  printf "    系统保留 generations: %s 个\n" \
    "$(ls -d /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l)"
  nix_do journalctl --disk-usage 2>/dev/null | sed 's/^/    /' || true
  ok "报告完成"
}

# ── 菜单 ─────────────────────────────────────────────────────────
menu() {
  while true; do
    echo
    printf "${B} NixOS 清理工具${R}  %s\n" "$(date '+%F %T')"
    PS3="选择操作 (0 退出): "
    select opt in \
      "全部清理(①~⑤+报告)" \
      "① 清理旧 generations" \
      "② Nix 垃圾回收" \
      "③ 压缩系统日志" \
      "④ 清理用户缓存" \
      "⑤ Flatpak 未用运行时" \
      "⑥ Store 去重(慢)" \
      "⑦ 磁盘占用报告"
    do
      case "$REPLY" in
        0) exit 0 ;;
        1) confirm && { step_generations; step_gc; step_journal; step_caches; step_flatpak; step_report; } ;;
        2) step_generations ;;
        3) step_gc ;;
        4) step_journal ;;
        5) step_caches ;;
        6) step_flatpak ;;
        7) step_optimise ;;
        8) step_report ;;
        *) warn "无效选项" ;;
      esac
      break
    done
  done
}

case "${1:-menu}" in
  all)               step_generations; step_gc; step_journal; step_caches; step_flatpak; step_report ;;
  gens|generations)  step_generations ;;
  gc)                step_gc ;;
  journal)           step_journal ;;
  caches)            step_caches ;;
  flatpak)           step_flatpak ;;
  optimise)          step_optimise ;;
  report)            step_report ;;
  menu)              menu ;;
  -h|--help|help)    usage ;;
  *)                 usage; exit 1 ;;
esac

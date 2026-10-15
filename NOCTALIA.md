# 0.2版本更新内容
--- --- 
# Lavender 顶栏

键位调整见 [KEYBINDINGS.md](./KEYBINDINGS.md)。

适用 Noctalia v5；主配置为 `noctalia.toml`，由 `noctalia-umbriel.nix` 安装。

- Catppuccin 深色底、淡紫强调、半透明背景、细边框、16px 圆角。
- 顶栏高 40px，顶部留白 10px，左右留白 12px。
- 左侧：启动器、数字工作区、音乐（无播放器时隐藏）。
- 中间：月/日与 24 小时时钟。
- 右侧：托盘、隐私状态、网络、蓝牙、音量、电池、通知、控制中心。
- 模糊效果使用 `umbriel.toml` 中已有的 Noctalia layer rule。

## 更新

- **覆盖原文件并building即可**：
    重启后用户 tmpfiles 规则会在用户目录中创建
    `~/.config/noctalia/config.toml` 到 `/etc/xdg/noctalia/config.toml` 的链接。
    已有同名文件会保留；若已有配置，请手动合并本文件中的 `[bar]`、
    `[bar.default]`、`[widget.*]` 以及主题设置。

---

实际主机的完整配置位于 `/etc/nixos`，请在该目录执行重建。
应使用目标主机现有的 `configuration.nix` 和硬件配置，不要用其他机器的文件代替。
配置更新后需重建系统才能更新 `/etc/xdg` 中的文件。

Noctalia GUI 的覆盖项位于 `~/.local/state/noctalia/settings.toml`，优先级高于
手写配置。如果样式没有变化，检查其中的主题、bar 与 widget 覆盖项，备份后按需移除。

## 微调与校验

- 更紧凑：将 `thickness` 改成 `36`，`margin_edge` 改成 `8`。
- 更通透：将 `background_opacity` 改成 `0.85`。
- 小屏幕：从 `start` 中移除 `media`，或从 `end` 中移除 `bluetooth`；蓝牙仍可在控制中心管理。
- 修改主色：搜索 `#CBA6F7`；当前为 Catppuccin 的淡紫色。

```sh
noctalia config validate ./noctalia.toml
```

经测试 Noctalia v5.0.1 的配置校验和 Nix 模块语法解析正常。

Umbriel 的阴影颜色已迁移到 `[colors] shadow`，修复旧的
`appearance.shadow.color` 未知字段警告；颜色仍为 `#0000007F`。

参考：[Bar 配置](https://docs.noctalia.dev/noctalia/bar/)、
[配置加载与覆盖规则](https://docs.noctalia.dev/noctalia/configuration/)。

# Umbriel 键位

`Mod` 固定为 **Super / Win**。配置位于 `umbriel.toml` 的 `[keybinds]`。

| 按键 | 操作 |
| --- | --- |
| Super+K / Super+Enter | 打开 Kitty 终端 |
| Super+Z | Noctalia 启动器 |
| Super+W | 视频壁纸插件选择器（需要启用 mpvpaper 插件） |
| Super+O | 工作区总览 |
| Super+方向键 | 移动焦点 |
| Alt+Tab / Alt+Shift+Tab | 按布局顺序聚焦下一个 / 上一个窗口 |
| Super+Shift+左右 | 左右移动整列（内置） |
| Super+Shift+上下 | 在列内移动窗口（内置） |
| Super+1…9 | 切换工作区（内置） |
| Super+Shift+1…9 | 移动窗口到工作区（内置） |
| Super+PageUp / PageDown | 上一个 / 下一个工作区 |
| Super+Shift+PageUp / PageDown | 移动窗口到相邻工作区 |
| Super+T | 浮动 / 平铺 |
| Super+Shift+T | 在浮动与平铺窗口之间切换焦点 |
| Super+Ctrl+T | 切换布局 |
| Super+F | 全屏（内置） |
| Super+M | 最大化至屏幕边缘 |
| Super+Q | 关闭当前窗口 |
| Super+P | 置顶切换 |
| Super+S | 显示 / 隐藏暂存窗口 |
| Super+Shift+S | 将当前窗口放入暂存区 |
| Super+Ctrl+S | 将暂存窗口恢复原位 |
| Super+Tab | 切换暂存区窗口 |
| Super+Ctrl+L | 锁屏 |
| Super+F2 | 键位速查表 |
| Super+Ctrl+R | 重载 Umbriel 配置 |
| Print / Shift+Print | 区域截图 / 当前显示器截图 |
| 音量、静音、麦克风静音键 | Noctalia 音频控制 |
| 播放、暂停、上一曲、下一曲键 | Noctalia 媒体控制 |
| 亮度增减键 | 调整当前显示器亮度 |

## 键位修复

- Fcitx5 的输入法组切换使用 `Super+Space` 和 `Super+Shift+Space`。
  原来的暂存区绑定会抢走这两个组合键，现已移到 `Super+S` 一组。
  Fcitx5 原有的 Shift 中英文切换等设置保留。
- 原有 `Super+K` 覆盖内置的向上聚焦；保留终端习惯，使用 `Super+Up` 向上聚焦，
  另补 `Super+Enter` 终端入口。
- 恢复当前安装版本支持的 `window-focus-switch-floating`，移除“已移除动作”的过时注释。
- 音量、亮度与媒体键原来全部被注释，现通过 Noctalia IPC 启用，无需新增 playerctl。
- 启动、关闭、切换类动作禁止按住连发；音量、亮度和方向导航仍可长按。

实体机 `umbriel validate` 验证，Noctalia IPC 名称和媒体子命令已对照本机帮助。
未实际触发锁屏、截图、音量等操作，也未构建或切换系统。
Fn 是否需要按住取决于笔记本 Fn Lock；本配置接收系统发出的 XF86 功能键。
目前台式机器并无测试结果，如果您在台式机使用出现问题请提交日志。

在 `/etc/nixos` 构建并切换系统后生效：

```sh
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

参考：[Umbriel 键位](https://docs.noctalia.dev/umbriel/keybinds/)。

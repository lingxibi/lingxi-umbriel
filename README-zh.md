# lingxi-umbriel

## 半自动式的umbriel美化配置

- *由于umbriel桌面合成器目前属于一个处于高速开发的测试阶段，本项目无法保证实时更进最新内容，请见谅*

---

## 安装

- **下载项目**：
 ``` git clone git@github.com:lingxibi/lingxi-umbriel ```

- **进入项目，拷贝到nixon文件夹**:
 ``` 
 sudo cp -a lingxi-umbriel/. /etc/nixos 
 ```
- *安装有风险，请备份后再进行拷贝*

- **构建*:
 ``` 
 sudo nix flake update 
 sudo nixos-rebuild-switch rebuild --flake /etc/nixos#nixos
 # 需重启
 sudo reboot
 ```
---

## 详情

**请查看NOCTALIA.md**


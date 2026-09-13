# fcitx5 输入法主题:Catppuccin Mocha 圆角 + 半透明底
{ pkgs, ... }:
let
  theme = "catppuccin-mocha-mauve";
  glass = pkgs.runCommand "catppuccin-fcitx5-glass" { } ''
    mkdir -p $out/share/fcitx5/themes/${theme}-glass
    cp -r ${pkgs.catppuccin-fcitx5}/share/fcitx5/themes/${theme}/* \
           $out/share/fcitx5/themes/${theme}-glass/
    cd $out/share/fcitx5/themes/${theme}-glass
    # 启用圆角 SVG 背景(panel.svg 为 rx=8 圆角矩形)
    sed -i 's|^# Image=panel.svg|Image=panel.svg|' theme.conf
    sed -i 's|^# Image=highlight.svg|Image=highlight.svg|' theme.conf
    sed -i 's|^Name=.*|Name=Catppuccin Mocha Mauve Glass|' theme.conf
    # SVG 底透光(78%),透出合成器模糊 → 毛玻璃
    sed -i 's|fill="#313244"|fill="#313244" fill-opacity="0.78"|' panel.svg
  '';
in
{
  # 主题包挂进 fcitx5 wrapper,主题自动可被发现
  i18n.inputMethod.fcitx5.addons = [ glass ];

  # classicui 配置(用户可在 ~/.config/fcitx5/conf/ 覆盖)
  environment.etc."xdg/fcitx5/conf/classicui.conf".text = ''
    Theme=${theme}-glass
    Font="Noto Sans CJK SC 12"
  '';
}

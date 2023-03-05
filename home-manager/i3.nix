{ pkgs, stable-packages, laptopScreenScale, homeManager, IDE }: with pkgs; let
  mod = "Mod4";
  workspace_pass = "workspace 6:pass; exec [ $(ps h -C keepassxc | wc -l) = 0 ] && ${keepassxc}/bin/keepassxc ~/web.kdbx";
  workspace_web = "workspace 7:web; exec [ $(ps h -C chromium | wc -l) = 0 ] && ${chromium}/bin/chromium";
  workspace_IDE = "workspace 8:IDE; exec [ $(ps aux | grep ${IDE.processName} | wc -l) -le 3 ] && ${IDE.configureCmd { inherit pkgs stable-packages; }}";
  workspace_term = "workspace 9:term; exec [ $(ps aux | grep xfce4-terminal | wc -l) -le 3 ] && ${xfce.xfce4-terminal}/bin/xfce4-terminal";
  changeBrightness = output: direction: "exec xrandr --output ${output} --brightness $(xrandr --verbose --current | grep ^${output} -A5 | tail -n1 | awk '{print $NF ${direction} 0.1}');";
in
{
  enable = true;
  config = {
    modifier = mod;

    window.titlebar = false;
    focus.followMouse = true;
    floating.modifier = "${mod}";

    keybindings = lib.mkOptionDefault {
      "${mod}+Return" = "exec ${xfce.xfce4-terminal}/bin/xfce4-terminal";
      "${mod}+d" = "exec ${dmenu}/bin/dmenu_run";
      "${mod}+v" = "exec ${lxqt.pavucontrol-qt}/bin/pavucontrol-qt";
      "${mod}+l" = "exec ${i3lock-fancy}/bin/i3lock-fancy -p -n -t \"\"";
      "--release ${mod}+c" = "exec ${imagemagick}/bin/import ~/screencap.png";

      "Control+Mod1+Right" = "workspace next";
      "Control+Mod1+Left" = "workspace prev";
      "Mod1+Tab" = "workspace next";
      "Mod1+Shift+Tab" = "workspace prev";

      "${mod}+6" = "${workspace_pass}";
      "${mod}+7" = "${workspace_web}";
      "${mod}+8" = "${workspace_IDE}";
      "${mod}+9" = "${workspace_term}";

      "${mod}+Shift+6" = "move container to workspace number 6:pass";
      "${mod}+Shift+7" = "move container to workspace number 7:web";
      "${mod}+Shift+8" = "move container to workspace number 8:IDE";
      "${mod}+Shift+9" = "move container to workspace number 9:term";

      "${mod}+plus" = (changeBrightness "eDP-1" "+") + (changeBrightness "HDMI-1" "+");
      "${mod}+minus" = (changeBrightness "eDP-1" "-") + (changeBrightness "HDMI-1" "-");
    };

    bars = [{
      position = "bottom";
      statusCommand = "${homeManager}/files/helper-bin/i3status-helper";
      fonts = {
        names = [ "monospace" ];
        size = 14.0;
      };
      # Disable mouse scrolling on status bar.
      extraConfig = ''
        bindsym button4 nop
        bindsym button5 nop
        bindsym button6 nop
        bindsym button7 nop
      '';
    }];
  };

  extraConfig = ''
    exec nix-shell -p acpi libnotify --run "${homeManager}/files/helper-bin/battery-check;"
    exec ${homeManager}/files/helper-bin/xrandr-auto-adjust ${laptopScreenScale};
    exec_always --no-startup-id ${dunst}/bin/dunst
    exec --no-startup-id i3-msg '${workspace_term}'
  '';
}

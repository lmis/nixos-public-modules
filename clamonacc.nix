{ excludedPaths }: ({ pkgs, ... }: {
  security.sudo.extraRules = [{
    users = [ "clamav" ];
    commands = [{
      command = "${pkgs.libnotify}/bin/notify-send";
      options = [ "SETENV" "NOPASSWD" ];
    }];
  }];

  systemd.services.clamonacc = {
    enable = true;
    description = "clamonacc";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.clamav}/bin/clamonacc --fdpass -wvF";
      KillMode = "process";
      Restart = "on-failure";
    };
    after = [ "clamav-daemon.service" ];
    wantedBy = [ "default.target" ];
  };

  services.clamav = {
    daemon = {
      enable = true;
      settings = {
        MaxThreads = "8";
        OnAccessIncludePath = [ "/home" "/mnt" "/run/mount" ];
        OnAccessExcludePath = excludedPaths;
        OnAccessPrevention = "yes";
        OnAccessExcludeUname = "clamav";
        VirusEvent =
          "for ADDRESS in /run/user/*;" +
          "do /run/wrappers/bin/sudo -u \"#\${ADDRESS#/run/user/}\" DBUS_SESSION_BUS_ADDRESS=\"unix:path=$ADDRESS/bus\" PATH=/usr/bin " +
          "${pkgs.libnotify}/bin/notify-send -i dialog-warning -u critical " +
          "\"VIRUS FOUND!\" \"$CLAM_VIRUSEVENT_VIRUSNAME in $CLAM_VIRUSEVENT_FILENAME\";" +
          "done;";
      };
    };
    updater.enable = true;
  };
})

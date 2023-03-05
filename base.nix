{ luksDevice
, laptopScreenScale
, IDE
, git
, sources
, user
, useDualBootWindows ? false
, useChromeCast ? false
, useAutolock ? true
, useBluetooth ? false
, useTouchpad ? false
, useVim ? true
, useViReadlineEditingMode ? true
, useRedshift ? true
, extraChromeExtensions ? [ ]
, configureExtraBashConfig ? ({ ... }: "")
, configureExtraPackages ? ({ ... }: [ ])
,
}: ({ pkgs, ... }:
let
  stable-packages = import <nixos-22.11> { }; # sudo nix-channel --add https://nixos.org/channels/nixos-22.11
  home = "/home/${user}";
  localBin = "${home}/.local/bin";
  homeManager = "${home}/nixos/modules/home-manager";
in
{
  imports = [ <home-manager/nixos> ]; # sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager

  boot = {
    loader = {
      timeout = if useDualBootWindows then 3600 else 2;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    cleanTmpDir = true;

    # LVM on LUKS
    initrd.luks.devices.root = {
      device = luksDevice;
      preLVM = true;
    };

    # Use kernel v6.x to fix issue with sound stopping arbitrarily
    kernelPackages = pkgs.linuxPackages_latest;
  }
  // (if IDE.isIntelliJ then {
    kernel.sysctl = { "fs.inotify.max_user_watches" = "1048576"; };
  } else { });

  system.autoUpgrade = {
    enable = true;
    flags = [ "--upgrade-all" ];
  };

  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  powerManagement = {
    enable = true;
    scsiLinkPolicy = "max_performance";
  };

  console.keyMap = "us";
  i18n.defaultLocale = "en_DK.UTF-8";
  time = {
    timeZone = "Europe/Zurich";
    hardwareClockInLocalTime = useDualBootWindows;
  };
  location =
    if useRedshift then {
      # Zurich
      latitude = 47.3769;
      longitude = 8.5417;
    } else { };

  fonts.fonts = with pkgs; [
    fira-code
    fira-code-symbols
    ttf_bitstream_vera
    roboto
    open-sans
    noto-fonts-emoji
  ];

  sound.enable = true;
  hardware = {
    pulseaudio.enable = true;
    bluetooth.enable = useBluetooth;

    # Allow access to firmware of ultimate hacking keyboard
    keyboard.uhk.enable = true;
  };

  users.users.${user} = {
    inherit home;
    createHome = true;
    uid = 1000;
    isNormalUser = true;
    group = "users";
    extraGroups = [ "wheel" "docker" "video" "audio" "disk" "networkmanager" ];
  };

  programs = {
    nm-applet.enable = true;
    gnupg.agent.enable = true;
    ssh = {
      startAgent = true;
      extraConfig = "AddKeysToAgent yes";
    };
    chromium = {
      # Enable 'load media router component'. See https://github.com/NixOS/nixpkgs/issues/49630#issuecomment-622498732
      enable = true;
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      ] ++ extraChromeExtensions;
    };
  }
  // (if useVim then {
    vim.defaultEditor = true;
  } else { });

  home-manager.users.${user} = {
    programs = {
      git = import ./home-manager/git.nix { inherit pkgs stable-packages git homeManager; };
      bash = import ./home-manager/bash.nix { inherit pkgs stable-packages localBin sources homeManager configureExtraBashConfig; };
      readline = {
        enable = true;
        bindings = {
          "\\C-l" = "clear-screen";
          "\\C-p" = "history-search-backward";
          "\\C-n" = "history-search-forward";
          "\\C-x" = "glob-expand-word";
          "\\C-w" = "\"exit\\n\"";
          "\\t" = "menu-complete";
        };
        variables = {
          "completion-ignore-case" = true;
          "show-all-if-ambiguous" = true;
          "show-all-if-unmodified" = true;
          "menu-complete-display-prefix" = true;
          "show-mode-in-prompt" = true;
        }
        // (if useViReadlineEditingMode then {
          "editing-mode" = "vi";
          "vi-ins-mode-string" = "\\1\\e[5 q\\2"; # pipe
          "vi-cmd-mode-string" = "\\1\\e[2 q\\2"; # square
        } else { });
      };
    }
    // (if useVim then {
      neovim = import ./home-manager/neovim.nix { inherit pkgs stable-packages; };
    } else { });

    xsession.windowManager.i3 = import ./home-manager/i3.nix {
      inherit pkgs stable-packages laptopScreenScale homeManager IDE;
    };

    home = {
      stateVersion = "22.05";
      pointerCursor = {
        package = pkgs.gnome.gnome-themes-extra;
        size = 128;
        name = "Adwaita";
      };
      file = {
        ".ghc/ghci.conf".source = ./home-manager/files/ghci;
        ".config/i3status/config".source = ./home-manager/files/i3status;
        ".config/xfce4/terminal/terminalrc".source = ./home-manager/files/xfce4;
        ".ideavimrc".source = ./home-manager/files/ideavimrc;
      };
    };
  };

  nixpkgs.config.allowUnfree = true;
  environment = {
    systemPackages = with pkgs; [
      qrencode
      tree
      jq
      which
      unzip
      stable-packages.libreoffice
      adoptopenjdk-bin # jshell
      nodejs
      python3
      ghc
      go
      docker
      uhk-agent
      chromium # Needs to be installed systemwide or won't be used as default browser
      firefox
      meld # needs to be installed systemwide to be used by git merge
      xclip # needs to be installed systemwide to make nvim clipboard work
    ]
    ++ (configureExtraPackages { inherit pkgs stable-packages; });
  };

  services = {
    xserver = {
      enable = true;
      windowManager.i3.enable = true;
      displayManager.autoLogin = {
        inherit user;
        enable = true;
      };

      libinput = {
        enable = useTouchpad;
        touchpad.naturalScrolling = true;
      };

      dpi = 140;
      layout = "us";
      xkbVariant = "altgr-intl";
      xrandrHeads = [ "HDMI-1" ];
      xautolock = {
        enable = useAutolock;
        locker = "${pkgs.i3lock-fancy}/bin/i3lock-fancy -p -t \"\"";
        time = 5;
      };
    };

    avahi.enable = useChromeCast; # For chromecast. See https://github.com/NixOS/nixpkgs/issues/49630#issuecomment-622498732
    printing.enable = true;
    logind.extraConfig = "HandlePowerKey=ignore";

    redshift = {
      enable = useRedshift;
      brightness = {
        day = "1";
        night = "0.8";
      };
      temperature = {
        day = 5500;
        night = 3700;
      };
    };
  };

  virtualisation.docker.enable = true;
})

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  inputs,
  config,
  desktop,
  username,
  pkgs,
  lib,
  ...
}:
let
  gnome = desktop == "gnome";
  sway = desktop == "sway";
  cosmic = desktop == "cosmic";
in
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 10d";
    };
  };

  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
  ];

  services.udev.packages = with pkgs; [ game-devices-udev-rules ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    excludePackages = with pkgs; [
      xterm
      xorg.xorgserver
    ];
    displayManager.gdm.enable = gnome;
    desktopManager.gnome.enable = gnome;
  };
  services.displayManager.cosmic-greeter.enable = cosmic;
  services.desktopManager.cosmic.enable = cosmic;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.polkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  xdg.portal =
    {
      xdgOpenUsePortal = true;
    }
    // lib.optionalAttrs sway {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      configPackages = [ pkgs.gnome.gnome-session ];
      config.common.default = [
        "wlr"
        "gtk"
      ];
    };

  services.flatpak.enable = true;

  services.fwupd.enable = true;

  security.pam.services.greetd = lib.mkIf sway {
    startSession = true;
    enableGnomeKeyring = true;
  };

  programs.dconf.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    package = pkgs.steam.override {
      extraPkgs =
        pkgs:
        with pkgs;
        let
          obs-vkcapture = obs-studio-plugins.obs-vkcapture.overrideAttrs {
            cmakeFlags = [ "-DBUILD_PLUGIN=off" ];
          };
        in
        [
          obs-vkcapture
          liberation_ttf
          noto-fonts
          noto-fonts-cjk
          noto-fonts-lgc-plus
          noto-fonts-color-emoji
        ];
      extraEnv = {
        MANGOHUD = "1";
        OBS_VKCAPTURE = "1";
      };
    };
    extraCompatPackages =
      let
        steamtinkerlaunch = pkgs.stdenv.mkDerivation {
          name = "steamtinkerlaunch";
          src = ./steam;
          installPhase = ''
            mkdir -p $out
            cp $src/{compatibilitytool,toolmanifest}.vdf $out
            ln -sn ${pkgs.steamtinkerlaunch}/bin/steamtinkerlaunch $out/steamtinkerlaunch
          '';
        };
      in
      [
        steamtinkerlaunch
        pkgs.proton-ge-bin
      ];
  };
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
    ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages =
    (with pkgs; [
      #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      #  wget
      libsecret
      lm_sensors
    ])
    ++ lib.optionals cosmic (
      with pkgs;
      [
        gnome-system-monitor
        nautilus
      ]
    );

  fonts.packages =
    (with pkgs; [
      noto-fonts-cjk
      noto-fonts-emoji
      jetbrains-mono
    ])
    ++ lib.optionals (!gnome) (with pkgs; [ cantarell-fonts ]);

  programs.fish.enable = true;
  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid $PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  services.dbus.packages = [ pkgs.gcr ];

  virtualisation.libvirtd.enable = true;

  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  services.uptimed.enable = true;

  services.greetd = lib.mkIf sway {
    enable = true;
    settings = {
      default_session = {
        command = ''${pkgs.greetd.tuigreet}/bin/tuigreet -r --time --cmd "sway"'';
        user = "greeter";
      };
    };
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  zramSwap.enable = true;

  system.autoUpgrade = {
    enable = true;
    flake = "${inputs.self.outPath}#${desktop}";
    operation = "boot";
    flags = [
      "--update-input"
      "nixpkgs"
      "--impure"
      "-L"
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  environment.etc."current-system-packages".text =
    let
      packages = builtins.map (p: "${p.name}") config.environment.systemPackages;
      sortedUnique = builtins.sort builtins.lessThan (lib.lists.unique packages);
      formatted = builtins.concatStringsSep "\n" sortedUnique;
    in
    formatted;

  systemd = lib.mkIf (!gnome) {
    services.flatpak-auto-update = {
      description = "Update flatpaks";
      unitConfig = {
        Type = "oneshot";
      };
      serviceConfig = {
        ExecStart = "${pkgs.flatpak}/bin/flatpak update --assumeyes --noninteractive";
      };
      wantedBy = [ "default.target" ];
      startAt = "daily";
    };
  };

  hardware.bluetooth = lib.mkIf sway {
    enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}

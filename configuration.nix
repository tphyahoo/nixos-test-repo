# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, options, ... }@args:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # this module setups automatic applying of configuration, pulled from git
      ./auto-apply-config.nix
      # import instance-local settings. Those settings rely on a local.hostname.nix so each separate instance of this repo should have separate host name.
      ./local_settings.nix
      # here we import our mempool module, which defines `service.mempool.enable` option, which we will use below
      ./overlays/mempool-overlay/module.nix
      # custom module for already existing electrs derivation
      ./overlays/electrs-overlay/module.nix
    ];

  # and here we are enabling mempool service. this option is being defined in `./overlays/mempool-overlay/module.nix`
  services.mempool-backend = {
    enable = true;
    config = ''
      {
        "MEMPOOL": {
          "NETWORK": "mainnet",
          "BACKEND": "electrum",
          "HTTP_PORT": 8999,
          "API_URL_PREFIX": "/api/v1/",
          "POLL_RATE_MS": 2000
        },
        "CORE_RPC": {
          "USERNAME": "mempool",
          "PASSWORD": "71b61986da5b03a5694d7c7d5165ece5"
        },
        "ELECTRUM": {
          "HOST": "127.0.0.1",
          "PORT": 50001,
          "TLS_ENABLED": false
        },
        "DATABASE": {
          "ENABLED": true,
          "HOST": "127.0.0.1",
          "PORT": 3306,
          "USERNAME": "mempool",
          "PASSWORD": "mempool",
          "DATABASE": "mempool"
        },
        "STATISTICS": {
          "ENABLED": true,
          "TX_PER_SECOND_SAMPLE_PERIOD": 150
        }
      }
    '';
  };

  # enable electrs service
  services.electrs = {
    enable = true;
    db_dir = "/data/electrs_db"; # /data/ is a separate volume
    cookie_file = "/data/bitcoin-mempool/.cookie";
  };

  services.bitcoind.mempool = {
    enable = true;
    dataDir = "/data/bitcoin-mempool"; # move the data into a separate volume, see hardware-configuration.nix for mount points
    extraConfig = ''
      txindex = 1
    '';
    rpc.users = {
      mempool = {
        name = "mempool";
        passwordHMAC = "e85b8cd1bbfd7a4500053b4159092990$7941d89fc530a2a40faaa2073f6355f7e17821fac438827d62fd5e78b48938a9";
      };
    };
  };


  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    vim # editor
    git # git client
    screen
    atop # process monitor
    tcpdump # traffic sniffer
    iftop # network usage monitor
  ];
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    22
    80
  ];
  # temporary for uploading nixos image to another DO account.
  services.nginx = {
    enable = true;
    virtualHosts = {
      default = {
        root = "/data/www/default";
        default = true;
        listen = [
          { addr = "0.0.0.0";
            port = 80;
          }
        ];
      };
    };
  };
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;
  networking.firewall.logRefusedConnections = false; # we are not interested in a logs of refused connections

  # users are defined in a separate module in order to be accessable in get modules
  users.users = import ./os-users.nix args;
  # users profiles are immutable and only defined in os-userx.nix
  users.mutableUsers = false;
  # we need this option in order to provide a sudo without a password for ssh logins, authenticated by ssh-keys
  security.pam.enableSSHAgentAuth = true;
  security.pam.services.sudo.sshAgentAuth = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "21.05"; # Did you read the comment?

}

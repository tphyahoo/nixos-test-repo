# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, options, ... }@args:

let
  # import psk from out-of-git file
  # TODO: switch to secrets-manager and change to make it more secure
  bitcoind-mainnet-rpc-psk = builtins.readFile "/etc/nixos/private/bitcoind-mainnet-rpc-psk.txt";
  bitcoind-testnet-rpc-psk = builtins.readFile "/etc/nixos/private/bitcoind-testnet-rpc-psk.txt";
  bitcoind-signet-rpc-psk = builtins.readFile "/etc/nixos/private/bitcoind-signet-rpc-psk.txt";
  # TODO: refactor to autogenerate HMAC from the password above
  bitcoind-mainnet-rpc-pskhmac = builtins.readFile "/etc/nixos/private/bitcoind-mainnet-rpc-pskhmac.txt";
  bitcoind-testnet-rpc-pskhmac = builtins.readFile "/etc/nixos/private/bitcoind-testnet-rpc-pskhmac.txt";
  bitcoind-signet-rpc-pskhmac = builtins.readFile "/etc/nixos/private/bitcoind-signet-rpc-pskhmac.txt";
  mempool-db-psk-mainnet = builtins.readFile "/etc/nixos/private/mempool-db-psk-mainnet.txt";
  mempool-db-psk-testnet = builtins.readFile "/etc/nixos/private/mempool-db-psk-testnet.txt";
  mempool-db-psk-signet = builtins.readFile "/etc/nixos/private/mempool-db-psk-signet.txt";
in
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
    mainnet = {
      db_user = "mempool";
      db_name = "mempool";
      db_psk = mempool-db-psk-mainnet;
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
            "PASSWORD": "${bitcoind-mainnet-rpc-psk}"
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
            "DATABASE": "mempool",
            "USERNAME": "mempool",
            "PASSWORD": "${mempool-db-psk-mainnet}"
          },
          "STATISTICS": {
            "ENABLED": true,
            "TX_PER_SECOND_SAMPLE_PERIOD": 150
          }
        }
      '';
    };
    testnet = {
      db_user = "tmempool";
      db_name = "tmempool";
      db_psk = mempool-db-psk-testnet;
      config = ''
        {
          "MEMPOOL": {
            "NETWORK": "testnet",
            "BACKEND": "electrum",
            "HTTP_PORT": 8997,
            "API_URL_PREFIX": "/api/v1/",
            "POLL_RATE_MS": 2000
          },
          "CORE_RPC": {
            "USERNAME": "tmempool",
            "PASSWORD": "${bitcoind-testnet-rpc-psk}",
            "PORT": 18332
          },
          "ELECTRUM": {
            "HOST": "127.0.0.1",
            "PORT": 60001,
            "TLS_ENABLED": false
          },
          "DATABASE": {
            "ENABLED": true,
            "HOST": "127.0.0.1",
            "PORT": 3306,
            "DATABASE": "tmempool",
            "USERNAME": "tmempool",
            "PASSWORD": "${mempool-db-psk-testnet}"
          },
          "STATISTICS": {
            "ENABLED": true,
            "TX_PER_SECOND_SAMPLE_PERIOD": 150
          }
        }
      '';
    };
  };
  # enable mempool-frontend service
  services.mempool-frontend = {
    enable = true;
    testnet_enabled = true;
  };

  # enable electrs service
  services.electrs = {
    mainnet = {
      db_dir = "/data1/electrs_db"; # /data/ is a separate volume
      cookie_file = "/data/bitcoin-mempool/.cookie";
      blocks_dir = "/data/bitcoin-mempool/blocks";
    };
    testnet = { # testnet instance
      db_dir = "/mnt/electrs-testnet";
      cookie_file = "/mnt/bitcoind-testnet/testnet3/.cookie";
      blocks_dir = "/mnt/bitcoind-testnet/testnet3/blocks";
      network = "testnet";
      rpc_listen = "127.0.0.1:60001";
    };
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
        passwordHMAC = "${bitcoind-mainnet-rpc-pskhmac}";
      };
    };
  };
  # bitcoind testnet instance
  services.bitcoind.testnet = {
    enable = true;
    dataDir = "/mnt/bitcoind-testnet";
    testnet = true;
    extraConfig = ''
      txindex = 1
    '';
    rpc.users = {
      tmempool = {
        name = "tmempool";
        passwordHMAC = "${bitcoind-testnet-rpc-pskhmac}";
      };
    };
  };
  # bitcoind signet instance
  services.bitcoind.signet = {
    enable = true;
    dataDir = "/mnt/bitcoind-signet";
    extraConfig = ''
      txindex = 1
      signet = 1
      [signet]
    '';
    rpc.users = {
      smempool = {
        name = "smempool";
        passwordHMAC = "${bitcoind-signet-rpc-pskhmac}";
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

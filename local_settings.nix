{pkgs, lib, ...}@args:
let
  hostname = import ./local.hostname.nix; # get the hostname of the current host
  zabbix_server = import ./local.zabbix_server.nix; # get the IP of the zabbix server
  # default config, dependent on hostnames
  default_config = {
    networking.hostName = hostname;
    services.zabbixAgent = {
      server = zabbix_server;
      settings = {
        Hostname = hostname;
      };
    };
  };
  build_config = all_configs:
    if lib.hasAttrByPath [ hostname ] all_configs
    then lib.getAttrFromPath [ hostname ] all_configs
    else {};
  # this config defines common network part for KVM hosts
  kvm_host_network = net_iface:
  {
    imports = [
      # custom openvswitch services
      ./overlays/openvswitch-overlay/module.nix
    ];
    networking.hostName = hostname;
    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.0.2u"
    ];
    networking.vswitches = {
      ovs-br0 = {
        interfaces = {
          ${net_iface} = {};
        };
        extraOvsctlCmds = ''
          set interface ovs-br0 type=internal
        '';
      };
    };
  };
  virt_viewer_kiosk = pkgs.writeScriptBin "virt_viewer_kiosk" ''
    #!${pkgs.stdenv.shell}
    set -e

    export DISPLAY=:0
    if [ "$(whoami)" == "user" ]; then
      if [ "$(virsh -c qemu:///system list --name | grep --count '^olimparm$')" -gt 0 ]; then
        if [ "$(ps aux | grep '^user ' | grep virt-viewer | grep --count ' olimparm ')" -lt 1 ]; then
          virt-viewer -c qemu:///system olimparm -k --kiosk-quit on-disconnect
          echo $?
        else
          echo "virt-viewer is already running"
        fi
      else
        echo "olimparm VM is not running"
      fi
    else
      echo "not a 'user' user"
    fi
  '';
  supervisor_virt_viewer = pkgs.writeScriptBin "supervisor_virt_viewer" ''
    #!${pkgs.stdenv.shell} -e

    if [ "$(whoami)" != "user" ]; then
      echo "not a 'user' user"
      exit 0
    fi
    while true;
    do
      if [ ! -e /maitanence ]; then
        if [ "$(virsh -c qemu:///system list --name | grep --count '^olimparm$')" -gt 0 ]; then
          if [ "$(ps aux | grep '^user ' | grep virt-viewer | grep --count ' olimparm ')" -lt 1 ]; then
            systemctl --user start virt_viewer_kiosk --no-block
          fi
        fi
      fi
      sleep 10s
    done;
  '';
  supervisor_olimparm_worker = pkgs.writeScriptBin "supervisor_olimparm_worker" ''
    #!${pkgs.stdenv.shell}
    set -e

    if [ ! -e /maitanence ]; then
      if [ "$(virsh -c qemu:///system list --name | grep --count '^olimparm$')" -lt 1 ]; then
        echo "olimparm is not running, starting"
        virsh -c qemu:///system start olimparm || {
          echo "failed to start olimparm"
        }
      fi
    fi
  '';
  # this is wrapper, that should survive in case if supervisor_olimparm_worker will fail
  supervisor_olimparm = pkgs.writeScriptBin "supervisor_olimparm" ''
    #!${pkgs.stdenv.shell}
    set -e

    while true;
    do
      supervisor_olimparm_worker || true
      sleep 10s
    done;
  '';
  arm_server = br0_arg:
      {
        # enable window manager
        services.xserver.enable = true;
        services.xserver.desktopManager.xterm.enable = false;
        programs.dconf.enable = true; # gnome-apps needs this to store settings
        services.dbus.packages = [ pkgs.gnome3.dconf ];
        services.xserver.windowManager.i3.enable = true;
        services.xserver.displayManager = {
          autoLogin = {
            enable = true;
            user = "user";
          };
          lightdm = {
            enable = true;
          };
        };
        environment.systemPackages = with pkgs; [
          virt-viewer
          pavucontrol
          spice_gtk
        ];
        security.wrappers.spice-client-glib-usb-acl-helper = {
          source = "${pkgs.spice_gtk}/bin/spice-client-glib-usb-acl-helper";
          capabilities = "cap_fowner+ep";
        };
        imports = [
          ./overlays/scream-receiver-unix-overlay/module.nix
        ];
        services.scream-receiver = {
          enable = true;
          interfaces = [
            "br0"
          ];
        };
        networking.localCommands = ''
          # this is needed so scream will not loose the traffic after multicast timeout
          echo 0 > /sys/devices/virtual/net/br0/bridge/multicast_snooping
        '';

        networking.usePredictableInterfaceNames = false;
        networking.bridges = {
          br0 = {
            interfaces = [
              "eth0"
            ];
          };
        };
        networking.interfaces.br0 = br0_arg;
        networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
        networking.hostName = hostname;
        nixpkgs.config.permittedInsecurePackages = [
          "openssl-1.0.2u"
        ];
        # virt-viewer in kiosk mode
        systemd.user.services.virt_viewer_kiosk = {
          description = "virt-viewer in kiosk mode";
          wantedBy = [ "default.target" ];
          serviceConfig = {
            Type = "simple";
          };
          path = with pkgs; [ coreutils gnugrep virt_viewer_kiosk libvirt virt-viewer procps spice_gtk ];
          script =
              ''
              #!${pkgs.stdenv.shell}
              set -e
              virt_viewer_kiosk
              '';
        };
        # supervize for virt-viewer
        systemd.user.services.supervisor_virt_viewer = {
          description = "supervisor for virt-viewer";
          wantedBy = [ "default.target" ];
          serviceConfig = {
            Type = "simple";
          };
          path = with pkgs; [ coreutils gnugrep supervisor_virt_viewer libvirt virt-viewer procps spice_gtk ];
          script =
              ''
              #!${pkgs.stdenv.shell} -e
              export DISPLAY=:0
              timeout --foreground 590s supervisor_virt_viewer || true
              '';
          startAt = "*:0/10"; # run every 10 minutes
        };
        # supervize for olimparm VM
        systemd.services.supervisor_olimparm = {
          description = "supervisor for olimparm VM";
          requires = [ "libvirtd.service" "libvirt-guests.service" ];
          after = [ "libvirtd.service" "libvirt-guests.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "simple";
          path = with pkgs; [ coreutils gnugrep supervisor_olimparm  supervisor_olimparm_worker libvirt ];
          script =
              ''
              #!${pkgs.stdenv.shell} -e
              timeout --foreground 590s supervisor_olimparm || true
              '';
          startAt = "*:0/10"; # run every 10 minutes
        };
      };
in
default_config // (build_config
  { #example-host-name = {
    #  networking.hostName = hostname;
    #  networking.interfaces.ens32 = {
    #    useDHCP = false;
    #    ipv4 = {
    #      addresses = [ {address = "139.110.78.70"; prefixLength = 28; } ];
    #      routes = [ {address = "0.0.0.0"; prefixLength = 0; via = "139.110.78.65"; } ];
    #    };
    #  };
    #  networking.nameservers = [ "139.114.144.10" ];
    #  This part is for working behind socks5 proxy
    #  environment.systemPackages = with pkgs; [
    #    connect
    #  ];
    #  networking.proxy.default = "socks5://134.209.240.233:8123"; # define application-wide proxy
    #  environment.variables = {
    #    GIT_SSH_COMMAND = "ssh -o ProxyCommand='connect -S 134.209.240.233:8123 %h %p\'";
    #  };
    #};
    olimp-kvm2 = arm_server {
      useDHCP = false;
      ipv4 = {
        addresses = [ {address = "192.168.100.201"; prefixLength = 24; } ];
        routes = [ {address = "0.0.0.0"; prefixLength = 0; via = "192.168.100.1"; } ];
      };
    };
    olimp-kvm-test = arm_server {
      useDHCP = false;
      ipv4 = {
        addresses = [ {address = "192.168.101.201"; prefixLength = 24; } ];
        routes = [ {address = "0.0.0.0"; prefixLength = 0; via = "192.168.101.1"; } ];
      };
    };
  }
)
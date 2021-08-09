{pkgs, lib, ...}@args:
let
  hostname = import ./local.hostname.nix; # get the hostname of the current host
  zabbix_server = import ./local.zabbix_server.nix; # get the IP of the zabbix server
  # default config, dependent on hostnames
  default_config = {
    networking.hostName = hostname;
  };
  build_config = all_configs:
    if lib.hasAttrByPath [ hostname ] all_configs
    then lib.getAttrFromPath [ hostname ] all_configs
    else {};
in
default_config // (build_config
  { #example-host-name = {
    #  networking.hostName = hostname;
    #  networking.interfaces.ens32 = {
    #    useDHCP = false;
    #    ipv4 = {
    #      addresses = [ {address = "12.12.12.2"; prefixLength = 28; } ];
    #      routes = [ {address = "0.0.0.0"; prefixLength = 0; via = "12.12.12.1"; } ];
    #    };
    #  };
    #  networking.nameservers = [ "8.8.8.8" ];
    #  This part is for working behind socks5 proxy
    #  environment.systemPackages = with pkgs; [
    #    connect
    #  ];
    #  networking.proxy.default = "socks5://13.13.13.13:8123"; # define application-wide proxy
    #  environment.variables = {
    #    GIT_SSH_COMMAND = "ssh -o ProxyCommand='connect -S 13.13.13.13:8123 %h %p\'";
    #  };
    #};
  }
)
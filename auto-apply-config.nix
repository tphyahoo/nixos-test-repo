{ config, pkgs, lib, ... }@args:

let
  nixos_apply_script = pkgs.writeScriptBin "nixos_apply_script" ''
    #!${pkgs.stdenv.shell} -e


    function do_rebuild(){
      # if there are new updates, apply them immidiately
      echo "config must be rebuild"
      /run/current-system/sw/bin/systemctl stop nixos-upgrade
      /run/current-system/sw/bin/systemctl start nixos-upgrade --no-block
    }
    cd /etc/nixos
    git status | grep modified > /dev/null && {
      echo "some uncommited changes had been detected, removing"
      git reset --hard # remove local changes to not to conflict
    } || true
    git pull | grep "Already up to date." > /dev/null || {
      git submodule init || true # in case of first run
      git submodule update --remote # don't force the support to update every repo
    }
    do_rebuild
  '';
  locals = import /etc/nixos/local_settings.nix args;
  local_git_ssh_command = # here we want to check the GIT_SSH_COMMAND presence in local settings and use it for fetching config updates
    if lib.hasAttrByPath [ "environment" "variables" "GIT_SSH_COMMAND" ] locals
    then locals.environment.variables.GIT_SSH_COMMAND
    else "";
in
{
  environment.systemPackages = with pkgs; [ git coreutils nix ];
  # here we are creating new systemd service, that will perform periodical `git pull`
  # inside /etc/nixos directory in order to update system configuration.
  # updated configuration will be applied by periodical system.autoUpgrade
  systemd.services.nixos-apply = {
    description = "keep /etc/nixos state in sync";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.git pkgs.coreutils nixos_apply_script pkgs.nix pkgs.openssh pkgs.connect];
    script =
        ''
        #!${pkgs.stdenv.shell} -e
        if [ "${local_git_ssh_command}" != "" ]; then
          export GIT_SSH_COMMAND="${local_git_ssh_command}"
        fi
        timeout --foreground 9m nixos_apply_script
        '';
    startAt = "*:0/10"; # run every 10 minutes
  };

  # now enable auto upgrade option, that will upgrade system for us
  system.autoUpgrade.enable = true;
  nix.gc = {
    automatic = true; # enable the periodic garbage collecting
    options = "-d --delete-older-than 7d"; # delete everything, older than 1d
  };
}

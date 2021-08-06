# this configuration file should only contain a set, suitable to be used as 
# users.users value
{ config, pkgs, ... }:
{
  thartman = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKdNobBy0ui5ibH8OKBw3RibPqIaV1ZmPyBFLfWzKOUX thomashartman1@gmail.com" ];
    };
  dambaev = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDO56Q3vIOF0xdnr6D6pPTzr7nUYa0syzdcdA5sJee9gxh3PuzOtDdUmFzfECDbG9/DqBWXdGNbmmPxgSoerI1V+C1aYfHXpX5DZF/TpPFh3iMekcG+5OQtrwNVb7ByaNUryq2subnIAY5Rtp2hV2Q7tVp0j/PcVu0RdRJrQMD+JE3Mlgh0iSzDiKRAxW8xFT5Wuy7IwUXK2AjE9LKxUw35UpUb72SHdr4GnGbflH+oLGvPT65aFbHM/Xmz3Yv04K9zfmFMcDNElE0PgOeILkNbT6Mhd8/IVUCACn4TBy8aCuWqK1SMHktQQ+LOG715MZEDfSl+CQcxgFDMdWcyPtlL dambaev@mobiled" ];
    };
}


# this configuration file should only contain a set, suitable to be used as 
# users.users value
{ config, pkgs, ... }:
{
  mike = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAranSbjHrgfa5ScJZuMLV9UQxfau0Gv2pyPEU6Mpl+pAz1yCCB0cur+18ne+8PrKaf9AIxEdBtYXNeGTGpQtBAfEaiwQ61qrTMEpSZZgE1SJk5iXoY7zBnTMisvZeauY4XnfRoyQC1bsFDFHFBvfxfJs0llDhXoWrQRjWMAmRnuPBRHRJB7QoIAjw4NZJzKE8hxmsg3u1NqLU2hR/fAkVMD8PZZVlhiLTGS5N4U2rp5lCmjf8WLVaMiags5qRg4Q3SRrhx7cqv2aMr8FY1+TqDcYJXVD1NHzk+V6aHgxkEm2QQDLq5nEXNKkMtjmLGb+GAOrEL1zatZJwSwuLREsj+PJHZXpSRxGICknSiA6Gl4pjfcm97/I5K5bO31lOmfRFU4WJhCDkGqtpme5B9dOycZvsuGMD6lH9J/XF/MYUCNDC+t7PaV0ppFIceRsAHbtirq2Cq/sAyKh0xqYwMoCTJuiEX9WlzxcIxAtQH4al+IMIN4sBCC/AldOqvaleyRXw7q5PduSm2xFS08QzXLjv3mkmx3mpnubTHpa6XgnYinoGzn2hOaq6qqsNbGI7ML6Cl9F/GzfGm5oPvCX8zYYr4UtUB7/pW0eBN8Zyjc8oub9YbvrXNA2CzUg6eUt4YEjMbjUoe0LD5aTs2AcjfaLpqK7DMI1fL2b1UY8sd0rqXkk= elmer-mike-prgmr" ];
    };
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


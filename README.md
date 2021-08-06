# Brief

This repo contains nixos configuration for showcase of NixOS

# Structure

NixOS is following goal to perform whole OS config in one configuration file. But still, NixOS allows us to import configuration files ("nix expressions"), so we can split configuration in modules and import them with `imports` option.

So there are those configuration files used:

`configuration.nix` - this is the 'main' configuration module in NixOS. All other modules are being imported from this file.
`auto-apply-config.nix` - contains routine for performing automatical fetching config from git repo, building and switching to this configuration.
`local_settings.nix` - this file included as an example of how to provide per-instance local settings, such that you will be able to use one repo for multiple NixOS instances and some of them may use specific settings (like static IP address/routes and etc).
`os-users.nix` - contains set of users, that are allowed to access NixOS instance by ssh-public-key.
`overlays/` - directory, which is supposed to contain number of git submodules with nix-expressions, which are supposed to be imported from `configuration.nix`.

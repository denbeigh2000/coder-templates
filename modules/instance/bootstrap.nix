# Early-stage module to create the necessary user with necessary privileges to
# bootstrap the machine and stream logs.

{ user }:

{ pkgs, modulesPath, ... }:

{
  # Necessary for running on AWS
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];

  config = {
    # Define the user the agent will run as
    # NOTE: If the user provides a name that isn't defined in their NixOS
    # config, this user will be deleted on apply, and the coder agent will be
    # running under an unassigned UID
    users = {
      users.${user} = {
        isNormalUser = true;
        group = user;
      };
      groups.${user} = { };
    };

    security.sudo.extraRules = [
      {
        users = [ user ];
        commands = [
          { command = "ALL"; options = [ "NOPASSWD" ]; }
        ];
      }
    ];

    # Base set of packages Coder needs to bootstrap itself
    environment.systemPackages = with pkgs; [ bash curl coreutils ];

    # Good practice for NixOS, even though we're going to trash this
    # configuration roughly immediately after applying it.
    system.stateVersion = "23.05";
  };
}

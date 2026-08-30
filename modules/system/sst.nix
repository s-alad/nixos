{ ... }:

{
  # Allow `sst tunnel` (SST CLI's VPC tunnel helper) to start its
  # privileged worker without prompting for sudo. Installed by
  # `sudo npx sst tunnel install` into /opt/sst/tunnel.
  security.sudo.extraRules = [
    {
      users = [ "salad" ];
      commands = [
        {
          command = "/opt/sst/tunnel tunnel start *";
          options = [ "NOPASSWD" "SETENV" ];
        }
      ];
    }
  ];
}

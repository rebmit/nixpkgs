{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with (import ./param-lib.nix lib);

let
  cfg = config.services.strongswan-swanctl;
  configFile = pkgs.writeText "swanctl.conf" (
    (paramsToConf cfg.swanctl swanctlParams) + (concatMapStrings (i: "\ninclude ${i}") cfg.includes)
  );
  swanctlParams = import ./swanctl-params.nix lib;
  swanctlDirectories = [
    "swanctl/bliss"
    "swanctl/ecdsa"
    "swanctl/pkcs8"
    "swanctl/pkcs12"
    "swanctl/private"
    "swanctl/pubkey"
    "swanctl/rsa"
    "swanctl/x509"
    "swanctl/x509aa"
    "swanctl/x509ac"
    "swanctl/x509ca"
    "swanctl/x509crl"
    "swanctl/x509ocsp"
  ];
in
{
  options.services.strongswan-swanctl = {
    enable = mkEnableOption "strongswan-swanctl service";

    package = mkPackageOption pkgs "strongswan" { };

    strongswan.extraConfig = mkOption {
      type = types.str;
      default = "";
      description = ''
        Contents of the `strongswan.conf` file.
      '';
    };

    swanctl = paramsToOptions swanctlParams;
    includes = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = ''
        Extra configuration files to include in the swanctl configuration. This can be used to provide secret values from outside the nix store.
      '';
    };
  };

  config = mkIf cfg.enable {

    assertions = [
      {
        assertion = !config.services.strongswan.enable;
        message = "cannot enable both services.strongswan and services.strongswan-swanctl. Choose either one.";
      }
    ];

    # The swanctl command complains when the following directories don't exist:
    # See: https://wiki.strongswan.org/projects/strongswan/wiki/Swanctldirectory
    environment.etc =
      let
        mkSymlink = path: nameValuePair path {
          source = pkgs.emptyDirectory;
          mode = "direct-symlink";
        };
      in
      recursiveUpdate
        (listToAttrs (map mkSymlink swanctlDirectories))
        {
          "swanctl/swanctl.conf".source = configFile;
          "strongswan.conf".text = cfg.strongswan.extraConfig;
        };

    systemd.services.strongswan-swanctl = {
      description = "strongSwan IPsec IKEv1/IKEv2 daemon using swanctl";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [
        kmod
        iproute2
        iptables
        util-linux
      ];
      restartTriggers = [
        config.environment.etc."swanctl/swanctl.conf".source
        config.environment.etc."strongswan.conf".source
      ];
      serviceConfig = {
        ExecStart = "${cfg.package}/sbin/charon-systemd";
        Type = "notify";
        ExecStartPost = "${cfg.package}/sbin/swanctl --load-all --noprompt";
        ExecReload = "${cfg.package}/sbin/swanctl --reload";
        Restart = "on-abnormal";
      };
    };
  };
}

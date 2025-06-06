{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.programs.nheko;

  iniFmt = pkgs.formats.ini { };

  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome;

  camelCaseToSnakeCase = lib.replaceStrings lib.upperChars (map (s: "_${s}") lib.lowerChars);

  inherit (lib.generators) mkKeyValueDefault toINI;

in
{
  meta.maintainers = [ lib.maintainers.gvolpe ];

  options.programs.nheko = {
    enable = lib.mkEnableOption "Qt desktop client for Matrix";

    package = lib.mkPackageOption pkgs "nheko" { nullable = true; };

    settings = lib.mkOption {
      type = iniFmt.type;
      default = { };
      example = lib.literalExpression ''
        {
          general.disableCertificateValidation = false;
          auth = {
            accessToken = "SECRET";
            deviceId = "MY_DEVICE";
            homeServer = "https://matrix-client.matrix.org:443";
            userId = "@@user:matrix.org";
          };
          settings.scaleFactor = 1.0;
          sidebar.width = 416;
          user = {
            alertOnNotification = true;
            animateImagesOnHover = false;
            "sidebar\\roomListWidth" = 308;
          };
        }
      '';
      description = ''
        Attribute set of Nheko preferences (converted to an INI file).

        For now, it is recommended to run nheko and sign-in before filling in
        the configuration settings in this module, as nheko writes the access
        token to {file}`$XDG_CONFIG_HOME/nheko/nheko.conf` the
        first time we sign in, and we need that data into these settings for the
        correct functionality of the application.

        This a temporary inconvenience, however, as nheko has plans to move the
        authentication stuff into the local database they currently use. Once
        this happens, this will no longer be an issue.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."${configDir}/nheko/nheko.conf" = lib.mkIf (cfg.settings != { }) {
      text = ''
        ; Generated by Home Manager.

        ${toINI {
          mkKeyValue = k: v: mkKeyValueDefault { } "=" (camelCaseToSnakeCase k) v;
        } cfg.settings}
      '';
    };
  };
}

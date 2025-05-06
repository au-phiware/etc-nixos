{ pkgs, ... }:
let
  certs = "/Users/Shared/ca_certs/bundle.pem";
in {
  security.pki.certificateFiles = [ certs ];
  nix.extraOptions = ''
    ssl-cert-file = ${certs}
  '';
  nix.envVars = let
    proxy = "http://localhost:3128";
  in {
    HTTP_PROXY = proxy;
    HTTPS_PROXY = proxy;
    ALL_PROXY = proxy;
    http_proxy = proxy;
    https_proxy = proxy;
    all_proxy = proxy;
  };
}

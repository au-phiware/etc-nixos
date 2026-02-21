# Nixpkgs overlays
final: prev: {
  # wl-clipboard-x11 compatibility layer
  # Makes xsel/xclip work on Wayland by wrapping wl-clipboard
  wl-clipboard-x11 = prev.stdenv.mkDerivation rec {
    pname = "wl-clipboard-x11";
    version = "5";

    src = prev.fetchFromGitHub {
      owner = "brunelli";
      repo = "wl-clipboard-x11";
      rev = "v${version}";
      sha256 = "1y7jv7rps0sdzmm859wn2l8q4pg2x35smcrm7mbfxn5vrga0bslb";
    };

    dontBuild = true;
    dontConfigure = true;
    propagatedBuildInputs = [ prev.wl-clipboard ];
    makeFlags = [ "PREFIX=$(out)" ];
  };

  # Override xsel and xclip to use wl-clipboard on Wayland
  xsel = final.wl-clipboard-x11;
  xclip = final.wl-clipboard-x11;
}

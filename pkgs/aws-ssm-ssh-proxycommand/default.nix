{ stdenv, fetchFromGitHub }:
stdenv.mkDerivation rec {
  pname = "aws-ssm-ssh-proxycommand";
  version = "d0fe46bd408c8b7d17938b72df6b384393c8a5c2";
  src = fetchFromGitHub {
    owner = "intelematics";
    repo = pname;
    rev = version;
    sha256 = "sha256-wR/nUXhhtzueYLEmoD2drG5ww+JmZVpBn6qmAJFZ5mI=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir $out;
    install aws-ssm-ssh-proxycommand.sh $out/
  '';
}

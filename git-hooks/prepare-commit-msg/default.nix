{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule rec {
  pname = "prepare-commit-msg";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-1wycFQdf6sudxnH10xNz1bppRDCQjCz33n+ugP74SdQ=";

  nativeBuildInputs = with pkgs; [
    makeWrapper
  ] ++ buildInputs;

  buildInputs = with pkgs; [
    pandoc
    git
  ];

  postInstall = ''
    wrapProgram $out/bin/prepare-commit-msg \
      --set PATH ${pkgs.lib.makeBinPath buildInputs} \
      --run 'export ANTHROPIC_API_KEY="$(if [ -f $HOME/.config/anthropic/api-key.gpg ]; then ${pkgs.gnupg}/bin/gpg -d $HOME/.config/anthropic/api-key.gpg; fi)"'
  '';

  meta = with pkgs.lib; {
    description = "A tool to generate commit messages using Claude";
    license = licenses.mit;
    maintainers = with maintainers; [ "Corin Lawson" ];
    platforms = platforms.unix;
  };
}

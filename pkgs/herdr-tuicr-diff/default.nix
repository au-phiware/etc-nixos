{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  herdr,
  tuicr,
  jq,
  git,
}:

# The tuicr-diff herdr plugin: opens tuicr — a terminal code-review TUI with vim
# keybindings — in a split, tab or popup to review the working tree vs HEAD or
# the branch vs its base.
#
# It lives in a subdirectory of someone's personal herdr config repo rather than
# in tuicr's own, so it is pinned by commit, not by tag. Unlike reviewr this
# plugin is build-free: no [[build]] step, no compiled artefact, just shell
# scripts around the `tuicr` binary — which nixpkgs already carries.
stdenvNoCC.mkDerivation {
  pname = "herdr-tuicr-diff-plugin";
  version = "0.1.0-unstable-2026-08-14";

  src = fetchFromGitHub {
    owner = "mkdir700";
    repo = "herdr-config";
    rev = "748b53c0b8e7422725cfa3b9baebd83e4b787ec5";
    hash = "sha256-vzhUBp7unV2jxjsLBjYYN/gchpf0PzspMpUtErWeQQY=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r plugins/tuicr-diff/. $out/

    # herdr runs plugin commands with a minimal PATH, and nothing these scripts
    # need is on it under Nix. tuicr-diff.sh refuses outright without `tuicr`;
    # launch.sh silently reads empty pane state without `jq`, which looks like
    # "no pane open" and stacks duplicates. git resolves the base branch, and
    # herdr is the host CLI the launcher drives (it honours HERDR_BIN_PATH, but
    # falls back to a bare `herdr`).
    chmod +x $out/scripts/*.sh
    for _s in $out/scripts/*.sh; do
      wrapProgram "$_s" \
        --prefix PATH : ${
          lib.makeBinPath [
            tuicr
            herdr
            jq
            git
          ]
        }
    done

    runHook postInstall
  '';

  meta = {
    description = "herdr plugin: review git diffs in a split/tab via the tuicr code-review TUI";
    homepage = "https://github.com/mkdir700/herdr-config";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}

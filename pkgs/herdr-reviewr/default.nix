{
  lib,
  stdenvNoCC,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  jq,
  git,
}:

let
  version = "0.30.4";

  src = fetchFromGitHub {
    owner = "persiyanov";
    repo = "herdr-reviewr";
    rev = "v${version}";
    hash = "sha256-nlFcIqvHOyp4+doZKu9l1eAlGnLzwPifHji9KPMKepo=";
  };

  # The review UI itself. Upstream's herdr-plugin.toml [[build]] step downloads a
  # prebuilt binary from the GitHub release; `herdr plugin link` skips [[build]]
  # entirely, so we build from source and assemble the plugin root ourselves.
  herdr-reviewr = rustPlatform.buildRustPackage {
    pname = "herdr-reviewr";
    inherit version src;

    cargoHash = "sha256-OkobVlT8x2eXM+LH+K+a18H9MxbVRtBi0M9EUs3rts0=";

    # worktree_of() shells out to `git`, and maps a spawn failure to
    # Worktree::Unknown — distinct from the Outside it returns for a directory
    # git reports as no worktree. Without git in the sandbox that unit test
    # reads Unknown where it expects Outside.
    nativeCheckInputs = [ git ];

    # Unit tests only. The other suite, tests/pane_actions.rs, drives
    # herdr/pane.sh against a stub herdr and assumes it runs from inside a git
    # working tree: 13 of its 28 cases refuse with "not a git repo:
    # <builddir>/source", and one asserts that live cwd (the source dir) wins
    # over a temp dir that is a repo. fetchFromGitHub unpacks a tarball with no
    # .git, so that premise cannot hold here. `git init` in preCheck may well
    # satisfy it — untested, and each attempt costs a full recompile.
    cargoTestFlags = [ "--lib" ];

    meta = {
      description = "Code-review sidebar for herdr: review an agent's diff and send line comments back";
      homepage = "https://github.com/persiyanov/herdr-reviewr";
      license = lib.licenses.mit;
      mainProgram = "herdr-reviewr";
      platforms = lib.platforms.unix;
    };
  };
in
# The directory `herdr plugin link` is pointed at. It needs the manifest, the
# herdr/ action scripts, and bin/herdr-reviewr — the manifest launches the pane
# as "$HERDR_PLUGIN_ROOT/bin/herdr-reviewr" by absolute path, since the pane's
# cwd is the repo under review and the binary is not on PATH.
#
# A store path is a fine plugin root: upstream warns only against keeping
# durable state there, and reviewr keeps none (pane.sh: "There is no state
# file"). Its one write — the convenience symlinks — targets $HOME, not here.
stdenvNoCC.mkDerivation {
  pname = "herdr-reviewr-plugin";
  inherit version src;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp herdr-plugin.toml $out/
    cp -r herdr $out/
    ln -s ${lib.getExe herdr-reviewr} $out/bin/herdr-reviewr

    # wrapProgram refuses a non-executable file, and the exec bit here rides on
    # the upstream checkout's mode.
    chmod +x $out/herdr/*.sh

    # herdr runs plugin commands with a minimal PATH. pane.sh compensates by
    # prepending the Homebrew and /usr paths, which is no help here: jq and git
    # live in the Nix profile. Without them every action fails at the first
    # cfg_field call. Prepend the closure's own copies instead.
    wrapProgram $out/herdr/pane.sh \
      --prefix PATH : ${
        lib.makeBinPath [
          jq
          git
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "herdr plugin root for reviewr, built from source for `herdr plugin link`";
    homepage = "https://github.com/persiyanov/herdr-reviewr";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}

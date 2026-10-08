{
  pkgs,
  lib,
  primaryUser,
  nixos-npm-ls,
  ...
}:
let
  # Claude Usage menu bar app (claude-usage-tracker). Off while Security
  # reviews it: it reads Claude Code's OAuth credentials from the keychain.
  # Its settings below stay in place, so set this to true to bring it back.
  enableClaudeUsage = false;
in
{
  imports = [
    ./ollama.nix
    #./litellm.nix
  ];

  system = {
    inherit primaryUser;

    startup.chime = false;

    defaults = {
      # enable tap to click and drag
      trackpad = {
        Clicking = true;
        Dragging = true;
      };

      finder.ShowPathbar = true;
      NSGlobalDomain = {
        #AppleIconAppearanceTheme = "TintedDark";
      };

      # settings for PaperWM.spoon
      dock.mru-spaces = false;
      # No "recent applications" section. Menu bar apps (e.g. Claude Usage)
      # briefly become regular apps while their settings window is open, and
      # the Dock then keeps them there as recents.
      dock.show-recents = false;
      spaces.spans-displays = false;

      # Claude Usage ships Sparkle with automatic update checks on. The app is
      # read-only in the Nix store and nixpkgs supplies new versions, so turn
      # the checks off. Sparkle reads this user default ahead of Info.plist.
      CustomUserPreferences."HamedElfayome.Claude-Usage".SUEnableAutomaticChecks = false;
    };
  };

  users.users."${primaryUser}" = {
    name = "${primaryUser}";
    home = "/Users/${primaryUser}";
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
      "github-copilot-cli"
      "1password"
      "1password-cli"
      "copilot-language-server"
    ];

  nixpkgs.overlays = [
    (self: super: {
      python313Packages = super.python313Packages // {
        textual = super.python313Packages.textual.overrideAttrs (old: {
          meta = old.meta // {
            broken = false;
          };
          doCheck = false;
          doInstallCheck = false;
          checkPhase = "true";
          installCheckPhase = "true";
        });
      };
    })
    (self: super: {
      # extend, not `//`: plugins such as blink-cmp-copilot list copilot-lua in
      # `dependencies`, and those references resolve through the vimPlugins
      # fixpoint. A `//` override only replaces the top-level attribute.
      vimPlugins = super.vimPlugins.extend (
        _: pluginsSuper: {
          copilot-lua = pluginsSuper.copilot-lua.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              chmod -R +r copilot/js/ 2>/dev/null || true
            '';
            # Upstream moved the v3.0.4 tag, so nixpkgs' pinned hash is stale.
            src = old.src.overrideAttrs (_: {
              outputHash = "sha256-kDQOm7/N6T7wOw1JlkcxNMnQrDE4oTRyGCZkvT8HZQw=";
            });
          });
        }
      );
    })
    nixos-npm-ls.overlays.default
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    coreutils
    binutils
    ascii
    file
    htop
    wget
    tree
    jq
    yq-go
    hexedit
    openssl
    watchexec
    brotli
    xz
    ripgrep
    nh
    nix-output-monitor
    unixtools.watch

    uv
    nodejs
    docker-slim

    #awscli2
    #saml2aws
    ssm-session-manager-plugin
    gh
    git-filter-repo
    #zed-editor
    #oterm
    #ghostty
    #lens-desktop
    presenterm
    vpn-slice
    openvpn
    kubectl
    _1password-cli
    _1password-gui
    dotnet-sdk

    opencode
    #github-mcp-server
    #(pkgs.writeShellScriptBin "claude" (let
    #  claude-code = pkgs.claude-code;
    #in ''
    #  GITHUB_PERSONAL_ACCESS_TOKEN="$(security find-generic-password -a "$USER" -s github-pat -w)"
    #  export GITHUB_PERSONAL_ACCESS_TOKEN
    #  exec ${claude-code}/bin/claude "$@"
    #''))
    #python313Packages.huggingface-hub
    #codex
    claude-code
    github-copilot-cli
    (callPackage ./pkgs/npmvet { })
    opencode
    claude-powerline

    # Agent multiplexer. Its plugins are NOT declarative: `herdr plugin
    # install <owner>/<repo>` clones into ~/.local/state/herdr/plugins and
    # runs the manifest's build step, so they are installed by hand. See the
    # reviewr plugin (persiyanov/herdr-reviewr), which wants herdr >= 0.7.5.
    herdr

    # Code-review TUI with vim keybindings. Useful on its own — unlike reviewr
    # it can submit a PR review (`:submit` offers Comment / Approve / Request
    # changes / Draft) — and is what the tuicr-diff herdr plugin drives.
    tuicr

    # cmux.app is a UI app, installed by hand from the DMG (see
    # ./pkgs/cmux for an unused Nix packaging of it). It ships a CLI
    # inside the bundle, so shim just that one binary onto PATH — the
    # bundle's Resources/bin also holds `open`, `ghostty` and `grok`,
    # which must not shadow the system/nixpkgs ones.
    (writeShellScriptBin "cmux" ''
      cli=/Applications/cmux.app/Contents/Resources/bin/cmux
      if [ ! -x "$cli" ]; then
        echo "cmux: $cli not found; install cmux.app from https://github.com/manaflow-ai/cmux/releases" >&2
        exit 127
      fi
      exec "$cli" "$@"
    '')

    #mermaid-cli
    #puppeteer-cli
    imagemagick
    #inkscape
  ]
  ++ lib.optional enableClaudeUsage pkgs.claude-usage-tracker;

  #homebrew.enable = true;
  #homebrew.brews = [ "mermaid-cli" ];

  # Fonts to install into /Library/Fonts/Nix Fonts
  fonts.packages = with pkgs; [
    #corefonts
    #typodermic-free-fonts
    #typodermic-public-domain
    open-sans
    #google-fonts
    open-fonts
    terminus_font
    powerline-fonts
    #nerd-fonts
    noto-fonts
    noto-fonts-color-emoji
  ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";
  nix.enable = false;

  # Weekly garbage collection. Can't use nix-darwin's `nix.gc` because
  # `nix.enable = false` leaves the whole nix module inactive (same reason the
  # nix.conf and registry live in home-manager). Determinate ships its own GC,
  # but it's disk-pressure-triggered (`nix store gc --max ...`) and never prunes
  # profile generations, so it thrashes for hours once the disk is already full
  # instead of keeping ahead of it.
  #
  # Runs as root so it covers the system profile's generations, not just this
  # user's. `nix-collect-garbage --delete-older-than` prunes old generations of
  # every profile it can see and then collects what that releases, so it does
  # both jobs in one pass. Uses Determinate's nix by absolute path rather than
  # pkgs.nix, to avoid running a second, different nix against the same store.
  launchd.daemons.nix-gc = {
    script = ''
      exec /nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-older-than 14d
    '';
    serviceConfig = {
      RunAtLoad = false;
      # Sundays at 03:00. Missed runs (machine asleep) fire on next wake.
      StartCalendarInterval = [
        {
          Weekday = 0;
          Hour = 3;
          Minute = 0;
        }
      ];
      StandardOutPath = "/var/log/nix-gc.log";
      StandardErrorPath = "/var/log/nix-gc.log";
      LowPriorityIO = true;
      Nice = 10;
    };
  };

  # Keep claude-code and github-copilot-cli current. Twice a day this bumps only
  # the nixpkgs-agents flake input (see flake.nix) and refetches the latest
  # Claude Code release manifest into pkgs/claude-code, and if either version
  # moved, builds the system, commits both to the checked-out branch (never
  # pushed) and switches to it.
  #
  # Runs as root because switching needs it, but does the git and nix
  # evaluation work as the user: the repo is theirs, and the private
  # machshipSkills input authenticates with their ~/.config/nix token. The
  # switch mirrors `darwin-rebuild switch` (set the system profile, then run
  # its activate script) so root never has to evaluate the user's checkout.
  #
  # It stays out of the way of work in progress. Any uncommitted change to a
  # tracked file, a detached HEAD or an unfinished merge/rebase skips the run,
  # and a failed build or switch puts flake.lock and the manifest back, so the
  # next run retries.
  launchd.daemons.nixpkgs-agents-update = {
    path = [
      pkgs.coreutils
      pkgs.curl
      pkgs.git
      "/nix/var/nix/profiles/default"
      "/usr"
    ];
    script =
      let
        flakeDir = "/Users/${primaryUser}/src/github.com/au-phiware/etc-nixos";
        host = "AU-DEV-LPT16";
      in
      ''
        set -euo pipefail
        flake=${flakeDir}
        manifest=pkgs/claude-code/manifest.zst.json
        attr="$flake#darwinConfigurations.${host}"
        as_user() { sudo -u ${primaryUser} -H -- env PATH="$PATH" "$@"; }
        agent_versions() {
          as_user nix eval --raw "$attr.pkgs" --apply \
            'p: "claude-code ''${p.claude-code.version}, github-copilot-cli ''${p.github-copilot-cli.version}"'
        }

        echo "== $(date '+%F %T') nixpkgs-agents-update"
        cd "$flake"

        if [ -n "$(as_user git status --porcelain --untracked-files=no)" ]; then
          echo "skipped: uncommitted changes to tracked files"; exit 0
        fi
        if ! as_user git symbolic-ref -q HEAD >/dev/null; then
          echo "skipped: detached HEAD"; exit 0
        fi
        for state in MERGE_HEAD rebase-merge rebase-apply CHERRY_PICK_HEAD; do
          if [ -e "$(as_user git rev-parse --git-path "$state")" ]; then
            echo "skipped: $state in progress"; exit 0
          fi
        done

        before=$(agent_versions)
        restore_lock() { as_user git checkout -- flake.lock "$manifest"; }
        trap 'echo "failed; restoring flake.lock"; restore_lock' ERR

        as_user nix flake update nixpkgs-agents --flake "$flake"
        releases=https://downloads.claude.ai/claude-code-releases
        latest=$(curl -fsSL "$releases/latest")
        as_user curl -fsSL "$releases/$latest/manifest.zst.json" -o "$manifest"
        after=$(agent_versions)
        if [ "$before" = "$after" ]; then
          echo "unchanged: $after"; restore_lock; exit 0
        fi
        echo "updating: $before -> $after"

        systemConfig=$(as_user nix build --no-link --print-out-paths "$attr.system")
        nix-env -p /nix/var/nix/profiles/system --set "$systemConfig"
        "$systemConfig/activate"

        trap - ERR
        as_user git commit --quiet -m "chore: bump $after" -- flake.lock "$manifest"
        echo "switched and committed: $after"
      '';
    serviceConfig = {
      RunAtLoad = false;
      # 07:00 and 19:00, outside working hours. Missed runs (machine asleep)
      # fire on next wake.
      StartCalendarInterval = [
        {
          Hour = 7;
          Minute = 0;
        }
        {
          Hour = 19;
          Minute = 0;
        }
      ];
      StandardOutPath = "/var/log/nixpkgs-agents-update.log";
      StandardErrorPath = "/var/log/nixpkgs-agents-update.log";
      LowPriorityIO = true;
      Nice = 10;
    };
  };

  # Microsoft Defender folder exclusions.
  #
  # Defender is MDM-managed and the pushed profile
  # (/Library/Managed Preferences/com.microsoft.wdav.plist) excludes only the
  # Atera agent's six paths, with enableRealTimeProtection and scanArchives
  # both true. Local exclusions live in a separate root-owned store,
  # /Library/Application Support/Microsoft/Defender/wdavcfg. They are merged
  # with the admin set, not overridden by it: the profile leaves
  # exclusionsMergePolicy unset, and `sudo mdatp exclusion list` returns the
  # six Atera paths alongside the locally-added ones. That store is machine
  # state, not config, so it was silently lost on rebuild. This puts it back.
  #
  # As of 2026-09-09 the local additions were /nix and the Docker Data
  # directory. The Go caches were not excluded, which is where
  # wdavdaemon_unprivileged was spending 33% of a core during Go builds.
  #
  # ~/src is deliberately left in. Everything excluded here is either derived
  # build output or an opaque VM image Defender cannot usefully inspect; ~/src
  # holds third-party code, so it keeps real-time protection.
  #
  # Has to hang off postActivation. nix-darwin builds the activation script
  # from an explicit list of names in modules/system/activation-scripts.nix, so
  # `system.activationScripts.<anything-else>` type-checks, evaluates, and then
  # never runs. That script also refuses to run as anything but root, which is
  # what mdatp needs.
  #
  # `mdatp exclusion folder add` is idempotent: given a path already present it
  # writes nothing and reports "New setting value is the same as the current
  # value". Its exit code in that case is undocumented, so errors are swallowed
  # rather than aborting the switch. Consequence worth knowing: if IT removes
  # one of these, the next `darwin-rebuild switch` puts it back.
  system.activationScripts.postActivation.text = ''
    if [ -x /usr/local/bin/mdatp ]; then
      echo "configuring Microsoft Defender folder exclusions..." >&2
      for path in \
        /nix \
        /Users/${primaryUser}/.cache/nix \
        /Users/${primaryUser}/Library/Caches/go-build \
        /Users/${primaryUser}/go/pkg/mod \
        /Users/${primaryUser}/Library/Containers/com.docker.docker/Data
      do
        /usr/local/bin/mdatp exclusion folder add --path "$path" >/dev/null 2>&1 || true
      done
    fi
  '';

  # Enable alternative shell support in nix-darwin.
  programs.zsh.enable = true;

  # Enable nix-index and its command-not-found helper.
  programs.nix-index.enable = true;

  # Unlock sudo commands with Touch ID.
  security.pam.services.sudo_local.touchIdAuth = true;

  # Enable AeroSpace (i3-like) tiling window manager.
  #services.aerospace.enable = true;

  #services.openvpn.servers = {
  #  split = { config = ./share/openvpn/cvpn-endpoint-0e542def271e55c72.ovpn; };
  #};

  # Enable direnv and lorri (but lorri doesn't support determinant nix)
  #services.lorri.enable = true;
  programs.direnv.enable = true;

  # Enable ollama
  services.ollama = {
    enable = true;
  };

  ## Enable litellm with GitHub Copilot proxy
  #services.litellm = {
  #  enable = true;
  #  settings = {
  #    general_settings = {
  #      master_key = "sk-dummy";
  #    };
  #    litellm_settings = {
  #      drop_params = true;
  #    };
  #    model_list = [
  #      {
  #        model_name = "gpt-5";
  #        litellm_params = {
  #          model = "github_copilot/gpt-5";
  #          extra_headers = {
  #            editor-version = "vscode/1.85.1";
  #            editor-plugin-version = "copilot/1.155.0";
  #            Copilot-Integration-Id = "vscode-chat";
  #            user-agent = "GithubCopilot/1.155.0";
  #          };
  #        };
  #      }
  #    ];
  #  };
  #};

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}

# Coding and DevOps role configuration
{ config, lib, pkgs, unstable, ... }:

{
  # User groups for development
  users.users.corin.extraGroups = [
    "docker"
    "kvm"
    "libvirtd"
    "libvirt"
    "dialout"  # Serial ports for embedded dev
  ];

  # Docker
  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
  };

  # Lorri for nix-shell environments
  services.lorri.enable = true;

  # Development packages
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    emacs

    # Build tools
    gnumake
    gcc
    gdb

    # Language tools
    universal-ctags
    shellcheck

    # Nix tools
    nil  # Nix LSP
    nixpkgs-fmt

    # Containers
    docker-compose

    # CLI tools
    rlwrap
    bc
    hexedit
    bats  # Bash testing

    # Text processing
    ascii
    discount  # Markdown

    # Linting
    languagetool
    mdl

    # AI assistants
    unstable.opencode
    (pkgs.callPackage ../pkgs/claude-code.nix { })
    (pkgs.callPackage ../pkgs/copilot.nix { })
  ];
}

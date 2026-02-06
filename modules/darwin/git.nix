{ config, pkgs, lib, ... }:

{
  # macOS-specific git overrides (shared config in modules/home-manager/git.nix)

  # --- dd-gitsign handles signing via the included gitconfig
  programs.git.includes = [
    { path = "~/.config/gitsign/gitconfig"; }
  ];

  programs.git.settings = {
    core = {
      hooksPath = "/usr/local/dd/global_hooks";
      editor = "code --wait";
      pager = "delta";
    };
    url."git@github.com:" = {
      insteadOf = "https://github.com/";
    };
    tag.forceSignAnnotated = true;
    interactive.diffFilter = "delta --color-only";
    delta.navigate = true;
    merge.conflictStyle = "zdiff3";
  };

  home.packages = with pkgs; [
    delta
  ];
}

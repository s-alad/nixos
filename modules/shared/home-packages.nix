{ pkgs }:

with pkgs; [
  # --- cloud / ops
  awscli2
  azure-cli
  eksctl
  kind
  kubectx
  kubernetes-helm
  skaffold
  bazelisk
]

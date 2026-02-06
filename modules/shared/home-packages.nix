{ pkgs }:

with pkgs; [
  # --- cloud / ops
  awscli2
  google-cloud-sdk
  azure-cli
  eksctl
  kind
  kubectx
  kubernetes-helm
  skaffold
  bazelisk
]

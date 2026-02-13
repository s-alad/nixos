{ pkgs }:

with pkgs; [
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

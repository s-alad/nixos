{ pkgs }:

with pkgs; [
  awscli2
  google-cloud-sdk
  eksctl
  kind
  kubectx
  kubernetes-helm
  skaffold
  bazelisk
  buildifier
  wrangler
  nodejs
  yarn
  lazydocker
]

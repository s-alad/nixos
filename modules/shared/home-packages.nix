{ pkgs }:

with pkgs; [
  awscli2
  google-cloud-sdk
  # azure-cli  # broken in nixpkgs unstable (missing azure.mgmt.web.v2024_11_01) — re-enable when fixed
  eksctl
  kind
  kubectx
  kubernetes-helm
  skaffold
  bazelisk
  wrangler
]

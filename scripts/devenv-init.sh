#!/usr/bin/env bash
set -e

echo " ▸ Creating devenv scaffold..."

# Create .nixdev directory and run devenv init there
mkdir -p .nixdev
devenv init --quiet .nixdev

# Create .envrc at root (overwrite the one devenv created in .nixdev)
cat > .envrc << 'EOF'
#!/usr/bin/env bash
cd .nixdev || exit
eval "$(devenv direnvrc)"
use devenv --quiet
cd ..
EOF

# Remove the .envrc that devenv created in .nixdev
rm -f .nixdev/.envrc

# Update enterShell to show a nice status line (replace multiline block)
perl -i -0pe "s/enterShell = ''.*?'';/enterShell = ''\n    echo \" ▸ devenv online\"\n  '';/s" .nixdev/devenv.nix

# Add to .gitignore if it exists, or create it
if [ -f .gitignore ]; then
  if ! grep -q ".nixdev/.devenv" .gitignore 2>/dev/null; then
    cat >> .gitignore << 'EOF'

# Devenv
.nixdev/.devenv*
.nixdev/devenv.lock
.nixdev/devenv.local.nix

# direnv
.direnv

# pre-commit
.pre-commit-config.yaml
EOF
  fi
else
  cat > .gitignore << 'EOF'
# Devenv
.nixdev/.devenv*
.nixdev/devenv.lock
.nixdev/devenv.local.nix

# direnv
.direnv

# pre-commit
.pre-commit-config.yaml
EOF
fi

# Allow direnv
direnv allow

echo " ▸ Done! Edit .nixdev/devenv.nix to customize."

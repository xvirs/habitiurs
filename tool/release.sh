#!/usr/bin/env bash
# tool/release.sh — release de un comando. Uso: ./tool/release.sh patch|minor|major|X.Y.Z
set -euo pipefail
PUBSPEC="pubspec.yaml"
[[ -f "$PUBSPEC" ]] || { echo "❌ Corré desde la raíz del repo." >&2; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { echo "❌ Working tree sucio." >&2; git status --short >&2; exit 1; }
[[ $# -eq 1 ]] || { echo "Uso: ./tool/release.sh <patch|minor|major|X.Y.Z>" >&2; exit 1; }

current="$(grep -E '^version:' "$PUBSPEC" | head -1 | sed 's/version: //' | tr -d '[:space:]')"
name_part="${current%%+*}"; build_part="${current##*+}"
IFS='.' read -r major minor patch <<< "$name_part"
case "$1" in
  patch) patch=$((patch+1));;
  minor) minor=$((minor+1)); patch=0;;
  major) major=$((major+1)); minor=0; patch=0;;
  *.*.*) IFS='.' read -r major minor patch <<< "$1";;
  *) echo "❌ Argumento inválido: '$1'" >&2; exit 1;;
esac
new_name="${major}.${minor}.${patch}"; new_build=$((build_part+1))
new_version="${new_name}+${new_build}"; tag="v${new_name}"
branch="$(git rev-parse --abbrev-ref HEAD)"
echo "  ${current} → ${new_version}   (tag ${tag}, rama ${branch})"
echo "Esto edita pubspec, commitea, taggea y pushea (DISPARA deploy a producción)."
read -r -p "¿Continuar? [y/N] " c; [[ "$c" == "y" || "$c" == "Y" ]] || { echo "Cancelado."; exit 0; }
git rev-parse "$tag" >/dev/null 2>&1 && { echo "❌ El tag $tag ya existe." >&2; exit 1; }
sed -i '' -E "s/^version:.*/version: ${new_version}/" "$PUBSPEC"   # macOS sed; en Linux usá: sed -i -E
git add "$PUBSPEC"; git commit -m "chore(release): ${new_name} (build ${new_build})"
git tag "$tag"; git push origin "$branch"; git push origin "$tag"
echo "✅ Release ${tag} disparado: https://github.com/xvirs/habitiurs/actions"
echo "   iOS: entrá a App Store Connect y enviá la versión a revisión."

---
description: Publica una nueva versión — analiza commits, bumpea versión, mueve ramas develop→main, crea el tag y dispara el deploy a las stores.
argument-hint: "[patch|minor|major|X.Y.Z] [--dry-run]"
allowed-tools: Bash, Read, Edit
---

Sos el release manager (Flutter, publicada en App Store y/o Play Store).
Tu trabajo: ejecutar un release completo de forma segura, deduciendo todo lo que puedas y
pidiendo confirmación antes de cualquier acción irreversible.

Argumentos recibidos: `$ARGUMENTS`
- Si incluye `patch`, `minor`, `major` o un `X.Y.Z` explícito → usalo como bump (override).
- Si incluye `--dry-run` → hacé SOLO el análisis y mostrá el plan, sin ejecutar nada.
- Si está vacío → deducí el bump de los commits (ver paso 3).

## Flujo de ramas (respetalo)

`develop` = trabajo. `main` = producción, lleva el tag `vX.Y.Z`.
El release se prepara en develop, se mergea a main, se taggea en main, y se sincroniza develop.
El push del tag `v*.*.*` dispara los workflows de release (Android → Play, iOS → App Store Connect).

## Paso 1 — Estado y precondiciones

- `git status --porcelain` — el working tree debe estar limpio. Si hay cambios, frená y mostralos.
- `git rev-parse --abbrev-ref HEAD` — deberías estar en `develop`. Si no, frená y preguntá.
- `git fetch origin --tags`.
- Verificá que `develop` local y `origin/develop` no divergan; si divergen, avisá.

## Paso 2 — Versión actual y último release

- Leé la versión actual de `pubspec.yaml` (línea `version: X.Y.Z+N`).
- Último tag: `git describe --tags --abbrev=0 --match 'v*'`.
- Commits desde el último tag: `git log <ultimo-tag>..HEAD --pretty=format:'%s'`.

## Paso 3 — Deducir el bump (si no vino por argumento)

Clasificá los commits desde el último tag por su prefijo conventional:
- `BREAKING CHANGE` en el body, o `!` después del tipo (ej. `feat!:`) → **major**.
- Algún `feat:` → **minor**.
- Solo `fix:`, `perf:`, `refactor:`, `chore:`, `docs:`, etc. → **patch**.
Tomá el nivel más alto. Ignorá `chore(release):` y merges al clasificar.

Nueva versión = aplicar el bump al `X.Y.Z` actual. **El build number (+N) SIEMPRE incrementa +1**
(si no, las stores rechazan la subida por build repetido). Nuevo tag = `vX.Y.Z`.

## Paso 4 — Mostrar el plan y CONFIRMAR

Presentá: versión actual → nueva, tipo de bump y por qué, changelog agrupado
(Features / Fixes / Otros), y las acciones git exactas. Recordá que el tag dispara deploy
a **producción** en Android y subida a App Store Connect en iOS.

Si es `--dry-run`: terminá acá.
Si no: pedí confirmación explícita ("¿Ejecuto el release vX.Y.Z? [y/N]"). No sigas sin un sí claro.

## Paso 5 — Ejecutar (solo tras confirmación)

1. Verificá que el tag no exista: `git rev-parse vX.Y.Z` debe fallar. Si existe, frená.
2. Bump en develop: editá `version:` de `pubspec.yaml` a `X.Y.Z+N`;
   `git add pubspec.yaml`; `git commit -m "chore(release): X.Y.Z (build N)"`.
3. Merge a main y tag:
   `git checkout main`; `git merge --no-ff develop -m "Merge develop into main for release vX.Y.Z"`;
   `git tag -a vX.Y.Z -m "Release vX.Y.Z"`.
4. Push de producción (DISPARA los workflows): `git push origin main`; `git push origin vX.Y.Z`.
5. Sincronizar develop: `git checkout develop`; `git merge main`; `git push origin develop`.
6. Confirmá que terminaste en `develop`.

## Paso 6 — Reportar

- Link a workflows: https://github.com/xvirs/habitiurs/actions
- **Android**: sube al track **`alpha`** (prueba cerrada) por defecto. Producción requiere que
  Google te habilite acceso (cuenta personal: 12 testers / 14 días). No cambies a `production`
  a ciegas o falla con "Precondition check failed".
- **iOS**: el build llega a App Store Connect (TestFlight). Apple **obliga a revisión humana** —
  recordale al usuario entrar a https://appstoreconnect.apple.com, seleccionar el build nuevo
  y enviar la versión a revisión (~1 día). No se puede automatizar ese envío.
- Si un workflow falla por secrets faltantes, remití a `docs/cicd_setup.md`.

Sé conciso en la ejecución.

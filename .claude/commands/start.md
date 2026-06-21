---
description: Empezar un trabajo nuevo — pregunta el tipo (fix/feature/refactor…) y una descripción, y crea la rama bien nombrada desde develop.
argument-hint: "[tipo] [descripción corta]"
allowed-tools: Bash, Read, AskUserQuestion
---

Sos el asistente de inicio de trabajo (git-flow: las ramas nacen de `develop`).

## Paso 1 — Tipo de trabajo

Si `$ARGUMENTS` ya trae un tipo válido y una descripción, usalos y salteá la pregunta.
Si no, usá **AskUserQuestion** "¿Qué tipo de trabajo es?" con estas opciones (la opción
"Other" que aparece sola cubre los casos menos comunes: docs, perf, test, style):

- **Feature** — funcionalidad nueva. Prefijo de rama `feature/`, commits `feat:`.
- **Fix** — corrección de bug. Prefijo `fix/`, commits `fix:`.
- **Refactor** — reorganizar código sin cambiar comportamiento. Prefijo `refactor/`, commits `refactor:`.
- **Chore** — mantenimiento, deps, config. Prefijo `chore/`, commits `chore:`.

Mapeo tipo → prefijo de rama / tipo de commit:
`feature→feature/ + feat` · `fix→fix/ + fix` · `refactor→refactor/ + refactor` ·
`chore→chore/ + chore` · `docs→docs/ + docs` · `perf→perf/ + perf`.

## Paso 2 — Descripción

Si no vino en `$ARGUMENTS`, pedile al usuario una descripción corta de qué va a hacer
(una frase). De ahí derivá un **slug kebab-case** (minúsculas, sin acentos, palabras con `-`,
máx ~5 palabras). Ej: "rediseño del alta de gasto" → `rediseno-alta-de-gasto`.

Nombre de rama final: `<prefijo>/<slug>` (ej. `feature/rediseno-alta-de-gasto`).

## Paso 3 — Crear la rama (con confirmación)

Mostrale al usuario: tipo, nombre de rama, y el prefijo de commit que va a usar.
Pedí confirmación corta. Tras el OK:

1. `git status --porcelain` — si hay cambios sin commitear, avisá y preguntá antes de cambiar de rama.
2. `git checkout develop`
3. `git fetch origin && git pull --ff-only origin develop` (partir de develop al día).
4. `git checkout -b <prefijo>/<slug>`
5. Confirmá con `git rev-parse --abbrev-ref HEAD`.

## Paso 4 — Reportar

Decile al usuario:
- Que ya está en la rama nueva, lista para trabajar.
- Que use el prefijo de commit correspondiente (`feat:`, `fix:`, etc.) — eso es lo que después
  hace que `/release` deduzca bien si el próximo release es patch/minor/major.
- Que cuando termine, corra `/finish` (o `/flow` → "Terminar") para mergear a `develop`.

Sé conciso.

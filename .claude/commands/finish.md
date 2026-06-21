---
description: Terminar el trabajo actual — commitea lo pendiente, mergea la rama a develop, la pushea y opcionalmente la borra y/o lanza el release.
allowed-tools: Bash, Read, Edit, AskUserQuestion
---

Sos el asistente de cierre de trabajo (git-flow: las ramas vuelven a `develop`).

## Paso 1 — Validar contexto

- `git rev-parse --abbrev-ref HEAD` — rama actual. Debe ser una rama de trabajo
  (`feature/…`, `fix/…`, `refactor/…`, etc.). Si estás en `develop` o `main`, **frená**:
  no hay nada que cerrar; sugerí `/start` o `/release`.
- `git status --short` — mirá qué hay sin commitear.

## Paso 2 — Commitear lo pendiente

Si hay cambios sin commitear:
- Resumí qué cambió (`git status --short` y, si ayuda, `git diff --stat`).
- Proponé un mensaje conventional acorde al prefijo de la rama
  (ej. rama `feature/x` → `feat: …`; `fix/x` → `fix: …`), con una descripción clara.
- Mostrá el mensaje y pedí confirmación. Tras OK: `git add -A && git commit -m "<mensaje>"`.
- Si no hay cambios pendientes, seguí.

## Paso 3 — Mergear a develop (con confirmación)

Mostrá el plan (rama → develop) y pedí confirmación. Tras OK, en orden, parando si algo falla:

1. `git checkout develop`
2. `git fetch origin && git pull --ff-only origin develop`
3. `git merge --no-ff <rama-de-trabajo> -m "Merge <rama-de-trabajo> into develop"`
4. `git push origin develop`

## Paso 4 — Limpieza (preguntá)

Preguntá si querés borrar la rama de trabajo ya mergeada:
- Local: `git branch -d <rama>`
- Remota (si existía): `git push origin --delete <rama>`

## Paso 5 — ¿Publicar ahora?

Preguntá si querés lanzar un release ya mismo con estos cambios.
- Si sí → leé `.claude/commands/release.md` y ejecutá ese playbook.
- Si no → recordale que cuando junte varios cambios puede correr `/release` (o `/flow` → "Publicar").

Sé conciso: mostrá comandos y resultados, no narres de más.

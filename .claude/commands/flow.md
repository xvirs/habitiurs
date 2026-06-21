---
description: Menú central del flujo de desarrollo — preguntá qué querés hacer (empezar trabajo, terminar, publicar release) y enrutá al comando correcto.
allowed-tools: Bash, Read, Edit, AskUserQuestion
---

Sos el orquestador del flujo de desarrollo (Flutter, git-flow: `develop` trabajo, `main` producción).

Primero, dale contexto al usuario de dónde está parado: corré `git rev-parse --abbrev-ref HEAD`
(rama actual) y `git status --short` (cambios pendientes), y mostralo en una línea.

Después usá **AskUserQuestion** para preguntar "¿Qué querés hacer?" con estas opciones:

1. **Empezar un trabajo nuevo** — crear una rama para un fix/feature/refactor.
   → Seguí las instrucciones de `.claude/commands/start.md` (leelo y ejecutalo).
2. **Terminar el trabajo actual** — mergear la rama actual a `develop`.
   → Seguí las instrucciones de `.claude/commands/finish.md` (leelo y ejecutalo).
3. **Publicar un release** — bump de versión, `develop→main`, tag y deploy a las stores.
   → Seguí las instrucciones de `.claude/commands/release.md` (leelo y ejecutalo).

Según la opción elegida, leé el archivo de comando correspondiente con la tool Read y ejecutá
ese playbook completo. No reimplementes la lógica acá — el archivo es la fuente de verdad.

Si el usuario ya dijo en `$ARGUMENTS` qué quiere (ej. "empezar", "terminar", "release"),
salteá la pregunta y andá directo al playbook correspondiente.

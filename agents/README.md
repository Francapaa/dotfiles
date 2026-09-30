# Skills

## Públicas (reinstalables desde GitHub)

Estas se reinstalan con el `install` vía URL, no se copian binarios:

- `supabase-postgres-best-practices` <- https://github.com/supabase/agent-skills.git (`skills/supabase-postgres-best-practices/SKILL.md`)
- `emil-design-eng` <- https://github.com/emilkowalski/skill.git (`skills/emil-design-eng/SKILL.md`)

Ver `skills-manifest.json` y `../scripts/Install-Skills.ps1` (lógica incluida en `install.ps1`).

## Privadas / propias (NO van a este repo público)

Tus customs (~22: `brand`, `dev-rules`, `seo-geo`, `threejs-*`, `ui-*`, `design`, `slides`, `banner-design`, `cpp-best-practices`, `create-pr`, `frontend-scream`, `design-game-of-thrones`, etc.) van a un repo PRIVADO aparte, ej:

```
skills-private/
  brand/SKILL.md
  dev-rules/SKILL.md
  ...
```

Recomendado: crea `skills-private` privado en GitHub y setea en tu `.env`:

```
SKILLS_PRIVATE_REPO=git@github.com:TU_USUARIO/skills-private.git
```

El `install.ps1` lo clona a `~/.agents/skills-private` y linkea cada skill a `~/.agents/skills/<nombre>` si no existe. Si no hay acceso, lo salta sin romper.

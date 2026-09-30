# dotfiles

Mis configs multiplataforma (Windows + Linux/Mac/WSL). Lenguaje: **Shell** — `install.ps1` (PowerShell) + `install.sh` (bash). Sin binarios, sin C: texto plano auditable para repo público.

Solo uso **opencode** (no claude/codex/gemini).

## Estructura

```
zed/          settings.json, keymap.json, AGENTS.md, extensions.txt
opencode/     opencode.jsonc, package.json, plugins/
agents/       skills-manifest.json (públicas por URL) + README privadas
git/          .gitconfig template
powershell/   profile + oh-my-posh.json
ssh/          config.example (nunca keys)
scripts/      Export-Configs.ps1
tests/        Test-Dotfiles.ps1
```

## Uso en PC nuevo

```powershell
git clone https://github.com/TU_USUARIO/dotfiles.git ~/dotfiles
cd ~/dotfiles
Copy-Item .env.example .env   # completa tus valores, nunca se commitea
.\install.ps1
```

Linux/Mac/WSL:

```bash
git clone https://github.com/TU_USUARIO/dotfiles.git ~/dotfiles
cd ~/dotfiles
cp .env.example .env
./install.sh
```

Restaura con symlinks (fallback a copia si no hay Developer Mode). Hace backup `.bak-fecha` de lo existente.

## Skills públicas vs privadas

- Públicas (`supabase-postgres-best-practices`, `emil-design-eng`): se reinstalan por URL, ver `agents/skills-manifest.json`.
- Privadas (~22 customs): van a repo privado `skills-private`, seteado en `.env` como `SKILLS_PRIVATE_REPO`. El install lo clona a `~/.agents/skills-private` y linkea. Si no hay acceso, lo salta.

## Mantener actualizado

```powershell
./scripts/Export-Configs.ps1
pwsh -File tests/Test-Dotfiles.ps1
git add -A; git commit -m "Update configs"; git push
```

## Seguridad (repo público)

- `.env` siempre gitignored, solo `.env.example` se sube.
- `id_ed25519`, `*.pem`, `*.key`, tokens: bloqueados en `.gitignore` + test `sin secretos detectados`.
- `.ssh/` nunca se copia al repo.

# SSH

Este repo NUNCA incluye claves privadas.

Generar nuevas en PC nuevo:

```powershell
ssh-keygen -t ed25519 -C "tu@email.com"
cat ~/.ssh/id_ed25519.pub
# subir la .pub a GitHub
```

El `install.ps1` solo crea `~/.ssh` y copia `config.example` -> `config` si no existe. Nunca toca tus keys.

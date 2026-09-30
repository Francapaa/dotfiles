# Exporta configs reales -> dotfiles (para mantener actualizado)
# Uso: pwsh ./scripts/Export-Configs.ps1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

function Copy-Safe($src, $dst) {
  if (Test-Path $src) {
    New-Item -ItemType Directory -Path (Split-Path $dst) -Force | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
    Write-Host "OK $dst"
  } else { Write-Host "SKIP (no existe): $src" -ForegroundColor Yellow }
}

# Zed (Windows)
Copy-Safe "$env:APPDATA\Zed\settings.json" "$Root\zed\settings.json"
Copy-Safe "$env:APPDATA\Zed\keymap.json" "$Root\zed\keymap.json"
Copy-Safe "$env:APPDATA\Zed\AGENTS.md" "$Root\zed\AGENTS.md"
# Extensiones: solo lista
$work = "$env:LOCALAPPDATA\Zed\extensions\work"
if (Test-Path $work) {
  Get-ChildItem $work -Directory | Select-Object -ExpandProperty Name | Set-Content "$Root\zed\extensions.txt"
  Write-Host "OK zed/extensions.txt"
}

# Opencode
Copy-Safe "$env:USERPROFILE\.config\opencode\opencode.jsonc" "$Root\opencode\opencode.jsonc"
Copy-Safe "$env:USERPROFILE\.config\opencode\package.json" "$Root\opencode\package.json"
if (Test-Path "$env:USERPROFILE\.config\opencode\plugins") {
  Copy-Item "$env:USERPROFILE\.config\opencode\plugins\*" "$Root\opencode\plugins\" -Force -Recurse
  Write-Host "OK opencode/plugins"
}

# Skills lock (sin secretos, solo URLs públicas)
Copy-Safe "$env:USERPROFILE\.agents\.skill-lock.json" "$Root\agents\skill-lock.json"

Write-Host "Export listo. Revisa git diff antes de commitear." -ForegroundColor Green

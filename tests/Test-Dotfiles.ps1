# Tests dotfiles — validación sin dependencias (corre con PowerShell 5.1+)
# Uso: pwsh -File tests/Test-Dotfiles.ps1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$failed = 0
function Check($name, $cond) {
  if ($cond) { Write-Host "PASS $name" -ForegroundColor Green }
  else { Write-Host "FAIL $name" -ForegroundColor Red; $script:failed++ }
}

# 1. Archivos base existen
Check "gitignore existe" (Test-Path "$Root\.gitignore")
Check "env.example existe" (Test-Path "$Root\.env.example")
Check "install.ps1 existe" (Test-Path "$Root\install.ps1")
Check "install.sh existe" (Test-Path "$Root\install.sh")
Check "zed/settings.json existe" (Test-Path "$Root\zed\settings.json")
Check "zed/keymap.json existe" (Test-Path "$Root\zed\keymap.json")
Check "opencode.jsonc existe" (Test-Path "$Root\opencode\opencode.jsonc")
Check "profile ps1 existe" (Test-Path "$Root\powershell\Microsoft.PowerShell_profile.ps1")
Check "skills-manifest existe" (Test-Path "$Root\agents\skills-manifest.json")

# 2. .env real NO commiteado (no debe existir en repo limpio / debe estar gitignored)
$gi = Get-Content "$Root\.gitignore" -Raw
Check ".gitignore bloquea .env" ($gi -match '(?m)^\.env$')
Check ".gitignore bloquea ssh keys" ($gi -match 'id_ed25519')

# 3. Sin secretos en repo (scan básico, excluye el propio test para evitar auto-match)
$bad = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '[\\/]tests[\\/]' } | Select-String -Pattern 'BEGIN (OPENSSH |RSA )?PRIVATE KEY|sk-ant-[A-Za-z0-9_-]{10,}|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}' -ErrorAction SilentlyContinue
Check "sin secretos detectados" ($null -eq $bad)

# 4. JSON válidos (Zed usa JSONC: se permiten comentarios //)
try { (Get-Content "$Root\zed\keymap.json" | Where-Object { $_ -notmatch '^\s*//' }) -join "`n" | ConvertFrom-Json | Out-Null; Check "keymap.json válido" $true } catch { Check "keymap.json válido" $false }
try { Get-Content "$Root\agents\skills-manifest.json" -Raw | ConvertFrom-Json | Out-Null; Check "skills-manifest válido" $true } catch { Check "skills-manifest válido" $false }
try { Get-Content "$Root\powershell\oh-my-posh.json" -Raw | ConvertFrom-Json | Out-Null; Check "oh-my-posh válido" $true } catch { Check "oh-my-posh válido" $false }

# 5. Scripts parsean (PowerShell AST)
try {
  [void][System.Management.Automation.Language.Parser]::ParseFile("$Root\install.ps1", [ref]$null, [ref]$null)
  Check "install.ps1 parsea" $true
} catch { Check "install.ps1 parsea" $false }

# 6. .gitconfig template no tiene email real
$gc = Get-Content "$Root\git\.gitconfig" -Raw
Check ".gitconfig es template" ($gc -match 'TU_EMAIL' -and $gc -notmatch 'franciscocaparruva@gmail.com')

if ($failed -gt 0) { Write-Host "$failed tests FAILED" -ForegroundColor Red; exit 1 }
Write-Host "Todos los tests pasaron." -ForegroundColor Green

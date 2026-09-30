# PowerShell profile — dotfiles (Windows + PS7 compatible)
# Ubicación Windows: ~/OneDrive/Documentos/WindowsPowerShell/Microsoft.PowerShell_profile.ps1
#                    o ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1 (PS7)
# En Linux/Mac: ~/.config/powershell/Microsoft.PowerShell_profile.ps1

# 1. Cargar .env del dotfiles (si existe, nunca se commitea)
$DotfilesRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path $DotfilesRoot)) { $DotfilesRoot = "$env:USERPROFILE\dotfiles" }
$EnvFile = Join-Path $DotfilesRoot ".env"
if (Test-Path $EnvFile) {
  Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
    $k, $v = $_ -split '=', 2
    if ($k -and $v) { Set-Item -Path "env:$($k.Trim())" -Value $v.Trim() }
  }
}

# 2. oh-my-posh (si está instalado)
$OmpTheme = Join-Path $DotfilesRoot "powershell\oh-my-posh.json"
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
  if (Test-Path $OmpTheme) { oh-my-posh init pwsh --config $OmpTheme | Invoke-Expression }
  else { oh-my-posh init pwsh | Invoke-Expression }
}

# 3. PATH útil (multiplataforma, solo agrega si existe)
$ExtraPaths = @(
  "$env:USERPROFILE\.bun\bin",
  "$env:USERPROFILE\.cargo\bin",
  "$env:USERPROFILE\go\bin",
  "$env:USERPROFILE\scoop\shims"
)
foreach ($p in $ExtraPaths) {
  if ((Test-Path $p) -and ($env:PATH -notlike "*$p*")) { $env:PATH = "$p;$env:PATH" }
}

# 4. Aliases
Set-Alias -Name ll -Value Get-ChildItem -ErrorAction SilentlyContinue
function gs { git status $args }
function gp { git pull $args }
function dot { Set-Location $DotfilesRoot }
function edit-zed { zed $DotfilesRoot }

# 5. Opencode default (coincide con tu Zed settings.json)
if (-not $env:OPECODE_MODEL) { $env:OPECODE_MODEL = "opencode/muse-spark-1.3-contributor-free" }

Write-Host "dotfiles profile cargado ($DotfilesRoot)" -ForegroundColor DarkGray

# dotfiles install — Windows (PowerShell 5.1+) y PS7 multiplataforma
# Uso: pwsh -File install.ps1   (o .\install.ps1)
# No requiere admin. Si Developer Mode está activo usa symlinks, si no copia.
param([switch]$CopyOnly)

$ErrorActionPreference = "Stop"
$Dotfiles = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "dotfiles: $Dotfiles" -ForegroundColor Cyan

function Link-Or-Copy($src, $dst) {
  if (-not (Test-Path $src)) { Write-Host "SKIP (falta fuente): $src" -ForegroundColor Yellow; return }
  $dir = Split-Path -Parent $dst
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  if (Test-Path $dst) {
    $bak = "$dst.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Move-Item -LiteralPath $dst -Destination $bak -Force
    Write-Host "backup: $bak" -ForegroundColor DarkGray
  }
  if ($CopyOnly) { Copy-Item -LiteralPath $src -Destination $dst -Force -Recurse; Write-Host "copy: $dst"; return }
  try {
    New-Item -ItemType SymbolicLink -Path $dst -Target $src -Force | Out-Null
    Write-Host "link: $dst -> $src" -ForegroundColor Green
  } catch {
    Copy-Item -LiteralPath $src -Destination $dst -Force -Recurse
    Write-Host "copy (fallback, activa Developer Mode para symlinks): $dst" -ForegroundColor Yellow
  }
}

# --- Rutas por OS ---
if ($IsLinux -or $IsMacOS) {
  $ZedDir = "$HOME/.config/zed"
  $OpencodeDir = "$HOME/.config/opencode"
  $SkillsDir = "$HOME/.agents/skills"
  $ProfileDest = "$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"
} else {
  $ZedDir = "$env:APPDATA\Zed"
  $OpencodeDir = "$env:USERPROFILE\.config\opencode"
  $SkillsDir = "$env:USERPROFILE\.agents\skills"
  # PowerShell profile: respetar $PROFILE real (OneDrive mueve Documents en tu PC)
  $ProfileDest = $PROFILE
}

# --- .env (nunca se commitea) ---
if (-not (Test-Path (Join-Path $Dotfiles ".env"))) {
  Copy-Item (Join-Path $Dotfiles ".env.example") (Join-Path $Dotfiles ".env") -Force
  Write-Host "creado .env desde .env.example — completalo" -ForegroundColor Yellow
}
# Cargar .env a sesión
Get-Content (Join-Path $Dotfiles ".env") | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
  $k, $v = $_ -split '=', 2
  if ($k -and $v) { Set-Item -Path "env:$($k.Trim())" -Value $v.Trim() -ErrorAction SilentlyContinue }
}

# --- Zed ---
Link-Or-Copy (Join-Path $Dotfiles "zed\settings.json") (Join-Path $ZedDir "settings.json")
Link-Or-Copy (Join-Path $Dotfiles "zed\keymap.json") (Join-Path $ZedDir "keymap.json")
Link-Or-Copy (Join-Path $Dotfiles "zed\AGENTS.md") (Join-Path $ZedDir "AGENTS.md")
Write-Host "Zed extensions (instalar manual): zed extensions install <id>  (ver zed/extensions.txt)"

# --- Opencode (solo opencode, no claude/codex/gemini) ---
Link-Or-Copy (Join-Path $Dotfiles "opencode\opencode.jsonc") (Join-Path $OpencodeDir "opencode.jsonc")
$plugSrc = Join-Path $Dotfiles "opencode\plugins"
if (Test-Path $plugSrc) {
  New-Item -ItemType Directory -Path (Join-Path $OpencodeDir "plugins") -Force | Out-Null
  Copy-Item "$plugSrc\*" (Join-Path $OpencodeDir "plugins\") -Force -Recurse
  Write-Host "opencode plugins copiados"
}

# --- Git (no pisa tu identidad si ya existe) ---
$gitName = git config --global user.name 2>$null
$gitEmail = git config --global user.email 2>$null
if (-not $gitName -and $env:DOTFILES_GIT_NAME) { git config --global user.name $env:DOTFILES_GIT_NAME }
if (-not $gitEmail -and $env:DOTFILES_GIT_EMAIL) { git config --global user.email $env:DOTFILES_GIT_EMAIL }
if (-not (git config --global user.name 2>$null)) { Write-Host "TIP: setea user.name/email o DOTFILES_GIT_* en .env" -ForegroundColor Yellow }

# --- PowerShell profile ---
Link-Or-Copy (Join-Path $Dotfiles "powershell\Microsoft.PowerShell_profile.ps1") $ProfileDest

# --- SSH (solo estructura, nunca keys) ---
$sshDir = if ($IsLinux -or $IsMacOS) { "$HOME/.ssh" } else { "$env:USERPROFILE\.ssh" }
New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
if (-not (Test-Path (Join-Path $sshDir "config")) -and (Test-Path (Join-Path $Dotfiles "ssh\config.example"))) {
  Copy-Item (Join-Path $Dotfiles "ssh\config.example") (Join-Path $sshDir "config")
  Write-Host "ssh config creado desde ejemplo"
}

# --- Skills públicas (reinstalables) ---
New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
$manifest = Get-Content (Join-Path $Dotfiles "agents\skills-manifest.json") -Raw | ConvertFrom-Json
foreach ($s in $manifest.public) {
  Write-Host "skill pública: $($s.name) <- $($s.sourceUrl) [$($s.skillPath)]"
  Write-Host "  -> clónala manual o con tu gestor de skills (ver agents/README.md)"
}

# --- Skills privadas (repo privado aparte, opcional) ---
if ($env:SKILLS_PRIVATE_REPO) {
  $priv = if ($IsLinux -or $IsMacOS) { "$HOME/.agents/skills-private" } else { "$env:USERPROFILE\.agents\skills-private" }
  if (-not (Test-Path $priv)) {
    Write-Host "clonando skills privadas: $env:SKILLS_PRIVATE_REPO"
    git clone $env:SKILLS_PRIVATE_REPO $priv
  } else { Write-Host "skills privadas ya existen: $priv" }
  Get-ChildItem $priv -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $link = Join-Path $SkillsDir $_.Name
    if (-not (Test-Path $link)) { Link-Or-Copy $_.FullName $link }
  }
} else { Write-Host "SKILLS_PRIVATE_REPO no seteado — salto skills privadas (ver agents/README.md)" -ForegroundColor DarkGray }

Write-Host "Listo. Reinicia terminal/Zed." -ForegroundColor Green

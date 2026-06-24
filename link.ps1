<#
.SYNOPSIS
  Napoji AI konfiguraciu (tento repo) do cieloveho projektu cez junctions + symlinky.

.DESCRIPTION
  Zdroj pravdy su subory v tomto repe. Cielovy projekt ($Dst) ich vidi na povodnych
  cestach cez 8 linkov:
    CLAUDE.md                        symlink  -> CLAUDE.md                        (Claude)
    AGENTS.md                        symlink  -> AGENTS.md                        (Codex)
    .github/copilot-instructions.md  symlink  -> .github/copilot-instructions.md  (Copilot)
    .github/instructions             junction -> .github/instructions             (Copilot + Claude)
    .github/skills                   junction -> .github/skills                   (Copilot + Claude)
    .claude/skills                   junction -> .github/skills                   (Claude)
    .agents/skills                   junction -> .github/skills                   (Codex)

  Adresarove linky su JUNCTION (mklink /J) - Codex skilly cez dir-symlink necita,
  cez junction ano. Suborove symlinky funguju bez admina vdaka zapnutemu Developer Mode.
  Skript je idempotentny (existujuce linky bezpecne nahradi) a sam doplni
  $Dst\.git\info\exclude.

  Spustenie:  powershell -File link.ps1                       # default $Dst nizsie
              powershell -File link.ps1 -Dst C:\Code\iny-projekt
#>
param([string]$Dst = 'C:\Code\client')

$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot

if (-not (Test-Path $Dst)) { throw "Cielovy projekt neexistuje: $Dst" }

function Remove-LinkSafe($path) {
  # Odstrani LEN reparse point (junction/symlink), realny obsah ciela necha.
  $i = Get-Item $path -Force
  if ($i.PSIsContainer) { [System.IO.Directory]::Delete($i.FullName, $false) }
  else { [System.IO.File]::Delete($i.FullName) }
}

function New-Link($path, $target, $kind) {
  # $kind: 'file' (symlink na subor) | 'dir' (junction na adresar, mklink /J)
  if (-not (Test-Path $target)) { throw "Ciel neexistuje: $target" }
  $parent = Split-Path $path -Parent
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  if (Test-Path $path) {
    $i = Get-Item $path -Force
    if ($i.LinkType) { Remove-LinkSafe $path }
    else { throw "$path je realny subor/adresar, nie link - presun/zmaz rucne a spusti znova" }
  }
  $opt = if ($kind -eq 'dir') { '/J ' } else { '' }
  $out = cmd /c "mklink $opt`"$path`" `"$target`"" 2>&1
  if ($LASTEXITCODE -ne 0) { throw "mklink zlyhal pre $path : $out" }
  Write-Host "OK ($kind): $path"
}

New-Link "$Dst\CLAUDE.md"                       "$src\CLAUDE.md"                       file
New-Link "$Dst\AGENTS.md"                       "$src\AGENTS.md"                       file
New-Link "$Dst\.github\copilot-instructions.md" "$src\.github\copilot-instructions.md" file
New-Link "$Dst\.github\instructions"            "$src\.github\instructions"            dir
New-Link "$Dst\.github\skills"                   "$src\.github\skills"                  dir
New-Link "$Dst\.claude\skills"                   "$src\.github\skills"                  dir
New-Link "$Dst\.agents\skills"                   "$src\.github\skills"                  dir

# .git/info/exclude (per-klon, lokalne) - doplnit idempotentne
$ex = Join-Path $Dst '.git\info\exclude'
if (Test-Path (Join-Path $Dst '.git')) {
  $need = @('CLAUDE.md','AGENTS.md','.github/copilot-instructions.md','.github/instructions/',
            '.github/skills/','.claude/','.agents/')
  $have = if (Test-Path $ex) { Get-Content $ex } else { @() }
  $add  = $need | Where-Object { $_ -notin $have }
  if ($add) {
    Add-Content $ex (@('', '# local-only AI tooling') + $add)
    Write-Host "exclude: pridanych $($add.Count) riadkov"
  } else { Write-Host "exclude: uz kompletny" }
} else { Write-Warning "$Dst nie je git repo - .git/info/exclude preskoceny" }

Write-Host "`nHotovo. AI konfiguracia je napojena do $Dst."

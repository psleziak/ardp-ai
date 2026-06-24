<#
.SYNOPSIS
  Vytvori novy AI-config repo (skeleton) pre dalsi projekt, zoseedovany z tohto repa ako template.

.DESCRIPTION
  Skopiruje strukturu (CLAUDE.md, AGENTS.md, .github/*, .claude/settings.local.json, link.ps1,
  README.md, HANDOFF.md, .gitignore) do noveho priecinka, nastavi v jeho link.ps1 default $Dst
  na cielovy projekt, a spravi git init + prvy commit.

  Obsah je len VYCHODISKO - inspirakcie/skilly/CLAUDE.md/AGENTS.md treba adaptovat na novy projekt
  (viz HANDOFF.md v novom repe).

  Priklad:
    powershell -File new-project.ps1 -Name foo-web -Dst C:\Code\foo-web
    # -> vytvori C:\Code\foo-web-ai (default), pripraveny na `git remote add` + push
#>
param(
  [Parameter(Mandatory)][string]$Name,                 # napr. foo-web
  [Parameter(Mandatory)][string]$Dst,                  # cesta k cielovemu projektu
  [string]$Path = "C:\Code\$Name-ai"                   # kam vytvorit AI repo
)

$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot

if (Test-Path $Path) {
  if (@(Get-ChildItem $Path -Force).Count -gt 0) { throw "Cielovy priecinok existuje a nie je prazdny: $Path" }
} else {
  New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

# Polozky template-u, ktore skopirujeme (BEZ .git/)
$items = @(
  'CLAUDE.md', 'AGENTS.md', '.github', '.claude',
  'link.ps1', 'new-project.ps1', 'README.md', 'HANDOFF.md', '.gitignore'
)
foreach ($it in $items) {
  $from = Join-Path $src $it
  if (-not (Test-Path $from)) { Write-Warning "preskakujem (chyba v template): $it"; continue }
  Copy-Item $from -Destination $Path -Recurse -Force
  Write-Host "kopia: $it"
}

# V novom link.ps1 nastavit default $Dst na cielovy projekt (nahradi akykolvek existujuci default)
$linkPs1 = Join-Path $Path 'link.ps1'
$content = Get-Content $linkPs1 -Raw
$content = $content -replace "param\(\[string\]\`$Dst = '[^']*'\)", "param([string]`$Dst = '$Dst')"
Set-Content $linkPs1 $content -Encoding utf8 -NoNewline

# Cisty git repo + prvy commit
Push-Location $Path
try {
  git init -b main | Out-Null
  git config core.autocrlf false
  $n = (git config --global user.name);  if (-not $n) { $n = 'Peter Sleziak' }
  $e = (git config --global user.email); if (-not $e) { $e = 'peter@sleziak.cz' }
  git add -A
  git -c user.name="$n" -c user.email="$e" commit -q -m "initial AI config (skeleton from template) for $Name"
} finally { Pop-Location }

Write-Host "`nHotovo. Novy AI repo: $Path  (cielovy projekt: $Dst)"
Write-Host "Dalsie kroky:"
Write-Host "  1) Adaptuj obsah na projekt '$Name' (CLAUDE.md, AGENTS.md, .github/instructions/*, skilly) - viz HANDOFF.md"
Write-Host "  2) powershell -File `"$linkPs1`"            # napoji do $Dst"
Write-Host "  3) Vytvor privatny GitHub repo psleziak/$Name-ai, potom:"
Write-Host "     git -C `"$Path`" remote add origin https://github.com/psleziak/$Name-ai.git"
Write-Host "     git -C `"$Path`" push -u origin main"

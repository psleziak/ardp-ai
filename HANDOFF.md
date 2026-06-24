# Handoff: nastavenie lokálnej AI konfigurácie pre tento projekt

> Tento dokument odovzdaj AI agentovi (Claude Code / Codex / Copilot) pracujúcemu v **novom
> projekte**. Agent podľa neho zriadi a **adaptuje** AI konfiguráciu pre daný projekt.

## 0. Vyplň pred odovzdaním
- **Projekt (názov):** `ardp`
- **Cesta k projektu na tomto stroji:** `<doplň na cieľovom stroji, napr. C:\Code\ardp>`
  (potom spusti `link.ps1 -Dst <tá cesta>`)
- **Stack:** `<doplň - ak Angular/Nx, prevezmi obsah skoro celý; inak adaptuj inštrukcie/skilly>`
- **Cieľový AI repo (privátny GitHub):** `psleziak/ardp-ai` (https://github.com/psleziak/ardp-ai.git)

---

## 1. O čo ide (kontext)

Vo firemnom repozitári tohto projektu je **zakázané AI tooling**. Napriek tomu chcem Claude Code,
GitHub Copilot aj Codex používať - ale tak, aby v repozitári projektu **nebola žiadna ich stopa**.

Riešenie (osvedčené na referenčnom projekte `converge` / repo `psleziak/converge-ai`):
AI konfigurácia žije v **samostatnom privátnom GitHub repe** fyzicky **mimo** projektu a do projektu
sa **napája cez junctions + symlinky**. Súbory sú teda reálne v AI repe (verzuješ ich normálne),
v projekte sú len linky a tie sú skryté cez `.git/info/exclude` (lokálny, necommitovaný ignore).

**Tvoja úloha:** zriadiť taký AI repo pre tento projekt a **adaptovať jeho obsah** (inštrukcie,
skilly, CLAUDE.md, AGENTS.md) na tento konkrétny projekt - nie len skopírovať converge.

## 2. Architektúra (dodrž ju)

AI repo `<projekt>-ai` má túto štruktúru (zdroj pravdy):
```
CLAUDE.md                              # Claude Code projektová pamäť
AGENTS.md                              # Codex root inštrukcie
.github/copilot-instructions.md        # Copilot repo-wide inštrukcie
.github/instructions/*.instructions.md # file-type inštrukcie (Copilot + Claude @import), majú `applyTo` frontmatter
.github/skills/*/SKILL.md              # skilly - ZDIEĽANÉ Copilot + Claude + Codex
.claude/settings.local.json            # lokálne Claude nastavenia
link.ps1                               # vytvorí linky do projektu (nižšie, skopíruj celý)
README.md, .gitignore
```

`link.ps1` vytvorí do projektu **8 linkov**:

| Link v projekte | Typ | Cieľ v AI repe | Pre |
|---|---|---|---|
| `CLAUDE.md` | symlink (file) | `CLAUDE.md` | Claude |
| `AGENTS.md` | symlink (file) | `AGENTS.md` | Codex |
| `.github/copilot-instructions.md` | symlink (file) | `.github/copilot-instructions.md` | Copilot |
| `.github/instructions` | **junction** (dir) | `.github/instructions` | Copilot + Claude |
| `.github/skills` | **junction** (dir) | `.github/skills` | Copilot + Claude |
| `.claude/skills` | **junction** (dir) | `.github/skills` | Claude |
| `.agents/skills` | **junction** (dir) | `.github/skills` | Codex |
| `.claude/settings.local.json` | symlink (file) | `.claude/settings.local.json` | Claude |

> **KRITICKÉ:** adresárové linky musia byť **junction (`mklink /J`)**, NIE dir-symlink (`mklink /D`).
> Codex skilly cez dir-symlink **nečíta**, cez junction áno (junction sa Windowsu javí ako normálny
> adresár). Súborové symlinky vyžadujú zapnutý **Developer Mode** (inak `mklink` na súbor zlyhá).
> Skilly majú jediný zdroj `.github/skills`, naň ukazujú tri junctions (`.claude/skills`,
> `.agents/skills`, `.github/skills`) - žiadne kópie, žiadny drift.

`link.ps1` tiež **idempotentne doplní** do `<projekt>\.git\info\exclude` týchto 7 riadkov:
```
CLAUDE.md
AGENTS.md
.github/copilot-instructions.md
.github/instructions/
.github/skills/
.claude/
.agents/
```

## 3. Čo prevziať 1:1 vs čo ADAPTOVAŤ na tento projekt

**Prevziať bez zmeny (generické):**
- `link.ps1` (len nastav `$Dst` na cestu tohto projektu), `.gitignore`, mechanizmus, štruktúra.
- Skilly `grill-me` a `generate-commit-message` (sú projektovo-neutrálne).

**Adaptovať na tento projekt (NEkopíruj converge špecifiká naslepo):**
- `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `.github/instructions/*` - prejdi
  reálny projekt (`package.json`, `nx.json`, `tsconfig.base.json`, `eslint`, štýl existujúceho kódu)
  a prepíš ich tak, aby sedeli: názov a popis projektu, **path aliasy** (converge má `@converge/...`),
  závislostné pravidlá / lib boundaries, použité knižnice (kendo, ag-grid, ngrx...), príkazy, konvencie.
  `applyTo` glob v inštrukciách over voči reálnej štruktúre projektu.
- `create-nx-library` skill - ak je projekt Nx, uprav scope/tagy/cesty/generator flagy podľa tohto
  workspace; ak projekt nie je Nx, skill odstráň.
- `.claude/settings.local.json` - ponechaj minimálne; hooky špecifické pre iný stroj (napr. fnm cesty)
  vyhoď alebo uprav.

## 4. Postup (krok za krokom)

1. **Prereqs:** Developer Mode ON (Settings -> For developers); Git + GitHub auth (PAT/SSH);
   globálne prihlásené nástroje (Claude Code, Copilot, `codex login`).
2. **Template:** `git clone https://github.com/psleziak/converge-ai.git C:\Code\converge-ai-template`
   (zdroj na skopírovanie štruktúry a generických skillov). Ak nemáš prístup, použi `link.ps1` nižšie.
3. Vytvor `C:\Code\<projekt>-ai`, skopíruj doň štruktúru z template.
4. **Adaptuj obsah** podľa sekcie 3 (analyzuj tento projekt a prepíš inštrukcie/CLAUDE.md/AGENTS.md).
5. V `link.ps1` nastav `param([string]$Dst = '<cesta k tomuto projektu>')`.
6. Spusti: `powershell -File C:\Code\<projekt>-ai\link.ps1` (alebo `-Dst <cesta>`).
7. **Over** (sekcia 6).
8. Vytvor prázdny **privátny** GitHub repo `psleziak/<projekt>-ai`, potom v `<projekt>-ai`:
   `git init -b main && git add -A && git commit -m "initial AI config" && git remote add origin <URL> && git push -u origin main`.
   POZN.: do commit message **nedávaj** `Co-Authored-By` ani "Generated with" stopy nie sú potrebné, ale
   tento AI repo je privátny, takže tam zmienky o AI vadiť nemusia - dôležité je len, aby NIČ z toho
   neskončilo v repe samotného projektu.

## 5. Kompletný `link.ps1` (skopíruj a uprav `$Dst`)

```powershell
param([string]$Dst = 'C:\Code\<PROJEKT>')   # <-- cesta k tomuto projektu
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
if (-not (Test-Path $Dst)) { throw "Projekt neexistuje: $Dst" }

function Remove-LinkSafe($path) {
  $i = Get-Item $path -Force
  if ($i.PSIsContainer) { [System.IO.Directory]::Delete($i.FullName, $false) }
  else { [System.IO.File]::Delete($i.FullName) }
}
function New-Link($path, $target, $kind) {   # $kind: 'file' = symlink, 'dir' = junction (mklink /J)
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
New-Link "$Dst\.claude\settings.local.json"      "$src\.claude\settings.local.json"     file

# .git/info/exclude (per-klon, lokalne) - doplnit idempotentne
$ex = Join-Path $Dst '.git\info\exclude'
if (Test-Path (Join-Path $Dst '.git')) {
  $need = @('CLAUDE.md','AGENTS.md','.github/copilot-instructions.md','.github/instructions/',
            '.github/skills/','.claude/','.agents/')
  $have = if (Test-Path $ex) { Get-Content $ex } else { @() }
  $add  = $need | Where-Object { $_ -notin $have }
  if ($add) { Add-Content $ex (@('','# local-only AI tooling') + $add); Write-Host "exclude: +$($add.Count) riadkov" }
} else { Write-Warning "$Dst nie je git repo - exclude preskoceny" }

Write-Host "`nHotovo. AI konfiguracia napojena do $Dst."
```

## 6. Akceptačné kritériá (over po nasadení)

1. `Get-Item` na 8 ciest: `.github/instructions`, `.github/skills`, `.claude/skills`, `.agents/skills`
   majú `LinkType = Junction`; `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`,
   `.claude/settings.local.json` majú `LinkType = SymbolicLink`. Žiaden dir nesmie byť SymbolicLink.
2. Obsah čitateľný cez linky: `ls .github/instructions`, `ls .agents/skills`, `cat CLAUDE.md`, `cat AGENTS.md`.
3. Codex reálne vidí skilly (spusti Codex v projekte a over, že skilly z `.agents/skills` sú dostupné).
4. Projekt je čistý: `git -C <projekt> status` clean; `git -C <projekt> ls-files | grep -iE 'claude|copilot|agents'` = prázdne.
5. AI repo pushnutý na `psleziak/<projekt>-ai`.

## 7. Riziká / poznámky
- **Developer Mode** musí byť ON, inak file-symlinky cez `mklink` zlyhajú (junctions by išli aj bez neho).
- **Codex skilly** fungujú LEN cez junction, nie dir-symlink (overené empiricky).
- `.git/info/exclude` je per-klon, lokálny - po každom re-clone projektu znova spusti `link.ps1`.
- `~/.codex/` (auth, config.toml, global skilly) je per-stroj, mimo repa - rieš `codex login` zvlášť.
- **IP/policy:** inštrukcie opisujú interné firemné konvencie; uloženie na osobný GitHub je vedomé rozhodnutie.

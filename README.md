# ardp-ai

Súkromná AI konfigurácia (GitHub Copilot + Claude Code + Codex) pre projekt **ardp**
(repo `C:\Code\client`, Nx workspace `icz`).

> Obsah (CLAUDE.md, AGENTS.md, `.github/instructions/*`, skilly) je adaptovaný na projekt ardp.
> Tieto súbory **nie sú** súčasťou ardp repozitára (na tom projekte je AI tooling zakázaný).
> Žijú tu, verzujú sa normálne cez git a do ardp sa napájajú cez junctions + symlinky.

## Štruktúra

```text
AGENTS.md                              # Codex projektové inštrukcie (bridge na .github/*)
CLAUDE.md                              # Claude Code projektová pamäť (importuje .github/*)
.github/copilot-instructions.md        # Copilot repo-wide inštrukcie
.github/instructions/*.instructions.md # file-type-specific inštrukcie (Copilot + Claude + Codex cez AGENTS.md)
.github/skills/*/SKILL.md              # skilly (zdieľané Copilot + Claude + Codex)
link.ps1                               # napojí všetko do projektu (default C:\Code\client)
new-project.ps1                        # vyseeduje nový AI repo pre ďalší projekt
HANDOFF.md                             # briefing pre zriadenie setupu na novom projekte
```

## Setup po naklonovaní

```powershell
git clone https://github.com/psleziak/ardp-ai.git C:\Code\ardp-ai
powershell -File C:\Code\ardp-ai\link.ps1                 # default cieľ = C:\Code\client
# iný projekt:
powershell -File C:\Code\ardp-ai\link.ps1 -Dst C:\Code\iny-projekt
```

`link.ps1` vytvorí **7 linkov** - junctions (`.github/instructions`, `.github/skills`,
`.claude/skills`, `.agents/skills`) a symlinky (`AGENTS.md`, `CLAUDE.md`,
`.github/copilot-instructions.md`) do cieľa - a sám idempotentne doplní jeho `.git/info/exclude`.
Junctions nepotrebujú admin; symlinky na súbory potrebujú zapnutý **Developer Mode**
(Settings -> For developers). Skript je idempotentný.

## Codex

Codex číta repo inštrukcie z `AGENTS.md`. Tento súbor je len bridge: hlavný zdroj pravdy ostáva
`.github/copilot-instructions.md` a doplnkové pravidlá v `.github/instructions/*.instructions.md`.

Codex skilly vidí cez `.agents/skills`, čo je junction na `.github/skills`. Skilly sa preto neupravujú
ani neduplikujú špeciálne pre Codex.

**Pozor:** `.agents/skills` musí byť **junction** (`mklink /J`), nie dir-symlink - Codex skilly cez
dir-symlink nečíta. `link.ps1` to tak robí. Globálny `~/.codex/` (auth, config.toml, global skilly)
je per-stroj, mimo tohto repa - rieš `codex login` zvlášť.

## Nový projekt / nový počítač

- **Iný projekt:** `powershell -File new-project.ps1 -Name <proj> -Dst <cesta-k-projektu>` vytvorí
  `C:\Code\<proj>-ai` skeleton; potom adaptuj obsah na nový projekt (viď `HANDOFF.md`) a pushni na
  nový privátny GitHub repo.
- **ardp na nový stroj:** naklonuj ardp (`C:\Code\client`) + tento repo a spusti `link.ps1`.
- `HANDOFF.md` je samostatný briefing, ktorý možno odovzdať AI agentovi v novom projekte, aby si
  setup zriadil a obsah adaptoval sám.

## Workflow

Súbory upravuj kdekoľvek (tu alebo cez napojené cesty v projekte - je to ten istý súbor) a commituj
normálne v tomto repe. ardp o nich nevie (sú v jeho `.git/info/exclude`).

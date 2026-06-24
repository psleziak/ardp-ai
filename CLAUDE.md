# ardp - Claude Code

Tento projekt zdieľa AI inštrukcie s GitHub Copilotom. Jediný zdroj pravdy je `.github/`.
Inštrukcie nižšie sa importujú z Copilot konfigurácie, aby sa udržiavali na jednom mieste.

@.github/copilot-instructions.md
@.github/instructions/components.instructions.md
@.github/instructions/forms.instructions.md
@.github/instructions/api.instructions.md
@.github/instructions/utils.instructions.md

## Skilly

Skilly žijú v `.github/skills/` a do Claude sú napojené junctionom `.claude/skills` -> `.github/skills`.
Tieto súbory fyzicky žijú v samostatnom AI repe `C:\Code\ardp-ai` a do projektu (`C:\Code\client`) sú
napojené cez junctions + symlinky. Ak Claude skilly nevidí (napr. po novom naklonovaní projektu),
spusti raz:

```powershell
powershell -File C:\Code\ardp-ai\link.ps1
```

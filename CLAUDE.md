# Converge — Claude Code

Tento projekt zdieľa AI inštrukcie s GitHub Copilotom. Jediný zdroj pravdy je `.github/`.
Inštrukcie nižšie sa importujú z Copilot konfigurácie, aby sa udržiavali na jednom mieste.

@.github/copilot-instructions.md
@.github/instructions/components.instructions.md
@.github/instructions/forms.instructions.md
@.github/instructions/api.instructions.md
@.github/instructions/utils.instructions.md

## Skilly

Skilly žijú v `.github/skills/` a do Claude sú napojené junctionom `.claude/skills` → `.github/skills`.
Po naklonovaní repa (alebo ak Claude skilly nevidí) spusti raz:

```bash
npm run setup:claude
```

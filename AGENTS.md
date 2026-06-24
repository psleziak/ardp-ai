# Converge - Codex

This repository shares its AI guidance with GitHub Copilot and Claude Code. The canonical source of truth is the linked `.github/` configuration from `C:\Code\converge-ai`.

Before making code changes, read `.github/copilot-instructions.md` and treat it as the repo-wide Converge guidance.

Also read the relevant focused instruction files when the task touches these areas:

- `.github/instructions/components.instructions.md` for Angular component `.ts`, `.html`, or `.scss` work.
- `.github/instructions/forms.instructions.md` for form-related TypeScript work.
- `.github/instructions/api.instructions.md` for API/client/data-access work.
- `.github/instructions/utils.instructions.md` for utility/helper work.

## Skills

Codex skills are exposed at `.agents/skills`, which is a junction to the shared `.github/skills` directory. Do not duplicate or rewrite those skills for Codex; use the existing `SKILL.md` files there.

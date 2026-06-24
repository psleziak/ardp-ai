---
name: generate-commit-message
description: 'Generate a semantic Conventional Commit message from staged Git changes. Use when asked for commit message, semantic commit, conventional commit, staged files, staged diff, git commit message, or sprava commitu.'
argument-hint: '[optional intent or scope]'
---

# Generate Commit Message

## When to Use

Use this skill when the user wants a commit message for files already staged in Git.

## Goal

Produce one concise semantic commit message based only on staged changes. Prefer Conventional Commits format:

```text
type(scope): concise summary

Optional body explaining why or notable behavior changes.
```

## Procedure

1. Inspect staged changes only:
   - `git diff --cached --name-status`
   - `git diff --cached --stat`
   - `git diff --cached --`
2. If there are no staged changes, tell the user that no files are staged and do not invent a message.
3. Infer the commit `type` from the change:
   - `feat` for new user-facing behavior or capabilities
   - `fix` for bug fixes
   - `refactor` for behavior-preserving code restructuring
   - `perf` for performance improvements
   - `docs` for documentation-only changes
   - `style` for formatting-only changes
   - `test` for tests
   - `build` for build system or dependency changes
   - `ci` for CI configuration
   - `chore` for maintenance that does not fit another type
4. Infer a short `scope` from the main affected app, library, feature, or package. Omit scope when it would be noisy or misleading.
5. Write the subject in imperative mood, lowercase after the prefix, and keep it short. Avoid trailing punctuation.
6. Add a body only when it helps explain intent, risk, migration notes, or multiple meaningful changes. Keep the body to one or two short lines.
7. Do not include markdown fencing unless the user asks for it. Provide the message ready to paste into `git commit -m` or an editor.

## Output Rules

- Return the best commit message first.
- If useful, add a brief note after the message explaining the chosen type or scope.
- Do not mention unstaged or untracked files unless they affect the user's request.
- Do not run `git commit` unless the user explicitly asks.

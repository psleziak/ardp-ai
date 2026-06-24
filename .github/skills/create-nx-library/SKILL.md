---
name: create-nx-library
description: "Create a new Nx Angular library in the ardp monorepo (libs/<domain>/** where domain is core/aida/ibas/ras/ardp). Use when asked to create/scaffold/generate a new lib, feature library, ui library, or utils library (e.g. 'vytvor projekt feat-...', 'create a new ui-... library', 'add a utils lib'). Covers scope:core/aida/ibas/ras/ardp and type:feature/ui/utils/plugin, runs the @nx/angular:library generator with the correct flags, and applies the required repo-specific fixups (tags, tsconfig path alias, eslint config, reverting unwanted package.json changes)."
argument-hint: '<lib-path> e.g. libs/aida/feat-document-space (scope:aida, type:feature)'
---

# Create an Nx Library (ardp monorepo)

Scaffold a new Nx Angular library under `libs/<domain>/**`, tagged with a `scope:<domain>` and a
`type:feature` / `type:ui` / `type:utils` / `type:plugin`, matching this repo's conventions. Works for
an empty scaffold or a standard library with an entry component.

## When to Use

- "Vytvor projekt / knižnicu `feat-...`", "create a new feature library"
- "Add a `ui-...` library", "scaffold a `utils-...` lib"
- Any request to generate a new Nx library inside `libs/<domain>/**`

## ardp workspace facts

- **Domains (scope):** `core` (cross-domain shared), `ardp` (umbrella), `aida` / `ibas` / `ras`
  (per-app). Tag = `scope:<domain>`.
- **Types:** `type:feature` (`feat-*`), `type:ui` (`ui-*`), `type:utils` (`utils-*`), `type:plugin`.
- **Paths** are 2- or 3-level: `libs/aida/document-space`, `libs/core/shared/ui-form`,
  `libs/core/document/ui-detail-page`.
- **Import alias** = `@icz/<path-under-libs>` -> `libs/<path>/src/index.ts`
  (e.g. `@icz/core/shared/ui-form`).
- **Project name** is usually the path under `libs/` joined by `-` (`libs/core/shared/ui-form` ->
  `core-shared-ui-form`), **but the repo is inconsistent** (e.g. `libs/aida/document-space` is just
  `document-space`). Always pass `--name` explicitly and confirm the result with `npx nx show projects`.
- **Generator defaults** (`nx.json`): `linter: eslint`, `unitTestRunner: jest`, `prefix: app`,
  `standalone: true`, `skipTests: true`, `style: scss`.

## Inputs to confirm first

1. **Path** - `libs/<domain>/<name>` (domain = core/aida/ibas/ras/ardp).
2. **type** - `feature` / `ui` / `utils` / `plugin`. Folder name should reflect it (`feat-*` / `ui-*` / `utils-*`).
3. **Empty scaffold vs. with component** - empty = no entry component/module (recommended for feature libs).

## Critical gotchas

> The generator quirks below were captured on an older Nx. **This repo is on Nx 21.4** - flags may
> differ. Always run with `--dry-run` first and adjust.

- **Use `npx nx`, NOT `npm run nx -- g ...`.** npm can strip `--directory`.
- Prefer `--directory` + `--name` over a positional name argument.
- **Always pass `--skipPackageJson`.** Without it the generator may edit `package.json` /
  `package-lock.json` and run an install. If that already happened, revert with
  `git checkout -- package.json package-lock.json` then `npm ci`.
- To skip the NgModule use `--skipModule` (verify the exact flag name on Nx 21.4 via `--help`).

## Procedure

### 1. Run the generator (preview first)

For an **empty scaffold** (no component, no module - recommended for new feature libs):

```powershell
npx nx g @nx/angular:library `
  --directory=libs/<domain>/<name> --name=<project-name> `
  --tags=scope:<domain>,type:<type> --prefix=app `
  --importPath=@icz/<domain>/<name> `
  --style=scss --skipPackageJson --skipModule --no-interactive --dry-run
```

Drop `--dry-run` once the file list looks right. For a library **with a standalone entry component**,
drop `--skipModule` (libs default to `standalone: true` here).

### 2. Fix `project.json`

Make it match the repo standard:

```jsonc
{
  "name": "<project-name>",
  "$schema": "../../../node_modules/nx/schemas/project-schema.json", // depth depends on nesting
  "sourceRoot": "libs/<domain>/<name>/src",
  "prefix": "app",
  "projectType": "library",
  "tags": ["scope:<domain>", "type:<type>"], // an ARRAY, not a single "scope:x type:y" string
  "targets": {},
}
```

### 3. Fix the `tsconfig.base.json` path alias

The generator may append the alias at the END with a wrong `./` prefix. Move it to its correct
**alphabetical** position among the other `@icz/...` entries and drop the leading `./`:

```jsonc
"@icz/<domain>/<name>": ["libs/<domain>/<name>/src/index.ts"]
```

### 4. Fix the ESLint config (repo is mid-migration)

ardp has **mixed** per-lib eslint configs - most libs use `.eslintrc.json` (extends the root), a few
newer ones use flat `eslint.config.cjs`. **Match a sibling lib in the same domain.**

- **`.eslintrc.json`** style - `extends` the root with the correct relative depth (count the
  `libs/<domain>/<name>` nesting):

  ```jsonc
  { "extends": ["../../../.eslintrc.json"], "ignorePatterns": ["!**/*"], "overrides": [ /* app selector rules + "@angular-eslint/prefer-standalone": "off" */ ] }
  ```

- **flat `eslint.config.cjs`** style - `...baseConfig` must come FIRST (later configs override),
  `baseConfig` is the root `.eslintrc.json`:

  ```js
  const nx = require('@nx/eslint-plugin');
  const baseConfig = require('../../../.eslintrc.json');
  module.exports = [
    ...baseConfig,
    ...nx.configs['flat/angular'],
    ...nx.configs['flat/angular-template'],
    { files: ['**/*.ts'], rules: { /* @angular-eslint/component-selector + directive-selector, prefix app */ } },
    { files: ['**/*.html'], rules: {} },
  ];
  ```

### 5. If a component/module was generated but you wanted empty

Delete `src/lib/` and empty `src/index.ts` (an empty barrel lints fine).

### 6. Verify

```powershell
npx nx lint <project-name>                  # must pass
npx nx show project <project-name>          # tags = {scope:<domain>, type:<type>}, projectType library
npx prettier --check "libs/<domain>/<name>/**/*" "tsconfig.base.json"
git status --short                          # only tsconfig.base.json + new lib folder should change
```

## Module boundary reminder (enforced by ESLint)

When wiring imports later, respect the allowed dependency directions.

**By type:** `type:utils -> utils`; `type:ui -> utils, ui`; `type:feature -> utils, ui`;
`type:plugin -> utils, ui, feature`.

**By scope:** `scope:core -> core`; `scope:ardp -> ardp`; `scope:aida -> ardp, core, aida`;
`scope:ibas -> ardp, core, ibas`; `scope:ras -> ardp, core, ras`.

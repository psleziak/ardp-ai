---
name: create-nx-library
description: "Create a new Nx Angular library in the Converge monorepo (libs/app/** or libs/shared/**). Use when asked to create/scaffold/generate a new lib, feature library, ui library, or utils library (e.g. 'vytvor projekt feat-...', 'create a new ui-... library', 'add a utils lib'). Covers scope:app/scope:shared and type:feature/type:ui/type:utils, runs the @nx/angular:library generator with the correct flags, and applies the required repo-specific fixups (tags, tsconfig path alias, eslint order, reverting unwanted package.json changes)."
argument-hint: '<lib-path> e.g. libs/app/feat-acquisition-summary (scope:app, type:feature)'
---

# Create an Nx Library (Converge monorepo)

Scaffold a new Nx Angular library under `libs/app/**` (`scope:app`) or `libs/shared/**`
(`scope:shared`), tagged with a `type:feature` / `type:ui` / `type:utils`, matching this
repo's conventions. Works for an empty scaffold or a standard library with an entry component.

## When to Use

- "Vytvor projekt / knižnicu `feat-...`", "create a new feature library"
- "Add a `ui-...` library", "scaffold a `utils-...` lib"
- Any request to generate a new Nx library inside `libs/app/**` or `libs/shared/**`

## Inputs to confirm first

1. **Path** — `libs/<scope>/<name>` where `<scope>` is `app` or `shared`
   (e.g. `libs/app/feat-acquisition-summary`, `libs/shared/ui-foo`).
2. **type** — `feature`, `ui`, or `utils`. Folder name should reflect it: `feat-*` / `ui-*` / `utils-*`.
3. **Empty scaffold vs. with component** — empty = no entry component/module.

Project name = the path under `libs/` joined by `-`
(`libs/app/feat-x` → `app-feat-x`, `libs/shared/ui-x` → `shared-ui-x`).
Import alias = `@converge/<scope>/<name>` → `libs/<scope>/<name>/src/index.ts`.

## Critical gotchas (Nx 22.7.5 in this repo)

- **Use `npx nx`, NOT `npm run nx -- g ...`.** npm strips `--directory` and nx then looks for
  `<root>/app/package.json` → `ENOENT`. The big-heap `npm run nx` script is only needed for builds.
- **No positional name arg.** The generator rejects a positional name
  ("Schema does not support positional arguments"). Use `--directory` + `--name`.
- **`--skipModuleFile` does not exist** in this version. To skip the module use `--skipModule`.
- **Always pass `--skipPackageJson`.** Without it the generator edits `package.json`
  (adds `@swc/*`, bumps `prettier ^2 → ~3`) and `package-lock.json`, then runs install.
  If that already happened, revert with `git checkout -- package.json package-lock.json`
  followed by `npm ci` to restore `node_modules`.

## Procedure

### 1. Run the generator

For an **empty scaffold** (no component, no module — recommended for new feature libs):

```powershell
npx nx g @nx/angular:library `
  --directory=libs/<scope>/<name> --name=<scope>-<name> `
  --tags=scope:<scope>,type:<type> --prefix=app `
  --importPath=@converge/<scope>/<name> `
  --style=scss --skipPackageJson --standalone=false --skipModule --no-interactive
```

For a library **with a standalone entry component**, drop `--standalone=false --skipModule`
and keep `--style=scss`.

Tip: run once with `--dry-run` first to preview the file list.

### 2. Fix `project.json`

The generator can emit malformed tags and extra targets. Make it match the repo standard:

```jsonc
{
  "name": "<scope>-<name>",
  "$schema": "../../../node_modules/nx/schemas/project-schema.json",
  "sourceRoot": "libs/<scope>/<name>/src",
  "prefix": "app",
  "projectType": "library",
  "tags": ["scope:<scope>", "type:<type>"], // NOT a single "scope:app type:feature" string
  "targets": {},
}
```

### 3. Fix the `tsconfig.base.json` path alias

The generator appends the alias at the END with a wrong `./` prefix. Move it to its correct
**alphabetical** position among the other `@converge/<scope>/*` entries and drop the leading `./`:

```jsonc
"@converge/<scope>/<name>": ["libs/<scope>/<name>/src/index.ts"]
```

### 4. Fix `eslint.config.mjs`

Reorder so `...baseConfig` comes FIRST (repo convention — later configs override earlier),
and remove the placeholder `// Override or add rules here` comment:

```js
export default [
  ...baseConfig,
  ...nx.configs['flat/angular'],
  ...nx.configs['flat/angular-template'],
  // ...selector rules...
];
```

### 5. If a component/module was generated but you wanted empty

Delete `src/lib/` and empty `src/index.ts` (an empty barrel lints fine).

### 6. Verify

```powershell
npx nx lint <scope>-<name>                  # must pass
npx nx show project <scope>-<name>          # tags = {scope:<scope>, type:<type>}, projectType library
npx prettier --check "libs/<scope>/<name>/**/*" "tsconfig.base.json"
git status --short                          # only tsconfig.base.json + new lib folder should change
```

## Module boundary reminder (enforced by ESLint)

When wiring imports later, respect the allowed dependency directions:
`type:utils → utils` only; `type:ui → utils, ui`; `type:feature → utils, ui`;
`scope:shared → shared` only; `scope:app → shared, app`.

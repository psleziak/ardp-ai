# ardp - Copilot instructions

These repo-wide instructions are read automatically by GitHub Copilot for every request in this
workspace. File-type-specific rules live in `.github/instructions/*.instructions.md` and are applied
automatically when you edit matching files:

- `components.instructions.md` -> `**/*.component.{ts,html,scss}`
- `forms.instructions.md` -> `**/*.form.ts`
- `api.instructions.md` -> `**/*.api.ts`
- `utils.instructions.md` -> `**/*.utils.ts`

## Overview

ardp is a large **Angular 20 + Nx 21** monorepo (npm package name `icz`). Unlike a single-app
workspace, it ships **three deployable applications** that share a common core:

- `aida`, `ibas`, `ras` (each under `apps/`; `ibas` is the Nx `defaultProject`). `ibas-e2e` /
  `ras-e2e` are their Cypress e2e projects.

Feature/domain code lives in **~250 Nx libraries** under `libs/`, organised by **domain** (see
Architecture). Node 20+ is expected (toolchain managed via `fnm`).

## Commands

There is **no `npm start`**. Serve an app explicitly:

```bash
npx nx serve ibas              # serve the ibas app (default project) at http://localhost:4200
npx nx serve aida              # or aida / ras
npm run build:aida            # dev build (also build:ibas / build:ras)
npm run build:aida:prod       # production build (also build:ibas:prod / build:ras:prod)
npm run lint                  # nx workspace-lint && ng lint (lints everything)
npm run format                # prettier write across affected projects
npm run format:all            # prettier write across the whole workspace
npm run format:check          # prettier check (CI)
npm test                      # ng test (Jest) across projects
```

Targeted / affected Nx invocations:

```bash
npx nx lint <project>                 # lint one project, e.g. core-shared-ui-form
npx nx test <project>                 # test one project (Jest)
npx nx build ras --configuration production
npm run affected:lint                 # lint only affected projects
npm run affected:test
npm run dep-graph                     # visualize the project dependency graph
```

> The `ras` production build is memory-heavy and already sets `NODE_OPTIONS=--max_old_space_size=8192`
> in its npm script. Other targets do not need an enlarged heap.

Project names usually follow the directory path under `libs/` joined by `-`
(`libs/core/shared/ui-form` -> `core-shared-ui-form`), but naming is **not fully consistent** in this
repo (e.g. `libs/aida/document-space` is just `document-space`). Always confirm via the `name` field
in `project.json` or `npx nx show projects`.

### Tests

Unlike some sibling repos, ardp **does have a unit test runner**: Jest is configured
(`@nx/jest:jest`), each project has a `test` target, and `.spec.ts` files exist. Targets run with
`passWithNoTests`. Run `npx nx test <project>` or `npm test`. New `.spec.ts` files are welcome.

### Pre-commit

No pre-commit hooks are configured. Run `npm run format` and `npm run lint` before committing.

## Architecture

### Apps vs. libraries

- `apps/<app>/` (`aida`, `ibas`, `ras`) - thin app shells that wire routing and bootstrap.
- `libs/` - where feature/domain code lives. New work goes here.

### Library taxonomy (`libs/`)

Libraries are grouped by **domain**, not by a single `app`/`shared` split:

- `libs/core/**` - cross-domain shared building blocks (`shared/ui-core`, `shared/ui-form`,
  `shared/utils-core`, `shared/utils-http`, `shared/utils-intl`, plus domain features like
  `document`, `issue`, `lookup`, ...).
- `libs/ardp/**` - the umbrella/base domain.
- `libs/aida/**`, `libs/ibas/**`, `libs/ras/**` - per-application domains.

Each lib is tagged in its `project.json` with a `scope:*` and a `type:*`. Import libs via their
`@icz/...` path alias (defined in `tsconfig.base.json` `paths`), never by relative path across lib
boundaries.

### Module boundary rules (enforced by ESLint)

`@nx/enforce-module-boundaries` (root `.eslintrc.json`) is an **error**. Allowed directions:

**By type:**

- `type:utils` -> `utils`
- `type:ui` -> `utils`, `ui`
- `type:feature` -> `utils`, `ui`
- `type:plugin` -> `utils`, `ui`, `feature`

**By scope (domain):**

- `scope:core` -> `core` only
- `scope:ardp` -> `ardp` only
- `scope:aida` -> `ardp`, `core`, `aida`
- `scope:ibas` -> `ardp`, `core`, `ibas`
- `scope:ras` -> `ardp`, `core`, `ras`

A lint failure mentioning module boundaries means the import violates this matrix - fix the
dependency direction, don't suppress it. Folder names reflect the type: `feat-*` / `ui-*` / `utils-*`.

### Path aliases

- `@icz/<domain>/<...>` -> the lib's `src/index.ts` (e.g. `@icz/core/shared/ui-form`,
  `@icz/aida/document-space`, `@icz/core/document/ui-detail-page`).
- `@icz/ardp`, `@icz/ardp/*` and `@ibas/*` also exist for the umbrella/ibas domains.

### API layer (hand-written, NOT generated)

ardp's HTTP API layer is **hand-written** - there is no swagger/OpenAPI codegen here. API services
live in domain `utils-api` libs (`@icz/{core,aida,ibas,ras}/shared/utils-api`) and in
`@icz/ardp/shared/api`. A service is a plain `@Injectable({ providedIn: 'root' })` that calls the
shared `HttpService` (`@icz/core/shared/utils-http`):

```ts
@Injectable({ providedIn: 'root' })
export class AdminService {
  readonly #http = inject(HttpService);

  getAuditLogRecord(auditLogId: number): Observable<AuditLogRecordDto> {
    return this.#http.post('Admin/GetAuditLogRecord', { auditLogId });
  }
}
```

Models are `*Dto` interfaces under each `utils-api` lib's `models/`. To add an endpoint, **write the
service method and DTOs by hand** following the existing shape - do not look for a generator. See
`api.instructions.md` for the per-component `*.api.ts` wrapper convention.

### State management

NGRX is used across the workspace: `@ngrx/store`, `effects`, `component-store`, `signals`,
`operators`, `store-devtools`, plus `ngrx-forms` for reactive form state on large pages.

### Key UI stacks

**Kendo Angular** is used heavily (buttons, inputs, dropdowns, dialog, layout, treeview, upload,
date-inputs, intl/l10n, ...), alongside **ag-Grid**, **Angular Material + CDK**, **FontAwesome Pro**,
and **SignalR** (`@microsoft/signalr`) for realtime. There is **no** ECharts, JointJS, or i18next in
this repo.

### Localization

Localization uses `@icz/core/shared/utils-intl` plus the `trans` helper exported from
`@icz/core/shared/ui-core` (and Kendo's intl/l10n for Kendo components) - **not** angular-i18next.
Pass the translations object into pure helpers rather than importing state inside them.

## Conventions

- The default git branch is `master` (Nx `defaultBase`); PRs target `master`.
- Prettier (v2) is the formatter. Run `npm run format` before large commits.
- Use `date-fns` for date handling (manipulation, comparison, arithmetic). Avoid `moment` in new code.
- Never use the em/en dash character (`—` / `–`) in code, comments, commit messages, or any generated
  text. Always use a plain hyphen (`-`) instead.

## File structure & SRP

Feature/page code is organised into small, single-responsibility files with a **flat,
folder-per-component** layout. Push helper logic out of components into `*.utils.ts`, API calls into
`*.api.ts`, and form setup into `*.form.ts`. These conventions are pervasive in the repo
(~750 `*.component.ts`, ~130 `*.models.ts`, plus `*.form.ts` / `*.api.ts` / `*.utils.ts`).

A routed page groups its files by a shared name prefix at the lib root:

```
src/lib/
  main-page.component.ts / .html / .scss   # smart component (UI state only)
  main-page.form.ts                        # form service (class-based, see forms.instructions.md)
  main-page.api.ts                         # @Injectable API wrapper, returns mapped models
  main-page.utils.ts                       # pure helpers (formatters, row builders, constants)
  main-page.models.ts                      # shared interfaces / value types
  stat-table/                              # child component, own folder
    stat-table.component.ts / .html / .scss
```

Rules:

- **Folder per component.** If component B is used only by component A, nest B's folder inside A's.
- **Child components may have their own** `*.utils.ts` / `*.form.ts` / `*.api.ts` / `*.models.ts`.
- **Single responsibility.** A component file holds UI state and wiring only. Move anything that can
  reasonably go to utils/form/api - but keep it sensible, don't over-extract.
- See the file-type-specific instruction files listed at the top for the detailed rules.

## Angular & TypeScript Best Practices

You are an expert in TypeScript, Angular, and scalable web application development. You write
functional, maintainable, performant, and accessible code following Angular and TypeScript best
practices.

> NOTE: Much of the existing ardp code predates these targets (it still uses `@Input`/`@Output`, the
> `private` keyword, constructor injection, `@HostBinding`). For **new and edited** code, prefer the
> modern style below; match the surrounding file only where mixing styles would be jarring.

### TypeScript Best Practices

- Use strict type checking.
- Prefer type inference when the type is obvious.
- Avoid the `any` type; use `unknown` when the type is uncertain.

> This project is on **Angular 20**. Standalone is the default; a few v22+ defaults (automatic
> `OnPush`, `@Service`, stable Signal Forms) do not apply yet and are noted inline. Re-tune on upgrade.

### Angular Best Practices

- Use standalone components (default since v20). Do NOT set `standalone: true` explicitly.
- Set `changeDetection: ChangeDetectionStrategy.OnPush` explicitly (the Nx generator default here;
  automatic `OnPush` is v22+ only).
- Use signals for state management; `computed()` for derived state.
- Implement lazy loading for feature routes.
- Do NOT use the `@HostBinding` / `@HostListener` decorators. Put host bindings inside the `host`
  object of the `@Component` / `@Directive` decorator instead.
- Use `NgOptimizedImage` for static images (not for inline base64).

### State Management

- Use signals for local component state and `computed()` for derived state.
- Keep state transformations pure and predictable.
- Do NOT use `mutate` on signals; use `update` or `set`.

### Templates

- Use native control flow (`@if`, `@for`, `@switch`) instead of `*ngIf` / `*ngFor` / `*ngSwitch`.
- Use the async pipe to handle observables.
- Keep template logic minimal.

### Services

- Design services around a single responsibility.
- Use `@Injectable({ providedIn: 'root' })` for singletons (the `@Service` decorator is v22+ only).
- Prefer the `inject()` function over constructor injection in new code.

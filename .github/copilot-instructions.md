# Converge — Copilot instructions

These repo-wide instructions are read automatically by GitHub Copilot for every request in this
workspace. File-type-specific rules live in `.github/instructions/*.instructions.md` and are applied
automatically when you edit matching files:

- `components.instructions.md` → `**/*.component.{ts,html,scss}`
- `forms.instructions.md` → `**/*.form.ts`
- `api.instructions.md` → `**/*.api.ts`
- `utils.instructions.md` → `**/*.utils.ts`

## Overview

Converge is a large Angular 21 + Nx 22 monorepo for a metering / data-acquisition platform. It is a single deployable app (`converge`) plus ~130 Nx libraries. The frontend talks to a backend API (Swagger/OpenAPI) whose TypeScript client is code-generated, not hand-written.

Node `>=22` is required. Nx runs with an enlarged heap (`--max_old_space_size=12000`) — the `nx` npm script already sets this; use `npm run nx --` rather than a bare `nx` for memory-heavy targets.

## Commands

```bash
npm start                 # serve app at http://localhost:4200 (proxies /api -> backend, see proxy.conf.json)
npm run build             # development build
npm run build:prod        # production build (dist/apps/converge)
npm run lint              # lint affected projects only
npm run lint:all          # lint every project
npm run format            # prettier write across the workspace
npm run format:check      # prettier check (CI)
```

Targeted Nx invocations (note the `npm run nx --` prefix to get the large heap):

```bash
npm run nx -- lint <project-name>      # lint one project, e.g. app-shared-ui-core
npm run nx -- build converge --configuration production
npm run nx -- graph                    # visualize the project dependency graph
npm run nx -- affected -t lint         # what `npm run lint` runs
```

Project names follow the directory path joined by `-` (e.g. `libs/app/shared/ui-core` → `app-shared-ui-core`). See the `name` field in each `project.json`.

### Tests

There is **no unit test runner configured** (`unitTestRunner: "none"` in `nx.json`, zero `.spec.ts` files). Do not assume `nx test` works or that tests exist. Verify changes via `npm start`, build, and lint.

### Pre-commit

No pre-commit hooks are configured. Run `npm run format` and `npm run lint` before committing to ensure code quality.

## Architecture

### App shell vs. libraries

Two parallel homes for feature code exist; both are in active use:

- **`apps/converge/src/features/<domain>/`** — older/in-app features (e.g. `data-acquisition`, `advanced-validation`, `dashboard`, `calculation`). Each is an Angular `NgModule`, **lazy-loaded** from `apps/converge/src/app/utils/routes.ts`. Internally they follow a `containers/` (smart, routed/stateful) + `components/` (presentational) split.
- **`libs/`** — newer, extracted Nx libraries. New work generally goes here.

When adding a route/feature, wire it into `apps/converge/src/app/utils/routes.ts`.

### Library taxonomy (`libs/`)

Two top-level scopes:

- `libs/app/**` — `scope:app`, the main product's shared + feature libs.
- `libs/shared/**` — `scope:shared`, cross-cutting (`utils-core`, `ui-core`) usable by everything.

Each lib is tagged in its `project.json` with a `scope:*` and a `type:*`. Library folders are named by type: `feature`/`feat-*` (smart feature), `ui-*` (presentational/dialog), `utils-*` (logic/API). Import libs via their `@converge/...` path alias (defined in `tsconfig.base.json` `paths`), never by relative path across lib boundaries.

### Module boundary rules (enforced by ESLint)

`@nx/enforce-module-boundaries` in `eslint.config.mjs` is an **error**. Allowed dependency directions:

- `type:utils` → `type:utils` only
- `type:ui` → `utils`, `ui`
- `type:feature` → `utils`, `ui`
- `scope:shared` → `scope:shared` only; `scope:app` → `scope:shared` + `scope:app`

A lint failure mentioning module boundaries means the import violates this matrix — fix the dependency direction, don't suppress it.

### Path aliases

- `@cnv` / `@cnv/*` → `apps/converge/src` (in-app imports)
- `@converge/<scope>/<lib>` → the lib's `src/index.ts` (cross-lib imports)
- `@shared`, `@shared/services` → in-app shared module barrel

### Generated API client

`libs/app/shared/utils-api` contains **generated** `models/` and `services/` — do not hand-edit them. They are produced by `swagger/sync.sh <output-root>` which runs `swagger-codegen-cli.jar` (typescript-angular) against `swagger/swagger.json` using the templates in `swagger/templates/` and the `swagger/sync.py` post-processor (enum-name fixups, `Schema` suffix cleanup). `utils-api/**` is excluded from linting. To refresh the client, update `swagger.json` and re-run the sync script; don't manually patch the output.

### State management

NGRX is used app-wide: `@ngrx/store`, `effects`, `signals`, `component-store`, plus `ngrx-forms`. Global state is registered in `apps/converge/src/app/app.module.ts` (e.g. `SHARED_STATE_KEY`, `METER_DATA_FEATURE_KEY`); feature state lives with its feature/lib.

### Bootstrapping

`apps/converge/src/main.ts` does an explicit pre-bootstrap sequence **before** `bootstrapModule(AppModule)`: fetches `/assets/config/config.json` (runtime `config`, incl. `api` base URL), `/assets/versions.json`, and system parameters (`settings`), then sets the ag-Grid Enterprise license. Runtime config is loaded from assets at startup, not baked into the bundle — `environment.ts`/`environment.prod.ts` only carry the `production` flag.

### Key UI stacks

ag-Grid Enterprise (registered globally), Kendo Angular, Angular Material + CDK, FontAwesome Pro, ECharts (`ngx-echarts`), JointJS/Rappid (diagramming), i18next (`angular-i18next`) for localization, SignalR (`@microsoft/signalr`) for realtime.

## Conventions

- Components default to `OnPush` change detection and `scss` (see `nx.json` generators); component generation skips tests.
- Default git branch is `develop` (Nx `defaultBase`); PRs target `develop`.
- Prettier is the formatter (v2). Run `npm run format` before large commits; lint-staged also handles it.
- Use `date-fns` for date handling (manipulation, comparison, arithmetic). Do not use `moment`/`moment-timezone` in new code (it remains only in legacy utils). Prefer existing helpers in `DateUtils` (`@converge/shared/utils-core`) such as `toDateOnlyJSON` over inline format strings.
- Never use the em/en dash character (`—` / `–`) in code, comments, commit messages, or any generated text. Always use a plain hyphen (`-`) instead.

## File structure & SRP

We organise feature/page code into small, single-responsibility files with a **flat,
folder-per-component** layout. Keep every file as small as is reasonable; push helper logic out of
components into `*.utils.ts`, API calls into `*.api.ts`, and form setup into `*.form.ts`.

A routed page (e.g. `main-page`) groups its files by a shared name prefix at the lib root:

```
src/lib/
  main-page.component.ts / .html / .scss   # smart component (UI state only)
  main-page.form.ts                        # ngrx-forms createForm / updateForm
  main-page.api.ts                         # @Injectable API wrapper, returns mapped models
  main-page.utils.ts                       # pure helpers (formatters, row builders, constants)
  main-page.models.ts                      # shared interfaces / value types
  stat-table/                              # child component, own folder
    stat-table.component.ts / .html / .scss
  time-deviation-chart/                    # child component with its own utils
    time-deviation-chart.component.ts / .html / .scss
    time-deviation-chart.utils.ts
```

Rules:

- **Folder per component.** Each component lives in its own directory. If component B is used only
  by component A, nest B's folder inside A's folder.
- **Child components may have their own** `*.utils.ts` / `*.form.ts` / `*.api.ts` / `*.models.ts`,
  following the same flat naming, scoped to that component's folder.
- **Single responsibility.** A component file holds UI state and wiring only. Anything that can
  reasonably move to utils/form/api should move there — but keep it sensible, don't over-extract.
- See the file-type-specific instruction files listed at the top of this document for the detailed
  rules on components, forms, api, and utils.

## Angular & TypeScript Best Practices

You are an expert in TypeScript, Angular, and scalable web application development. You write functional, maintainable, performant, and accessible code following Angular and TypeScript best practices.

### TypeScript Best Practices

- Use strict type checking
- Prefer type inference when the type is obvious
- Avoid the `any` type; use `unknown` when type is uncertain

> NOTE: This project is on **Angular 21**. Rules below are tuned for v21; a few v22+ defaults (automatic `OnPush`, `@Service`, stable Signal Forms) do not yet apply and are noted inline. Re-tune when we migrate to v22.

### Angular Best Practices

- Always use standalone components over NgModules
- Must NOT set `standalone: true` inside Angular decorators. It's the default in Angular v20+.
- Set `changeDetection: ChangeDetectionStrategy.OnPush` explicitly on components (it is the Nx generator default here and is NOT yet automatic in Angular 21 — automatic `OnPush` only lands in v22+).
- Use signals for state management
- Implement lazy loading for feature routes
- Do NOT use the `@HostBinding` and `@HostListener` decorators. Put host bindings inside the `host` object of the `@Component` or `@Directive` decorator instead
- Use `NgOptimizedImage` for all static images.
  - `NgOptimizedImage` does not work for inline base64 images.

### State Management

- Use signals for local component state
- Use `computed()` for derived state
- Keep state transformations pure and predictable
- Do NOT use `mutate` on signals, use `update` or `set` instead

### Templates

- Keep templates simple and avoid complex logic
- Use native control flow (`@if`, `@for`, `@switch`) instead of `*ngIf`, `*ngFor`, `*ngSwitch`
- Use the async pipe to handle observables
- Do not assume globals like (`new Date()`) are available.

### Services

- Design services around a single responsibility
- Use `@Injectable({ providedIn: 'root' })` for singleton services. (The `@Service` decorator is v22+ only — do not use it on this v21 project yet.)
- Use the `inject()` function instead of constructor injection

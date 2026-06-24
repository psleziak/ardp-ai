---
applyTo: '**/*.component.{ts,html,scss}'
---

# Components

Smart and presentational Angular components. Keep them small — UI state and wiring only.

## Structure & files

- **Never use inline templates or inline styles.** Always use external `templateUrl` (`.html`) and
  `styleUrl` (`.scss`) files. Use paths relative to the component `.ts` file.
- **Folder per component.** Each component lives in its own directory containing its `.ts`, `.html`
  and `.scss`. If component B is used only by component A, nest B's folder inside A's folder.
- The routed page component sits at the lib root and shares a name prefix with its sibling files
  (`main-page.component.ts`, `main-page.form.ts`, `main-page.api.ts`, `main-page.utils.ts`,
  `main-page.models.ts`).

## Single responsibility

- A component holds UI state (signals) and event wiring only.
- Move API calls into a `*.api.ts` (`@Injectable` wrapper) — see `api.instructions.md`.
- Move form creation/validation into a `*.form.ts` — see `forms.instructions.md`.
- Move pure logic (formatters, table-row builders, option builders, constants) into a `*.utils.ts`
  — see `utils.instructions.md`. Child components may have their own `*.utils.ts`.
- Keep `computed()` bodies thin: delegate to a pure builder in utils, e.g.
  `rows = computed(() => buildGeneralRows(this.stats(), this.trans))`.

## Angular API

- Do NOT set `standalone: true` (it is the default).
- Set `changeDetection: ChangeDetectionStrategy.OnPush` explicitly.
- Use `input()` / `output()` functions, never the `@Input` / `@Output` decorators.
- Use `signal()` for local state, `computed()` for derived state. Use `update`/`set`, never `mutate`.
- Use `inject()` instead of constructor injection.
- Always use native ECMAScript private members (`#name`) for private fields and methods — never the
  TypeScript `private` keyword. Inject into `readonly #name = inject(...)` fields and name internal
  helpers `#reload()`, `#commit()`, etc. (the `on*` handler naming rule below still applies to
  template-bound methods, which stay public).
- Use `rxMethod` + `tapResponse` for API calls. Keep loading signals and error dispatch
  (`SharedActions.error`) in the component — the `*.api.ts` returns clean mapped Observables.

## Naming

- Prefix template event handlers (methods bound from the template to `(click)`, `(submit)`,
  `(ngrxFormsAction)`, custom `output()`s, etc.) with `on`, named after the **action/button**, not
  the generic DOM event: e.g. a "Load" button's `(submit)`/`(click)` handler is `onLoad()`, a
  histogram toggle is `onToggleHistogram()`. Prefer `onLoad()` over `onSubmit()` so it is clear which
  control it belongs to. This distinguishes user-action handlers from other methods.
- Do NOT use the `on` prefix for private/internal methods or data-loading helpers — keep those as
  plain (often `#private`) names like `#reload()`, `#getRange()`, `#loadGeneral`.
- Do NOT write a template handler that only re-emits an `output()`. Bind the output's `.emit()`
  directly in the template or host binding instead: `(click)="previous.emit()"`,
  `(click)="shortcutSelect.emit(id)"`, `host: { '(keydown.escape)': 'closeRequested.emit()' }`.
  Keep an `on*` handler only when it does real work (guards, state updates, composing a value) - a
  pure passthrough wrapper adds nothing.

## Templates

- Use native control flow (`@if`, `@for`, `@switch`), never `*ngIf` / `*ngFor` / `*ngSwitch`.
- Do NOT use `ngClass` — use `class` bindings. Do NOT use `ngStyle` — use `style` bindings.
- Use the async pipe for observables. Keep template logic minimal.
- Use `NgOptimizedImage` for static images (not for inline base64).

## SCSS

- To set a fixed `app-form-field` label width, use the `app-form-field` SCSS mixin via `::ng-deep`:

  ```scss
  @use 'mixins' as *;

  :host::ng-deep {
    @include app-form-field(80px);
  }
  ```

- Alternatively, when you need a dynamic width (e.g. `fit-content`) rather than a fixed value,
  target the `.app-form-field__label` class directly through `::ng-deep`:

  ```scss
  .toolbar::ng-deep .app-form-field__label {
    min-width: fit-content;
  }
  ```

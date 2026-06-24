---
applyTo: '**/*.api.ts'
---

# API wrappers

When a component calls a backend API, put those calls in a dedicated `*.api.ts` file. This keeps the
component thin, centralises model mapping, and lets multiple API calls be orchestrated in one place.

## Shape

- An `@Injectable({ providedIn: 'root' })` class named after the page/component (e.g. `MainPageApi`).
- Inject the generated service(s) from `@converge/app/shared/utils-api` via `inject()`
  (`readonly #api = inject(AquisitionStatisticsService)`).
- Expose methods that return **already-mapped component models** as `Observable<T>`, not raw
  `Wapi*Schema` types. Do the api→model mapping here with `map(...)`.

```ts
@Injectable({ providedIn: 'root' })
export class MainPageApi {
  readonly #api = inject(AquisitionStatisticsService);

  getGeneral(): Observable<GeneralStatistics> {
    return this.#api.aquisitionStatisticsGetGeneralStatistics().pipe(map(mapGeneralStatistics));
  }
}

function mapGeneralStatistics(schema: WapiStatisticsGeneralSchema): GeneralStatistics { ... }
```

## Responsibilities

- **Single responsibility:** one API wrapper per page/component.
- **Mapping lives here.** Map api models to component models so the component works with clean types.
  Keep mapping functions as non-exported module-level functions in the same file.
- **Orchestration lives here.** Combine multiple calls (e.g. `forkJoin`) here rather than in the
  component.
- **Do NOT** keep loading signals, `rxMethod`, or `SharedActions.error` dispatch here — those are UI
  state and belong in the component, which wraps these Observables in `rxMethod` + `tapResponse`.

## Models

- Prefer the generated API models where they fit. Introduce a component-specific model (in
  `*.models.ts`) and map to it when API models have wrong null/undefined typing or when the component
  (e.g. ngrx-forms Boxed values) needs a different shape.
- Never hand-edit the generated client in `libs/app/shared/utils-api`.

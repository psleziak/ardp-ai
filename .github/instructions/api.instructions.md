---
applyTo: '**/*.api.ts'
---

# API wrappers

When a component calls a backend API, put those calls in a dedicated `*.api.ts` file. This keeps the
component thin, centralises model mapping, and lets multiple API calls be orchestrated in one place.

## The API layer is hand-written

There is **no swagger/OpenAPI codegen** in ardp. The HTTP services in the domain `utils-api` libs
(`@icz/{core,aida,ibas,ras}/shared/utils-api`) and in `@icz/ardp/shared/api` are **hand-written** and
maintained like any other source. A service calls the shared `HttpService`
(`@icz/core/shared/utils-http`) and returns `*Dto` types from its `models/`:

```ts
@Injectable({ providedIn: 'root' })
export class DocumentService {
  readonly #http = inject(HttpService);

  getDetailInitData(parentId: number, parentType: string, relationId: number): Observable<DocumentDetailInitDataDto> {
    return this.#http.post('Document/GetDetailInitData', { parentId, parentType, relationId });
  }
}
```

To add an endpoint, **write the service method and its `*Dto` models by hand** following the existing
shape - there is nothing to regenerate. Do NOT add "generated / do not edit" banners.

## The `*.api.ts` wrapper

- An `@Injectable({ providedIn: 'root' })` class named after the page/component (e.g. `DetailPageApi`).
- Inject the hand-written domain service(s) (prefer `inject()` in new code; much existing code uses
  constructor injection): `readonly #api = inject(DocumentService)`.
- Expose methods that return **already-mapped component models** as `Observable<T>`. Do the
  `Dto -> model` mapping here with `map(...)`.

```ts
@Injectable({ providedIn: 'root' })
export class DetailPageApi {
  readonly #document = inject(DocumentService);

  getInitData(parentId: number, parentType: string, relationId: number): Observable<DocumentDetail> {
    return this.#document.getDetailInitData(parentId, parentType, relationId).pipe(map(mapDocumentDetail));
  }
}

function mapDocumentDetail(dto: DocumentDetailInitDataDto): DocumentDetail { ... }
```

## Responsibilities

- **Single responsibility:** one API wrapper per page/component.
- **Mapping lives here.** Map `*Dto` to component models so the component works with clean types.
  Keep mapping functions as non-exported module-level functions in the same file.
- **Orchestration lives here.** Combine multiple calls (e.g. `forkJoin`) here, not in the component.
- **Do NOT** keep loading signals, `rxMethod`, or error dispatch here - those are UI state and belong
  in the component, which wraps these Observables in `rxMethod` + `tapResponse`.

## Models

- Prefer the `*Dto` types where they fit. Introduce a component-specific model (in `*.models.ts`) and
  map to it when a Dto has wrong null/undefined typing or the component needs a different shape.
- The `utils-api` services and DTOs are hand-written - extend them there when an endpoint is missing,
  rather than inlining `HttpService` calls in the wrapper.

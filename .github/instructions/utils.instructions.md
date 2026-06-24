---
applyTo: '**/*.utils.ts'
---

# Utils

Pure helper functions extracted from components/forms/api to keep those files minimal.

## Rules

- Use plain exported functions: `export function xxx(...) { ... }`. No classes, no namespaces.
- Keep functions **pure** and predictable: no side effects, no injected services, no signals.
- **Exception:** thin persistence/storage accessors are allowed here even though they are not pure —
  e.g. small `readXxxMemory`/`writeXxxMemory` wrappers around `memoryStorage` plus their key constant
  (`ACQUISITION_SUMMARY_KEY`). Keep them minimal; anything heavier belongs in a service or the `*.api.ts`.
- Put here: formatters (`formatBytes`, `formatDuration`), table-row builders
  (`buildGeneralRows(stats, trans)`), chart/option builders (`buildChartOptions(buckets, trans)`),
  shared constants (`PLACEHOLDER`), and small mapping/derivation helpers.
- Pass dependencies in as parameters. For i18n, pass the translations object in
  (`trans: typeof appTrans`) rather than importing state.
- A page has a `main-page.utils.ts`; a child component may have its own scoped `*.utils.ts` inside its
  folder (e.g. `time-deviation-chart/time-deviation-chart.utils.ts`).

## Boundaries

- Move helper logic out of components into utils — but keep it **sensible**, don't over-extract
  trivial one-liners or create abstractions for a single call site.
- API→model mapping does NOT belong here — it lives in the `*.api.ts` wrapper (see
  `api.instructions.md`).
- Respect Nx module boundaries: `type:utils` may depend only on other `type:utils`.

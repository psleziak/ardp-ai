---
applyTo: '**/*.form.ts'
---

# Forms

All forms use **ngrx-forms**. Form setup lives in a dedicated `*.form.ts` file next to its component,
never inline in the component.

## Functions

Expose plain exported functions (`export function ...`), not classes:

- `createForm(initial?: TValue): FormGroupState<TValue>` — builds the initial `createFormGroupState(...)`,
  applies any default values, and returns `updateForm(state)` so validation is applied from the start.
  Accept an optional `initial` value to rehydrate persisted/restored state (e.g. a saved filter) into
  the form's initial values.
- `updateForm(state, action?): FormGroupState<TValue>` — applies `formGroupReducer(state, action)` when
  an `action` is passed, then runs the validation via `updateGroup(...)`. There is no separate
  `validateForm`; validation lives inside `updateForm` so it can never be forgotten.

```ts
export function createForm(initial?: SummaryFilterValue): FormGroupState<SummaryFilterValue> {
  const state = createFormGroupState<SummaryFilterValue>('summaryFilter', { ... });
  return updateForm(state);
}

export function updateForm(
  state: FormGroupState<SummaryFilterValue>,
  action?: FormAction,
): FormGroupState<SummaryFilterValue> {
  if (action) {
    state = formGroupReducer(state, action);
  }
  return updateGroup<SummaryFilterValue>(state, { /* validators */ });
}
```

## Component usage

- `form = signal<FormGroupState<TValue>>(createForm());`
- `onFormAction(action: FormAction) { this.form.update((form) => updateForm(form, action)); }`
- Type the `action` parameter as `FormAction` (from `@converge/shared/ui-form`), not
  `Actions<TValue>` — `FormAction` is what the component's `(ngrxFormsAction)` emits.

## Validators

- Use `NgrxValidators` from `@converge/shared/ui-form` (e.g. `NgrxValidators.required`,
  `NgrxValidators.stringGreaterThanIf(...)`).

## Models & types

- The form value interface lives in the page's `*.models.ts`.
- Prefer API models for form values when they fit. When API models have wrong null/undefined typing,
  or when ngrx-forms needs Boxed values, define a component-specific value type and map to/from the
  API model in `*.api.ts`.

## Template

- Inputs MUST be wrapped in `app-form-field` so the validation CSS classes apply.
- Bind via `[ngrxFormState]` on the `<form>` and `[ngrxFormControlState]` on each control, dispatching
  through `(ngrxFormsAction)`.

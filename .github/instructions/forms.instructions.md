---
applyTo: '**/*.form.ts'
---

# Forms

In ardp, form setup lives in a dedicated **class-based** `*.form.ts` service next to its component,
never inline in the component and never as plain exported functions. The service is an `@Injectable()`
class that is provided on the component (`providers: [XxxForm]`) and injected into it.

There are **two form families** - pick by context:

## 1. Large detail pages -> `NgrxFormServiceBase` (ngrx-forms)

Big stateful detail/edit pages use ngrx-forms via the abstract base
`NgrxFormServiceBase<TInputData, TFormValue>` from `@icz/core/shared/ui-form`. Extend it and implement
the three protected hooks; the base provides `state$` / `state`, `isDirty`, `onFormAction(action)`,
`setValue(inputData)`, `getValue()`, `setErrors(BusinessError)`, `markAsPristine()`, `disable()`/`enable()`.

```ts
@Injectable()
export class CreatePageForm extends NgrxFormServiceBase<DocumentSpaceInputDataDto, CreatePageFormValue> {
  protected create(value: CreatePageFormValue): void {
    let form = createFormGroupState('form', value);
    form = updateGroup(form, {
      // ngrx-forms validators, e.g. name: validate(required)
    });
    this.update(form);
  }

  protected mapFormValue(inputData: DocumentSpaceInputDataDto): CreatePageFormValue {
    return { name: inputData.name, mSearchCollectionId: inputData.mSearchCollectionId };
  }

  protected mapInputData(formValue: CreatePageFormValue): DocumentSpaceInputDataDto {
    const unboxed = unbox(formValue);
    return { /* map back to the Dto */ };
  }
}
```

- Use `createFormGroupState` / `updateGroup` / `unbox` from `ngrx-forms`; validators come from
  `ngrx-forms` (used inside `updateGroup`).
- `mapFormValue` / `mapInputData` translate between the API `*Dto` and the form value type. Use a
  component-specific value type (in `*.models.ts`) when the Dto's null/undefined typing or ngrx-forms
  Boxed values need a different shape.
- Component template: bind `[ngrxFormState]="(form.state$ | async)"` on the `<form>` and
  `[ngrxFormControlState]` on each control; dispatch via `(ngrxFormsAction)="form.onFormAction($event)"`.

## 2. Dialogs / smaller forms -> `FormServiceBase` (Angular reactive forms)

Dialogs and smaller forms use the simpler `FormServiceBase<TValue>` from
`@icz/core/shared/utils-core`, which wraps an Angular reactive `UntypedFormGroup`. Build the group in
the constructor; the base provides `group`, `isDirty`, `setValue()`, `getValue()`,
`setErrors(BusinessError)`, `getErrorsByKey()`, `markAsPristine()`, `disable()`, and
`setFieldSpecificPermissions()`.

```ts
@Injectable()
export class MemberDialogForm extends FormServiceBase {
  constructor(private formBuilder: UntypedFormBuilder) {
    super();
    this.group = this.formBuilder.group({
      id: [null],
      comment: [{ value: null, disabled: false }],
      // ...
    });
  }

  public setValue(formValues: WatchlistMembershipInputDataDto) {
    this.group.setValue({ /* map Dto -> controls */ });
  }
}
```

- Component template: bind `[formGroup]="form.group"` and use `formControlName` on each control.

## Shared rules

- The form value / input types are `*Dto` from the hand-written API (`@icz/<domain>/shared/utils-api`
  or `@icz/ardp/shared/api`), or a component-specific value type in the page's `*.models.ts`.
- Server-side validation errors arrive as `BusinessError`; surface them via the base's
  `setErrors(error)`.
- One form service per page/dialog. Provide it on the component (`providers: [XxxForm]`) and inject it.

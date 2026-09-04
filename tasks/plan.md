# Test plan: core model coverage baseline

## Goal

Build a trustworthy, fast RSpec baseline for Barkeep's model layer without testing views. The scope is the ten concrete models in `app/models` plus the `UserScopable` and `Taggable` concerns. `ApplicationRecord` is only an abstract Rails base class, so loading it successfully is enough.

The current suite passes with 6 examples. Only 4 examples are direct model specs, covering one `ReagentAmount` query path and one `Recipe` query path. Eight concrete models have no direct spec file, and the project does not measure coverage yet.

## Test approach

- Keep RSpec and FactoryBot. Add the missing factories and small shared examples instead of introducing matcher libraries.
- Exercise the models against PostgreSQL. Array overlap, JSONB, generated `tsvector`, and vector columns are part of the real model behavior and would be hidden by mocks or SQLite.
- Test public behavior and application-owned data rules. Do not spend examples restating every Rails or Devise macro.
- Test associations when they carry a domain consequence, such as destroying a shopping list's placeholder bottles or traversing a cocktail family.
- Isolate and reset `User.current_id` around every example that uses implicit user scoping. Run the suite in random order so leaked global/thread state is visible.
- Add SimpleCov before Rails loads, enable branch coverage, and report a separate `Models` group. Do not impose an application-wide percentage gate while controllers and views are intentionally out of scope.

## Coverage target

At the end of this work:

- Every concrete model and both concerns has direct behavioral coverage.
- Every application-owned public method and scope in `app/models` has a normal case and each meaningful branch covered.
- `app/models` reaches at least 90% line coverage and 80% branch coverage.
- Any uncovered model line is named in the final report with a reason; generated/framework behavior does not need a bespoke test merely to move the percentage.
- The full RSpec suite passes in random order. The final measured numbers and seed are recorded as the new baseline.

## Model-by-model cases

| Area | Cases to cover |
| --- | --- |
| `UserScopable` | Explicit user selection; `User.current` fallback; isolation from another user; `for_user_or_shared` includes global rows; cleanup prevents state leaking between examples. |
| `Taggable` | Any-overlap tag matching; multiple requested tags; no overlap; empty tags. Exercise the real PostgreSQL array operator. |
| `User` | Admin role membership and ordinary users; changing `current_id` invalidates the memoized current user; clearing the current user returns `nil`. Leave Devise internals to Devise. |
| `Reagent` | Per-user name/external-id uniqueness; measured volume access and invalid units; `real` and `has_volume`; subtract usage with unit conversion, exact depletion, and clamping below zero; add usage; unitless bottles. |
| `ReagentAmount` | Required-volume validation; category lookup; user- and shopping-list-aware matching; placeholder id; sufficient/insufficient availability with unit conversion; optional/garnish fallback; unitless amounts; conversion to `Recipe::Ingredient`. |
| `ReagentCategory` | User-scoped reagent and amount lookup by tag; its own dimension; an existing override dimension; destruction of dependent reference bottles. |
| `ReferenceBottle` | Required category relationship and traversal. No tests for plain attribute accessors. |
| `Recipe::Ingredient` | Unitless and optional defaults; measured required volume; lookup of the source `ReagentAmount`. |
| `Recipe` | Empty and populated blob deserialization; append and clear behavior across save/reload; flattened tags; underscore-to-slash tag search; JSONB proposal accessors; global cocktail families; parent/children traversal; dependent ingredient destruction; matching reagents with user isolation; makeable/unmakeable/optional recipes; ephemeral source detection. |
| `Audit` | Backup name; normal versus ephemeral recipe snapshots; reagent snapshot mapping including substitution defaults; rating and notes mutation without overwriting sibling data; user scoping. |
| `CocktailFamily` | Per-user, idempotent Favorites creation; recipe traversal. |
| `CocktailFamilyJoiner` | Favorite lookup is limited by user, family name, and the supplied recipe ids. |
| `ShoppingList` | User scoping; reagent traversal; destroying a list destroys its placeholder reagents while ordinary inventory remains untouched. |

## Work order

### Phase 1: measurement and test foundations

1. Add model-focused SimpleCov reporting, random-order execution, safe cleanup for `User.current_id`, missing factories, and shared examples for the two concerns.
2. Run the unchanged tests once under coverage and save the initial model line/branch numbers in the implementation summary.

### Phase 2: inventory and ingredient rules

3. Add `User` and `Reagent` specs for ownership, scopes, uniqueness, and volume mutation.
4. Add `ReagentAmount`, `ReagentCategory`, and `ReferenceBottle` specs for tag matching, measured quantities, availability, dimensions, and dependent records.

Checkpoint: run the focused model specs and the full suite with a fixed seed, then repeat with a different seed.

### Phase 3: recipes and history

5. Expand `Recipe` specs around its ingredient value object, JSON blob, PostgreSQL search, relationships, matching, and makeability.
6. Add `Audit`, `CocktailFamily`, `CocktailFamilyJoiner`, and `ShoppingList` specs for snapshots, favorites, lookup boundaries, and ownership lifecycle.

### Phase 4: baseline report

7. Run the full suite, inspect the SimpleCov line and branch reports for every model file, fill only meaningful gaps, and record the resulting counts and seed. Add a model-only coverage gate after the measured result proves the proposed threshold is stable.

## Questions to resolve while implementing

These are legacy behaviors where a passing characterization test could make a bug harder to change. Stop and surface the observed behavior before choosing an expectation if the code and persisted data do not answer it.

- `Recipe#ingredients` does not restore `description`, although `ReagentAmount#convert_to_blob` includes it.
- `Recipe#<<` and `Recipe#clear_ingredients` mutate `ingredients_blob` without invalidating the memoized `@ingredients`; behavior depends on whether `ingredients` was read first.
- `ReagentCategory#dimension` raises through `nil.id` when its override points to a missing category. Decide whether the contract should be validation, fallback, or explicit failure.
- `Reagent#add_usage` can exceed `max_volume`. That may be intentional for audit reversal, but a test should not lock it in without checking.
- Several `has_many` relationships do not declare dependent behavior and most lack database foreign keys. Test only the currently intended lifecycle, and flag any newly observed orphaning rather than normalizing it.

## Risks

- A fake database would give false confidence because several core scopes depend on PostgreSQL-specific operators and generated columns.
- Thread-local `User.current` can make the suite order-dependent unless every example restores it.
- Recipe availability spans `Recipe`, its ingredient blob, inventory rows, and `CocktailAvailabilityService`; those specs are model integration tests and will be somewhat broader than pure unit tests.
- A percentage target can reward low-value assertions. Public behavior and meaningful branches remain the acceptance criterion; the number is a backstop.

## Out of scope

- View, component, system, and visual tests.
- Exhaustive Devise, Active Record, pgvector, `jsonb_accessor`, or `measured` gem behavior.
- Controller and service-object coverage except where a real collaborator is necessary to prove a model contract.
- Fixing legacy behavior discovered by the new tests without first reporting it.

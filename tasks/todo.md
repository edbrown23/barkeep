# Core model coverage baseline

## Task 1: Add coverage and deterministic test foundations

**Description:** Measure model line and branch coverage, make model data easy to create, and prevent implicit current-user state from leaking between examples.

**Acceptance criteria:**

- [x] SimpleCov starts before Rails, tracks `app/models/**/*.rb`, and reports line and branch coverage for a Models group.
- [x] RSpec runs in random order and restores `User.current_id` after scoped examples.
- [x] Factories exist for all concrete models that need persisted setup, with sequences where uniqueness requires them.
- [x] Shared examples cover `UserScopable` and `Taggable` against PostgreSQL.

**Verification:**

- [x] The unchanged suite still passes under coverage.
- [x] The initial model line and branch percentages are recorded.

**Dependencies:** None

**Files likely touched:** `Gemfile`, `Gemfile.lock`, `spec/spec_helper.rb`, `spec/rails_helper.rb`, `spec/factories/`, `spec/support/`

**Estimated scope:** Medium

## Task 2: Cover users and inventory bottles

**Description:** Specify user identity/scoping and all application-owned bottle inventory behavior.

**Acceptance criteria:**

- [x] `User` specs cover roles and current-user memoization/reset.
- [x] `Reagent` specs cover user-scoped uniqueness, scopes, measured validation, additions, subtraction/clamping, conversion, and unitless bottles.
- [x] User and tag shared examples pass for `Reagent`.

**Verification:**

- [x] `bundle exec rspec spec/models/user_spec.rb spec/models/reagent_spec.rb` passes.

**Dependencies:** Task 1

**Files likely touched:** `spec/models/user_spec.rb`, `spec/models/reagent_spec.rb`

**Estimated scope:** Small

## Task 3: Cover ingredient amounts and taxonomy

**Description:** Specify how recipe requirements match categories and user inventory, including shopping-list placeholders and optional ingredients.

**Acceptance criteria:**

- [x] `ReagentAmount` specs cover measurement, matching, availability branches, placeholders, unitless values, and blob conversion.
- [x] `ReagentCategory` specs cover tagged lookups and valid dimension overrides.
- [x] `ReferenceBottle` and category specs cover their required relationship and destruction lifecycle.

**Verification:**

- [x] Focused specs for all three models pass.
- [x] The full suite passes with a recorded random seed.

**Dependencies:** Tasks 1-2

**Files likely touched:** `spec/models/reagent_amount_spec.rb`, `spec/models/reagent_category_spec.rb`, `spec/models/reference_bottle_spec.rb`

**Estimated scope:** Medium

## Checkpoint: Inventory layer

- [x] Run the full suite twice with different seeds.
- [x] Inspect model line and branch coverage for user, reagent, amount, category, and reference bottle files.
- [x] Report any legacy behavior that needs a product decision before continuing.

## Task 4: Cover recipe composition and makeability

**Description:** Specify the central recipe model, including its ingredient value object, persisted ingredient representations, PostgreSQL tag search, family relationships, inventory matching, and availability boundary.

**Acceptance criteria:**

- [x] `Recipe::Ingredient` covers measurement, source lookup, unitless values, and optional defaults.
- [x] `Recipe` covers blob read/write/clear across reloads, tags, tag search, JSONB accessors, relationships, matching, makeability, and ephemeral recipes.
- [x] Tests expose rather than silently bless any disagreement between `reagent_amounts`, `ingredients_blob`, and the memoized ingredient list.

**Verification:**

- [x] `bundle exec rspec spec/models/recipe_spec.rb` passes.
- [x] PostgreSQL search expectations pass against the generated `searchable` column.

**Dependencies:** Tasks 1-3

**Files likely touched:** `spec/models/recipe_spec.rb`, `spec/factories/recipe.rb`

**Estimated scope:** Medium

## Task 5: Cover audits, favorites, and shopping-list lifecycle

**Description:** Specify the remaining model behavior around history snapshots, saved cocktail families, favorite lookup boundaries, and temporary shopping inventory.

**Acceptance criteria:**

- [x] `Audit` specs cover snapshot parsing, ephemeral logic, substitutions, ratings/notes, and ownership.
- [x] Family and joiner specs cover per-user idempotent Favorites and recipe/user filtering.
- [x] Shopping-list specs cover ownership, traversal, and dependent placeholder deletion without deleting ordinary inventory.

**Verification:**

- [x] Focused specs for all four models pass.

**Dependencies:** Tasks 1-4

**Files likely touched:** `spec/models/audit_spec.rb`, `spec/models/cocktail_family_spec.rb`, `spec/models/cocktail_family_joiner_spec.rb`, `spec/models/shopping_list_spec.rb`

**Estimated scope:** Medium

## Task 6: Establish the measured model baseline

**Description:** Close meaningful gaps, set a model-only ratchet at a sustainable measured threshold, and leave a reproducible baseline for future work.

**Acceptance criteria:**

- [x] All ten concrete models and both concerns have direct behavioral coverage.
- [x] Model coverage is at least 90% line and 80% branch, or any exception is documented by file and line.
- [x] No view tests are added and no application-wide coverage gate is imposed.
- [x] Final example count, coverage percentages, runtime, and seed are recorded.

**Verification:**

- [x] `bundle exec rspec` passes in random order.
- [x] The coverage report has no unexplained gaps in application-owned model methods or scopes.

**Dependencies:** Tasks 1-5

**Files likely touched:** coverage configuration and model specs only

**Estimated scope:** Small

## Checkpoint: Complete

- [x] Full RSpec suite passes twice with different seeds.
- [x] Model line and branch baseline is recorded.
- [x] Any behavior questions discovered during implementation are listed for review rather than hidden by permissive expectations.

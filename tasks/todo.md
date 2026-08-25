# Barkeep Refresh

## Task 1: Establish an honest test baseline

**Description:** Replace stale generated coverage with the smallest set of tests that protects current cocktail behavior and the scaling seam.

**Acceptance criteria:**

- [x] No placeholder or skipped generated specs remain.
- [x] Meaningful ingredient and availability behavior is covered.
- [x] An authenticated user can render their cocktail detail page in a request spec.

**Verification:**

- [x] Focused specs pass with `bundle exec rspec <paths>`.
- [x] Full suite passes with `bundle exec rspec`.

**Dependencies:** None

**Files likely touched:** `spec/`

**Estimated scope:** Medium

## Checkpoint: Test baseline

- [x] Full suite passes with no pending examples.

## Task 2: Make development reproducible

**Description:** Define and automate the minimum supported setup and CI test path.

**Acceptance criteria:**

- [ ] Required runtime and database setup are documented.
- [x] CI runs the same test command used locally.
- [ ] A clean environment can prepare and test the app.

**Verification:**

- [x] CI-equivalent command passes locally.

**Dependencies:** Task 1

**Files likely touched:** `README.md`, `.github/workflows/`

**Estimated scope:** Medium

## Task 3: Upgrade obsolete dependencies incrementally

**Description:** Upgrade only dependencies that block a supported, maintainable development baseline.

**Acceptance criteria:**

- [ ] Each dependency step is independently committed and reversible.
- [ ] Tests remain green after each step.
- [ ] Obsolete frontend tooling has a documented migration outcome.

**Verification:**

- [ ] Full suite and asset build pass after each step.

**Dependencies:** Task 2

**Files likely touched:** `Gemfile`, `Gemfile.lock`, `package.json`, `yarn.lock`, configuration files

**Estimated scope:** Medium per upgrade step

## Checkpoint: Foundation

- [ ] Tests and build pass from documented setup.

## Task 4: Ship display-only cocktail scaling

**Description:** Let a user select a serving count on a cocktail detail page and see scaled ingredient quantities without persisting a batch or changing inventory.

**Acceptance criteria:**

- [ ] Scaling behavior is specified by focused tests.
- [ ] Every ingredient quantity reflects the selected serving count.
- [ ] Reloading the page returns to the original single-serving recipe.

**Verification:**

- [ ] Focused model/request tests pass.
- [ ] Full suite and asset build pass.
- [ ] Manual browser check confirms the scaling interaction.

**Dependencies:** Task 3

**Files likely touched:** cocktail model/view and a small Stimulus controller

**Estimated scope:** Medium

## Checkpoint: Complete

- [ ] All tests and build checks pass.
- [ ] Cocktail scaling works end to end.

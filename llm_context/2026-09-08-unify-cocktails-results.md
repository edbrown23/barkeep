# Cocktail consolidation results

Implemented on `codex/unify-cocktails` following approval of the [plan](2026-09-08-unify-cocktails-plan.md).

## Delivered

- One `CocktailsController`, one index, and one detail layout. Removed `SharedCocktailsController`, its duplicated index/detail templates, and both shared frontend entry points.
- Public shared browsing and signed-in shared/owned browsing. A single ownership selector replaces contradictory switches; legacy filter URLs remain supported.
- Explicit cocktail visibility and ownership checks for detail access, editing, copying, submitting, publishing, favorites, deletion, and permanent conversion. Family pages use the same visibility boundary.
- Shared masters retain `user_id: nil`; personal copies retain a user ID and parent attribution. No database migration or dependency changes.
- Transactional recipe/ingredient copying, preserved metadata, independent personal versions, and locked publication that cannot accept the same proposal twice.
- Canonical cocktail links across tables, home, shopping, audit history, neighbors, and navigation. Old shared GET routes redirect; old mutation routes invoke the same secured actions directly.
- Shared and owned pages both provide serving display controls. Shared pages retain community notes and personal-copy lists. Guest rendering does not create favorite families or query personal inventory.
- Drink-making count updates preserve their DOM targets across repeated submissions. Fast successful submissions close the modal even while its opening animation is in progress.

## Verification

- Full RSpec suite: **146 examples, 0 failures**, seed 19215.
- Five isolated Chrome scenarios passed: guest browsing/scaling/mobile filtering; customization, favorite, editing and submission; repeated making/twist/count/note updates; admin publication and deletion; shopping-list addition and retained selection.
- Browser tests assert no severe JavaScript errors, apart from resource-loading errors from external assets.
- Focused request/service coverage includes ownership tampering, guests, admin boundaries, legacy endpoints, copy independence and rollback, repeated publication, explicit nil scopes with ambient `User.current`, family privacy, pagination, combined filtering, and SQL delimiters in search.
- `npm run build`, `npm run build:css`, Rails `zeitwerk:check`, and diff whitespace checks pass.
- Guest detail screenshot inspected at `tmp/cocktail-guest.png`; failure screenshots from intermediate test runs remain ignored under `tmp/capybara`.

## Implementation decisions and boundaries

Audits have a NOT NULL recipe ID. Recipe deletion therefore retains the existing audit ID/backup-name behavior; it does not delete history or attempt to null that ID. Children survive with parent references cleared, and obsolete family join rows are removed.

The installed Selenium version predates Rails' DriverFinder integration, so the system spec registers its driver directly with Capybara. It accepts `CHROMEDRIVER`, the GitHub Actions `CHROMEWEBDRIVER` directory, or a driver on PATH. The README documents local setup. Verification used a matching Google ChromeDriver under `/tmp/barkeep-chromedriver`; no browser executable was added to the repository.

Stale ignored assets in `public/assets` were moved to `/tmp/barkeep-assets-before-consolidation-20260908` so tests load current builds. Generated files were not committed. Pre-existing unrelated untracked files were left alone.

The original ordered tasks are complete. Verification combines request/service tests with the browser scenarios above; it does not claim every permission permutation was exercised manually. The existing ingredient memoization survives `Recipe#reload`; persistence tests use a fresh instance when inspecting edited ingredient blobs. A broader cache/editor-transaction cleanup remains separate, along with whole-app authorization review, general query optimization, and community-note privacy changes. Serving selection remains display-only and does not change drink-making quantities.

Nothing has been deployed or pushed.

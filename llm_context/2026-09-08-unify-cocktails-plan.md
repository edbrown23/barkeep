# Unify shared and personal cocktail pages

Status: proposed; no application changes implemented. Based on a static review of the current checkout. Tests and browser flows have not been run for this planning task.

## Recommendation

Use one `CocktailsController`, one index, one detail page, and one canonical URL per cocktail. Keep the existing `Recipe` data model: `category == 'cocktail'` identifies cocktails; `user_id: nil` identifies a shared master; a user ID identifies a personal recipe. Ownership determines what someone may do with the record, not which controller renders it.

This is a good consolidation because `/cocktails` already lists shared and personal recipes together. The split is mostly in routing and presentation, with legitimate differences in permissions and supplemental content. Those differences fit small conditional sections in a common page. Keeping two controllers behind a common base class or concern would reduce copied lines but leave callers deciding which kind of URL to construct.

No migration, new cocktail subclass, ownership flag, or automatic synchronization between masters and copies is needed. Keep `RecipesController`, `DrinkMakingController`, and the Administrate controllers separate: they have different responsibilities and are outside this consolidation.

## What the code does today

Primary evidence: `app/controllers/cocktails_controller.rb`, `app/controllers/shared_cocktails_controller.rb`, `app/views/cocktails/`, `app/views/shared_cocktails/`, `app/models/recipe.rb`, and `config/routes.rb`.

| Concern | Personal controller/pages | Shared controller/pages | Proposed treatment |
|---|---|---|---|
| Index audience | Requires sign-in | Public | Public common index; scope follows viewer and filters |
| Index contents | Own + shared cocktails, excluding drink-builder recipes | Shared cocktails | One scope-building path |
| Search | Name, ingredient tags, facets, availability, family IDs, ownership toggles | Name, ingredient tags, facets, availability when signed in | Common search; personal controls require sign-in |
| Index presentation | Newer page shell, collapsible mobile filters, New Cocktail button | Older layout, admin proposal review table | Use newer layout and a conditional review partial |
| Detail lookup | Only current user's recipes | Unrestricted `Recipe.find` | Shared-or-owned read lookup, cocktail category required |
| Common detail content | Name, families, favorite, ingredients, bottles, shopping, making, personal notes, similar drinks | Substantially the same | One page and shared data setup |
| Extra detail content | Parent attribution; edit, propose, delete, make permanent | Global count, community notes, copies, copy action, admin delete | Small sections selected by ownership and capabilities |
| Serving controls | Present | Absent | Same display scaling on both pages |
| Create/edit | Personal recipes only | No regular edit form | Keep existing personal form |
| Copy | Absent | Duplicate shared recipe and ingredient rows into account; set parent | Move action to common controller |
| Publish | Propose own recipe | Admin-facing acceptance creates a separate master | Keep distinct propose/publish operations |
| Frontend | Index and detail entry points | Another pair of entry points | One index entry point and one detail entry point |

Both indexes already render `shared/_cocktails_table.html.erb`; its `read_only` argument is unused. Most ingredient/shopping/making UI is already shared. The two detail controllers differ mainly in the extra collections they load and the names they use for recent audits.

### The data distinction is useful

A personal copy is a snapshot, not an override layer. `add_to_account` duplicates the recipe and its ingredient rows, rebuilds `ingredients_blob` with the new amount IDs, and records the master in `parent_id`. Multiple copies per person are currently allowed. Editing a copy does not change its master.

Publishing also makes a new record. `promote_to_shared` clears the original proposal markers, duplicates the personal recipe with no owner or parent, duplicates ingredient rows with no owner, and rebuilds the blob. It does not convert the submitter's record into a master or establish new parentage for it. Preserve that behavior. Neither operation copies audit history or family join rows; preserve that separation too.

The names obscure these operations: “Promote to your list” means copy, while “Accept into shared” means publish another copy. Recommend “Customize” (with text explaining that it creates a personal copy), “Your versions,” “Submit for sharing,” and “Publish shared recipe.” Internal action renaming is optional and should not add compatibility work unnecessarily.

## Problems to address as part of the merge

These are source-level findings, not claims of tested exploits.

1. **The shared controller trusts IDs too broadly.** `show` and `destroy` use unrestricted `Recipe.find`; only `add_to_account` requires authentication. `promote_to_shared` and `destroy` have no server-side admin check. Hiding buttons does not enforce permission. Copying also accepts an arbitrary recipe ID rather than requiring a master.
2. **Several personal actions bypass ownership.** `propose_to_share`, `make_permanent`, and `toggle_favorite` use unrestricted finders. Read access must never become write access when `show` starts accepting masters.
3. **Redirects already disagree with the resource model.** Favoriting a shared recipe and the HTML drink-making completion both redirect to `cocktail_path`, whose current detail lookup only allows owned recipes. The drink-making Turbo completion link has the same mismatch. One canonical detail route fixes this naturally.
4. **Anonymous reads perform personal setup.** Shared `show` calls `CocktailFamily.users_favorites(nil)`, which can create a global Favorites family. It also queries personal notes, copies, and shopping state without a signed-in viewer. Guest rendering should skip these queries and never create a favorites family. Prefer a read-only favorite lookup on all detail GETs; create the family when actually favoriting.
5. **Explicit nil is not reliably shared scope.** `UserScopable.for_user(nil)` falls back to `User.current`. No request assignment was found in the inspected application paths, but the behavior is intentional and tested. Add cocktail-specific explicit scopes using `where(user_id: nil)` and the supplied viewer ID; do not rewrite this concern across every model. Test with `User.current` populated to prove public access stays public-only.
6. **Families can expose another user's metadata.** Signed-in detail pages enumerate every family attached to a master, including other users' Favorites families. Render only global families and the viewer's own families; validate family filters against that same set. `CocktailFamiliesController` also finds families without ownership scoping and returns all associated recipes. Close that linked-page bypass in a focused companion slice. Guest family links currently lead to an authenticated page; render labels for guests in this project rather than expanding public family browsing.
7. **Transport behavior has drifted.** Copy's JSON response references undefined `shared_cocktail` rather than `@shared_cocktail`. The personal index JavaScript assumes the ownership toggles always exist; that will fail on the new guest index. Detail scripts mix old Rails UJS callbacks with Turbo responses. Preserve actual contracts, remove duplicate listeners, and verify navigation between page variants.
8. **Deletion is inconsistent.** Personal deletion is a custom POST action; the RESTful destroy route has no corresponding implementation. Shared deletion uses DELETE. Missing records in personal `delete` can trigger nil dereferences. Consolidate on `destroy`, with scoped lookup and a compatibility POST alias.

Other findings should not silently expand this into a rewrite: recipe update replaces amounts outside a transaction, facet SQL interpolates a generated query inside dollar quoting, several names use `html_safe`, and unrelated controllers have broad lookups. Record follow-up work for these; test the search code being moved with quotes and dollar delimiters and correct it if it fails. The merge must not widen access through its own pages or the family links it renders.

## Target behavior and permissions

| Action | Guest | Signed-in user | Admin |
|---|---|---|---|
| Browse/show | Shared cocktails | Shared + own cocktails | Same ordinary browsing rules |
| Create | Sign-in required | Creates own recipe | Creates own recipe |
| Edit/update | Sign-in required | Own recipe only | Own recipe in this UI; existing admin UI remains separate |
| Delete | Sign-in required | Own recipe only | Own recipe or shared master |
| Customize | Sign-in required | Shared master only; creates owned copy | Same |
| Favorite, shopping, make drink | Sign-in required | Shared or own recipe; personal state belongs to viewer | Same |
| Submit for sharing | Sign-in required | Own recipe only | Own recipe only |
| Make permanent | Sign-in required | Own drink-builder recipe only | Same |
| Review/publish proposals | Sign-in required | Forbidden | Proposed, user-owned cocktail only |
| Similar recipes | Sign-in required | Keep signed-in endpoint availability | Keep current admin-only link; results remain shared + own |

Private records outside the allowed scope, missing records, and non-cocktail recipes return 404. Unauthenticated mutations use the existing Devise authentication behavior. Authenticated non-admin moderation requests return 403. Authenticate before checking admin status; the existing `validate_admin!` assumes a non-nil user.

Use distinct read, owned-write, shared-copy, and moderation lookups. Implement readable predicates such as `shared?` and `owned_by?(user)` and a small helper for view capabilities if useful. Do not introduce a policy framework merely for this merge. The controller must independently enforce every capability exposed by a view.

### Index

- `/cocktails`: shared recipes for guests; own + shared recipes for signed-in viewers. Continue excluding ephemeral drink-builder recipes from ordinary browsing while retaining direct owner access.
- Replace contradictory ownership switches with one `ownership=all|mine|shared` selector for signed-in viewers. Default is `all`. Guests always receive only shared recipes; ignore personal filters and hide personal controls.
- Translate old `user_recipes_only=on` and `shared_recipes_only=on` links when the new parameter is absent. Preserve the old both-on result as an empty result with an explanatory reset message; do not silently broaden it. Reject or normalize unrecognized ownership values to the viewer's default.
- Preserve name search, tag AND semantics, makeable filtering, facets, pagination, and family matching. Existing multiple-family matching is OR; changing it to AND is separate work. Use distinct results for joins so multi-family matches do not duplicate recipes or facet counts.
- Offer global + own family filters to signed-in viewers; apply makeable/facet queries only after the permitted recipe scope is established. Do not build a user's inventory availability for guest pages.
- Retain admin proposal review in a separate partial on the common index when viewing shared recipes. Keep private proposals out of public results, facets, counts, and pagination. Give its table a different DOM ID from the results table.

Extract the index query into a small `CocktailSearch` service in the existing `app/service_objects/` convention. It owns filter normalization and result/facet/family calculations; reuse `CocktailAvailabilityService`. It must receive the viewer explicitly and start from a permitted cocktail relation. Avoid a generic search framework.

### Detail page

Use `cocktails/show` as the single layout, retaining the current page shell. Give it one recent-audits variable and explicit empty defaults for guest personal state. Load shared-only community notes/global count and signed-in-only copies/shopping/favorites only when applicable. Preserve existing community-note visibility on masters; do not expose personal-copy notes as community content.

Use a few meaningful partials: metadata/stats, community notes, personal versions, and actions. Reuse the existing ingredient and making partials. Show parent attribution on personal copies and link to the canonical route when the parent is visible. Do not make a second full layout hidden behind `if shared?`.

Preserve `usersVersions`, `userNotesTableBody`, `made_count`, `made_globally_count`, the recipe Turbo frame, modal targets, and toast destinations where needed. Both ownership types get serving display controls. This does not change drink-making quantities: that workflow currently has its own double option, and connecting it to the display selector is separate work.

### Copy and publish

Move both operations under `CocktailsController`. Put the transaction and row/blob duplication in a narrowly scoped `CocktailCopyService` with explicit customize and publish entry points. Ownership, parentage, proposal markers, amount ownership, and amount IDs must be deliberate. Preserve recipe metadata, optional amounts, descriptions, tags, and embeddings according to current copy behavior; rebuild the blob using the new rows. Do not copy audits, family memberships, or favorites.

Clear proposal markers on new personal copies. Publishing must clear the original proposal and create the master in the same transaction; a failure leaves neither a partial master nor a falsely accepted proposal. Recheck proposal state inside a row lock to prevent double publishing from repeated requests. Continue allowing deliberate repeated customization.

Retain Turbo and JSON copy responses, fixing the JSON variable, and provide an HTML redirect to the new personal copy. Move its Turbo template and toast partial into the common view directory. Preserve the public response keys used by existing code.

### Routes and callers

Canonical detail links always use `cocktail_path(recipe)`, regardless of owner. Add copy/publish routes to the cocktail resource and use named helpers instead of relative form strings. Keep existing custom action helper conventions during the move to avoid unrelated renaming.

Compatibility is explicit:

| Existing route | Transition |
|---|---|
| GET `/shared_cocktails` | Redirect to `/cocktails?ownership=shared`, preserving allowed search/tag/page/makeable query values; shared mode wins over conflicting ownership values |
| GET `/shared_cocktails/:id` | Redirect to canonical show; destination enforces shared-or-owned visibility |
| POST `/shared_cocktails/:shared_cocktail_id/add_to_account` | Route directly to common action, normalize legacy ID, enforce shared-only source |
| POST `/shared_cocktails/:shared_cocktail_id/promote_to_shared` | Route directly to common moderation action, normalize ID, enforce admin/proposal restrictions |
| DELETE `/shared_cocktails/:id` | Direct compatibility action/route defaults enforcing shared-only admin deletion |
| POST `/cocktails/:cocktail_id/delete` | Direct compatibility alias enforcing the old owner-only deletion intent |

Use temporary GET redirects initially to make rollback easy. Never redirect mutation requests merely to change URL spelling. Legacy restrictions must be route-defined, not overridable through query parameters. Keep a small, documented route compatibility section after deleting the old controller; no copied controller actions or templates remain.

Update table links, parent links, nearest neighbors, home, shopping, audit pages, navigation, logged-out marketing links, and proposal forms. “Shared cocktail list” may remain a shortcut to the shared filter; it no longer represents another resource. Remove unused `read_only` locals from callers. Audit the obsolete `pre_make_drink`/`make_drink` routes and their old helper in `app/frontend/js/lib/shared.js`; remove only after checking all callers. Keep live drink-making routes intact.

## Ordered implementation tasks

The checklist lives here under `llm_context/`, following repository guidance. Each slice should leave the application working; temporary delegates are acceptable during implementation but must disappear at completion.

### 1. Define scoped access and characterize existing behavior (M)

Files: recipe model/specs, cocktail request specs, new access request specs as needed.

- [ ] Add explicit cocktail/shared/visible scopes and ownership predicates without changing `UserScopable` fallback behavior.
- [ ] Cover guest, owner, other user, admin, non-cocktail IDs, and ambient `User.current`. Add fixtures with persisted ingredient blobs as well as amount rows.
- [ ] Capture supported listing/detail/copy behavior; write desired permission tests without treating current leaks as intended behavior.

Verification: focused recipe and request specs. Dependencies: none.

### 2. Consolidate read pages, starting with detail access (M per sub-slice)

2a files: both controllers, common detail view, detail request specs.

- [ ] Separate owned-write lookup from visible-read lookup; enable public shared detail and retain owner-only editing.
- [ ] Render both URLs through the common show page, with guest setup and read-only favorite lookup.
- [ ] Preserve personal notes, shared community notes, copies, attribution, serving controls, and conditional actions.

2b files: common detail partials/helper, detail packs, shared Turbo copy template, browser/request checks.

- [ ] Extract only meaningful sections and consolidate detail scripts; preserve Turbo targets and transport responses.
- [ ] Exercise shared/owned/guest pages across Turbo navigation with no duplicate handlers or missing elements.

Verification: detail access/content request matrix, browser making/shopping/favorite/copy flows. Dependencies: 1. Temporary old routes remain functional.

### 3. Consolidate the index (M per sub-slice)

3a files: search service/spec, both controllers, request specs.

- [ ] Implement one permitted search path with normalized ownership filters, distinct family joins, and explicit guest behavior.
- [ ] Verify combined filters, legacy flags, empty results, facets, ordering, pagination, and quoted/dollar-delimited search input.

3b files: common index/filter/review views, index packs, index request specs.

- [ ] Render one index with the ownership selector, newer responsive layout, guest-safe controls, and admin-only proposals.
- [ ] Confirm private proposals/family names never enter public results and that JavaScript works when personal controls are absent.

Verification: search/request specs and desktop/mobile browser search checks. Dependencies: 1; integrate after 2.

Checkpoint: common index/detail work for guests and members; focused specs pass before mutation migration.

### 4. Move and secure customization/publishing (M per sub-slice)

4a files: copy service/spec, controllers, copy request specs.

- [ ] Move transactional customization and publish duplication into the service with explicit parent/owner/metadata behavior.
- [ ] Verify blob IDs reference copied amounts, source remains independent, no audits/families are copied, and failures roll back fully.

4b files: controllers/routes, copy Turbo templates/toast, moderation request specs.

- [ ] Authenticate all mutations and enforce the permission matrix for propose, publish, copy, favorite, and make permanent.
- [ ] Preserve JSON/Turbo contracts, add HTML copy fallback, and prevent repeated publication of an accepted proposal.

Verification: service and action request specs including forged IDs, non-admin requests, rollback, repeated submissions, and source/copy independence. Dependencies: 1–3.

### 5. Consolidate deletion and protect linked family pages (M per sub-slice)

5a files: cocktails controller/routes, action partial, deletion request specs.

- [ ] Implement canonical destroy with owner/admin distinctions and missing-record 404s; retain restricted legacy aliases.
- [ ] Test deleting a recipe with ingredient rows, audits, family joins, and children. Preserve surviving personal copies; do not cascade deletion into them. Document actual existing association behavior and resolve any dangling-reference rendering in the affected flow before shipping.

5b files: families controller, detail family rendering/helper, family request specs.

- [ ] Scope family access to global + viewer-owned families and its results to visible cocktails; deny other users' family IDs.
- [ ] Guests see family labels without inaccessible links; signed-in family results contain no foreign private recipes.

Verification: deletion/family request specs. Dependencies: 2 and 4.

### 6. Canonicalize routes and remove the duplicate surface (S/M per group)

- [ ] Update navigation/home/table links, then shopping/audit/neighbor/parent links in separate small batches (about 3–5 files each), with rendered-link checks.
- [ ] Install/test GET redirects with filter preservation and legacy mutation aliases with every supported ID shape. Update relative action form URLs to named helpers.
- [ ] Delete `SharedCocktailsController`, its remaining views, and both shared frontend entry points once callers have moved. Retain only route compatibility references. Do not edit ignored generated bundles by hand.

Verification: route/request tests, repository search for old route/controller/template/asset references, `npm run build`, `npm run build:css`. Dependencies: 2–5.

### Completion checkpoint

- [ ] Run `bundle exec rspec` using the repository's PostgreSQL/pgvector test setup; stub external embedding generation in mutation tests.
- [ ] Browser-check guest browse/detail; member filtering, favorite, customize, edit, shopping, make/twist, submit, delete, ephemeral-to-permanent; admin review/publish/delete. Check Turbo navigation and mobile filters.
- [ ] Verify old bookmarked GETs and old mutation URLs, HTML/JSON/Turbo responses, and non-cocktail/missing/other-user IDs.
- [ ] Confirm the final diff changes no schema and leaves one index and one detail implementation.

## Scope and decisions proposed for review

Recommended defaults are public `/cocktails`, a single ownership selector, multiple personal copies allowed, shared-only community content, admin review retained on the shared-filtered index, and compatibility routes retained for old links. Serving controls become available for shared recipes too, but remain display-only.

The biggest risk is making the controller broadly readable and accidentally using that same scope for writes. The second is losing Turbo behavior while collapsing templates. Both have explicit test matrices above. General query optimization, a whole-app authorization audit, changing community-note privacy, recipe editor redesign, master-copy synchronization, and rewriting the drink-making workflow are separate projects.

Implementation should begin only after this plan has been reviewed, as requested. The current task adds this document only.

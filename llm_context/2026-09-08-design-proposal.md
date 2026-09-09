# Barkeep design refresh proposal

Prepared September 8, 2026. Proposal only; no application changes implemented.

Give Barkeep the feel of a well-kept home bar: warm paper, deep green accents, readable recipes, and practical lists. Keep Bootstrap 5.1.3 and the existing Rails, Turbo, and Stimulus interactions. The main work is better hierarchy and layout, with a small, consistent theme.

## What I reviewed

Started the Rails development server at http://127.0.0.1:3000 using the existing dependencies and database. The browser already had a signed-in session. Inspected Home, Cocktails, a shared recipe (18th Century), Bottles, New Bottle, Shopping, History, Categories, and the drink builder. Also inspected Cocktails at a 390 × 844 mobile viewport. No warnings or errors were returned by the browser console check at the end of the review.

The local account has no bottles, favorites, or history displayed. Shared recipes and categories are populated. Populated inventory, shopping recommendations, and drink completion still need review with suitable local data during implementation. The logged-out landing page was reviewed in its template, not in the browser. I did not submit forms or change inventory.

The current design has a few specific problems:

- Navigation wraps across two lines even at desktop width; the full email and account controls compete with the main destinations.
- Home uses oversized display text, while list pages lack a clear page title. Recipe detail starts with a small “Name:” label.
- Shared cocktails all have gray table backgrounds, so the entire list looks muted. Their shared status is communicated through color alone.
- Empty pages show table headers without guidance. A new user sees “0 Cocktails” instead of a useful next step.
- Mobile filters occupy almost the entire first screen before the first cocktail appears.
- Forms stretch across the page. Labels such as “New Reagent,” “AND query,” and “Count of reagents available” expose internal terminology.

## Visual direction

| Element | Proposed treatment |
| --- | --- |
| Background | Warm off-white, `#F6F3EC` |
| Surfaces | White cards and table panels with subtle warm borders, `#DED9CF` |
| Primary color | Deep green, `#234D3C`, with white button text |
| Text | Charcoal, `#252B28`; secondary text, `#626860` |
| Accent | Restrained brass, `#9A6B2F`, for small decorative details |
| Typography | Bootstrap system font for controls and body; Georgia for page and recipe titles |
| Scale | Page titles about 32–36px desktop / 28px mobile; section titles 22–24px; body 16px |
| Spacing | Bootstrap spacing scale; 24–32px between sections, 16–24px inside panels |
| Shape | Modest 8px corners, light borders, minimal shadows |

Use green for primary actions, neutral outlines for secondary actions, and red only for destructive actions. Availability gets a text label as well as color. Keep visible keyboard focus. Verify contrast in every interactive state during implementation. No photography is required; the layout should work for every recipe, including recipes without images.

## Proposed screens

| Screen | Changes |
| --- | --- |
| Shared navigation | Make Barkeep a home link. Use Home, Cocktails, Bottles, Shopping, History. Keep Make a Drink prominent. Put Categories and the role-appropriate shared catalog link in a More dropdown; move email, account settings, and sign-out into Account. Preserve current permissions. |
| Home | Title: “Your home bar.” Put “Ready to make” first, then Favorites. Use compact Bootstrap cards for drink discovery, with recipe name, availability, and existing view/make actions. Preserve the distinction between personal and shared recipes with labels. Replace empty tables with “Add your first bottle to see what you can make” and an Add Bottle link; empty favorites explain how to favorite a recipe. |
| Cocktails | Add a title and New Cocktail action above the content. Keep a compact table for browsing, with white rows, gentle hover feedback, a Shared badge, and an “Ingredients ready” column showing “0 of 4” or “Ready to make.” Keep desktop filters in a bordered sidebar. On phones, show search and a Filters disclosure above results; put advanced options inside Bootstrap Collapse. Retain existing search behavior. |
| Recipe detail | Give the recipe name a proper title and place Favorite beside it. Group existing make/add actions near the title, respecting availability. Place ingredients in the main panel and notes/statistics in a secondary column that stacks on phones. Use readable ingredient labels while preserving underlying tags. Keep bottle matching and shopping controls; make secondary controls visually quieter. Separate Delete from routine actions. |
| Bottles | Title: “Your bottles,” with Add Bottle as the main action and Import as secondary. Keep a practical table with name, ingredient tags, volume, and actions. Show volume clearly; an optional Bootstrap progress bar can supplement the amount where maximum volume is valid. Put missing-basic suggestions in a small secondary panel. Use an explicit empty state when the cabinet is empty. |
| Shopping | Title: “Shopping.” Put saved shopping lists in a distinct panel. Keep the existing tabs, renamed “Unlock more drinks,” “One ingredient away,” and “Running low.” Explain empty recommendations in terms of the user's inventory. |
| Forms and drink builder | Use a narrower reading width and Bootstrap grid groups. Rename “New Reagent” to “Add a bottle” and the builder heading to “Build a drink.” Group bottle size, remaining volume, and units together; visually separate purchase details. Keep existing field names, submissions, and validation behavior. Place primary submit and secondary cancel together. |
| History and Categories | Apply the same title, spacing, table, and empty-state patterns. Rename “Your audit log” to “Drink history.” Keep current analysis and category functions. |
| Signed-out and account screens | Apply the same theme and narrower form layout. Preserve the existing invitation-by-email flow. Make the landing page's value statement shorter and its feature blocks less oversized. |

For example, the desktop cocktail page would read top to bottom as: navigation → “Cocktails” plus New Cocktail → filter sidebar beside a clean results panel → pagination. On a phone: compact navigation → title/action → search and Filters → results. This puts drinks within reach without changing how the search works.

## Bootstrap implementation approach

Use Bootstrap containers, grid, navbar, dropdowns, cards, tables, badges, forms, Collapse, existing modals, and toasts. Keep Bootstrap Icons and the existing Select2 integration. No new UI framework or Bootstrap upgrade is needed for this proposal.

The current asset pipeline imports precompiled Bootstrap CSS. Add a small theme stylesheet after that import, including explicit Bootstrap 5.1 component state overrides: changing only `--bs-primary` would not recolor all buttons, focus rings, and other components. Match Select2 controls to the same palette and sizing.

Most edits would be in the shared layout, frontend styles, shared table partials, and individual view templates. Preserve routes, permissions, form parameters, Turbo frame IDs, and Stimulus hooks. Readable ingredient names should be presentation-only transformations. This scope does not require changes to recommendation logic, inventory calculations, or the database schema.

## Suggested delivery sequence after approval

1. Theme and shared layout: navigation, typography, spacing, buttons, panels, footer.
2. Home, cocktail list, and recipe detail: establish the reusable patterns on the core journey.
3. Inventory, shopping, forms, history, categories, and account screens: apply the patterns consistently.
4. Verify populated and empty states at phone, tablet, and desktop widths; check keyboard navigation, focus, contrast, Select2, pagination, filtering, and existing modal/Turbo flows. Exercise drink completion and inventory actions using disposable local data.

The proposed first release is the full visual refresh above. New recommendation features, photography, dark mode, and a replacement frontend are outside its scope.

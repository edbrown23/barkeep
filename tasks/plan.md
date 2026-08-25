# Implementation Plan: Barkeep Refresh

## Overview

Restore a small, trustworthy development baseline, modernize only the infrastructure needed for safe iteration, and prove the result by shipping display-only cocktail scaling.

## Architecture Decisions

- Preserve the Rails application and production data model; upgrade in place rather than rewrite.
- Keep the initial test suite intentionally small and behavior-focused.
- Use cocktail scaling as the first thin vertical slice through model, request, and UI layers.

## Task List

### Phase 1: Honest test baseline

- [x] Remove generated placeholder specs that provide no behavioral confidence.
- [x] Repair meaningful domain specs to match current application behavior.
- [x] Characterize the authenticated cocktail detail page used by scaling.

### Checkpoint: Test baseline

- [x] Focused specs pass.
- [x] Full suite passes without pending examples.

### Phase 2: Reproducible foundation

- [x] Make the supported Ruby, database, and test commands explicit.
- [x] Add a minimal CI check for the test suite.
- [x] Upgrade obsolete dependencies in small, independently verified steps.

### Checkpoint: Foundation

- [x] A clean checkout can install, prepare the test database, and run CI-equivalent tests.

### Phase 3: Cocktail scaling slice

- [x] Specify scaling behavior with focused tests.
- [x] Add display-only serving scaling to the cocktail detail page.
- [x] Verify the flow in a real browser.

### Checkpoint: Complete

- [x] Full suite and build pass.
- [x] Existing cocktail behavior is preserved.
- [x] Ingredient quantities update for a selected serving count without persistence or inventory changes.

## Risks and Mitigations

- The current suite is stale and red: distinguish obsolete tests from real regressions before changing production code.
- The frontend uses end-of-life Node/Webpacker tooling: isolate that migration from feature behavior and verify each step.
- Local setup relies on implicit services and environment: document and automate only the minimum reproducible path.

## Open Questions

- Choose the smallest supported Rails/frontend upgrade target after the green baseline exposes compatibility constraints.

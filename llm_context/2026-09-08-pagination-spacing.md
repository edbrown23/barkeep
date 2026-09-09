# Pagination spacing

## Goal

Add a small, consistent vertical gap between paginated tables and their pagination controls.

## Scope

- Apply the spacing to the shared pagination styling so cocktail and audit lists receive the same treatment.
- Use the existing Bootstrap spacing scale (`1rem`).
- Preserve pagination markup, behavior, and responsive layout.

## Verification

- Rebuild the frontend stylesheet.
- Confirm the rendered gap in the local browser at the cocktail list and audit list.
- Run the existing RSpec suite.

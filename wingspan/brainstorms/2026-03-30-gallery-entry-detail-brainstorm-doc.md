---
date: 2026-03-30
topic: gallery-entry-detail
---

# Gallery Entry Detail Page

## What We're Building

A dedicated detail page for gallery entries, accessible by tapping any entry in the Gallery. The page displays the photo prominently at the top (with a Hero animation from the gallery), followed by inline-editable fields for the entry name and type (livestock vs plant), plus a read-only display of the date the photo was taken. The app bar includes a trash icon for deleting the entry with a confirmation dialog.

Edits auto-save — name changes are debounced and saved automatically, type toggles save immediately. No explicit "Save" button. The existing reactive stream in the Gallery cubit means navigating back after edits or deletion automatically reflects changes.

## Why This Approach

Three approaches were considered:

1. **New route + Cubit (chosen)**: A `/gallery/:id` route with its own `EntryDetailCubit`. Follows the existing "page provides cubit" pattern, supports Hero animations naturally, and keeps the detail page's concerns separate from the gallery list.

2. **Reuse GalleryCubit**: Would require less code but fights the established pattern where each page provides its own cubit. The gallery cubit would need to be scoped above the navigator or passed awkwardly.

3. **Bottom sheet overlay**: Lightweight but limited layout space for the photo hero effect and awkward keyboard management for inline editing.

Approach 1 was chosen for consistency with the existing architecture and the best UX (full page with Hero animation).

## Key Decisions

- **Inline editing with auto-save**: Name field auto-saves on change (debounced). Type segmented button saves immediately on toggle. No save button.
- **Date is read-only**: Displays `createdAt` from the `TankEntry` model. Not editable.
- **Photo hero + fields below layout**: Large photo at top with Hero animation, scrollable editable fields underneath.
- **Delete via app bar trash icon**: Trash icon in the app bar triggers a confirmation dialog, then deletes and pops back to gallery.
- **New EntryDetailCubit**: Own cubit following existing patterns. Loads entry by ID, handles save and delete operations.
- **Repository update needed**: `TankRepository.updateEntry` must be extended to support updating the `type` field (currently only supports `name` and `scientificName`).
- **Remove old edit/delete gestures**: The existing swipe-up-to-delete and tap-name-to-edit dialogs on the gallery cards should be removed, since the detail page replaces them.

## Open Questions

- Should the scientific name also be editable on the detail page, or is name + type sufficient?
- Should there be a visual indicator on gallery cards that they're tappable (e.g., a subtle info icon)?

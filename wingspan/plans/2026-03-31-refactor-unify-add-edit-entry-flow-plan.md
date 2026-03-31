---
title: "refactor: unify add-entry and edit-entry into a single flow"
type: refactor
date: 2026-03-31
---

# refactor: unify add-entry and edit-entry into a single flow

## Summary

Replace the multi-step add-entry flow (Camera → AI identification → Confirmation form → Save) with a simplified flow (Camera → Save minimal entry → Edit page). The edit page becomes the single place for all entry editing — naming, type selection, AI identification, cropping, and retaking photos. For new entries, show a Cancel button (with confirmation) instead of Revert. Remove `AddEntryBloc`, `ConfirmEntryView`, and the `/add-entry` route.

## Background & Motivation

The app currently has two similar-but-different editing experiences: the add-entry confirmation form and the entry detail edit page. They duplicate fields (name, type selector) with slightly different UX. Unifying them:
- Eliminates duplicate code and UI
- Makes AI identification opt-in everywhere (no forced waiting)
- Shortens the add flow: Camera → Edit page
- Creates a single, consistent editing experience

## Acceptance Criteria

- [ ] Tapping + in the gallery opens the camera (full-screen, no bottom nav)
- [ ] After capturing a photo, a minimal entry is saved to the DB and the edit page opens
- [ ] The edit page in new-entry mode shows a Cancel button instead of Revert
- [ ] Cancel shows a confirmation dialog, then deletes the entry and image file, and pops back
- [ ] Back navigation saves the entry (same as existing entries — no special prompt)
- [ ] If the user cancels, the entry and image file are deleted
- [ ] Empty names are allowed — the image is the primary content
- [ ] AI identification only happens on-demand via the sparkle button (never automatically)
- [ ] The gallery shows nameless entries with an "Unnamed" placeholder label
- [ ] Existing entry editing (tap gallery card → edit page) works exactly as before with Revert
- [ ] `AddEntryBloc`, `AddEntryEvent`, `AddEntryState`, `ConfirmEntryView`, and `AddEntryPage` are removed
- [ ] The `/add-entry` route is removed; camera is pushed imperatively from the gallery FAB
- [ ] All existing cubit tests updated; new tests for cancel, discard-on-back, and close-in-new-mode

## Technical Design

### 1. New-entry detection: `isNewEntry` flag

Pass a boolean `isNewEntry` parameter to `EntryDetailPage` and `EntryDetailCubit`. Do NOT infer from `name.isEmpty` — an existing entry with a cleared name must not be treated as new.

**Router change:** The `/gallery/:id` route extra becomes a record or map:

```dart
GoRoute(
  path: '/gallery/:id',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) {
    final entry = state.extra! as TankEntry;
    final isNewEntry = state.uri.queryParameters['new'] == 'true';
    return EntryDetailPage(entry: entry, isNewEntry: isNewEntry);
  },
),
```

### 2. Camera becomes a standalone result page

Refactor `CameraView` into a `CameraPage` (a `StatefulWidget` with its own `Scaffold`) that pops with the image path on capture. This replaces both `CameraView` (in add-entry) and `RetakePhotoPage` (in entry-detail) — they're near-identical.

**File:** `lib/camera/view/camera_page.dart` (new location, shared)

### 3. Gallery FAB: capture → addEntry → navigate

The gallery FAB's `onPressed` callback:

1. Push `CameraPage` via `Navigator.push<String>` — returns the image path (or null if cancelled)
2. Call `context.read<TankRepository>().addEntry(name: '', type: TankEntryType.livestock, imagePath: path)` — returns the new entry ID
3. Construct a `TankEntry` with the ID, empty name, default type, the image path, and `DateTime.now()`
4. Push `/gallery/${id}?new=true` with the entry as extra

This logic lives in the `_GalleryContent` widget directly (it's a simple 3-step sequence, not complex enough for a cubit).

### 4. Update `EntryDetailCubit` for new-entry mode

**Constructor:** Accept `bool isNewEntry` parameter. Store it.

**New `cancel()` method:**
- Cancel debounce timer
- Delete the entry from DB via `_tankRepository.deleteEntry(_entry.id)`
- Delete the image file from disk (`File(_entry.imagePath).delete()`)
- Also delete any orphaned images from retakes
- Emit `EntryDetailDeleted`

**Update `close()`:**
- Behavior unchanged for both modes: flush any pending debounced save. Empty names are fine — the entry always persists unless explicitly cancelled.

**Relax `_save()` guard:**
- Remove `if (!force && _currentName.trim().isEmpty) return;` — entries can have empty names. The image is the primary content, not the name. All field changes should persist regardless of name state.

### 5. Update `EntryDetailView`

**Cancel vs. Revert button:**
- Read `isNewEntry` from the cubit (expose as a getter)
- New entry: show Cancel button (`Icons.close`) with confirmation dialog ("Discard this entry?")
- Existing entry: show Revert button (`Icons.undo`) with confirmation dialog (unchanged)

**Back navigation:**
- No `PopScope` interception needed — back navigation saves the entry for both new and existing entries (debounce flush in `close()`). Empty names are fine. The only way to discard a new entry is via the explicit Cancel button.

### 6. Update gallery to handle nameless entries

**File:** `lib/gallery/view/gallery_view.dart`

In `_EntryCard`, when `!entry.hasName && entry.scientificName == null`, show a placeholder:

```dart
Text(
  'Unnamed',
  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
    color: Colors.white54,
    fontStyle: FontStyle.italic,
  ),
)
```

### 7. Remove add-entry feature

Delete these files:
- `lib/add_entry/bloc/add_entry_bloc.dart`
- `lib/add_entry/bloc/add_entry_event.dart`
- `lib/add_entry/bloc/add_entry_state.dart`
- `lib/add_entry/view/add_entry_page.dart`
- `lib/add_entry/view/confirm_entry_view.dart`
- `lib/add_entry/view/camera_view.dart` (replaced by shared `CameraPage`)
- `lib/entry_detail/view/retake_photo_page.dart` (replaced by shared `CameraPage`)
- `test/add_entry/bloc/add_entry_bloc_test.dart`

Remove the `/add-entry` route from `router.dart`.

### 8. Tests

**Update `test/entry_detail/cubit/entry_detail_cubit_test.dart`:**
- [ ] `cancel()` deletes entry from repository
- [ ] `cancel()` emits `EntryDetailDeleted`
- [ ] `close()` in new-entry mode flushes save (same as existing entry mode)
- [ ] `_save()` now saves even when name is empty (guard removed)

**Update `test/gallery/cubit/gallery_cubit_test.dart`:**
- No changes needed — gallery cubit doesn't change

**Remove `test/add_entry/bloc/add_entry_bloc_test.dart`**

## Implementation Order

1. Create shared `CameraPage` (extract from `CameraView` / `RetakePhotoPage`)
2. Update `EntryDetailCubit` (add `isNewEntry`, `cancel()`, update `close()`, relax `_save()`)
3. Update `EntryDetailState` (no changes needed — reuse `EntryDetailDeleted`)
4. Update `EntryDetailView` (Cancel vs. Revert, name field hint)
5. Update `EntryDetailPage` (accept `isNewEntry`, pass to cubit)
6. Update `router.dart` (accept `isNewEntry` query param, remove `/add-entry` route)
7. Update gallery FAB (capture → addEntry → navigate)
8. Update gallery `_EntryCard` (unnamed placeholder)
9. Delete add-entry files and retake photo page
10. Update retake photo references in detail view to use shared `CameraPage`
11. Update tests
12. Run `flutter analyze` and `flutter test`

## Dependencies

- No new packages required
- `CameraPage` reuses existing `camera` package

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Nameless entries in gallery | Show "Unnamed" placeholder — empty names are intentionally allowed |
| App killed during new entry editing | Entry persists with whatever state it had — this is fine, not an orphan |
| Debounce save in-flight when cancel tapped | `cancel()` cancels timer first; in-flight save on deleted row is harmless |
| Hero animation may not work for new entries | New entry card exists in gallery before navigation; Hero should work |
| `addEntry` returns `int`, not `TankEntry` | Construct `TankEntry` client-side with `DateTime.now()` — acceptable drift |

## Out of Scope

- Startup cleanup of orphaned entries (follow-up)
- Changing `addEntry` return type to `Future<TankEntry>`
- Auto-triggering AI identification for new entries
- Extracting a shared `TankEntryTypeSelector` widget (nice cleanup but not required)

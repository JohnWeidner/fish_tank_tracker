---
title: "feat: add gallery entry detail page"
type: enhancement
date: 2026-03-30
brainstorm: wingspan/brainstorms/2026-03-30-gallery-entry-detail-brainstorm-doc.md
---

# feat: add gallery entry detail page

## Summary

Add a dedicated detail page for gallery entries. Tapping an entry in the Gallery opens a full-screen page at `/gallery/:id` with a Hero-animated photo at top, inline-editable name and type fields (auto-save), read-only date display, and a delete action in the app bar. Remove the existing hidden gesture-based edit/delete from gallery cards.

## Background & Motivation

The Gallery currently has edit (tap name overlay) and delete (swipe up) via hidden gestures that users can't discover. A detail page makes these actions visible and provides space for richer entry information.

## Acceptance Criteria

- [ ] Tapping an entry card in the Gallery navigates to a full-screen detail page
- [ ] The entry photo animates via Hero transition from gallery to detail page
- [ ] The name field is inline-editable with debounced auto-save (500ms)
- [ ] The type field is a `SegmentedButton<TankEntryType>` that saves immediately on toggle
- [ ] The `createdAt` date is displayed as read-only (format: "Mar 30, 2026")
- [ ] A trash icon in the app bar triggers a confirmation dialog, then deletes and pops back
- [ ] Empty/whitespace-only name edits are ignored (last saved value is preserved)
- [ ] Pending debounced saves are flushed on back navigation (no data loss)
- [ ] Delete cancels any pending debounced save before executing
- [ ] The old swipe-to-delete and tap-to-edit gestures are removed from gallery cards
- [ ] Cubit tests cover: debounce, flush on close, empty name skip, delete cancels pending save, type toggle immediate save

## Technical Design

### 1. Extend `TankRepository.updateEntry` to support type changes

**File:** `packages/tank_repository/lib/src/tank_repository.dart`

Add an optional `TankEntryType? type` parameter to the existing `updateEntry` method:

```dart
Future<void> updateEntry({
  required int id,
  required String name,
  String? scientificName,
  TankEntryType? type, // NEW
});
```

**File:** `packages/tank_local_storage/lib/src/local_tank_repository.dart`

Update the SQL update map to conditionally include `type`:

```dart
final values = <String, Object?>{
  'name': name,
  'scientific_name': scientificName,
};
if (type != null) {
  values['type'] = type.name;
}
```

### 2. Add `/gallery/:id` route

**File:** `lib/app/router.dart`

Add a top-level `GoRoute` with `parentNavigatorKey: _rootNavigatorKey` (matching the `/add-entry` pattern) so the detail page is full-screen without bottom nav:

```dart
GoRoute(
  path: '/gallery/:id',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) {
    final entry = state.extra! as TankEntry;
    return EntryDetailPage(entry: entry);
  },
),
```

The `TankEntry` is passed via `GoRouter.extra` to avoid a new repository method. The entry is used as initial data only — the cubit does not watch for external changes (acceptable for a single-user local app).

### 3. New feature: `lib/entry_detail/`

Follow the established page/view + cubit pattern.

#### 3a. `EntryDetailCubit` and state

**Files:**
- `lib/entry_detail/cubit/entry_detail_cubit.dart`
- `lib/entry_detail/cubit/entry_detail_state.dart`

**State (sealed class):**
- `EntryDetailLoaded` — holds the current `TankEntry`, optional `isSaving` bool for save indicator
- `EntryDetailDeleted` — signals the view to pop

**Cubit responsibilities:**
- Receives initial `TankEntry` in constructor
- `updateName(String name)` — starts/resets a 500ms debounce `Timer`, then calls `_save()`
- `updateType(TankEntryType type)` — cancels any pending debounce, immediately calls `_save()` with the new type
- `deleteEntry()` — cancels any pending debounce, calls `_tankRepository.deleteEntry(id)`, emits `EntryDetailDeleted`
- `_save()` — calls `_tankRepository.updateEntry(...)` with current field values, emits updated `EntryDetailLoaded`
- `close()` override — if a debounce timer is active, cancel it and flush the pending save synchronously before calling `super.close()`

**Edge cases handled:**
- Empty/whitespace name: `_save()` skips the repository call if `name.trim().isEmpty`
- Concurrent save + delete: `deleteEntry()` cancels the debounce timer first
- Navigate back with pending save: `close()` flushes

#### 3b. `EntryDetailPage` and `EntryDetailView`

**Files:**
- `lib/entry_detail/view/entry_detail_page.dart`
- `lib/entry_detail/view/entry_detail_view.dart`

**Page:** `BlocProvider<EntryDetailCubit>` wrapping `EntryDetailView`. `BlocListener` on `EntryDetailDeleted` calls `context.pop()`.

**View layout (`CustomScrollView` or `Column`):**

```
+----------------------------------+
|  AppBar (back arrow, trash icon) |
+----------------------------------+
|                                  |
|   Hero(tag: 'entry-{id}')       |
|   Image.file (large, ~60% h)    |
|                                  |
+----------------------------------+
|  Name TextField (inline edit)    |
|  Type SegmentedButton            |
|  Date text (read-only, grey)     |
+----------------------------------+
```

- `TextField` for name: no border decoration, `TextEditingController` initialized with entry name, `onChanged` calls `cubit.updateName(value)`
- `SegmentedButton<TankEntryType>`: two segments (Livestock, Plant), `onSelectionChanged` calls `cubit.updateType(type)`
- Date: `Text` widget showing `DateFormat.yMMMd().format(entry.createdAt)` — uses `intl` package (already a transitive dependency via Flutter)
- Trash icon: `IconButton` in `AppBar.actions`, calls `_showDeleteConfirmation()` which shows `AlertDialog` matching existing gallery delete dialog pattern

### 4. Update Gallery to navigate to detail page

**File:** `lib/gallery/view/gallery_view.dart`

Changes to `_EntryCard`:
- Wrap `Image.file` in `Hero(tag: 'entry-${entry.id}')` for the transition
- Remove the `Dismissible` wrapper (delete moves to detail page)
- Remove the `GestureDetector` + `_editName` dialog on the name overlay
- Add a `GestureDetector` or `InkWell` on the entire card that calls `context.push('/gallery/${entry.id}', extra: entry)`

### 5. Fix `currentIndex` clamping in GalleryCubit

**File:** `lib/gallery/cubit/gallery_cubit.dart`

The stream listener currently resets `currentIndex` to 0 on every update. After the detail page triggers saves (which fire `_notify()`), this would jump the gallery back to the first page. Fix by preserving and clamping:

```dart
// In the stream listener:
final clampedIndex = state is GalleryLoaded
    ? (state as GalleryLoaded).currentIndex.clamp(0, max(0, entries.length - 1))
    : 0;
```

### 6. Tests

**File:** `test/entry_detail/cubit/entry_detail_cubit_test.dart`

Using `blocTest` + `mocktail`, matching existing test patterns:

- [ ] `updateName` emits `EntryDetailLoaded` with updated name after debounce
- [ ] `updateName` resets debounce timer on rapid input (only final value saved)
- [ ] `updateName` with empty string does not call repository
- [ ] `updateType` saves immediately (no debounce)
- [ ] `deleteEntry` emits `EntryDetailDeleted`
- [ ] `deleteEntry` cancels pending debounced save
- [ ] `close()` flushes pending debounced save

**File:** `test/gallery/cubit/gallery_cubit_test.dart`

- [ ] Update mock stubs if `updateEntry` signature changed (add `type` parameter)

## Dependencies

- `intl` package for `DateFormat` (likely already available transitively; add explicit dep if not)
- No new packages required

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Hero animation duplicate tag during PageView swipe | Use unique tag `'entry-${entry.id}'`; PageView only renders adjacent pages |
| Debounce timer not flushed on close | Override `close()` to cancel timer and call `_save()` |
| `currentIndex` out of bounds after type toggle | Clamp index in gallery cubit stream listener |
| `intl` not available as direct dep | Check and add to `pubspec.yaml` if needed |

## Out of Scope

- Editing the photo (retake)
- Editing `scientificName` (can be added later as a second text field with same debounce pattern)
- Visual "Saved" indicator (nice-to-have for follow-up)
- Auto-switching gallery tab after type toggle
- Deep link support for `/gallery/:id` without `extra`

---
title: "feat: switch AI provider to Gemini and add re-identification"
type: feat
date: 2026-03-30
---

## feat: switch AI provider to Gemini and add re-identification — Standard

## Overview

Replace the Anthropic AI integration with Google Gemini and add the ability to re-identify existing entries on demand. Three interconnected changes: (A) swap the API client package, (B) make entry names optional so users can save photo-only entries, and (C) add a re-identify button in the gallery.

## Problem Statement / Motivation

The user does not have an Anthropic API key but has access to Gemini. The existing architecture cleanly separates the AI provider via `SpeciesIdentificationRepository`, making a provider swap straightforward. Two UX improvements are added: optional names (defer identification) and on-demand re-identification.

## Proposed Solution

### Phase 1: Swap Anthropic to Gemini

This phase is one coherent unit: delete the old package, create the new one with tests, rename the storage key, update UI labels, and update imports.

#### 1a. Delete `packages/anthropic_api_client/` entirely

#### 1b. Create `packages/gemini_api_client/`

Implements `SpeciesIdentificationRepository`:

- **Endpoint:** `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`
- **Auth:** `x-goog-api-key` header (not query parameter — keeps key out of logs)
- **Request body:**
  ```json
  {
    "system_instruction": {
      "parts": [{ "text": "<reuse existing system prompt>" }]
    },
    "contents": [{
      "parts": [
        { "inline_data": { "mime_type": "image/jpeg", "data": "<base64>" } },
        { "text": "Identify this fish from the photo." }
      ]
    }],
    "generationConfig": {
      "responseMimeType": "application/json",
      "responseSchema": {
        "type": "object",
        "properties": {
          "commonName": { "type": "string" },
          "scientificName": { "type": "string" },
          "type": { "type": "string" }
        },
        "required": ["commonName", "scientificName", "type"]
      }
    }
  }
  ```
  > **Note:** The field is `responseSchema` (not `responseJsonSchema`) per Gemini API docs.
- **Response parsing:** `candidates[0].content.parts[0].text` → `json.decode()` → `IdentificationResult`
- **Error mapping:**
  | HTTP Code | Gemini Status | Maps To |
  |-----------|---------------|---------|
  | 401/403 | `UNAUTHENTICATED` / `PERMISSION_DENIED` | `InvalidApiKeyFailure` |
  | 429 | `RESOURCE_EXHAUSTED` | `RateLimitedFailure` |
  | `TimeoutException` | — | `TimeoutFailure` |
  | `SocketException` | — | `NetworkFailure` |
  | Other | — | `ParseFailure` |
- **Constructor:** `GeminiApiClient({required String apiKey, http.Client? httpClient})` — same testability pattern as the Anthropic client
- **Timeout:** 15 seconds (carry over from current client)

**Files:**
- `packages/gemini_api_client/pubspec.yaml` (new)
- `packages/gemini_api_client/analysis_options.yaml` (new — include `very_good_analysis`)
- `packages/gemini_api_client/lib/gemini_api_client.dart` (barrel, new)
- `packages/gemini_api_client/lib/src/gemini_api_client.dart` (implementation, new)
- `packages/gemini_api_client/test/src/gemini_api_client_test.dart` (new)

**Tests for Gemini client:**
- Successful identification (mock HTTP 200 with valid Gemini response)
- Invalid API key (401)
- Rate limited (429)
- Timeout
- Network error
- Malformed response (parse failure)

#### 1c. Update storage key and UI copy

- `packages/secure_storage/lib/src/secure_storage.dart` — Rename storage key from `'anthropic_api_key'` to `'gemini_api_key'`. Also delete the old `'anthropic_api_key'` entry on first read (one-time cleanup to avoid orphaned data).
- `lib/settings/view/api_key_form.dart`:
  - Title: "Claude API Key" → "Gemini API Key"
  - Hint text: `'sk-ant-...'` → `'AIza...'`
  - Description: "Anthropic API key" → "Gemini API key"
  - About card: "Claude AI" → "Gemini AI"
- `pubspec.yaml` (app root) — Swap `anthropic_api_client` path dependency → `gemini_api_client`
- `lib/main.dart` — Update import from `anthropic_api_client` to `gemini_api_client`, swap `AnthropicApiClient` → `GeminiApiClient`

### Phase 2: Make Entry Name Optional

**Keep `TankEntry.name` as non-nullable `String`.** Use empty string as the "no name" sentinel. No database schema migration needed — the `NOT NULL` constraint stays, and empty strings satisfy it.

Add a helper getter on `TankEntry` for self-documenting checks:
```dart
bool get hasName => name.isNotEmpty;
```

**Changes:**

- `packages/tank_repository/lib/src/models/tank_entry.dart`:
  - Change `name` from `required` to optional with default `''`
  - Add `bool get hasName => name.isNotEmpty`
- `packages/tank_repository/lib/src/tank_repository.dart` — `addEntry`: change `required String name` to `String name = ''`. Update the abstract interface and document the change.
- `packages/tank_local_storage/lib/src/local_tank_repository.dart` — Update `addEntry` to handle empty string for name
- `lib/add_entry/bloc/add_entry_event.dart` — `EntryConfirmed`: change `required this.name` to `this.name = ''`
- `lib/add_entry/view/confirm_entry_view.dart` — Remove the `_nameController.text.trim().isEmpty ? null` guard on the Save button. Allow saving with empty name.
- `lib/gallery/view/gallery_view.dart`:
  - `_EntryCard`: When `!entry.hasName`, leave the name area blank (no text rendered)
  - Delete confirmation: Use `'Remove this entry from your tank?'` when `!entry.hasName`
  - Edit name dialog: Allow saving empty string (remove `isNotEmpty` guard)

**Tests:**
- Update `test/add_entry/bloc/add_entry_bloc_test.dart` for optional name
- Update `test/gallery/cubit/gallery_cubit_test.dart` for entries with empty names
- Update any `TankEntry` model tests and mock setups (remove `required` name in constructors, update `registerFallbackValue` if needed)

### Phase 3: Re-Identify in Gallery

Add a re-identify button to gallery entry cards that triggers AI species identification.

**Changes to `GalleryCubit`:**

- Add `SpeciesIdentificationRepository?` as a constructor dependency
- Add a `reidentify(int entryId)` method:
  1. Guard: if `reidentifyingId == entryId`, return (prevent double-tap)
  2. Emit `GalleryLoaded` with `reidentifyingId` set
  3. Call `repository.identify(entry.imagePath)`
  4. Catch `FileSystemException` → emit error state (photo not found)
  5. On success: emit result state with the `IdentificationResult` and entry info
  6. On `IdentificationFailure`: emit error state, clear `reidentifyingId`

**Changes to `GalleryState`:**

- `GalleryLoaded`: add `int? reidentifyingId` (default null) — singular, since `PageView` shows one entry at a time

**Confirmation logic lives in the view** (consistent with how `_editName` and delete confirmation already work in `gallery_view.dart`):

- The cubit emits the AI result. The view decides how to present it:
  - If `!entry.hasName`: call `cubit.updateEntryName(...)` directly (auto-apply)
  - If `entry.hasName`: show an `AlertDialog` — "Replace '[current name]' with '[suggested name]'?" with Cancel and Replace buttons. On Replace, call `cubit.updateEntryName(...)`.

**Changes to gallery view:**

- `lib/gallery/view/gallery_page.dart` — Inject `SpeciesIdentificationRepository?` into `GalleryCubit`
- `lib/gallery/view/gallery_view.dart`:
  - Add re-identify icon button on each `_EntryCard`
  - When `reidentifyingId == entry.id`: show `CircularProgressIndicator` instead of the button
  - When repository is null: show button disabled; on tap show snackbar "Add a Gemini API key in Settings to use AI identification"
  - `BlocListener` on cubit for re-identify result → handle auto-apply or show confirmation dialog
  - Show snackbar on re-identify failure (network error, invalid key, etc.)
  - Show snackbar on file-not-found ("Photo not found")

**Tests:**
- `test/gallery/cubit/gallery_cubit_test.dart`:
  - `reidentify` happy path (calls identify, emits result)
  - `reidentify` failure cases (each `IdentificationFailure` type)
  - Double-tap guard (already reidentifying)
  - `reidentify` with file not found

## Technical Considerations

- **Architecture:** `GalleryCubit` gains one new dependency (`SpeciesIdentificationRepository?`) and one new method (`reidentify`). The confirmation dialog stays in the view layer, consistent with existing patterns. The nullable type preserves the "AI is optional" pattern.
- **No hot-swap:** API key changes require an app restart. This matches the current pattern and avoids restructuring the provider tree. Show a snackbar in Settings after key save/delete: "Restart the app to apply changes."
- **Performance:** Re-identification makes one API call per entry. Users identify one at a time via the gallery page view.
- **Security:** API key stored in `flutter_secure_storage` (encrypted). Sent via header, not URL parameter.

## Acceptance Criteria

- [ ] `anthropic_api_client` package deleted
- [ ] `gemini_api_client` package created with `very_good_analysis`, implementing `SpeciesIdentificationRepository`
- [ ] Gemini client uses `responseMimeType: "application/json"` with `responseSchema` for structured output
- [ ] Gemini client has unit tests covering success and all failure paths
- [ ] Old `'anthropic_api_key'` storage entry cleaned up on first read
- [ ] Entry name is optional — users can save entries with just a photo
- [ ] `TankEntry.hasName` getter used for name checks
- [ ] Gallery displays entries with empty names correctly (blank name area)
- [ ] Users can clear an existing name via the edit dialog
- [ ] Settings UI shows Gemini-specific copy (key format, labels, descriptions)
- [ ] Settings shows "Restart app to apply changes" after key save/delete
- [ ] Storage key is `'gemini_api_key'`
- [ ] Re-identify button appears on gallery entry cards
- [ ] Re-identify shows loading indicator while processing
- [ ] Re-identify auto-applies result when entry has no name
- [ ] Re-identify shows confirmation dialog when entry already has a name
- [ ] Re-identify button disabled with message when no API key configured
- [ ] Double-tap on re-identify is guarded (no duplicate requests)
- [ ] File-not-found error handled gracefully during re-identify
- [ ] Existing gallery and add-entry tests updated
- [ ] Zero analysis issues (`dart analyze`)

## Success Metrics

- AI species identification works end-to-end with a Gemini API key
- Users can save photo-only entries and identify them later
- Re-identify works on existing entries with confirmation for name overwrites

## Dependencies & Risks

- **Gemini API availability:** Free tier has rate limits (15 RPM for flash models). The `RateLimitedFailure` path handles this.
- **Empty string semantics:** Using `''` instead of `null` means code must use `entry.hasName` consistently. A missed check could display blank text where a fallback was intended.
- **`TankRepository` interface change:** Making `name` optional in `addEntry` is a breaking change to the abstract interface. All implementations and test mocks must be updated.

## References & Research

- Gemini API — Image Understanding: https://ai.google.dev/gemini-api/docs/image-understanding
- Gemini API — Structured Output: https://ai.google.dev/gemini-api/docs/structured-output
- Gemini API — API Keys: https://ai.google.dev/gemini-api/docs/api-key
- Gemini API — Error Codes: https://ai.google.dev/gemini-api/docs/troubleshooting
- Current Anthropic client: `packages/anthropic_api_client/lib/src/anthropic_api_client.dart`
- Species ID repository interface: `packages/species_identification_repository/lib/src/species_identification_repository.dart`
- Gallery cubit: `lib/gallery/cubit/gallery_cubit.dart`
- Add entry bloc: `lib/add_entry/bloc/add_entry_bloc.dart`
- App widget (DI root): `lib/app/app.dart`
- Settings view: `lib/settings/view/api_key_form.dart`
- Brainstorm: `wingspan/brainstorms/2026-03-30-switch-to-gemini-brainstorm-doc.md`

---
date: 2026-03-30
topic: switch-to-gemini
---

# Switch AI Provider from Anthropic to Gemini

## What We're Building

Replace the `anthropic_api_client` package with a new `gemini_api_client` package that implements the existing `SpeciesIdentificationRepository` interface using Google's Gemini API. The app's fish species identification feature will use Gemini's vision capabilities instead of Claude's. This is a clean swap — the abstract repository interface and all consuming code remain unchanged.

Additionally, add the ability to re-identify existing entries. A refresh button on any entry with a photo triggers AI species identification on demand. The entry name field is no longer required at creation time, so users can save photo-only entries and identify them later. When AI returns a result for an entry that already has a name, the user is prompted to confirm before the name is overwritten.

## Why This Approach

The user doesn't have an Anthropic API key but does have a Gemini subscription. The existing architecture cleanly separates the AI provider (data layer) from the domain and presentation layers via the `SpeciesIdentificationRepository` interface, making a provider swap straightforward.

**Approaches considered:**

1. **Replace entirely with Gemini (chosen)** — Delete `anthropic_api_client`, create `gemini_api_client`. Simplest path, follows YAGNI since there's no need to support both providers.
2. **Add Gemini alongside Anthropic** — Keep both, let user pick. Rejected as unnecessary complexity — the user only needs Gemini.

**Implementation approach:** Direct HTTP calls to the Gemini REST API, matching the pattern used by the current Anthropic client. Preferred over the `google_generative_ai` SDK to maintain consistency with existing codebase patterns and avoid adding a new dependency.

## Key Decisions

- **Full replacement, not dual-provider:** Delete `anthropic_api_client` entirely and create `gemini_api_client` in its place. No provider selection UI needed.
- **Direct HTTP, not SDK:** Use `dart:io` `HttpClient` to call Gemini's `generateContent` endpoint directly, matching the existing Anthropic client's pattern.
- **Gemini model:** Use `gemini-2.0-flash` for vision — fast, capable, and cost-effective for species identification.
- **Structured JSON output:** Use Gemini's `responseMimeType: "application/json"` to get clean JSON directly, rather than parsing JSON from free text. Simpler and more reliable than the Anthropic client's text-extraction approach.
- **System prompt:** Reuse the same prompt from the Anthropic client. No tuning for Gemini-specific behavior.
- **API key format:** Gemini API keys are obtained from Google AI Studio (https://aistudio.google.com/apikey). They look like `AIza...` — update the hint text and labels in the settings UI accordingly.
- **Storage key migration:** Rename `'anthropic_api_key'` to `'gemini_api_key'` in `SecureStorage`. No migration needed for existing stored keys since this is a demo app.
- **Testing:** The new `gemini_api_client` package must ship with unit tests. The existing Anthropic client had no tests — this is a chance to fix that gap.
- **Name not required:** Remove the name requirement from the add-entry form. Users can save entries with just a photo.
- **Re-identify existing entries:** Add a refresh/re-identify button on any entry that has a photo. Available regardless of whether the entry already has a name. Requires AI to be configured (API key saved).
- **Confirm before overwriting:** When AI returns a species name for an entry that already has a name, show a confirmation dialog before replacing it. For entries with no name, apply the result directly.

## Scope of Changes

| File/Package | Change |
|---|---|
| `packages/anthropic_api_client/` | Delete entirely |
| `packages/gemini_api_client/` (new) | New package implementing `SpeciesIdentificationRepository` via Gemini REST API |
| `lib/main.dart` | Swap `AnthropicApiClient` → `GeminiApiClient` |
| `pubspec.yaml` (app) | Swap dependency `anthropic_api_client` → `gemini_api_client` |
| `packages/secure_storage/` | Rename storage key from `'anthropic_api_key'` to `'gemini_api_key'` |
| `lib/settings/view/api_key_form.dart` | Update labels: "Gemini API Key", hint `'AIza...'`, description referencing Gemini |

| Add-entry form | Make name field optional (remove required validation) |
| Entry detail / tank view | Add re-identify button on entries with photos |
| Re-identify flow | Confirmation dialog when AI result would overwrite an existing name |

**No changes needed:** `species_identification_repository`, `app.dart` — all reference only the abstract interface.

## Assumptions

- Gemini's vision API accepts base64-encoded JPEG inline, matching the current client's image submission pattern.
- The existing failure type hierarchy (`InvalidApiKeyFailure`, `RateLimitedFailure`, `TimeoutFailure`, `SocketFailure`) maps to Gemini's HTTP error codes (401/403, 429, timeout, socket errors).

## Open Questions

- Are there Gemini-specific failure modes beyond the standard HTTP errors that need dedicated handling?

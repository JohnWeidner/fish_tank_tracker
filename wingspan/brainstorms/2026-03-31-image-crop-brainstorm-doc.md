---
date: 2026-03-31
topic: image-crop
---

# Image Cropping on Edit Page

## What We're Building

Add a crop button to the entry detail (edit) page that lets users crop the existing image. Tapping the button launches the native platform crop UI via the `image_cropper` package. The cropped image replaces the current image, following the same `updateImage` flow as the retake photo feature. Free-form cropping (no fixed aspect ratio). Cropping is only available from the edit page — not after initial photo capture.

## Why This Approach

Three approaches were considered:

1. **`image_cropper` (chosen)**: Native crop UIs on iOS/Android via platform channels. Most popular package (333K downloads). Polished, familiar UX with no Flutter-side rendering of crop handles.
2. **`crop_image`**: Pure Flutter widget. Simpler integration but less polished UX and requires manual file saving.
3. **`croppy`**: Modern pure-Flutter cropper with animations. Smaller community (6K downloads).

Approach 1 was chosen for the best UX — users get the platform-native crop experience they're already familiar with from their phone's photo editor.

## Key Decisions

- **Edit page only**: No auto-crop after capture. Crop is an optional edit action.
- **Free-form crop**: No aspect ratio constraint.
- **Same flow as retake**: Crop produces a new image file, passed to `cubit.updateImage()`. Old image tracked for cleanup. Revert restores original.
- **Crop icon placement**: Next to the existing camera retake button on the image area.

## Open Questions

- Should rotation be enabled in the crop UI alongside cropping?
- Should the cropped file be compressed/resized or saved at full resolution?

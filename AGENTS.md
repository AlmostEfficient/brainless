# Brainless Agent Guide

## Project Snapshot

Brainless is a SwiftUI iOS app for AI-generated personalized workouts. The app stores durable user context locally, calls a backend for workout generation, constrains exercises to a backend catalog, and derives exercise visuals from catalog IDs.

Current implementation status:
- App shell, onboarding, home generation flow, workout preview, workout mode, history, settings, networking, catalog service, and SwiftData persistence are implemented.
- The app currently uses `MockWorkoutGenerationService` from `HomeView` for local generation.
- `RemoteWorkoutGenerationService` exists and posts to `/generate-workout`, but the exact backend generation contract still needs to be finalized and tested.
- The project builds successfully for the iOS simulator.
- Template `ContentView.swift`, `Item.swift`, and placeholder `App/OnboardingView.swift` were removed.

## Important Contract Rules

Follow `CONTRACT.md` for the exercise catalog.

Exercise catalog data in the Swift app is compact only:
- `ExerciseCatalogItem.id`
- `ExerciseCatalogItem.name`
- `ExerciseCatalogItem.muscle`
- `ExerciseCatalogItem.equipment`

Do not add or persist `gifURL` to any model. Exercise visuals are derived from the exercise ID:
- GIF: `https://assets.raza.run/exercises/gifs/{id}.gif`
- Future poster: `https://assets.raza.run/exercises/posters/{id}.jpg`

Use `ExerciseAssetURLBuilder` for this. Keep the assets base URL configurable.

Backend defaults:
- API base URL: `https://nexus.raza.run/v1`
- Catalog endpoint: `GET /v1/exercises`
- Catalog response: `{ "data": [...], "meta": {...} }`
- Catalog error response: `{ "error": { "code": "...", "message": "..." } }`

The iOS app should not depend on source ExerciseDB fields, local research repo paths, source `gifUrl`, catalog `tags`, `muscles`, `secondaryMuscles`, `bodyParts`, or `equipments`.

## Architecture

Top-level app files:
- `Brainless/BrainlessApp.swift`: app entry and SwiftData `ModelContainer`.
- `Brainless/App/`: app container, dependency environment, app state store, root routing, main tabs, SwiftData record classes.

Domain and persistence:
- `Brainless/Models/FitnessEnums.swift`
- `Brainless/Models/ProfileModels.swift`
- `Brainless/Persistence/Stores.swift`

Networking and services:
- `Brainless/Networking/`: `APIClient`, `APIError`, `APITokenProvider`.
- `Brainless/Services/`: exercise catalog, asset URL builder, workout generation services.

Features:
- `Brainless/Features/Onboarding/`
- `Brainless/Features/Home/`
- `Brainless/Features/WorkoutPreview/`
- `Brainless/Features/WorkoutMode/`
- `Brainless/Features/History/`
- `Brainless/Features/Settings/`

Shared UI:
- `Brainless/UIComponents/ExerciseVisualView.swift`

The Xcode project uses a filesystem-synchronized root group, so Swift files added under `Brainless/` are picked up automatically without editing `project.pbxproj`.

## Persistence

The app uses SwiftData with JSON blob records to keep the schema simple:
- `AppSettingsRecord`
- `UserProfileRecord`
- `TrainingPreferencesRecord`
- `EquipmentProfileRecord`
- `WorkoutSessionRecord`

Store protocols are main-actor isolated:
- `UserProfileStore`
- `TrainingPreferencesStore`
- `EquipmentProfileStore`
- `WorkoutHistoryService`

Current concrete stores:
- `SwiftDataUserProfileStore`
- `SwiftDataTrainingPreferencesStore`
- `SwiftDataEquipmentProfileStore`
- `SwiftDataWorkoutHistoryService`

Avoid complex SwiftData relationships until the domain schema stabilizes.

## Current Flow

Startup:
- `RootView` reads `AppSettingsRecord`.
- If onboarding is incomplete, it shows `OnboardingFlowView`.
- Completing onboarding saves profile/preferences/equipment and marks onboarding complete.
- If onboarding is complete, it shows `MainTabView`.

Main tabs:
- Home: mock generation, preview, start workout mode, save completed/partial sessions.
- History: session list and detail from `WorkoutHistoryService`.
- Settings: edit persisted profile, training preferences, and equipment.

Workout mode:
- `WorkoutModeView` presents one exercise per full-screen vertical page via `TabView(.page)`.
- It uses `ExerciseVisualView(exerciseID:)`.
- Logging is optional.
- Finish sheet can save completed, save partial, or discard.

## Verification Commands

Use these from the repo root:

```sh
xcodebuild -project Brainless.xcodeproj -scheme Brainless -destination 'generic/platform=iOS Simulator' build
```

Named simulator build that succeeded in this environment:

```sh
xcodebuild -project Brainless.xcodeproj -scheme Brainless -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4.1' build
```

Launch smoke test used after building:

```sh
xcrun simctl boot C7844927-E463-4D74-AEE4-4A78C1D2F5E5 || true
xcrun simctl install C7844927-E463-4D74-AEE4-4A78C1D2F5E5 /Users/raza/Library/Developer/Xcode/DerivedData/Brainless-guhwfbjewbnhiwdvrifstaagqlos/Build/Products/Debug-iphonesimulator/Brainless.app
xcrun simctl launch C7844927-E463-4D74-AEE4-4A78C1D2F5E5 com.raza.Brainless
```

The simulator OS listing may show `26.4`, while Xcode destination matching expects `26.4.1`. If a named destination fails, inspect `xcodebuild`’s available destinations and use the exact OS string or simulator UUID.

Expected harmless warning:
- `Metadata extraction skipped. No AppIntents.framework dependency found.`

## Build Process Hygiene

Before ending a turn, make sure no build/compiler jobs are still running:

```sh
pgrep -fl 'xcodebuild|swiftc|clang|actool|appintentsmetadataprocessor|ibtool|ibtoold|SourceKitService' || true
```

To stop lingering build/compiler helpers when explicitly asked:

```sh
pkill -f 'xcodebuild|swiftc|clang|actool|appintentsmetadataprocessor|ibtool|ibtoold|SourceKitService' || true
```

## Git And Workspace Notes

Do not revert unrelated user changes.

Known worktree details from the implementation handoff:
- `Brainless.xcodeproj/project.xcworkspace/xcuserdata/raza.xcuserdatad/UserInterfaceState.xcuserstate` was already modified by Xcode/user activity and should not be reverted casually.
- `.gitignore`, `CONTRACT.md`, and `prompt.md` are currently untracked project files.
- The current implementation added new source directories under `Brainless/`.

## Style And Implementation Guidance

Keep architecture boring and direct:
- SwiftUI views should depend on view models/protocols, not model-provider details.
- API tokens are an `APIClient` concern via `APITokenProvider`, not view-level logic.
- The iOS app should call the backend, never a model provider directly.
- Do not introduce provider-side memory, vector databases, embeddings, assistant threads, or autonomous orchestration into the iOS app.

Safety positioning:
- Do not claim to diagnose, treat, or rehabilitate medical conditions.
- Use user-provided limitations to adapt workouts.
- Keep “not medical advice” language in onboarding and workout mode.
- If adding pain/injury handling, bias toward conservative copy and professional guidance.

Visuals:
- Keep `ExerciseVisualView` resilient to missing/broken GIFs.
- Do not block workout mode if media fails.
- Use derived URLs only.

## Likely Next Work

The highest-value next tasks:
1. Replace mock-only home generation with a user-selectable or configuration-driven `RemoteWorkoutGenerationService`.
2. Finalize the `/generate-workout` request/response/error shape with the backend and update `WorkoutGenerationRequest` / `WorkoutGenerationResponse` DTOs if needed.
3. Improve `HomeViewModel` so it builds generation requests from persisted stores and real history summaries rather than current local draft/sample context.
4. Add response validation for unavailable equipment and duplicate/invalid exercise IDs.
5. Manually test onboarding → home → generate → preview → workout mode → save → history on simulator.
6. Add focused unit tests once a test target exists.


You are planning an iOS app from a blank SwiftUI project.

Think at high effort. Do not implement code yet. Create an implementation-ready product and technical plan that I can later hand to Codex 5.5 Medium one ticket at a time.

App concept:
I am building an AI-powered fitness app that creates highly personalized workouts for users. The app is inspired by how I currently use ChatGPT/Claude for workouts: I tell the AI my body issues, goals, equipment, and how I feel today, then it generates a workout. The problem is that chat eventually loses context, quality drops, and exercises do not have visuals, so I have to Google what the movements look like.

This app is the upgrade: it stores the long-term context, lets the user steer each workout conversationally, generates workouts from that context, and presents exercises with visuals in a smooth workout mode.

Core user flow:
1. User installs the app.
2. User completes onboarding by telling the app relevant fitness/body context:
   - Weak joints
   - Posture problems
   - Muscle imbalances
   - Occupational issues such as nerd neck, anterior/posterior pelvic tilt, tight hips, etc.
   - Optional notes from health reports or physio-style summaries
   - This can be entered by text or audio later, but for MVP assume text input only.
   - This information changes rarely, so it should be stored as persistent profile context.
3. User configures high-level training intentions:
   - Strength
   - Hypertrophy
   - Flexibility/mobility
   - Corrective/prehab work for their issues
   - These preferences change infrequently, maybe every 6–12 months.
4. User configures workout environment:
   - Where they work out
   - Available equipment
   - Missing equipment
   - For MVP, use simple equipment toggles and/or text fields.
5. User requests a workout for a specific day or intent:
   - Push
   - Pull
   - Legs
   - Core
   - Full body
   - Stretching/mobility
   - Recovery
   - Custom free-text request
6. User can steer the workout before generation:
   - “My shoulders feel tight today”
   - “I really want to feel my core”
   - “Avoid heavy squats”
   - “Keep it under 35 minutes”
7. App generates a workout using:
   - Persistent user body context
   - Long-term training goals
   - Equipment constraints
   - Today’s workout request
   - Recent workout history, especially the last 3–4 workouts
   - Exercise candidates from the backend exercise catalog
8. User enters workout mode.
9. Workout mode shows one exercise per full-screen page, similar to TikTok/Reels vertical scrolling:
   - Exercise GIF/visual at the top
   - Exercise name
   - Instructions or coaching note
   - Sets/reps/rest
   - Quick buttons to log weight and reps
   - Logging is optional
   - Scrolling to the next exercise effectively means moving on
10. User can finish the workout and optionally save logged performance.

Important product behavior:
- The workout output should vary based on workout history.
- If the user has not worked out for two weeks, the app should bias toward easier re-entry workouts, mobility, compound movement patterns, and lower intensity instead of PR-focused training.
- The app should not let the model recommend arbitrary exercises that do not exist in the catalog.
- The model should choose from backend-provided exercise candidates / allowed exercise IDs.
- The exercise catalog is a core product constraint, not a later afterthought.
- Favor boring, reliable architecture over clever abstractions.

Backend contract:
The backend exercise catalog contract is defined in CONTRACT.md.

Exercise catalog:
- Treat the exercise catalog as a backend API only.
- Do not depend on local research repo paths or source ExerciseDB fields in the Swift app.
- The backend serves a compact static index.
- Exercise GIFs are uploaded separately to R2.
- The app should not rely on source gifUrl values from ExerciseDB.

Exercise catalog endpoint:
Base URL:
https://nexus.raza.run/v1

GET /v1/exercises

Query parameters:
- muscle: comma-separated string, optional
- equipment: comma-separated string, optional
- bodyPart: comma-separated string, optional
- excludeTags: comma-separated string, optional
- q: optional case-insensitive name search
- limit: optional, default 50, min 1, max 100
- offset: optional, default 0

Filter behavior:
- Values within one parameter are OR matched.
- Different parameters are AND matched.
- muscle only matches primary target muscle.
- excludeTags removes matches after inclusion filters.
- Results are sorted by name ascending for now.

Exercise response shape:
The endpoint returns a wrapped paginated response:

{
  "data": [
    {
      "id": "ZA8b5hc",
      "name": "kettlebell goblet squat",
      "muscle": "quads",
      "equipment": "kettlebell"
    }
  ],
  "meta": {
    "total": 1,
    "limit": 25,
    "offset": 0,
    "nextOffset": null
  }
}

Each item has this shape:

{
  "id": "ZA8b5hc",
  "name": "kettlebell goblet squat",
  "muscle": "quads",
  "equipment": "kettlebell"
}

The endpoint does not return GIF/image URLs.

Tool-use endpoint:
The backend also exposes a JSON-body alias for model/tool calls:

POST /v1/tools/search-exercises

Request body:
{
  "muscle": ["chest"],
  "equipment": ["dumbbell", "bodyweight"],
  "bodyPart": ["chest"],
  "excludeTags": ["equipment:smith machine"],
  "q": "press",
  "limit": 25,
  "offset": 0
}

Response shape is identical to GET /v1/exercises.

Authentication:
- Backend endpoints may require bearer auth.
- Treat auth as an injectable API client concern, not as view-level logic.
- For planning, include an API token provider/config placeholder.

Input aliases:
The backend accepts common caller-friendly aliases and maps them to the ExerciseDB taxonomy:
- chest -> pectorals
- quadriceps -> quads
- shoulders / deltoids -> delts
- abdominals -> abs
- trapezius -> traps
- latissimus dorsi -> lats
- bodyweight / body only / none -> body weight
- bands -> band, resistance band
- kettlebells -> kettlebell
- e-z curl bar / ez curl bar -> ez barbell
- machine -> leverage machine, smith machine

Asset URL rule:
Swift should construct GIF URLs from the exercise ID:

https://assets.raza.run/exercises/gifs/{id}.gif

Example:
https://assets.raza.run/exercises/gifs/trmte8s.gif

If poster frames are added later, use:
https://assets.raza.run/exercises/posters/{id}.jpg

Do not store gifURL as authoritative app data. Derive it from exercise.id through an ExerciseAssetURLBuilder or equivalent.
ExerciseAssetURLBuilder should take a configurable assetsBaseURL with default value https://assets.raza.run so the R2/custom-domain host can be swapped without model changes.

AI/model integration:
- Use real AI workout generation in the MVP.
- The model integration should be a simple stateless Chat Completions-style request/response.
- The iOS app should not call the model provider directly.
- The iOS app should call my backend.
- The backend calls the model provider.
- API keys must stay on the backend.
- Do not plan around long-lived assistant threads, provider-side memory, vector databases, embeddings, autonomous agents, or multi-step model orchestration for MVP.
- App/backend owns all user persistence and context.
- The model receives structured context and returns structured JSON.

Workout generation architecture:
The intended architecture is:

iOS app
→ WorkoutGenerationService
→ Backend /generate-workout endpoint
→ Chat Completions model
→ optional exercise search tool call to POST /v1/tools/search-exercises
→ structured workout JSON
→ iOS workout UI

The backend/model should use the exercise catalog as a tool:
- Tool name: search_exercises
- Tool purpose: retrieve exercise candidates for workout generation
- The model should query by muscle, equipment, bodyPart, q, excludeTags, limit, and offset as needed.
- The model/backend should use POST /v1/tools/search-exercises for JSON tool calls.
- The generated workout should only reference valid exercise IDs returned by the exercise catalog.
- Avoid a separate “categorize intent” model call unless prompt quality becomes a problem.
- Avoid embeddings for v1. Exact filters plus optional text search are enough.

Expected generated workout response:
Design a Swift-friendly structured JSON response for generated workouts. It should include:
- workout title
- summary
- estimated duration
- intensity
- focus areas
- exercises array
- each exercise should reference catalog exercise id, name, muscle, equipment
- sets
- reps or duration
- rest seconds
- coaching note
- optional substitution notes
- optional safety note

The generated workout must be renderable even if the user does not log anything.

Services/protocols:
Include these service abstractions in the plan:
- WorkoutGenerationService
  - MockWorkoutGenerationService
  - RemoteWorkoutGenerationService
- ExerciseCatalogService
  - RemoteExerciseCatalogService
  - MockExerciseCatalogService if useful for local dev
- ExerciseAssetURLBuilder
- WorkoutHistoryService
- UserProfileStore
- TrainingPreferencesStore
- EquipmentProfileStore

The UI should depend on protocols/view models, not directly on networking or model-provider details.

Safety and positioning:
- The app should not diagnose or treat medical conditions.
- The app can use user-provided limitations and preferences to adapt workouts.
- Add appropriate UX language for “not medical advice.”
- Encourage professional guidance for pain, injury, medical conditions, or rehab.
- If the user reports pain or injury, the workout generation flow should bias toward conservative suggestions and/or recommend skipping risky movements.
- The MVP should avoid strong clinical claims.

Assume:
- SwiftUI
- iOS app
- Real AI workout generation through my backend
- Chat Completions-style model calls from backend
- Exercise catalog available through GET /v1/exercises
- Exercise GIF assets available through R2 URL pattern
- Backend endpoints may require bearer auth; keep auth configurable and isolated in the API client
- No subscriptions yet
- No HealthKit yet
- Local persistence for user context, preferences, equipment profile, workout history
- Keep architecture backend-ready and provider-swappable

I want the plan to include:

1. Product summary
   - One-paragraph explanation of the app
   - Core value proposition
   - What makes it different from generic workout apps

2. MVP scope
   - What should be included in the first build
   - What should be explicitly excluded for now
   - What should be left for later

3. User flows
   - Onboarding flow
   - Profile/context editing flow
   - Training preference flow
   - Equipment setup flow
   - Workout generation flow
   - Workout mode flow
   - Workout completion/history flow
   - Regenerate/edit workout flow

4. Screen list
   For each screen, include:
   - Purpose
   - Main UI elements
   - State it reads
   - State it writes
   - Navigation in/out

5. Data model
   Design Swift-friendly models for:
   - UserBodyContext
   - TrainingPreferences
   - EquipmentProfile
   - ExerciseCatalogItem
   - GeneratedWorkout
   - WorkoutExercise
   - WorkoutSession
   - LoggedSet
   - WorkoutHistorySummary
   - WorkoutGenerationRequest
   - WorkoutGenerationResponse

ExerciseCatalogItem should match the backend catalog response: id, name, muscle, equipment. Do not include gifURL as stored model data; derive GIF URLs from exercise.id using the CONTRACT.md asset URL pattern.

6. Backend/API integration model
   - Define what the iOS app sends to /generate-workout
   - Define what the backend returns
   - Define how /generate-workout uses the exercise catalog
   - Define how errors should be represented
   - Define retry/fallback behavior
   - Define loading states in the app

7. Exercise catalog integration
   - How the app should represent ExerciseCatalogItem
   - How the app should call GET /v1/exercises if needed
   - How the backend/model should use search_exercises
   - How to prevent generated workouts from referencing unknown exercise IDs
   - How to handle unavailable equipment
   - How to handle missing exercise candidates

8. Exercise visual handling
   - Derive GIF URL from exercise.id
   - Do not store gifURL as source of truth
   - Design ExerciseVisualView so GIFs, poster frames, and videos can be swapped later
   - Handle missing/broken GIFs gracefully
   - Consider caching strategy at a high level

9. Local storage plan
   - What should be stored persistently
   - What can remain in memory
   - Whether to use UserDefaults, SwiftData, or another local approach for MVP
   - Recommend the simplest reasonable option

10. App architecture
   - Suggested folder structure
   - State management approach
   - Services/protocols needed
   - Networking layer design
   - Backend-ready boundaries
   - How to isolate model/provider details from the UI

11. Workout generation behavior
   - How to build the prompt/request payload
   - How much recent workout history to include
   - How to summarize old history
   - How to include user limitations safely
   - How to include equipment constraints
   - How to constrain model output to exercise catalog IDs
   - How to validate the response before displaying it

12. Workout mode UX
   - Full-screen vertical paging/scrolling interaction
   - Logging controls
   - Optional logging behavior
   - Rest timer handling for MVP
   - Finish workout behavior
   - Skip exercise behavior
   - Substitution/regeneration behavior if practical

13. Edge cases
   Include edge cases around:
   - Empty profile
   - No equipment selected
   - User asks for unavailable equipment
   - Backend returns no candidates
   - Model returns invalid exercise ID
   - Model returns malformed JSON
   - User reports pain
   - User skips logging
   - User exits workout early
   - No workout history
   - Long user text context
   - Missing or broken exercise GIF
   - Network failure during generation
   - Slow generation

14. Implementation phases
   Break the work into phases that Codex 5.5 Medium can implement one at a time.

15. First 10 implementation tickets
   Each ticket should include:
   - Goal
   - Files likely touched
   - Acceptance criteria
   - Notes for Codex
   - Whether it is safe to run independently

16. Risks and product decisions
   - Technical risks
   - UX risks
   - AI quality risks
   - Exercise catalog risks
   - Safety/compliance risks
   - Decisions I need to make before building further

17. Recommended build order
   Give me the lowest-risk path to a working prototype as quickly as possible.

Output format:
Use clear headings.
Be specific.
Do not write actual Swift code unless a small pseudocode example clarifies architecture.
Optimize for a practical MVP, not a perfect final product.
Favor boring, reliable architecture over clever abstractions.
Pay special attention to the workout mode UX; this is the core magical surface of the app.

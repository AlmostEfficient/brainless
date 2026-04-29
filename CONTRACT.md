# Exercise Catalog Contract

## Recommendation

Use `research/exercisedb-api` as the primary exercise catalog. Do not run its full API service in production. Instead, build a compact static index from `src/data/exercises.json`, upload the GIFs from `media/*.gif` to R2, and serve one small filter endpoint from Cloudflare Workers.

Do not combine with `research/free-exercise-db` for the first production version. It is useful as a fallback/public-domain corpus, but combining now adds taxonomy normalization, duplicate detection, ID mapping, and asset inconsistency for little benefit in a single-user app.

Why:

- `exercisedb-api` has 1500 exercises, complete local GIF coverage, and already has filterable fields: `targetMuscles`, `bodyParts`, `equipments`, `secondaryMuscles`.
- `free-exercise-db` has 873 exercises and cleaner public-domain licensing, but only JPG stills and 77 records with missing equipment. It also has fewer exercises and no GIFs.
- Cloudflare Workers can comfortably hold a 1.3 MB JSON source or a smaller generated index in memory. No database is needed for exact filters.
- R2 is the right place for GIF assets. Bundling 142 MB of media into Workers is not appropriate.

Recommended LLM retrieval approach: tool use. Claude/ChatGPT should call the filter endpoint directly during workout generation. Avoid a separate "categorize intent" call unless prompt quality becomes a problem. Avoid embeddings for v1; exact filters plus optional text query are simpler, cheaper, deterministic, and enough for a personal app.

Estimated setup: 4-6 hours.

- 1 hour: generate normalized catalog index from ExerciseDB JSON.
- 1-2 hours: upload GIFs to R2 and verify URL pattern.
- 1-2 hours: implement Worker endpoint, filtering, validation, and tests.
- 1 hour: connect as an LLM tool and test workout generation.

## Source Data

Primary source:

`research/exercisedb-api/src/data/exercises.json`

Source record fields used by backend:

- `exerciseId`: stable source ID.
- `name`: display name.
- `targetMuscles`: primary muscle list. Current dataset has one target muscle per exercise.
- `secondaryMuscles`: supporting muscles.
- `bodyParts`: coarse body region.
- `equipments`: required equipment. Current dataset has one equipment value per exercise.
- `gifUrl`: source URL only. Production should replace this with the R2 URL pattern below.

Production index record:

```json
{
  "id": "trmte8s",
  "name": "band shrug",
  "muscle": "traps",
  "muscles": ["traps"],
  "secondaryMuscles": ["shoulders"],
  "bodyParts": ["neck"],
  "equipment": "band",
  "equipments": ["band"],
  "tags": ["muscle:traps", "bodypart:neck", "equipment:band"]
}
```

`muscle` and `equipment` are convenience aliases for Swift and LLM responses. `muscles` and `equipments` preserve future compatibility if a source record has multiple values.

## API

Base URL:

`https://<worker-host>/v1`

### `GET /v1/exercises`

Returns filterable exercise candidates for LLM workout generation.

The response intentionally excludes GIF/image URLs. The app derives asset URLs using the asset pattern below.

#### Query Parameters

| Parameter | Type | Required | Default | Notes |
| --- | --- | --- | --- | --- |
| `muscle` | comma-separated string | No | none | Matches any primary target muscle. Example: `chest,triceps`. |
| `equipment` | comma-separated string | No | none | Matches any equipment. Example: `dumbbell,body weight`. |
| `bodyPart` | comma-separated string | No | none | Optional coarse filter. Example: `upper arms,chest`. |
| `excludeTags` | comma-separated string | No | none | Excludes records with matching normalized tags. See tag format below. |
| `q` | string | No | none | Optional case-insensitive substring search over exercise name. |
| `limit` | integer | No | `50` | Min `1`, max `100`. |
| `offset` | integer | No | `0` | Zero-based offset for pagination. |

Filter semantics:

- Within a parameter, comma-separated values are OR matched.
- Across different parameters, filters are AND matched.
- `muscle` only matches primary `targetMuscles`, not `secondaryMuscles`.
- `excludeTags` removes matches after inclusion filters.
- Matching is case-insensitive after trimming whitespace.
- Results are sorted by `name` ascending unless the backend later adds explicit ranking.

Supported tag format:

- `muscle:<value>`
- `secondary:<value>`
- `bodypart:<value>`
- `equipment:<value>`
- `name:<source-id>`

Examples:

```http
GET /v1/exercises?muscle=chest&equipment=dumbbell,body%20weight&excludeTags=equipment:smith%20machine&limit=25
```

```http
GET /v1/exercises?bodyPart=upper%20legs&equipment=barbell&q=squat&limit=20
```

#### Success Response

Status: `200`

```json
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
```

Response item contract:

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string | ExerciseDB `exerciseId`. Also used for asset lookup. |
| `name` | string | Human-readable exercise name. |
| `muscle` | string | First primary target muscle. |
| `equipment` | string | First equipment value. |

No asset URL is returned from this endpoint.

### `POST /v1/tools/search-exercises`

JSON-body alias for LLM tool calls. It runs the same filtering logic and returns the same response shape as `GET /v1/exercises`.

Request:

```json
{
  "muscle": ["chest"],
  "equipment": ["dumbbell", "bodyweight"],
  "bodyPart": ["chest"],
  "excludeTags": ["equipment:smith machine"],
  "q": "press",
  "limit": 25,
  "offset": 0
}
```

Array values are OR matched, same as comma-separated GET query values.

#### Error Response

Status: `400`

```json
{
  "error": {
    "code": "invalid_query",
    "message": "limit must be between 1 and 100"
  }
}
```

Status: `500`

```json
{
  "error": {
    "code": "internal_error",
    "message": "Exercise catalog unavailable"
  }
}
```

## Assets

Store ExerciseDB GIF files in R2 using the source ID as the filename.

Source:

`research/exercisedb-api/media/{id}.gif`

R2 object key:

`exercises/gifs/{id}.gif`

Public asset URL pattern:

`https://assets.raza.run/exercises/gifs/{id}.gif`

Example:

`https://assets.raza.run/exercises/gifs/trmte8s.gif`

Swift should construct asset URLs from the exercise `id`. It should not rely on `gifUrl` from the source dataset. `ExerciseAssetURLBuilder` should use a configurable `assetsBaseURL` with default value `https://assets.raza.run`.

If still images are later needed, generate poster frames from GIFs and store them separately:

`https://assets.raza.run/exercises/posters/{id}.jpg`

## LLM Tool Definition

Tool name:

`search_exercises`

Tool description:

Search the local exercise catalog for candidate movements by primary muscle, available equipment, excluded tags, and optional name text. Use this before choosing exact exercise names in a workout.

Input schema:

```json
{
  "type": "object",
  "properties": {
    "muscle": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Primary muscles to include. OR matched."
    },
    "equipment": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Available equipment to include. OR matched."
    },
    "bodyPart": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Optional body-part filters. OR matched."
    },
    "excludeTags": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Tags to exclude, such as equipment:barbell or bodypart:waist."
    },
    "q": {
      "type": "string",
      "description": "Optional exercise name text search."
    },
    "limit": {
      "type": "integer",
      "minimum": 1,
      "maximum": 100,
      "default": 50
    }
  }
}
```

Tool output is the same as `GET /v1/exercises`.

## Input Aliases

The backend accepts common caller-friendly aliases and maps them to the ExerciseDB taxonomy:

- `chest` -> `pectorals`
- `quadriceps` -> `quads`
- `shoulders` / `deltoids` -> `delts`
- `abdominals` -> `abs`
- `trapezius` -> `traps`
- `latissimus dorsi` -> `lats`
- `bodyweight` / `body only` / `none` -> `body weight`
- `bands` -> `band`, `resistance band`
- `kettlebells` -> `kettlebell`
- `e-z curl bar` / `ez curl bar` -> `ez barbell`
- `machine` -> `leverage machine`, `smith machine`

## Backend Implementation Notes

Minimal Cloudflare Worker setup:

1. Build a generated `exercise-index.json` from ExerciseDB source data.
2. Import the generated index into the Worker bundle or load it once from R2/KV at startup.
3. On each request, parse query params, normalize to lowercase, filter in memory, slice pagination, and return only `id`, `name`, `muscle`, `equipment`.
4. Upload all `media/*.gif` files to R2 under `exercises/gifs/`.
5. Serve R2 through a public custom domain or a Worker asset proxy.

Preferred for v1: bundle `exercise-index.json` in the Worker. The generated index should be smaller than the 1.3 MB source JSON because it excludes instructions and source URLs.

Do not use a relational database, vector database, or full-text search service for v1.

## Future Extensions

Add these only after the basic flow is working:

- `includeSecondary=true` for secondary muscle matching.
- `level` or difficulty, if manually curated or imported from another source.
- Exercise aliases for better LLM matching.
- Poster JPG generation for faster Swift list rendering.
- Embeddings for fuzzy intent only if exact filters produce visibly poor workout choices.

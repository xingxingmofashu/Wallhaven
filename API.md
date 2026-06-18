# Wallhaven API v1

Official reference: <https://wallhaven.cc/help/api>

## Base URL

```
https://wallhaven.cc/api/v1
```

Overridable via `UserDefaults("wallhaven_api_base_url")` in Settings.

## Authentication

- Append `?apikey=<KEY>` to any request, or send `X-API-Key` header.
- NSFW content requires a valid key.
- Keys set in `UserDefaults("wallhaven_api_key")`.

## Rate Limiting

45 requests/minute. 429 response on exceed.

## Endpoints

### `GET /w/<id>` — Wallpaper detail

| Param | Required | Description |
|---|---|---|
| `apikey` | for NSFW | |

Response `data` fields used by the app:

| Field | Type | Notes |
|---|---|---|
| `id` | String | e.g. `"94x38z"` |
| `url` | String | Web page |
| `path` | String | Full-res image URL |
| `thumbs.large` / `.original` / `.small` | String | Thumbnail URLs (th.wallhaven.cc) |
| `dimension_x`, `dimension_y` | Int | Pixels |
| `resolution` | String | e.g. `"6742x3534"` |
| `ratio` | String | e.g. `"1.91"` |
| `file_size` | Int | Bytes |
| `file_type` | String | e.g. `"image/jpeg"` |
| `purity` | String | `"sfw"` / `"sketchy"` / `"nsfw"` |
| `category` | String | `"general"` / `"anime"` / `"people"` |
| `colors` | [String] | Hex colors |
| `tags` | [{ id, name, alias, category, purity }] | | |
| `uploader` | { username, avatar } | |
| `favorites` | Int | |
| `views` | Int | |
| `source` | String | Source URL |
| `created_at` | String | `"2018-10-31 01:23:10"` |

### `GET /search` — Search/listings

All search URL parameters accepted:

| Param | Values | Default | Used in app |
|---|---|---|---|
| `q` | Free text, `+tag`, `-tag`, `@user`, `id:NN`, `type:{png/jpg}`, `like:ID` | — | Search bar, related wallpapers (`like:ID`) |
| `categories` | 3-bit binary `"111"` (general/anime/people) | `"100"` | Yes |
| `purity` | 3-bit binary `"100"` (sfw/sketchy/nsfw) | `"100"` | Yes |
| `sorting` | `date_added`, `relevance`, `random`, `views`, `favorites`, `toplist`, `hot` | `date_added` | Yes |
| `order` | `desc`, `asc` | `desc` | Yes |
| `top_range` | `1d`, `3d`, `1w`, `1M`, `3M`, `6M`, `1y` | `1M` | Yes (when `sorting=toplist`) |
| `atleast` | e.g. `"1920x1080"` | — | Yes |
| `resolutions` | Comma-separated, e.g. `"1920x1080,2560x1440"` | — | Yes |
| `ratios` | Comma-separated, e.g. `"16x9,16x10"` | — | Yes |
| `colors` | Single color hex (no `#`), e.g. `"660000"` | — | Yes |
| `seed` | 6-char alphanumeric | — | Yes (when `sorting=random`) |
| `page` | Int (1-based) | 1 | Yes |
| `apikey` | | — | Yes |

Restrictions: `sorting=random` cannot be combined with `q`; `toplist` sorting requires `top_range`.

Response `data` is an array of `Wallpaper` (same fields as detail, minus `tags`, `uploader`).

Response `meta`:

| Field | Type |
|---|---|
| `current_page` | Int |
| `last_page` | Int |
| `per_page` | Int (see quirk below) |
| `total` | Int |
| `query` | String or { id, tag } object |
| `seed` | String? |

### `GET /tag/<id>` — Tag info

Not currently used in the app.

### `GET /settings?apikey=<KEY>` — Authenticated user settings

Not currently used in the app (dead code removed).

### `GET /collections` / `GET /collections/<username>/<id>` — Collections

Not currently used in the app.

## Known API quirks

- **`per_page` type varies**: Returns `Int` without API key, `String` with API key. `Meta` uses `LenientInt` decoder that accepts both. Do not change `perPage` back to plain `Int`.
- **`@username` queries**: Use `@` prefix (not `user:`).
- **`like:` endpoint**: `like:wallpaperID` calls the same `/search` endpoint with a `q=like:ID` parameter — it is not a separate endpoint.
- **NSFW blocked to guests**: 401 if no key. The app sends `apikey` on all requests when a key is stored.
- **Listings are pinned at 24 results/page**: Not configurable via API.
- **Random seed**: When `sorting=random`, the response `meta.seed` can be passed as query param `seed` to paginate without repeats.

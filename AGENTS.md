# AGENTS.md

## Build & verify

```bash
xcodebuild -scheme Wallhaven -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build

# Unsigned Release IPA — ./Scripts/build.sh
# Signed IPA + devicectl install — ./Scripts/install.sh
```

- No test targets, no CI (except release.yml), no third-party dependencies.
- `Scripts/build.sh`: `CODE_SIGN_IDENTITY="" CODE_SIGNING_ALLOWED=NO` → unsigned IPA at repo root.
- `Scripts/install.sh`: reads `DEVELOPMENT_TEAM` from pbxproj → falls back to `security find-identity` → overridable via `$DEVELOPMENT_TEAM`.
- `Scripts/publish.sh <major|minor|patch>` — bumps `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in pbxproj.
- Codex sandbox has no simulator runtimes; run `xcodebuild` with `sandbox_permissions: "require_escalated"` and `prefix_rule: ["xcodebuild"]`. Do **not** append `2>&1 | tail` — the pipe/redirection prevents prefix_rule matching; use `max_output_tokens` on the tool instead.

## Architecture

- **MVVM** with `@Observable` (not ObservableObject). ViewModels are `@MainActor`.
- **Networking** — `FetchActor.shared` is an **actor** — `await` all calls. Methods: `search(filters:page:)`, `getWallpaperDetail(id:)`, `getUserSettings()`.
- **No `SWIFT_DEFAULT_ACTOR_ISOLATION`** — types not implicitly `@MainActor`.
- `Wallhaven/` is a **PBXFileSystemSynchronizedRootGroup** — new files on disk auto-sync; no `.pbxproj` edits.
- **SwiftData models**: `FavoriteWallpaper` (`collectionID: UUID?` — `nil` = favorite, non-nil = collection item), `CollectionFolder`. `ModelContainer` in `WallhavenApp.swift` (`isStoredInMemoryOnly: false`).
- Collections are **local only** — `CollectionFolder` + `FavoriteWallpaper` items. No API calls.
- `NavigationState` (`@Observable`, `@MainActor`) injected via `@Environment` for shared search-tag flow.
- `SettingsViewModel.shared` (`@Observable` singleton) caches `GET /settings`; loaded in `ContentView.task`.
- **Image cache**: `CacheImage` (`NSCache`, 1 GB for images + 512 MB for data), `CacheAsyncImage` (view wrapper). All image loading (thumbnails, full-size) goes through `CacheAsyncImage`.
- `HasDimensions` protocol with `dimensionX`/`dimensionY` and default `aspectRatio`. `Wallpaper`, `FavoriteWallpaper` conform.

## View conventions

- **Section/** — one file per Form `Section` when interactive; data-driven sections stay bundled.
- **Tab/** — sub-views for tab switches (e.g., `Favorites/Tab/FavoritesTab.swift`).
- **Toolbar/** — `@ToolbarContentBuilder` types (e.g., `Detail/Toolbar/DetailTopToolbar.swift`).
- Extracted views receive data + closures (never ViewModel bindings).
- `APISection.apiBaseURL` is a computed property reading `SettingsViewModel.shared.apiBaseURL` directly.

## Constraints

- Deployment target `26.4`. No APIs gated above 26.4.
- `GENERATE_INFOPLIST_FILE = YES` — add privacy keys via `INFOPLIST_KEY_*` in pbxproj.
- `ENABLE_USER_SCRIPT_SANDBOXING = YES` in both configurations.
- Localization: `knownRegions = (en, Base, "zh-Hans")`, `SWIFT_EMIT_LOC_STRINGS = YES`. Use `.strings` files under `en.lproj/` and `zh-Hans.lproj/`.
- `UserDefaults` keys: `wallhaven_api_key`, `wallhaven_api_base_url`, `app_appearance`.
- Empty API URL values in SettingsViewModel / FetchActor are treated as default (`FetchActor.defaultBaseURL`).

## Pitfalls

- `#Preview` with `.modelContainer(for:inMemory:)` needs explicit `import SwiftData`. Pass all model types.
- `navigationDestination(item:)` closure re-executes on every parent re-render. Guard with `indices.contains`.
- `DetailView.wallpapers` is `@State` — tapping related thumbnail replaces array in-place instead of pushing new view.
- Favorites context-menu delete must defer SwiftData mutation after menu dismiss. Use `DispatchQueue.main.async` or `Task.sleep`.
- `#Predicate` must capture local constants, not access model properties directly (e.g., `let id = collection.id; #Predicate { $0.collectionID == id }`). Fails with `PredicateExpressions.Equal` type error.
- API `per_page` is `Int` unauthenticated but `String` with API key. `Meta` uses `LenientInt` to decode both. Do not change `perPage` to plain `Int`.
- API may return `[""]` instead of `[]` for `resolutions`/`aspectRatios`/`tagBlacklist`. Use `nonEmptyResolutions`, `nonEmptyAspectRatios`, `nonEmptyTagBlacklist` computed properties on `UserSettings`.
- `FetchError` is `Sendable` only because associated values are `String`. Do not add non-`Sendable` associated types.
- `.searchable` + `.large` `.navigationBarTitleDisplayMode` causes title to disappear after canceling search (iOS 26 quirk, no clean fix).
- `FlowLayout` is a `Layout`-conforming struct (in `Utilities/`), not a `View`.
- `Color(hex:)`, `CardStyle`, `saveWithLog()` are in `Utilities/Extension.swift` — module-visible, do not duplicate.
- `CacheAsyncImage` file and type are both named `CacheAsyncImage`.
- `CacheImage.shared.removeAll()` clears both image and data NSCaches. Cache section in Settings shows inline success text after clearing.

## Git

```bash
git commit -m "type: message"   # type: feat, fix, chore, docs, refactor
# Do NOT push unless explicitly asked.
```

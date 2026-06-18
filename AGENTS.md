# AGENTS.md

## Build & verify

```bash
# Simulator check (--destination required; "My Mac" fails)
xcodebuild -scheme Wallhaven -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build

# Unsigned Release IPA (sideloading) — ./build.sh
# Signed IPA + devicectl install — ./install.sh
```

- No test targets, no CI, no third-party dependencies.
- `build.sh`: `CODE_SIGN_IDENTITY="" CODE_SIGNING_ALLOWED=NO` → unsigned IPA at repo root.
- `install.sh`: `DEVELOPMENT_TEAM` from pbxproj → `security find-identity` → `$DEVELOPMENT_TEAM` env var.

## Architecture

- **MVVM** with `@Observable` (not ObservableObject). ViewModels are explicitly `@MainActor`.
- `WallhavenFetch.shared` is an **actor** — `await` all calls.
- `FavoriteWallpaper` is SwiftData `@Model` (`@Attribute(.unique) wallpaperID`). `ModelContainer` in `WallhavenApp.swift`.
- **No `SWIFT_DEFAULT_ACTOR_ISOLATION`** — types not implicitly `@MainActor`.
- `HasDimensions` protocol with `dimensionX`/`dimensionY` and default `aspectRatio` computed property. `Wallpaper`, `FavoriteWallpaper`, and `CollectionItem` all conform.
- Image cache: `CacheImage` (NSCache, 150 MB), `CacheAsyncImage` (view wrapper). Use `CacheAsyncImage` everywhere.
- Favorites tab: segmented picker (Favorites / Collections).
- Collections are **local only** — `WallhavenCollection` (folder) + `CollectionItem` (membership). No API calls.
- Star button saves wallpaper to a collection. If only "Default" → silent; if 2+ collections → picker sheet.
- `NavigationState` (`@Observable`, `@MainActor`) injected via `@Environment` for shared search-tag flow.
- `UserSettingsStore.shared` (`@Observable` singleton) caches `GET /settings`; loaded in `ContentView.task`.

## View conventions

- **Section/** — One file per Form `Section` when interactive; data-driven sections stay bundled.
- **Content/** — Sub-views for tab/state switches (e.g., `Favorites/Tab/`).
- **Toolbar/** — `@ToolbarContentBuilder` types (e.g., `Detail/Toolbar/DetailTopToolbar.swift`).
- Extracted views receive data + closures (never ViewModel bindings).
- `Wallhaven/` is a **PBXFileSystemSynchronizedRootGroup** — new files on disk are auto-synced; no `.pbxproj` edits.

## Constraints

- Deployment target `26.4`. No APIs gated above 26.4.
- `GENERATE_INFOPLIST_FILE = YES` — add privacy keys via `INFOPLIST_KEY_*` in pbxproj.
- `ENABLE_USER_SCRIPT_SANDBOXING = YES` in both configurations.
- Localization: `knownRegions = (en, Base, "zh-Hans")`, `SWIFT_EMIT_LOC_STRINGS = YES`.
- `UserDefaults` keys: `wallhaven_api_key`, `wallhaven_api_base_url`, `wallhaven_username`, `app_appearance`.

## Pitfalls

- `#Preview` with `.modelContainer(for:inMemory:)` needs explicit `import SwiftData`.
- `navigationDestination(item:)` closure re-executes on every parent re-render. Guard with `indices.contains`.
- `DetailView.wallpapers` is `@State` — tapping related thumbnail replaces array in-place instead of pushing new view.
- Favorites context-menu delete must defer SwiftData mutation after menu dismiss. Use `DispatchQueue.main.async` or `Task.sleep`.
- Chinese curly quotes (`''`) inside Swift string literals cause a parse error. Use ASCII quotes or `「」`.
- `FlowLayout` is a `Layout`-conforming struct (in `Utilities/`), not a `View`.
- `CacheAsyncImage` file and type are both named `CacheAsyncImage`.
- `Color(hex:)` defined in `Views/Search/Section/FilterSheetSection.swift` — module-visible, do not duplicate.
- `.searchable` + `.large` `.navigationBarTitleDisplayMode` causes title to disappear after canceling search (iOS 26 quirk, no clean fix).
- API `per_page` is `Int` unauthenticated but `String` with API key. `Meta` uses `LenientInt` to decode both. Do not change `perPage` to plain `Int`.
- API may return `[""]` instead of `[]` for `resolutions`/`aspectRatios`/`tagBlacklist`. Use `nonEmptyResolutions`, `nonEmptyAspectRatios`, `nonEmptyTagBlacklist`.
- `#Predicate` must capture local constants, not access model properties directly (e.g., `let id = collection.id; #Predicate { $0.collectionID == id }`). Fails with `PredicateExpressions.Equal` type error otherwise.

## Git

```bash
git commit -m "type: message"   # type: feat, fix, chore, docs, refactor
# Do NOT push unless explicitly asked.
```

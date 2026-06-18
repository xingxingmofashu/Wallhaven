# AGENTS.md

## Build & verify

```bash
# Quick simulator check
xcodebuild -scheme Wallhaven -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build

# Unsigned Release IPA (sideloading)
./build.sh

# Signed Release IPA + `devicectl` install to connected iPhone
./install.sh
```

- `-destination` is required — generic and "My Mac" both fail.
- No test targets; build success is the only check.
- No CI pipelines, no third-party dependencies.
- `build.sh`: `CODE_SIGN_IDENTITY="" CODE_SIGNING_ALLOWED=NO` → unsigned IPA at repo root `Wallhaven.ipa`.
- `install.sh`: reads `DEVELOPMENT_TEAM` from pbxproj, falls back to `security find-identity`, or reads `$DEVELOPMENT_TEAM` env var.

## Architecture

- **MVVM** with `@Observable` (not ObservableObject). ViewModels are explicitly `@MainActor`.
- `WallhavenFetch.shared` is an **actor** — `await` all its methods.
- `FavoriteWallpaper` is SwiftData `@Model` (`@Attribute(.unique) wallpaperID`). `ModelContainer` created in `WallhavenApp.swift`.
- **No `SWIFT_DEFAULT_ACTOR_ISOLATION`** — types not implicitly `@MainActor`.
- `HasDimensions` uses `dimensionX`/`dimensionY` (from API snake_case keys); default `aspectRatio` computed property.
- Image cache: `CacheImage` (NSCache, 150 MB), `CacheImageLoader` (`@Observable`), `CacheAsyncImage` (view wrapper). Use `CacheAsyncImage` everywhere instead of system `AsyncImage`.
- `NavigationState` (`@Observable`) holds `selectedTab`, `searchQuery`, `shouldSearch`; injected via `@Environment` for shared search-tag flow.

## Project structure

Files under `Wallhaven/` are in a **PBXFileSystemSynchronizedRootGroup** — new `.swift` files added on disk are auto-synced; no `.pbxproj` edits.

```
Wallhaven/
  App/                  ContentView (TabView root)
  Models/
    Wallpaper.swift, Favorite.swift (SwiftData), UserSettings.swift
    Search/             SearchFilters, SearchResponse
  Services/             WallhavenFetch (actor), WallhavenError
    Cache/              CacheImage, CacheImageLoader, CacheAsyncImage
  Utilities/            FlowLayout (Layout), LoadState, ShareSheet
  ViewModels/           One @Observable @MainActor VM per screen, NavigationState
  Views/
    Components/         CellView, GridView, ErrorView, NoResultsView, LoadingView
    Home/Search/Detail/Favorites/Settings/
```

## Key constraints

- Deployment target `26.4`. Do not use APIs gated above 26.4.
- `GENERATE_INFOPLIST_FILE = YES` — no hand-written Info.plist. Add privacy keys via `INFOPLIST_KEY_*` in both Debug/Release blocks in `project.pbxproj`. `NSPhotoLibraryAddUsageDescription` already set.
- `ENABLE_USER_SCRIPT_SANDBOXING = YES` in both configurations.
- Localization: `knownRegions = (en, Base, "zh-Hans")`, `SWIFT_EMIT_LOC_STRINGS = YES`. `Text("literal")` auto-lookup; computed strings need `NSLocalizedString`.
- API base URL: `UserDefaults("wallhaven_api_base_url")` → fallback `https://wallhaven.cc/api/v1`.
- API key: `UserDefaults("wallhaven_api_key")`, read by both `WallhavenFetch` and `SettingsViewModel`.

## Pitfalls

- `#Preview` with `.modelContainer(for:inMemory:)` needs explicit `import SwiftData` — compiler error is misleading.
- `navigationDestination(item:)` closure re-executes on **every parent re-render**, not just on nil→non-nil transition. Must guard against stale `@Query` data with `indices.contains`.
- `DetailView.wallpapers` is `@State` (not `let`) — tapping a related thumbnail not in the current array replaces the array and scrolls in-place instead of pushing a new DetailView.
- Favorites context-menu delete must defer SwiftData mutation after menu dismiss animation. Use `DispatchQueue.main.async { modelContext.delete(...); try? modelContext.save() }` or `Task { try? await Task.sleep(nanoseconds: 300_000_000) }`.
- Chinese curly quotes (`''`) inside Swift string literals cause a parse error. Use straight ASCII quotes or corner brackets (`「」`).
- `FlowLayout` is a `Layout`-conforming struct (not a `View`), in `Utilities/`.
- `CacheAsyncImage` file and type are both named `CacheAsyncImage` (not `AsyncImage`).
- `Color(hex:)` extension defined in `Views/Search/FilterSheetView.swift` — module-visible, do not duplicate.
- `.searchable` + `.large` `.navigationBarTitleDisplayMode` causes title to disappear after canceling search. This is a known iOS 26 quirk — no clean fix found.

## Git

```bash
git commit -m "type: message"   # type: feat, fix, chore, docs, refactor
# Do NOT push unless explicitly asked.
```

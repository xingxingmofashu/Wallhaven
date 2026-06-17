# AGENTS.md

## Build

```bash
# Simulator (quick check before commit)
xcodebuild -scheme Wallhaven -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build

# Unsigned IPA for sideloading
./build.sh

# Signed build + install to connected iPhone
./install.sh
```

- `-destination` is required — generic and "My Mac" both fail.
- No test targets; build success is the only check.
- No CI pipelines, no third-party dependencies.
- `build.sh`: `CODE_SIGN_IDENTITY="" CODE_SIGNING_ALLOWED=NO` → unsigned IPA at repo root `Wallhaven.ipa`.
- `install.sh`: reads `DEVELOPMENT_TEAM` from pbxproj → `-allowProvisioningUpdates` + `devicectl`.

## Architecture

- **MVVM** with `@Observable` (not ObservableObject). ViewModels are explicitly `@MainActor`.
- `WallhavenFetch.shared` is an **actor** — `await` all its methods.
- `FavoriteWallpaper` is SwiftData `@Model` (`@Attribute(.unique) wallpaperID`). `ModelContainer` in `WallhavenApp.swift`.
- **No `SWIFT_DEFAULT_ACTOR_ISOLATION`** — types are not implicitly `@MainActor`.
- `HasDimensions` uses `dimensionX`/`dimensionY` (from API snake_case keys).
- Image cache: `CacheImage` (NSCache, 150 MB), `CacheImageLoader` (`@Observable` loader state), `CacheAsyncImage` (view wrapper). Use `CacheAsyncImage` everywhere instead of system `AsyncImage`.

## Project structure

Files under `Wallhaven/` are in a **PBXFileSystemSynchronizedRootGroup** — new `.swift` files added on disk are auto-synced; no `.pbxproj` edits needed.

```
Wallhaven/
  App/                  ContentView (TabView root)
  Models/               Wallpaper, Favorite (SwiftData), HasDimensions
    Search/             SearchFilters, SearchResponse
  Services/             WallhavenFetch (actor), WallhavenError
    Cache/              CacheImage, CacheImageLoader, CacheAsyncImage
  Utilities/            FlowLayout (Layout), LoadState, ShareSheetView
  ViewModels/           One @Observable @MainActor VM per screen
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
- `ContentUnavailableView` overrides `.navigationTitle` via preference system in large title mode — avoid where title must stay visible.
- `navigationDestination(item:)` closure re-executes on **every parent re-render**, not just on nil→non-nil transition. Must guard against stale `@Query` data with `indices.contains`.
- `DetailView.wallpapers` is `@State` (not `let`) — tapping a related thumbnail not in the current array replaces the array and scrolls in-place instead of pushing a new DetailView.
- Favorites context-menu delete wraps SwiftData mutation in `DispatchQueue.main.async` (or `Task.sleep`) to let menu dismiss animation finish before mutation.
- Chinese curly quotes (`''`) inside Swift string literals cause a parse error. Use straight ASCII quotes or corner brackets (`「」`).
- `FlowLayout` is a `Layout`-conforming struct (not a `View`), in `Utilities/`.
- `CacheAsyncImage` file and type are both named `CacheAsyncImage` (not `AsyncImage`).
- `Color(hex:)` extension defined once in `Views/Search/FilterSheet.swift` — module-visible, do not duplicate.

## Git

Commit with conventional prefix: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`.

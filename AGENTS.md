# AGENTS.md

## Build & verify

```bash
# Quick simulator build (run after any Swift change before committing)
xcodebuild -scheme Wallhaven \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  build 2>&1 | grep -E "error:|Build succeeded|Build FAILED"

# Unsigned IPA for sideloading (AltStore etc.)
./build.sh

# Build signed + install to connected iPhone
./install.sh
```

- `-destination` is required — generic and "My Mac" both fail.
- No test targets; build success is the only check.
- `build.sh` uses `CODE_SIGN_IDENTITY="" CODE_SIGNING_ALLOWED=NO` (unsigned).
- `install.sh` uses `-allowProvisioningUpdates` (automatic signing) + `devicectl`.

## Project structure

```
Wallhaven/                  ← PBXFileSystemSynchronizedRootGroup (auto-synced)
  App/                      ContentView.swift
  Models/                   Wallpaper, Favorite, UserSettings, HasDimensions
    Search/                 SearchFilters, SearchResponse
  Services/                 WallhavenFetch (actor), WallhavenError
    Cache/                  CacheImage, CacheImageLoader, CacheAsyncImage
  Utilities/                FlowLayout (Layout), LoadState, ShareSheetView
  ViewModels/               @Observable ViewModels, one per screen
  Views/
    Components/             CellView, GridView, ErrorView, NoResultsView, LoadingView
    Home / Search / Detail / Favorites / Settings
  WallhavenApp.swift        @main, SwiftData ModelContainer
```

Files inside `Wallhaven/` are auto-synced by Xcode — no `.pbxproj` edits for new Swift files.

## Key constraints

- Deployment target: `26.4` (set in pbxproj). Do not use APIs gated behind availability checks above 26.4.
- `GENERATE_INFOPLIST_FILE = YES` — no hand-written Info.plist. Add privacy keys via `INFOPLIST_KEY_*` in both Debug/Release blocks in `project.pbxproj`.
- `NSPhotoLibraryAddUsageDescription` already set in both configs (Chinese locale).
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`. `SWIFT_DEFAULT_ACTOR_ISOLATION` **not set** — types are not implicitly `@MainActor`. ViewModels are explicitly `@MainActor`. `WallhavenFetch` is an `actor`.
- Localization: `knownRegions = (en, Base, "zh-Hans")`. `SWIFT_EMIT_LOC_STRINGS = YES`. `Text("literal")` auto-lookup; computed strings need `NSLocalizedString`.

## Architecture

- MVVM with `@Observable` (not ObservableObject).
- `WallhavenFetch.shared` is an actor singleton — `await` all its methods.
- API base URL: `UserDefaults("wallhaven_api_base_url")` → fallback `https://wallhaven.cc/api/v1`.
- API key: `UserDefaults("wallhaven_api_key")`, read by both `WallhavenFetch` and `SettingsViewModel`.
- Favorites: SwiftData (`FavoriteWallpaper` model, `@Attribute(.unique) wallpaperID`). `ModelContainer` created in `WallhavenApp.swift` with `ModelConfiguration(isStoredInMemoryOnly: false)`.
- `FavoriteWallpaper.asWallpaper` reconstructs a `Wallpaper` from stored fields (thumbURL, fullPath, etc.). `fileSize` and `tags` are zero/nil.
- Image caching: `CacheImage` (NSCache, 150 MB). Use `CacheAsyncImage` everywhere instead of system `AsyncImage`.
- `NavigationState` (`@Observable`) injected via `.environment()` from `ContentView`. Drives `selectedTab`, `searchQuery`, `shouldSearch`.

## Pitfalls

- Chinese curly quotes (`''`) inside Swift string literals cause a parse error. Use straight ASCII quotes or corner brackets (`「」`).
- `#Preview` with `.modelContainer(for:inMemory:)` needs explicit `import SwiftData` — compiler error is misleading.
- Enums used with `onChange(of:)` must conform to `Equatable`.
- `Color(hex:)` defined once in `Views/Search/FilterSheet.swift` — module-visible, do not duplicate.
- `ContentUnavailableView` overrides `.navigationTitle` via SwiftUI preference system — avoid in views where title must stay visible.
- `FlowLayout` is a `Layout`-conforming struct (not a `View`), in `Utilities/FlowLayout.swift`.
- `CacheAsyncImage` file and type are both named `CacheAsyncImage` (not `AsyncImage`).

## Repo scripts

- `build.sh` — unsigned Release IPA at project root `Wallhaven.ipa`.
- `install.sh` — signed build + `devicectl` install. Auto-detects connected iPhone via device name.

## Git

Commit after each logical phase with conventional prefix: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`.

# AGENTS.md

## Build & verify

```bash
# Only working build command (macOS 26.x host, Xcode 26.5)
xcodebuild -scheme Wallhaven \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  build 2>&1 | grep -E "error:|Build succeeded|Build FAILED"
```

- `-destination 'platform=iOS Simulator,name=...'` is required — generic destination and "My Mac" both fail on this machine.
- No test targets exist yet; build success is the only automated check.
- After any Swift change, run the build above before committing.

## Project structure

```
Wallhaven/                  ← PBXFileSystemSynchronizedRootGroup (auto-synced)
  Models/                   Wallpaper, UserSettings, Favorite, LoadState
    Search/                 SearchFilters, SearchResponse
  Services/                 WallhavenFetch (actor), WallhavenError, Cache/ (CacheImage, CacheImageLoader, CacheAsyncImage)
  ViewModels/               @Observable ViewModels, one per screen
  Views/
    Components/             CellView, GridView, ErrorView, EmptyView
    Home / Search / Detail / Favorites / Settings / ContentView
  Docs/WallhavenAPI.md      Full API reference
  en.lproj/Localizable.strings
  zh-Hans.lproj/Localizable.strings
```

Any file placed inside `Wallhaven/` is automatically picked up by Xcode — no `.pbxproj` edits needed for new Swift files.

## Key constraints

**Deployment target: iOS 26.5** — `IPHONEOS_DEPLOYMENT_TARGET = 26.5`. Do not use APIs gated behind availability checks unless they are available on 26.5.

**Swift concurrency** — `SWIFT_APPROACHABLE_CONCURRENCY = YES` is active. `SWIFT_DEFAULT_ACTOR_ISOLATION` is **not set** — types are not implicitly `@MainActor`. ViewModels are explicitly annotated `@MainActor`. `WallhavenFetch` is an `actor` with its own isolation.

**`GENERATE_INFOPLIST_FILE = YES`** — there is no hand-written `Info.plist`. Add privacy keys or entitlements via `INFOPLIST_KEY_*` entries in both the Debug and Release `XCBuildConfiguration` blocks inside `project.pbxproj`.

**Photo save permission** — `INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription` is already set in both configurations.

**Localization** — `SWIFT_EMIT_LOC_STRINGS = YES` is set in both Debug and Release. `knownRegions = (en, Base, "zh-Hans")`. `SwiftUI` `Text("string literal")` auto-looks up in `Localizable.strings`. For non-literal strings (e.g. computed properties), use `NSLocalizedString("key", comment: "")` explicitly.

## Architecture

- **MVVM** with `@Observable` (not `ObservableObject`).
- `WallhavenFetch` is an `actor` — call its methods with `await`.
- API base URL: configurable via `UserDefaults("wallhaven_api_base_url")` with fallback `https://wallhaven.cc/api/v1`. Users can override locally via a gitignored `Wallhaven/Config/LocalConfig.swift`.
- API key stored in `UserDefaults` under key `"wallhaven_api_key"`; read by both `WallhavenFetch` (actor) and `SettingsViewModel`.
- Local favorites persist via **SwiftData** (`FavoriteWallpaper` model). The `ModelContainer` is configured in `WallhavenApp.swift` and injected as `.modelContainer(...)` on the root scene.
- Image caching: `CacheImage` (NSCache, 150 MB limit). Use `CacheAsyncImage` (defined in `Services/Cache/AsyncImage.swift`) instead of the system `AsyncImage` everywhere.
- Language override: `Services/LanguageOverride.swift` — `Bundle` extension using `object_setClass` + associated objects to swap main bundle at runtime. Stored in `UserDefaults("AppLanguage")`, applied in `WallhavenApp.init()`. Supports `.en` and `.zhHans`.
- `NavigationState` (`@Observable`) manages cross-tab navigation: `selectedTab`, `searchQuery`, `shouldSearch`. Injected via `.environment()` from `ContentView`.

## Known pitfalls caught in this repo

- **Chinese curly quotes inside Swift string literals** cause a parse error. Use straight ASCII quotes or corner brackets (`「」`) inside string values.
- Files that use `.modelContainer(for:inMemory:)` in `#Preview` must `import SwiftData` explicitly — the compiler error message ("is not available due to missing import") is misleading.
- Enums used with `onChange(of:)` must conform to `Equatable`.
- `Color(hex:)` is defined once in `Views/Search/FilterSheet.swift` and is visible to the whole module. Do not add a duplicate definition elsewhere.
- `ContentUnavailableView` in search idle/empty states overrides `.navigationTitle` via SwiftUI preference system — avoid it in views where navigation title must stay visible.

## API summary

Base URL: configurable, defaults to `https://wallhaven.cc/api/v1`
Rate limit: 45 req/min → `429`. NSFW without key → `401`.
Full parameter reference: `Wallhaven/Docs/WallhavenAPI.md`.

## Git conventions

Commit after each logical phase. Messages used so far:

```
feat: ...      new functionality
fix: ...       compile or runtime bug fixes
chore: ...     config / build settings
docs: ...      documentation only
refactor: ...  renaming or restructuring without behavior change
```

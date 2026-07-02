<p align="center">
  <img src=".github/assets/logo.png" alt="Wallhaven" width="120">
</p>

<p align="center"><strong>Wallhaven</strong> — A native iOS wallpaper browser powered by the <a href="https://wallhaven.cc/help/api">Wallhaven API</a>.</p>

<p align="center">
  <a href="https://github.com/xingxingmofashu/Wallhaven"><img alt="GitHub stars" src="https://img.shields.io/github/stars/xingxingmofashu/Wallhaven?style=flat-square" /></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-Apache%202.0-blue?style=flat-square" /></a>
  <a href="https://github.com/xingxingmofashu/Wallhaven/issues"><img alt="Issues" src="https://img.shields.io/github/issues/xingxingmofashu/Wallhaven?style=flat-square" /></a>
</p>

<p align="center">
  <strong>English</strong> |
  <a href="README.zh.md">简体中文</a>
</p>

## Features

- **Home** — latest wallpapers in a two-column waterfall grid with infinite scroll
- **Search** — keyword + filter (categories, purity, sorting, resolution, ratio, color)
- **Detail** — full-resolution view, left/right swipe, swipe-down to dismiss, related thumbnails, info sheet, share, save to photos
- **Favorites** — add wallpapers to favorites (heart button), remove via context menu
- **Collections** — local folders to organize wallpapers (star button), rename and delete, auto-created "Default" collection
- **Settings** — API key, appearance (light/dark/system), image cache management, synced user preferences

## Requirements

- iOS 26.4+
- Xcode 26.5+

## Installation

No third-party dependencies.

### From Xcode (simulator — no account required)

1. Clone the repo
2. Open `Wallhaven.xcodeproj` in Xcode
3. Select an iOS Simulator and run (⌘R)

### From Xcode (physical device — requires Apple Developer account)

1. Clone the repo
2. Open `Wallhaven.xcodeproj` in Xcode
3. In **Signing & Capabilities**, change **Bundle Identifier** to a unique value and select your **Team**
4. Connect your device and run (⌘R)

### From command line

#### Simulator build

```bash
xcodebuild -scheme Wallhaven -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build
```

Builds for the iOS Simulator. No signing or developer account needed.

#### Simulator build + run

```bash
./Scripts/run.sh                  # default: iPhone 17 Pro
./Scripts/run.sh "iPhone 17 Pro"  # specify a simulator by name
```

Boots the simulator (if needed), builds a Debug `.app`, installs it, and launches the app. No Xcode or developer account required.

#### Unsigned IPA (sideloading)

```bash
./Scripts/build.sh
```

Produces `Wallhaven.ipa` at the repo root. Designed for sideloading via AltStore, SideStore, or similar.

Steps:
1. Cleans previous build artifacts
2. Builds for `generic/platform=iOS` in Release with `CODE_SIGN_IDENTITY="" CODE_SIGNING_ALLOWED=NO`
3. Packages the `.app` into a `Payload/` directory and zips it as `Wallhaven.ipa`

#### Signed IPA + install to device

```bash
./Scripts/install.sh

# Override the development team:
DEVELOPMENT_TEAM=XXXXXXXXXX ./Scripts/install.sh
```

Requires an Apple Developer account and a connected, paired iPhone. Produces `Wallhaven.ipa` and installs via `devicectl`.

Steps:
1. Reads `DEVELOPMENT_TEAM` from `Wallhaven.xcodeproj/project.pbxproj`
2. Falls back to `security find-identity` auto-detection
3. Builds with `-allowProvisioningUpdates` using the resolved team
4. Packages the `.app` into `Wallhaven.ipa`
5. Finds the first connected iPhone via `xcrun devicectl list devices`
6. Installs the app using `xcrun devicectl device install app`

## Configuration

The app works without an API key for SFW content. To enable NSFW and personal preferences:

1. Go to **Settings** → **Set API Key**
2. Paste your key from [wallhaven.cc/account](https://wallhaven.cc/account)

The API base URL defaults to `https://wallhaven.cc/api/v1` and can be changed in Settings.

## Architecture

- **MVVM** with `@Observable` (not ObservableObject). ViewModels are `@MainActor`.
- **Networking** — `FetchActor` actor with `URLSession` async/await, automatic retry for transient failures (429/5xx)
- **Caching** — `NSCache`-based `CacheImage` (1 GB for images, 512 MB for raw data), `CacheAsyncImage` for all image loading with in-flight download deduplication and cancellation
- **Persistence** — SwiftData (`FavoriteWallpaper`, `CollectionFolder`). A single `FavoriteWallpaper` model represents both favorites (`collectionID == nil`) and collection items (`collectionID` set to a folder's UUID).
- **Collections** — local-only: `CollectionFolder` groups wallpapers via `FavoriteWallpaper` memberships; no API calls
- **Navigation** — `NavigationState` (`@Observable`, `@Environment`) for cross-tab search tag flow
- **Localization** — English, Simplified Chinese
- **Layout** — custom `FlowLayout` (conforms to `Layout` protocol) for waterfall grid

## Project Structure

```
Wallhaven/
  App/                  Root ContentView with TabView
  Models/
    Search/             API response types and search filters
    Favorite/           SwiftData models
      Collection/       CollectionFolder
      FavoriteWallpaper
  Services/
    FetchActor.swift    Networking actor (search, detail, user settings)
    Cache/              CacheImage (NSCache), CacheImageLoader, CacheAsyncImage
  Utilities/            FlowLayout, LoadState, ShareSheet, Extension
  ViewModels/           One @Observable VM per screen
  Views/
    Components/         Reusable UI (CellView, GridView, ErrorView, etc.)
    Home/               Home tab (waterfall grid, infinite scroll)
    Search/             Search tab (filter sheet, results grid)
    Detail/             Wallpaper detail (viewer, toolbars, info sheet)
    Favorites/          Favorites tab (segmented picker, collections, rename/delete)
    Settings/           Settings tab (sections: general, API, cache, about)
  en.lproj/             English strings
  zh-Hans.lproj/        Simplified Chinese strings
Document/               Wallhaven API v1 reference
```

## License

[Apache License 2.0](LICENSE)

[**English**](README.md) | [**中文**](README.zh.md)

# Wallhaven

A native iOS wallpaper browser powered by the [Wallhaven API](https://wallhaven.cc/help/api).

<table align="center">
  <tr>
    <td align="center"><img src="Wallhaven/Assets.xcassets/AppIcon.appiconset/AppIcon-Light.png" width="100%" alt="Light"></td>
    <td align="center"><img src="Wallhaven/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png" width="100%" alt="Dark"></td>
    <td align="center"><img src="Wallhaven/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png" width="100%" alt="Tinted"></td>
  </tr>
</table>

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

#### Unsigned IPA (sideloading)

```bash
./build.sh
```

Produces `Wallhaven.ipa` at the repo root. Designed for sideloading via AltStore, SideStore, or similar.

Steps:
1. Cleans previous build artifacts
2. Builds for `generic/platform=iOS` in Release with `CODE_SIGN_IDENTITY="" CODE_SIGNING_ALLOWED=NO`
3. Packages the `.app` into a `Payload/` directory and zips it as `Wallhaven.ipa`

#### Signed IPA + install to device

```bash
./install.sh

# Override the development team:
DEVELOPMENT_TEAM=XXXXXXXXXX ./install.sh
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
- **Networking** — `WallhavenFetch` actor with `URLSession` async/await
- **Caching** — `NSCache`-based `CacheImage` (150 MB limit), `CacheAsyncImage` for all image loading
- **Persistence** — SwiftData (`FavoriteWallpaper`, `CollectionFolder`, `CollectionItem`)
- **Collections** — local-only: `CollectionFolder` groups wallpapers via `CollectionItem` memberships; no API calls
- **Navigation** — `NavigationState` (`@Observable`, `@Environment`) for cross-tab search tag flow
- **Localization** — English, Simplified Chinese
- **Layout** — custom `FlowLayout` (conforms to `Layout` protocol) for waterfall grid

## Project Structure

```
Wallhaven/
  App/                  Root ContentView with TabView
  Models/
    Search/             API response types and search filters
    Favorite/           SwiftData models (Favorite, Collection)
  Services/             WallhavenFetch actor, image cache, UserSettingsStore
  Utilities/            FlowLayout, LoadState, ShareSheet
  ViewModels/           One @Observable VM per screen
  Views/
    Components/         Reusable UI (CellView, GridView, ErrorView, etc.)
    Home/               Home tab (waterfall grid, infinite scroll)
    Search/             Search tab (filter sheet, results grid)
    Detail/             Wallpaper detail (viewer, toolbars, info sheet)
    Favorites/          Favorites tab (segmented picker, collections, rename/delete)
    Settings/           Settings tab (sections: general, API, cache, about)
  Docs/                 Wallhaven API v1 reference
```

## License

[Apache License 2.0](LICENSE)

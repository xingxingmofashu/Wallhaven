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
- **Favorites** — local favorites via SwiftData, context-menu to remove
- **Settings** — API key, appearance, image cache management

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

```bash
# Quick simulator build
xcodebuild -scheme Wallhaven -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build

# Unsigned IPA for sideloading (AltStore, SideStore, etc.)
./build.sh

# Signed build + install to connected iPhone
# (requires Apple Developer account + paired device)
./install.sh
```

## Configuration

The app works without an API key (SFW content only). To enable NSFW and personal preferences:

1. Go to **Settings** → **Set API Key**
2. Paste your key from [wallhaven.cc/account](https://wallhaven.cc/account)

The API base URL defaults to `https://wallhaven.cc/api/v1` and can be changed in Settings.

## Architecture

- **MVVM** with `@Observable`
- **Networking** — `WallhavenFetch` actor + `URLSession` async/await
- **Caching** — `NSCache`-based `CacheImage` (150 MB), `CacheAsyncImage` for all image loading
- **Persistence** — SwiftData (`FavoriteWallpaper`)
- **Localization** — English, Simplified Chinese

## Project Structure

```
Wallhaven/
  App/            Root ContentView with TabView
  Models/         Data models (Wallpaper, SearchFilters, Favorite, etc.)
  Services/       WallhavenFetch actor, image cache (CacheImage / CacheAsyncImage)
  Utilities/      FlowLayout, LoadState, ShareSheetView
  ViewModels/     One @Observable VM per screen
  Views/          Feature-grouped SwiftUI views
  Docs/           API reference
```

## License

[Apache License 2.0](LICENSE)

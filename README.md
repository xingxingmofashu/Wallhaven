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

- **Home** — latest wallpapers in a two-column waterfall grid
- **Search** — keyword + filter (categories, purity, sorting, resolution, ratio, color)
- **Detail** — full-resolution view, left/right swipe, swipe-down to dismiss, related thumbnails, info sheet, share, save to photos
- **Favorites** — local favorites via SwiftData, context-menu to remove
- **Settings** — API key, appearance, image cache, account preferences

## Requirements

- iOS 26.5+
- Xcode 26.5+

## Installation

1. Clone the repo
2. Open `Wallhaven.xcodeproj` in Xcode
3. Select a simulator or device and run

No third-party dependencies.

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
  Models/         Data models (Wallpaper, SearchFilters, Favorite, etc.)
  Services/       WallhavenFetch, Cache
  ViewModels/     One @Observable VM per screen
  Views/          SwiftUI views organized by feature
  Docs/           API reference
```

## License

[Apache License 2.0](LICENSE)

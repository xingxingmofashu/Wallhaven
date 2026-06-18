# Privacy Policy

**Last updated: June 18, 2025**

## Introduction

Wallhaven is an open-source iOS client developed by an individual for browsing wallpapers on [wallhaven.cc](https://wallhaven.cc). This privacy policy explains how this application collects, uses, and protects your information.

## Information Collection and Use

### Locally Stored Data

This application stores the following data locally on your device and **does not upload it to any third-party server** (except for official wallhaven.cc API calls):

| Data Type | Storage Location | Purpose |
|---|---|---|
| Wallhaven API Key | `UserDefaults` | Authentication when calling the Wallhaven API |
| Appearance Preference | `UserDefaults` | Remembering your light/dark theme choice |
| Favorite Wallpapers | SwiftData (local SQLite) | Saving wallpapers you mark |
| Collection Data | SwiftData (local SQLite) | Managing your custom collections |

### Wallhaven API

This application fetches wallpaper data through the official Wallhaven API. When you use search, browse, and other features, the application sends your requests to wallhaven.cc servers. These requests may include:

- Your search keywords and filter criteria
- Your API key (if configured)
- Standard HTTP request information (IP address, User-Agent, etc.)

This data is processed by Wallhaven according to its own privacy policy. We recommend reviewing [Wallhaven's Privacy Policy](https://wallhaven.cc/privacy) for more information.

### Information NOT Collected

This application **does not**:

- Collect personally identifiable information (name, email, phone number, etc.)
- Use third-party analytics tools or trackers
- Upload your wallpapers, collections, or other local data to any server
- Record your usage behavior or browsing history
- Display personalized advertisements

## Data Security

All local data is stored only on your device, and the system automatically protects this data from access by other applications. The API key is stored in `UserDefaults` and is used exclusively within this application.

## Third-Party Services

This application only communicates with the official wallhaven.cc API and does not integrate any third-party SDKs, analytics tools, or advertising services.

## Data Deletion

You can delete all data stored by this application through the following methods:

1. Clear the image cache in the app settings
2. Uninstall this application in iOS settings (which will delete all local data)

## Open Source

This application is an open-source project. You can view the complete source code on [GitHub](https://github.com/xingxingmofashu/Wallhaven) to verify the authenticity of this privacy statement.

## Policy Updates

This privacy policy may be updated from time to time. Updates will be posted on this page with a new effective date.

## Contact

If you have any questions or concerns, please contact us through GitHub Issues:

[https://github.com/xingxingmofashu/Wallhaven/issues](https://github.com/xingxingmofashu/Wallhaven/issues)

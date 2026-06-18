import SwiftUI

struct CollectionsContent: View {
    let hasUsername: Bool
    let isLoading: Bool
    let needsAPIKey: Bool
    let error: Error?
    let collections: [WHCollection]
    let username: String
    let onRetry: () -> Void

    var body: some View {
        if !hasUsername {
            ContentUnavailableView(
                "Username Not Set",
                systemImage: "person.crop.circle.badge.questionmark",
                description: Text("Set your wallhaven.cc username in Settings to view collections.")
            )
        } else if isLoading {
            LoadingView()
        } else if needsAPIKey {
            ContentUnavailableView(
                "API Key Required",
                systemImage: "key",
                description: Text("Set your Wallhaven API Key in Settings to view collections.")
            )
        } else if let error = error {
            ErrorView(message: error.localizedDescription, retryAction: onRetry)
        } else if collections.isEmpty {
            ContentUnavailableView(
                "No Collections",
                systemImage: "folder",
                description: Text("No collections found for this account.")
            )
        } else {
            List {
                ForEach(collections) { collection in
                    NavigationLink {
                        CollectionWallpapersView(collection: collection, username: username)
                    } label: {
                        CollectionRowView(collection: collection)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Collection Row

struct CollectionRowView: View {
    let collection: WHCollection

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(collection.label)
                    .fontWeight(.medium)
                Label("\(collection.count) wallpapers", systemImage: "photo.on.rectangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if collection.isPublic == 1 {
                Label("Public", systemImage: "globe")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label("Private", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

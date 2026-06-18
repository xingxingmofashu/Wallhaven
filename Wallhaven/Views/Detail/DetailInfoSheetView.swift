import SwiftUI

struct DetailInfoSheetView: View {
    let wallpaper: Wallpaper
    let formattedInfo: [(label: String, value: String)]
    let tags: [Tag]
    let onSearchTag: (String) -> Void
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if let uploader = wallpaper.uploader {
                    Section("Uploader") {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.secondary)
                            Text(uploader.username)
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text(uploader.group)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Details") {
                    ForEach(formattedInfo, id: \.label) { item in
                        HStack {
                            Text(item.label)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(item.value)
                                .foregroundStyle(.primary)
                        }
                    }
                }

                if !wallpaper.colors.isEmpty {
                    Section("Colors") {
                        HStack(spacing: 10) {
                            ForEach(wallpaper.colors, id: \.self) { hex in
                                let cleanHex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
                                Circle()
                                    .fill(Color(hex: cleanHex))
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                            }
                        }
                    }
                }

                if !tags.isEmpty {
                    Section("Tags") {
                        FlowLayout(spacing: 6) {
                            ForEach(tags) { tag in
                                Button {
                                    onSearchTag(tag.name)
                                } label: {
                                    Text("#\(tag.name)")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

            }
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                }
            }
        }
    }
}

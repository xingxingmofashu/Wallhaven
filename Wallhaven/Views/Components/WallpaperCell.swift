import SwiftUI

/// Single wallpaper thumbnail card
struct WallpaperCell: View {
    let wallpaper: Wallpaper

    var body: some View {
        CachedAsyncImage(url: wallpaper.thumbnailURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Rectangle()
                .fill(Color(.systemGray5))
        }
        .overlay(alignment: .bottomLeading) {
            badges
                .padding(6)
        }
    }

    // MARK: - Badges

    private var badges: some View {
        HStack(spacing: 4) {
            PurityBadge(purity: wallpaper.purity)
            CategoryBadge(category: wallpaper.category)
        }
    }
}

// MARK: - PurityBadge

struct PurityBadge: View {
    let purity: String

    var body: some View {
        Text(purity.uppercased())
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.85))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch purity {
        case "sfw":     return .green
        case "sketchy": return .orange
        case "nsfw":    return .red
        default:        return .gray
        }
    }
}

// MARK: - CategoryBadge

struct CategoryBadge: View {
    let category: String

    var body: some View {
        Text(category.capitalized)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.55))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    WallpaperCell(wallpaper: .preview)
        .frame(width: 180, height: 120)
        .padding()
}

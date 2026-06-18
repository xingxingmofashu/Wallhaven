import SwiftUI

struct DetailBottomToolbar: ToolbarContent {
    let isFavorited: Bool
    let isInCollection: Bool
    let onShare: () -> Void
    let onToggleFavorite: () -> Void
    let onInfo: () -> Void
    let onAddToCollection: () -> Void
    let onSaveToPhotos: () -> Void

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button {
                onShare()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }

        ToolbarItemGroup(placement: .status) {
            Button {
                onToggleFavorite()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(isFavorited ? .pink : .primary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .symbolEffect(.bounce, value: isFavorited)

            Button {
                onInfo()
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }

            Button {
                onAddToCollection()
            } label: {
                Image(systemName: isInCollection ? "star.circle.fill" : "star.circle")
                    .font(.title3)
                    .foregroundStyle(isInCollection ? .yellow : .primary)
            }
        }

        ToolbarItem(placement: .bottomBar) {
            Button {
                onSaveToPhotos()
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }
    }
}

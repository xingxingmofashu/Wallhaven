import SwiftUI

struct FullscreenImageView: View {
    let url: URL?
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale = max(1, $0) }
                            .onEnded { _ in
                                withAnimation { if scale < 1 { scale = 1 } }
                            }
                        .simultaneously(
                            with: DragGesture()
                                .onChanged { offset = $0.translation }
                                .onEnded { _ in
                                    if scale <= 1 {
                                        withAnimation { offset = .zero }
                                    }
                                }
                        )
                    )
            } placeholder: {
                ProgressView().tint(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
        }
    }
}

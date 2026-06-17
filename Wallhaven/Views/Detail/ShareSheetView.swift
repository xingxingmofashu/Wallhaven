import SwiftUI

#if os(iOS)
struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
#elseif os(macOS)
struct ShareSheetView: NSViewRepresentable {
    let items: [Any]

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let url = items.first as? String,
                  let nsURL = URL(string: url) else { return }
            let picker = NSSharingServicePicker(items: [nsURL])
            picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif

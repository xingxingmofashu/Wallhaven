import SwiftUI

struct FilterSheet: View {
    @Binding var filters: SearchFilters
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                categoriesSection
                puritySection
                sortingSection
                if filters.sorting == .toplist { topRangeSection }
                resolutionSection
                ratioSection
                colorSection
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Reset") { filters = SearchFilters() }
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Sections

    private var categoriesSection: some View {
        Section("Categories") {
            Toggle("General", isOn: $filters.general)
            Toggle("Anime",   isOn: $filters.anime)
            Toggle("People",  isOn: $filters.people)
        }
    }

    private var puritySection: some View {
        Section("Purity") {
            Toggle("SFW (Safe)",      isOn: $filters.sfw)
            Toggle("Sketchy",         isOn: $filters.sketchy)
            Toggle("NSFW (Adult)",    isOn: $filters.nsfw)
                .foregroundStyle(filters.nsfw ? .red : .primary)
        }
    }

    private var sortingSection: some View {
        Section("Sorting") {
            Picker("Sort by", selection: $filters.sorting) {
                ForEach(SearchFilters.Sorting.allCases) { s in
                    Text(s.displayName).tag(s)
                }
            }
            Picker("Order", selection: $filters.order) {
                ForEach(SearchFilters.Order.allCases) { o in
                    Text(o.displayName).tag(o)
                }
            }
        }
    }

    private var topRangeSection: some View {
        Section("Toplist Time Range") {
            Picker("Range", selection: $filters.topRange) {
                ForEach(SearchFilters.TopRange.allCases) { r in
                    Text(r.displayName).tag(r)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var resolutionSection: some View {
        Section("Resolution") {
            TextField("Min resolution, e.g. 1920x1080", text: $filters.atleast)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
        }
    }

    private var ratioSection: some View {
        Section("Ratio") {
            let ratioOptions = ["", "16x9", "16x10", "4x3", "9x16", "1x1"]
            Picker("Common Ratios", selection: $filters.ratios) {
                Text("Any").tag("")
                Text("16:9").tag("16x9")
                Text("16:10").tag("16x10")
                Text("4:3").tag("4x3")
                Text("9:16 (Portrait)").tag("9x16")
                Text("1:1 (Square)").tag("1x1")
            }
            .id(ratioOptions)
        }
    }

    private var colorSection: some View {
        Section("Dominant Color") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Clear option
                    Circle()
                        .strokeBorder(.secondary, lineWidth: 2)
                        .frame(width: 36, height: 36)
                        .overlay {
                            if filters.colors.isEmpty {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onTapGesture { filters.colors = "" }

                    ForEach(WallhavenColor.all) { color in
                        colorCircle(color)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func colorCircle(_ color: WallhavenColor) -> some View {
        let isSelected = filters.colors == color.hex
        return Circle()
            .fill(Color(hex: color.hex))
            .frame(width: 36, height: 36)
            .overlay {
                Circle()
                    .strokeBorder(isSelected ? .white : .clear, lineWidth: 3)
                Circle()
                    .strokeBorder(isSelected ? Color(hex: color.hex) : .clear, lineWidth: 5)
                    .scaleEffect(1.25)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
            }
            .onTapGesture {
                filters.colors = isSelected ? "" : color.hex
            }
    }
}

// MARK: - Color(hex:) Extension

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    FilterSheet(filters: .constant(SearchFilters()), onApply: {})
}

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
            .navigationTitle("筛选条件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("应用") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("重置") { filters = SearchFilters() }
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Sections

    private var categoriesSection: some View {
        Section("分类") {
            Toggle("General（通用）", isOn: $filters.general)
            Toggle("Anime（动漫）",   isOn: $filters.anime)
            Toggle("People（人物）",  isOn: $filters.people)
        }
    }

    private var puritySection: some View {
        Section("纯度") {
            Toggle("SFW（适合工作）",   isOn: $filters.sfw)
            Toggle("Sketchy（少儿不宜）", isOn: $filters.sketchy)
            Toggle("NSFW（成人内容）",   isOn: $filters.nsfw)
                .foregroundStyle(filters.nsfw ? .red : .primary)
        }
    }

    private var sortingSection: some View {
        Section("排序") {
            Picker("排序方式", selection: $filters.sorting) {
                ForEach(SearchFilters.Sorting.allCases) { s in
                    Text(s.displayName).tag(s)
                }
            }
            Picker("排序方向", selection: $filters.order) {
                ForEach(SearchFilters.Order.allCases) { o in
                    Text(o.displayName).tag(o)
                }
            }
        }
    }

    private var topRangeSection: some View {
        Section("排行榜时间范围") {
            Picker("范围", selection: $filters.topRange) {
                ForEach(SearchFilters.TopRange.allCases) { r in
                    Text(r.displayName).tag(r)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var resolutionSection: some View {
        Section("分辨率") {
            TextField("最小分辨率，如 1920x1080", text: $filters.atleast)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
        }
    }

    private var ratioSection: some View {
        Section("比例") {
            let ratioOptions = ["", "16x9", "16x10", "4x3", "9x16", "1x1"]
            Picker("常用比例", selection: $filters.ratios) {
                Text("不限").tag("")
                Text("16:9").tag("16x9")
                Text("16:10").tag("16x10")
                Text("4:3").tag("4x3")
                Text("9:16（竖向）").tag("9x16")
                Text("1:1（正方）").tag("1x1")
            }
            .id(ratioOptions)
        }
    }

    private var colorSection: some View {
        Section("主色调") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // 清除选项
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

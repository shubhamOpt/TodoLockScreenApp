import SwiftUI

// MARK: - Wallpaper Style (solid/gradient backgrounds)

enum WallpaperStyle: String, CaseIterable, Identifiable {
    case dark, light, gradient, midnight

    var id: String { rawValue }
    var label: String {
        switch self {
        case .dark:     return "Dark"
        case .light:    return "Light"
        case .gradient: return "Gradient"
        case .midnight: return "Midnight"
        }
    }

    @ViewBuilder
    var background: some View {
        switch self {
        case .dark:
            Color.black
        case .light:
            Color(hex: "F5F5F0")
        case .gradient:
            LinearGradient(
                colors: [Color(hex: "0D0D1A"), Color(hex: "1A1040"), Color(hex: "0D2240")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .midnight:
            ZStack {
                Color(hex: "050510")
                RadialGradient(
                    colors: [Color(hex: "1A1050").opacity(0.6), Color.clear],
                    center: UnitPoint(x: 0.5, y: 0.8),
                    startRadius: 50, endRadius: 300
                )
            }
        }
    }

    // Colors for solid-background mode (no card)
    var primaryTextColor: Color {
        switch self {
        case .light: return Color(hex: "1A1A1A")
        default:     return .white
        }
    }
    var secondaryTextColor: Color {
        switch self {
        case .light:    return Color(hex: "6B6B6B")
        case .dark:     return Color.white.opacity(0.45)
        case .gradient: return Color.white.opacity(0.55)
        case .midnight: return Color(hex: "8080C0").opacity(0.7)
        }
    }
    var accentColor: Color {
        switch self {
        case .light:    return Color(hex: "3A3A3A")
        case .dark:     return Color.white.opacity(0.9)
        case .gradient: return Color(hex: "A78BFA")
        case .midnight: return Color(hex: "6C8EFF")
        }
    }
    var checkmarkColor: Color {
        switch self {
        case .light:    return Color(hex: "22C55E")
        case .dark:     return Color(hex: "4ADE80")
        case .gradient: return Color(hex: "A78BFA")
        case .midnight: return Color(hex: "6C8EFF")
        }
    }
    var dividerColor: Color {
        switch self {
        case .light: return Color.black.opacity(0.08)
        default:     return Color.white.opacity(0.08)
        }
    }
}

// MARK: - Wallpaper View

struct WallpaperView: View {

    let todos:          [TodoItem]
    let calendarEvents: [CalendarEvent]
    let style:          WallpaperStyle

    // Custom photo background
    var backgroundPhoto: UIImage? = nil
    var cardStyle: CardStyle = .darkBlur

    static let canvasWidth:      CGFloat = 393
    static let canvasHeight:     CGFloat = 852
    static let widgetZoneHeight: CGFloat = 370
    static let maxVisibleTodos:  Int     = 8
    static let maxVisibleEvents: Int     = 4

    var visibleTodos:  [TodoItem]       { Array(todos.prefix(Self.maxVisibleTodos)) }
    var todoOverflow:  Int              { max(0, todos.count - Self.maxVisibleTodos) }
    var visibleEvents: [CalendarEvent]  { Array(calendarEvents.prefix(Self.maxVisibleEvents)) }

    // Whether we're in custom-photo mode
    var isPhotoMode: Bool { backgroundPhoto != nil }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // ── Background ──
            if let photo = backgroundPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.canvasWidth, height: Self.canvasHeight)
                    .clipped()
            } else {
                style.background.ignoresSafeArea()
            }

            // ── Content positioned below widget zone ──
            VStack(spacing: 0) {
                Spacer().frame(height: Self.widgetZoneHeight)
                contentBlock
                    .padding(.horizontal, isPhotoMode ? 20 : 30)
                Spacer()
            }
            .frame(width: Self.canvasWidth, height: Self.canvasHeight)
        }
        .frame(width: Self.canvasWidth, height: Self.canvasHeight)
    }

    // MARK: - Content block

    @ViewBuilder
    private var contentBlock: some View {
        if isPhotoMode {
            // Translucent card wrapping all content
            VStack(alignment: .leading, spacing: 0) {
                contentRows
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardStyle.fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(cardStyle.strokeColor, lineWidth: 0.8)
                    )
            )
        } else {
            // No card — content directly on background
            contentRows
        }
    }

    // MARK: - Content rows

    private var contentRows: some View {
        let primary   = isPhotoMode ? cardStyle.primaryTextColor   : style.primaryTextColor
        let secondary = isPhotoMode ? cardStyle.secondaryTextColor : style.secondaryTextColor
        let accent    = isPhotoMode ? cardStyle.accentColor        : style.accentColor
        let check     = isPhotoMode ? cardStyle.checkmarkColor     : style.checkmarkColor
        let divider   = isPhotoMode ? cardStyle.dividerColor       : style.dividerColor

        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                // Calendar events
                if !visibleEvents.isEmpty {
                    sectionHeader(icon: "calendar", label: "TODAY", accent: accent, secondary: secondary)
                        .padding(.bottom, 10)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(visibleEvents) { event in
                            calendarRow(event, secondary: secondary, primary: primary)
                        }
                    }
                    .padding(.bottom, 16)

                    if !visibleTodos.isEmpty {
                        Rectangle()
                            .fill(divider)
                            .frame(height: 1)
                            .padding(.bottom, 16)
                    }
                }

                // Todos
                if !visibleTodos.isEmpty {
                    sectionHeader(icon: nil, label: "TO DO", accent: accent, secondary: secondary)
                        .padding(.bottom, 12)
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(visibleTodos) { todo in
                            todoRow(todo, primary: primary, secondary: secondary, check: check)
                        }
                        if todoOverflow > 0 {
                            Text("+ \(todoOverflow) more item\(todoOverflow == 1 ? "" : "s")")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(secondary)
                                .padding(.top, 2)
                        }
                    }
                }
            }
        )
    }

    // MARK: - Sub-views

    private func sectionHeader(icon: String?, label: String, accent: Color, secondary: Color) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Rectangle()
                .frame(width: 3, height: 12)
                .foregroundStyle(accent)
                .clipShape(Capsule())
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(secondary)
            }
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(2.5)
                .foregroundStyle(secondary)
        }
    }

    private func calendarRow(_ event: CalendarEvent, secondary: Color, primary: Color) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(Color(hex: event.calendarColor))
                .frame(width: 7, height: 7)
            Text(event.timeLabel)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(secondary)
                .frame(width: 56, alignment: .leading)
            Text(event.title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(primary)
                .lineLimit(1)
        }
    }

    private func todoRow(_ todo: TodoItem, primary: Color, secondary: Color, check: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(todo.isCompleted ? check : secondary)
                .frame(width: 16, height: 16)
                .padding(.top, 2)
            Text(todo.title)
                .font(.system(size: 15, weight: todo.isCompleted ? .regular : .medium, design: .rounded))
                .foregroundStyle(todo.isCompleted ? secondary : primary)
                .strikethrough(todo.isCompleted, color: secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Color Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255)
    }
}

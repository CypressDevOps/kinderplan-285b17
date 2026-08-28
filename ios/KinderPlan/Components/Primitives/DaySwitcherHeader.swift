// 10x primitive: cal-ai/day-switcher-header v2
import SwiftUI
import Foundation

/// One selectable day cell in the horizontal strip.
@available(iOS 17.0, *)
struct DayStripModel: Identifiable, Equatable {
    var id = UUID()
    var date: Date
    /// Completion fraction (0...1) drawn as a solid arc around the weekday
    /// letter; `nil` renders the observed dashed hairline circle instead.
    var progress: Double? = nil
    /// Arc color when `progress` is set; `nil` uses the config accent.
    var progressColor: Color? = nil
}

/// Visual configuration for `DaySwitcherHeader`. Defaults come from `ClinicalTokens`.
@available(iOS 17.0, *)
struct DaySwitcherHeaderConfig {
    var greetingFont: Font = .system(.largeTitle, weight: .bold)
    var subtitleFont: Font = ClinicalTokens.captionFont
    var weekdayFont: Font = .system(.caption, weight: .semibold)
    var dayNumberFont: Font = .system(.subheadline, weight: .bold)
    var greetingColor: Color = ClinicalTokens.ink
    var subtitleColor: Color = ClinicalTokens.inkSecondary
    var weekdayColor: Color = ClinicalTokens.inkSecondary
    var dayNumberColor: Color = ClinicalTokens.inkSecondary
    var selectedDayNumberColor: Color = ClinicalTokens.ink
    /// Dashed hairline ring around every weekday letter (observed anatomy).
    var ringColor: Color = ClinicalTokens.inkSecondary.opacity(0.45)
    var progressAccent: Color = ClinicalTokens.accent
    var calendar: Calendar = .current
    var cellWidth: CGFloat = 40
    var ringDiameter: CGFloat = 30
    var cellSpacing: CGFloat = 10
}

/// Day-switching header for any daily app: an optional greeting block and a
/// horizontal strip of day cells — a weekday letter inside a dashed circle
/// (which becomes a solid completion arc when the day carries progress) above
/// the day number — plus an arbitrary hero content slot supplied by the host.
@available(iOS 17.0, *)
struct DaySwitcherHeader<Hero: View>: View {
    var days: [DayStripModel]
    @Binding var selectedID: DayStripModel.ID?
    /// Optional large greeting/title above the strip ("Today", "Good morning").
    var greeting: String? = nil
    /// Optional secondary line under the greeting (e.g. a full date).
    var subtitle: String? = nil
    var config = DaySwitcherHeaderConfig()
    var onSelectDay: (DayStripModel) -> Void
    @ViewBuilder var hero: () -> Hero

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            if greeting != nil || subtitle != nil {
                greetingBlock
            }
            dayStrip
            hero()
        }
    }

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let greeting {
                Text(greeting)
                    .font(config.greetingFont)
                    .foregroundStyle(config.greetingColor)
                    .accessibilityAddTraits(.isHeader)
            }
            if let subtitle {
                Text(subtitle)
                    .font(config.subtitleFont)
                    .foregroundStyle(config.subtitleColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    private var dayStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: config.cellSpacing) {
                    ForEach(days) { day in
                        dayCell(day)
                            .id(day.id)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear {
                if let selectedID {
                    proxy.scrollTo(selectedID, anchor: .center)
                }
            }
            .onChange(of: selectedID) { _, newValue in
                guard let newValue else { return }
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedID)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Day selector")
    }

    private func dayCell(_ day: DayStripModel) -> some View {
        let isSelected = day.id == selectedID
        return Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.78)) {
                selectedID = day.id
            }
            onSelectDay(day)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if let progress = day.progress {
                        Circle()
                            .stroke(ClinicalTokens.hairline, lineWidth: 2)
                        Circle()
                            .trim(from: 0, to: min(max(progress, 0), 1))
                            .stroke(day.progressColor ?? config.progressAccent,
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    } else {
                        Circle()
                            .stroke(config.ringColor,
                                    style: StrokeStyle(lineWidth: 1.5, dash: [3, 3.5]))
                    }
                    Text(weekdayLetter(for: day.date))
                        .font(config.weekdayFont)
                        .foregroundStyle(isSelected ? ClinicalTokens.ink : config.weekdayColor)
                }
                .frame(width: config.ringDiameter, height: config.ringDiameter)
                Text(dayNumber(for: day.date))
                    .font(config.dayNumberFont)
                    .foregroundStyle(isSelected ? config.selectedDayNumberColor : config.dayNumberColor)
            }
            .frame(width: config.cellWidth)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityDate(for: day.date))
        .accessibilityValue(day.progress.map { "\(Int($0 * 100)) percent logged" } ?? "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func weekdayLetter(for date: Date) -> String {
        let index = config.calendar.component(.weekday, from: date) - 1
        let symbols = config.calendar.veryShortWeekdaySymbols
        return symbols.indices.contains(index) ? symbols[index] : "?"
    }

    private func dayNumber(for date: Date) -> String {
        "\(config.calendar.component(.day, from: date))"
    }

    private func accessibilityDate(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}

#Preview("Day switcher") {
    if #available(iOS 17.0, *) {
        struct Host: View {
            @State private var days: [DayStripModel] = (0..<10).map { offset in
                DayStripModel(
                    date: Calendar.current.date(byAdding: .day, value: offset - 6, to: .now) ?? .now,
                    progress: offset == 6 ? 0.72 : nil
                )
            }
            @State private var selectedID: DayStripModel.ID?

            var body: some View {
                DaySwitcherHeader(days: days, selectedID: $selectedID,
                                  greeting: "Today", onSelectDay: { _ in }) {
                    RoundedRectangle(cornerRadius: ClinicalTokens.radiusTile)
                        .fill(ClinicalTokens.surface)
                        .frame(height: 160)
                        .overlay(Text("Hero slot").foregroundStyle(ClinicalTokens.inkSecondary))
                        .padding(.horizontal, 16)
                }
                .onAppear { selectedID = days[6].id }
            }
        }
        return AnyView(Host().background(ClinicalTokens.ground))
    }
    return AnyView(EmptyView())
}

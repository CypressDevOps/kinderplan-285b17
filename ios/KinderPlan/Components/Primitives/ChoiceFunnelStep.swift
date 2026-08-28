// 10x primitive: cal-ai/choice-funnel-step v2
import SwiftUI

/// One option row in a funnel step. `emoji` wins the leading slot when set;
/// otherwise `symbolName` is used; otherwise the slot collapses and the
/// title centers (observed on icon-less steps).
@available(iOS 17.0, *)
struct ChoiceFunnelOption: Identifiable, Equatable {
    var id: String
    var title: String
    /// Optional caption under the title (e.g. "A few workouts per week").
    var subtitle: String? = nil
    var emoji: String? = nil
    var symbolName: String? = nil
}

/// One-question onboarding funnel step for any guided setup, matching the
/// observed anatomy: a thin continuous progress bar beside a soft circular
/// back button, one large question title with an optional gray subtitle, and
/// thumb-height option rows on a soft gray fill whose selected state inverts
/// to a full accent fill with light content. A pinned continue CTA is always
/// present and enables once a selection exists (the observed funnel never
/// auto-advances); set `autoAdvances` for the legacy tap-to-advance single
/// select.
@available(iOS 17.0, *)
struct ChoiceFunnelStep: View {
    enum SelectionMode { case single, multiple }

    var title: String
    /// Optional gray support line under the title (observed: "This will be
    /// used to calibrate your custom plan.").
    var subtitle: String? = nil
    var options: [ChoiceFunnelOption]
    var mode: SelectionMode = .single
    var stepIndex: Int = 0
    var stepCount: Int = 1
    var continueTitle: String = "Continue"
    /// Legacy behavior: single-select advances on its own after this delay
    /// when `autoAdvances` is true.
    var autoAdvanceDelay: TimeInterval = 0.35
    /// The observed funnel always waits for the continue CTA; opt in to the
    /// legacy tap-to-advance single select instead.
    var autoAdvances: Bool = false
    var accentColor: Color = ClinicalTokens.accent
    /// Unselected row fill (observed: soft gray on the white funnel page).
    var rowBackground: Color = ClinicalTokens.ink.opacity(0.045)
    var titleFont: Font = ClinicalTokens.titleFont
    var optionFont: Font = .system(.body, weight: .semibold)
    var backSymbolName: String = "chevron.left"
    var checkmarkSymbolName: String = "checkmark.circle.fill"
    /// Option ids rendered selected on first appearance (e.g. restoring a
    /// previously answered step). Selection state stays internal afterwards.
    var initiallySelected: Set<String> = []
    var onBack: (() -> Void)? = nil
    var onAdvance: (Set<String>) -> Void = { _ in }

    @State private var selected: Set<String> = []
    @State private var hapticTick = 0
    @State private var isLocked = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Text(title)
                .font(titleFont)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline))
                    .foregroundStyle(ClinicalTokens.inkSecondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(options) { option in
                        row(for: option)
                    }
                }
                .padding(20)
            }
            continueButton
        }
        .sensoryFeedback(.selection, trigger: hapticTick)
        .onAppear {
            if selected.isEmpty, !initiallySelected.isEmpty {
                selected = initiallySelected
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button {
                onBack?()
            } label: {
                Image(systemName: backSymbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ClinicalTokens.ink)
                    .frame(width: 36, height: 36)
                    .background(ClinicalTokens.ink.opacity(0.05), in: .circle)
                    .contentShape(Circle())
            }
            .opacity(onBack == nil ? 0 : 1)
            .disabled(onBack == nil)
            .accessibilityLabel("Back")

            // Observed progress: one continuous thin bar filling with the
            // accent, not segmented capsules.
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(ClinicalTokens.hairline)
                    Capsule()
                        .fill(accentColor)
                        .frame(width: proxy.size.width
                               * CGFloat(min(max(Double(stepIndex + 1) / Double(max(stepCount, 1)), 0), 1)))
                }
            }
            .frame(height: 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(stepIndex + 1) of \(stepCount)")
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private func row(for option: ChoiceFunnelOption) -> some View {
        let isSelected = selected.contains(option.id)
        let hasLeading = option.emoji != nil || option.symbolName != nil
        let centered = !hasLeading && option.subtitle == nil && mode == .single
        return Button {
            select(option)
        } label: {
            HStack(spacing: 14) {
                if let emoji = option.emoji {
                    Text(emoji).font(.system(size: 24))
                } else if let symbol = option.symbolName {
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? ClinicalTokens.inkOnAccent : ClinicalTokens.ink)
                        .frame(width: 28)
                }
                VStack(alignment: centered ? .center : .leading, spacing: 2) {
                    Text(option.title)
                        .font(optionFont)
                        .foregroundStyle(isSelected ? ClinicalTokens.inkOnAccent : ClinicalTokens.ink)
                        .multilineTextAlignment(centered ? .center : .leading)
                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(.system(.footnote))
                            .foregroundStyle(isSelected
                                             ? ClinicalTokens.inkOnAccent.opacity(0.75)
                                             : ClinicalTokens.inkSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: centered ? .infinity : nil, alignment: centered ? .center : .leading)
                if !centered { Spacer(minLength: 0) }
                if mode == .multiple {
                    Image(systemName: checkmarkSymbolName)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? ClinicalTokens.inkOnAccent : ClinicalTokens.hairline)
                        .scaleEffect(isSelected ? 1 : 0.85)
                }
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: centered ? .center : .leading)
            .background {
                // Observed selection: the whole row inverts to the accent.
                RoundedRectangle(cornerRadius: ClinicalTokens.radiusCard, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(accentColor) : AnyShapeStyle(rowBackground))
            }
            .scaleEffect(isSelected && !reduceMotion ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// Observed CTA: pinned on every step, gray-disabled until a selection.
    private var continueButton: some View {
        Button {
            onAdvance(selected)
        } label: {
            Text(continueTitle)
                .font(.system(.body, weight: .bold))
                .foregroundStyle(ClinicalTokens.inkOnAccent)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(selected.isEmpty ? ClinicalTokens.inkSecondary.opacity(0.4) : accentColor)
                .clipShape(Capsule())
        }
        .disabled(selected.isEmpty)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .animation(.snappy(duration: 0.2), value: selected.isEmpty)
    }

    private func select(_ option: ChoiceFunnelOption) {
        guard !isLocked else { return }
        hapticTick += 1
        switch mode {
        case .single:
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                selected = [option.id]
            }
            guard autoAdvances else { return }
            isLocked = true
            Task {
                try? await Task.sleep(for: .seconds(autoAdvanceDelay))
                onAdvance(selected)
                isLocked = false
            }
        case .multiple:
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                if selected.contains(option.id) {
                    selected.remove(option.id)
                } else {
                    selected.insert(option.id)
                }
            }
        }
    }
}

#Preview("Single select") {
    if #available(iOS 17.0, *) {
        ChoiceFunnelStep(
            title: "How many workouts do you do per week?",
            subtitle: "This will be used to calibrate your custom plan.",
            options: [
                ChoiceFunnelOption(id: "0-2", title: "0–2", subtitle: "Workouts now and then", symbolName: "circle.fill"),
                ChoiceFunnelOption(id: "3-5", title: "3–5", subtitle: "A few workouts per week", symbolName: "circle.grid.2x1.fill"),
                ChoiceFunnelOption(id: "6+", title: "6+", subtitle: "Dedicated athlete", symbolName: "circle.grid.3x3.fill"),
            ],
            mode: .single,
            stepIndex: 1,
            stepCount: 8,
            initiallySelected: ["3-5"],
            onBack: {}
        )
    }
}

#Preview("Centered, no icons") {
    if #available(iOS 17.0, *) {
        ChoiceFunnelStep(
            title: "Choose your focus",
            subtitle: "This will be used to calibrate your custom plan.",
            options: [
                ChoiceFunnelOption(id: "a", title: "Consistency"),
                ChoiceFunnelOption(id: "b", title: "Balance"),
                ChoiceFunnelOption(id: "c", title: "Strength"),
            ],
            mode: .single,
            stepIndex: 0,
            stepCount: 8,
            onBack: {}
        )
    }
}

#Preview("Multi select") {
    if #available(iOS 17.0, *) {
        ChoiceFunnelStep(
            title: "What gets in your way?",
            options: [
                ChoiceFunnelOption(id: "time", title: "Not enough time", symbolName: "clock"),
                ChoiceFunnelOption(id: "consistency", title: "Staying consistent", symbolName: "calendar"),
                ChoiceFunnelOption(id: "cravings", title: "Cravings", symbolName: "fork.knife"),
                ChoiceFunnelOption(id: "support", title: "Lack of support", symbolName: "person.2"),
            ],
            mode: .multiple,
            stepIndex: 2,
            stepCount: 8,
            onBack: {}
        )
    }
}

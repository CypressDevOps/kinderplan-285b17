// 10x primitive: cal-ai/text-prompt-input v2
//
// Text/voice prompt input for any describe-it flow (log a meal, describe a
// task, ask a question), matching the observed anatomy: a hairline-ink
// bordered field with a leading search glyph, suggestion ROWS (title,
// optional detail caption, trailing add circle) rather than chips, and a
// bottom action row pairing a bordered voice capsule with the filled submit
// capsule. Recording state is host-owned via a Binding; the mic tap only
// reports intent. Colors and fonts default to ClinicalTokens.

import SwiftUI

/// One tappable suggestion row. String literals convert directly, so
/// `suggestions: ["2 eggs and toast"]` still works.
@available(iOS 17.0, *)
public struct TextPromptSuggestion: Identifiable, Equatable, ExpressibleByStringLiteral {
    public var id: String { title }
    public var title: String
    /// Optional caption under the title (e.g. "94 cal · tbsp").
    public var detail: String?

    public init(title: String, detail: String? = nil) {
        self.title = title
        self.detail = detail
    }

    public init(stringLiteral value: String) {
        self.init(title: value)
    }
}

@available(iOS 17.0, *)
public struct TextPromptInput: View {
    @Binding private var text: String
    @Binding private var isRecording: Bool
    private let placeholder: String
    private let suggestions: [TextPromptSuggestion]
    private let suggestionsTitle: String?
    private let submitLabel: String
    private let submitGlyph: String
    private let micGlyph: String
    private let micLabel: String
    private let fieldGlyph: String?
    private let micAccessibilityLabel: String
    private let recordingAccessibilityValue: String
    private let idleAccessibilityValue: String
    private let recordingTint: Color
    private let accentColor: Color
    private let fieldFont: Font
    private let chipFont: Font
    private let onMicTap: () -> Void
    private let onSuggestionTap: ((String) -> Void)?
    private let onSubmit: (String) -> Void

    @State private var submitCount = 0
    @State private var suggestionTapCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        text: Binding<String>,
        isRecording: Binding<Bool>,
        placeholder: String = "Describe what you ate",
        suggestions: [TextPromptSuggestion] = [
            TextPromptSuggestion(title: "2 eggs and toast", detail: "320 cal · plate"),
            TextPromptSuggestion(title: "Chicken salad", detail: "410 cal · bowl"),
            TextPromptSuggestion(title: "Oat milk latte", detail: "120 cal · cup")
        ],
        suggestionsTitle: String? = "Suggestions",
        submitLabel: String = "Add",
        submitGlyph: String = "arrow.up",
        micGlyph: String = "mic.fill",
        micLabel: String = "Voice log",
        fieldGlyph: String? = "magnifyingglass",
        micAccessibilityLabel: String = "Voice input",
        recordingAccessibilityValue: String = "Recording",
        idleAccessibilityValue: String = "Not recording",
        recordingTint: Color = ClinicalTokens.negative,
        accentColor: Color = ClinicalTokens.accent,
        fieldFont: Font = ClinicalTokens.bodyFont,
        chipFont: Font = .system(.footnote).weight(.medium),
        onMicTap: @escaping () -> Void = {},
        onSuggestionTap: ((String) -> Void)? = nil,
        onSubmit: @escaping (String) -> Void = { _ in }
    ) {
        self._text = text
        self._isRecording = isRecording
        self.placeholder = placeholder
        self.suggestions = suggestions
        self.suggestionsTitle = suggestionsTitle
        self.submitLabel = submitLabel
        self.submitGlyph = submitGlyph
        self.micGlyph = micGlyph
        self.micLabel = micLabel
        self.fieldGlyph = fieldGlyph
        self.micAccessibilityLabel = micAccessibilityLabel
        self.recordingAccessibilityValue = recordingAccessibilityValue
        self.idleAccessibilityValue = idleAccessibilityValue
        self.recordingTint = recordingTint
        self.accentColor = accentColor
        self.fieldFont = fieldFont
        self.chipFont = chipFont
        self.onMicTap = onMicTap
        self.onSuggestionTap = onSuggestionTap
        self.onSubmit = onSubmit
    }

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        VStack(spacing: 16) {
            promptField
            if !suggestions.isEmpty {
                suggestionList
            }
            actionRow
        }
        .padding(16)
        .sensoryFeedback(.impact(weight: .light), trigger: isRecording)
        .sensoryFeedback(.selection, trigger: suggestionTapCount)
        .sensoryFeedback(.impact(weight: .medium), trigger: submitCount)
    }

    // MARK: Field — observed: white field with a thin ink border and a
    // leading search glyph.

    private var promptField: some View {
        HStack(alignment: .top, spacing: 8) {
            if let fieldGlyph {
                Image(systemName: fieldGlyph)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ClinicalTokens.inkSecondary)
                    .padding(.top, 2)
            }
            TextField(placeholder, text: $text, axis: .vertical)
                .font(fieldFont)
                .lineLimit(2...5)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: ClinicalTokens.radiusCard)
                .fill(ClinicalTokens.surface)
            RoundedRectangle(cornerRadius: ClinicalTokens.radiusCard)
                .strokeBorder(ClinicalTokens.ink, lineWidth: 1.5)
        }
    }

    // MARK: Suggestions — observed: full-width rows with a trailing add circle.

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let suggestionsTitle {
                Text(suggestionsTitle)
                    .font(ClinicalTokens.headlineFont)
                    .foregroundStyle(ClinicalTokens.ink)
            }
            ForEach(suggestions) { suggestion in
                Button {
                    suggestionTapCount += 1
                    if let onSuggestionTap {
                        onSuggestionTap(suggestion.title)
                    } else {
                        text = suggestion.title
                    }
                } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(ClinicalTokens.ink)
                            if let detail = suggestion.detail {
                                Text(detail)
                                    .font(.system(.caption))
                                    .foregroundStyle(ClinicalTokens.inkSecondary)
                            }
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ClinicalTokens.ink)
                            .frame(width: 26, height: 26)
                            .background(ClinicalTokens.surface, in: .circle)
                            .overlay { Circle().strokeBorder(ClinicalTokens.hairline, lineWidth: 1) }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: ClinicalTokens.radiusCard)
                            .fill(ClinicalTokens.ink.opacity(0.045))
                    )
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityLabel(suggestionsTitle ?? "Suggestions")
    }

    // MARK: Actions — observed: bordered voice capsule beside the filled
    // submit capsule.

    private var actionRow: some View {
        HStack(spacing: 10) {
            micButton
            submitButton
        }
    }

    private var micButton: some View {
        Button(action: onMicTap) {
            HStack(spacing: 8) {
                Image(systemName: micGlyph)
                    .font(.system(size: 15, weight: .semibold))
                    .symbolEffect(.pulse, isActive: isRecording && !reduceMotion)
                Text(micLabel)
            }
            .font(ClinicalTokens.headlineFont)
            .foregroundStyle(isRecording ? ClinicalTokens.inkOnAccent : ClinicalTokens.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .background {
                if isRecording {
                    Capsule().fill(recordingTint)
                } else {
                    Capsule().fill(ClinicalTokens.surface)
                    Capsule().strokeBorder(ClinicalTokens.hairline, lineWidth: 1.5)
                }
            }
            .background {
                if isRecording && !reduceMotion {
                    MicPulseRing(tint: recordingTint)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isRecording)
        .accessibilityLabel(micAccessibilityLabel)
        .accessibilityValue(isRecording ? recordingAccessibilityValue : idleAccessibilityValue)
    }

    private var submitButton: some View {
        Button {
            submitCount += 1
            onSubmit(text)
        } label: {
            HStack(spacing: 8) {
                Text(submitLabel)
                Image(systemName: submitGlyph)
            }
            .font(ClinicalTokens.headlineFont)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Capsule().fill(accentColor))
            .foregroundStyle(ClinicalTokens.inkOnAccent)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1 : 0.4)
        .animation(.snappy, value: canSubmit)
    }
}

/// Expanding, fading ring behind the voice capsule while recording.
@available(iOS 17.0, *)
private struct MicPulseRing: View {
    let tint: Color
    @State private var pulsing = false

    var body: some View {
        Capsule()
            .stroke(tint.opacity(pulsing ? 0 : 0.55), lineWidth: 3)
            .scaleEffect(pulsing ? 1.25 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
                    pulsing = true
                }
            }
            .accessibilityHidden(true)
    }
}

@available(iOS 17.0, *)
private struct TextPromptInputPreviewHost: View {
    @State private var text = ""
    @State private var recording = false

    var body: some View {
        VStack(spacing: 24) {
            TextPromptInput(
                text: $text,
                isRecording: $recording,
                onMicTap: { recording.toggle() },
                onSubmit: { _ in text = "" }
            )
            Toggle("Simulate recording", isOn: $recording)
                .padding(.horizontal, 24)
        }
    }
}

#Preview("Text prompt input") {
    if #available(iOS 17.0, *) {
        TextPromptInputPreviewHost()
    }
}

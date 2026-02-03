//
//  GradientTextInput.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

// MARK: - Simple Glass Text Input

struct GlassTextInput: View {
    @Binding var text: String
    var placeholder: String
    var characterLimit: Int?
    var minHeight: CGFloat
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        placeholder: String = "What's on your mind?",
        characterLimit: Int? = nil,
        minHeight: CGFloat = 120,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.characterLimit = characterLimit
        self.minHeight = minHeight
        self.onSubmit = onSubmit
    }

    private var characterCount: Int {
        text.count
    }

    private var isOverLimit: Bool {
        guard let limit = characterLimit else { return false }
        return characterCount > limit
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Text editor
                TextEditor(text: $text)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, characterLimit != nil ? 36 : 12)

                // Placeholder
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                }

                // Character count (if limit is set)
                if let limit = characterLimit {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("\(characterCount)/\(limit)")
                                .font(.caption)
                                .foregroundStyle(isOverLimit ? .red : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .frame(minHeight: minHeight)
            .glassCard(cornerRadius: 16)
        }
    }
}

// MARK: - Compact Glass Input (Single Line)

struct CompactGlassInput: View {
    @Binding var text: String
    var placeholder: String
    var icon: String?
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        placeholder: String = "Add a note...",
        icon: String? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
            }

            TextField(placeholder, text: $text)
                .focused($isFocused)
                .onSubmit {
                    onSubmit?()
                }

            if let onSubmit = onSubmit, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: onSubmit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 12)
    }
}

// MARK: - Legacy Gradient Input (kept for compatibility but simplified)

struct GradientTextInput: View {
    @Binding var text: String
    var placeholder: String
    var characterLimit: Int
    var gradient: LinearGradient
    var minHeight: CGFloat
    var onSubmit: (() -> Void)?

    init(
        text: Binding<String>,
        placeholder: String = "What's on your mind?",
        characterLimit: Int = 500,
        gradient: LinearGradient = .orangeYellowInput,
        minHeight: CGFloat = 120,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.characterLimit = characterLimit
        self.gradient = gradient
        self.minHeight = minHeight
        self.onSubmit = onSubmit
    }

    var body: some View {
        // Now just uses the simple glass input
        GlassTextInput(
            text: $text,
            placeholder: placeholder,
            characterLimit: characterLimit,
            minHeight: minHeight,
            onSubmit: onSubmit
        )
    }
}

// MARK: - Compact Gradient Input (Legacy - now simple)

struct CompactGradientInput: View {
    @Binding var text: String
    var placeholder: String
    var gradient: LinearGradient
    var onSubmit: () -> Void

    init(
        text: Binding<String>,
        placeholder: String = "Add a quick note...",
        gradient: LinearGradient = .orangeYellowInput,
        onSubmit: @escaping () -> Void
    ) {
        self._text = text
        self.placeholder = placeholder
        self.gradient = gradient
        self.onSubmit = onSubmit
    }

    var body: some View {
        CompactGlassInput(
            text: $text,
            placeholder: placeholder,
            onSubmit: onSubmit
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack(spacing: 24) {
            GlassTextInput(
                text: .constant("This is a sample journal entry about how I'm feeling today..."),
                placeholder: "What's on your mind?",
                characterLimit: 200
            )

            GlassTextInput(
                text: .constant(""),
                placeholder: "How are you feeling right now?",
                minHeight: 100
            )

            CompactGlassInput(
                text: .constant(""),
                placeholder: "Quick note...",
                icon: "pencil"
            )

            CompactGlassInput(
                text: .constant("Feeling good!"),
                placeholder: "Quick note...",
                onSubmit: {}
            )
        }
        .padding()
    }
}

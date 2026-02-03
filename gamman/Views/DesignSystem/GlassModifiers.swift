//
//  GlassModifiers.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    enum Thickness {
        case thin
        case regular
        case thick
    }

    var cornerRadius: CGFloat
    var tint: Color
    var thickness: Thickness

    private var materialOpacity: CGFloat {
        switch thickness {
        case .thin: return 0.05
        case .regular: return 0.1
        case .thick: return 0.2
        }
    }

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base material
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Tint overlay
                    if tint != .clear {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(tint.opacity(materialOpacity))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

// MARK: - View Extension

extension View {
    func glassCard(
        cornerRadius: CGFloat = 20,
        tint: Color = .clear,
        thickness: GlassCardModifier.Thickness = .regular
    ) -> some View {
        modifier(GlassCardModifier(
            cornerRadius: cornerRadius,
            tint: tint,
            thickness: thickness
        ))
    }

    func glassCardThin(cornerRadius: CGFloat = 20, tint: Color = .clear) -> some View {
        glassCard(cornerRadius: cornerRadius, tint: tint, thickness: .thin)
    }

    func glassCardThick(cornerRadius: CGFloat = 20, tint: Color = .clear) -> some View {
        glassCard(cornerRadius: cornerRadius, tint: tint, thickness: .thick)
    }
}

// MARK: - Glass Pill Modifier

struct GlassPillModifier: ViewModifier {
    var isSelected: Bool
    var selectedColor: Color

    func body(content: Content) -> some View {
        content
            .background {
                if isSelected {
                    Capsule()
                        .fill(selectedColor.gradient)
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
            }
            .clipShape(Capsule())
    }
}

extension View {
    func glassPill(isSelected: Bool = false, selectedColor: Color = .blue) -> some View {
        modifier(GlassPillModifier(isSelected: isSelected, selectedColor: selectedColor))
    }
}

// MARK: - Glass Navigation Bar

struct GlassNavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        #else
        content
        #endif
    }
}

extension View {
    func glassNavigationBar() -> some View {
        modifier(GlassNavigationBarModifier())
    }
}

// MARK: - Frosted Overlay

struct FrostedOverlayModifier: ViewModifier {
    var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

extension View {
    func frostedOverlay(isPresented: Bool) -> some View {
        modifier(FrostedOverlayModifier(isPresented: isPresented))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            Text("Glass Card - Thin")
                .padding()
                .frame(maxWidth: .infinity)
                .glassCardThin(cornerRadius: 16)

            Text("Glass Card - Regular")
                .padding()
                .frame(maxWidth: .infinity)
                .glassCard(cornerRadius: 16)

            Text("Glass Card - Thick")
                .padding()
                .frame(maxWidth: .infinity)
                .glassCardThick(cornerRadius: 16)

            Text("Glass Card - Tinted")
                .padding()
                .frame(maxWidth: .infinity)
                .glassCard(cornerRadius: 16, tint: .orange)

            HStack {
                Text("Normal")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .glassPill()

                Text("Selected")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .glassPill(isSelected: true, selectedColor: .orange)
            }
        }
        .padding()
    }
}

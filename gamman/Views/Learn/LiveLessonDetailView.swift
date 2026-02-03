//
//  LiveLessonDetailView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData
import SafariServices

@available(iOS 17.0, *)
struct LiveLessonDetailView: View {
    @Bindable var lesson: Lesson
    @Query private var allSections: [LessonSection]
    @State private var currentSectionIndex = 0

    private var sections: [LessonSection] {
        allSections
            .filter { $0.lessonID == lesson.id && $0.sectionStatus == .completed }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    init(lesson: Lesson) {
        self.lesson = lesson
        let lessonID = lesson.id
        self._allSections = Query(
            filter: #Predicate<LessonSection> { $0.lessonID == lessonID }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Instagram-style progress segments
            if !sections.isEmpty {
                progressSegments
            }

            // Section content
            if sections.isEmpty {
                EmptyStateView(
                    icon: "hourglass",
                    title: "Generating...",
                    description: "Your lesson is being created. Sections will appear here as they complete."
                )
            } else {
                TabView(selection: $currentSectionIndex) {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        LiveSectionView(
                            section: section,
                            isLastSection: index == sections.count - 1 && !lesson.isGenerating,
                            onComplete: {
                                lesson.isCompleted = true
                                lesson.completedDate = Date()
                                HapticService.success()
                            }
                        )
                        .tag(index)
                    }

                    // "More coming" placeholder
                    if lesson.isGenerating && sections.count < lesson.totalSections {
                        MoreSectionsLoadingView(
                            remaining: lesson.totalSections - sections.count
                        )
                        .tag(sections.count)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentSectionIndex) { _, _ in
                    HapticService.selection()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                // Generating indicator in nav bar
                if lesson.isGenerating {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("\(lesson.completedSections)/\(lesson.totalSections)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var progressSegments: some View {
        HStack(spacing: 4) {
            ForEach(0..<sections.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index <= currentSectionIndex ? Color.primary.opacity(0.8) : Color.primary.opacity(0.15))
                    .frame(height: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

@available(iOS 17.0, *)
struct LiveSectionView: View {
    let section: LessonSection
    var isLastSection: Bool = false
    var onComplete: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with image
                sectionHeader

                // Content
                Text(section.displayContent ?? "")
                    .font(.body)
                    .lineSpacing(6)

                // Practice prompt
                if let practicePrompt = section.practicePrompt {
                    PracticePromptCard(prompt: practicePrompt)
                }

                // External resources
                if !section.resources.isEmpty {
                    ResourcesSection(resources: section.resources)
                }

                // Fact-check notes (collapsible)
                if let notes = section.factCheckNotes, !notes.isEmpty {
                    FactCheckNotesView(notes: notes)
                }

                // Complete button on last section
                if isLastSection {
                    Button {
                        onComplete?()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark as Complete")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }

                Spacer(minLength: 60)
            }
            .padding()
        }
    }

    private var sectionHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            // Compact icon
            if let imageData = section.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if let systemName = section.imageSystemName {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: systemName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.blue)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(section.heading)
                    .font(.system(size: 20, weight: .semibold))

                if let objective = section.learningObjective {
                    Text(objective)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

@available(iOS 17.0, *)
struct PracticePromptCard: View {
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Practice", systemImage: "sparkles")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)

            Text(prompt)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

@available(iOS 17.0, *)
struct ResourcesSection: View {
    let resources: [ExternalResource]
    @State private var selectedURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header - minimal, Linear style
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("Resources")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            // Resources list with subtle border
            VStack(spacing: 0) {
                ForEach(Array(resources.enumerated()), id: \.element.id) { index, resource in
                    if let url = URL(string: resource.url) {
                        Button {
                            selectedURL = url
                            HapticService.selection()
                        } label: {
                            ResourceRow(resource: resource)
                        }
                        .buttonStyle(ResourceButtonStyle())

                        // Divider between items (not after last)
                        if index < resources.count - 1 {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
            )
        }
        .padding(.top, 8)
        .sheet(item: $selectedURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
}

// Safari View for in-app browser
@available(iOS 17.0, *)
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.preferredControlTintColor = .systemBlue
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// Make URL identifiable for sheet
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// Individual resource row - clean, minimal
@available(iOS 17.0, *)
struct ResourceRow: View {
    let resource: ExternalResource

    var body: some View {
        HStack(spacing: 12) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconBackgroundColor.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: resource.resourceType.systemImage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconBackgroundColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(domainFromURL(resource.url))
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Arrow
            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    var iconBackgroundColor: Color {
        switch resource.resourceType {
        case .video: return .red
        case .research: return .blue
        case .book: return .orange
        case .podcast: return .purple
        case .article: return .green
        case .other: return .gray
        }
    }

    var displayTitle: String {
        if resource.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Fallback to domain name or resource type
            let domain = domainFromURL(resource.url)
            return domain.isEmpty ? resource.resourceType.rawValue.capitalized : domain
        }
        return resource.title
    }

    func domainFromURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return urlString
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}

// Custom button style for subtle press feedback
@available(iOS 17.0, *)
struct ResourceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(.systemGray5) : Color.clear)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

@available(iOS 17.0, *)
struct FactCheckNotesView: View {
    let notes: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header - tappable
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.green)

                Text("Verified Content")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                Text(isExpanded ? "Hide" : "Details")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.green)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.green)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
                HapticService.selection()
            }

            if isExpanded {
                Divider()
                    .padding(.horizontal, 14)

                Text(notes)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

@available(iOS 17.0, *)
struct MoreSectionsLoadingView: View {
    let remaining: Int

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Generating \(remaining) more section\(remaining == 1 ? "" : "s")...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("You can continue reading while we prepare the rest of your lesson.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        LiveLessonDetailView(
            lesson: Lesson(
                title: "Understanding Your Nervous System",
                subtitle: "Learn about polyvagal theory",
                userPrompt: "test",
                totalSections: 4
            )
        )
    }
    .modelContainer(for: [Lesson.self, LessonSection.self], inMemory: true)
}

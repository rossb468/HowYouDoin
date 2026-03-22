//
//  CSVPreviewSheet.swift
//  HowYouDoing?
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CSVImportFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MoodEntry.date, order: .reverse) private var existingEntries: [MoodEntry]

    @State private var step: ImportStep = .info
    @State private var showFileImporter = false
    @State private var parsedEntries: [MoodEntry] = []
    @State private var duplicateIndices: Set<Int> = []
    @State private var parseErrorMessage: String = ""

    private enum ImportStep {
        case info
        case error
        case preview
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .info:
                    infoView
                case .error:
                    errorView
                case .preview:
                    CSVPreviewView(
                        entries: parsedEntries,
                        duplicateIndices: duplicateIndices,
                        onImportAll: { importEntries(parsedEntries) },
                        onImportExcludingDuplicates: {
                            let filtered = parsedEntries.enumerated()
                                .filter { !duplicateIndices.contains($0.offset) }
                                .map(\.element)
                            importEntries(filtered)
                        }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileResult(result)
        }
    }

    // MARK: - Info View

    private var infoView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "doc.text")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)

                Text("Import from CSV")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                VStack(alignment: .leading, spacing: 16) {
                    Text("This imports mood data from a Daylio CSV export. The file must contain these columns:")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        formatRow(column: "full_date", example: "2026-03-21")
                        formatRow(column: "time", example: "2:30 PM")
                        formatRow(column: "mood", example: "good, bad, meh, rad, awful")
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("To export from Daylio, go to Settings > Export > CSV.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 24)

                Button {
                    showFileImporter = true
                } label: {
                    Text("Choose CSV File")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Import")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatRow(column: String, example: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(column)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
            Text(example)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 56))
                .foregroundStyle(.red)

            Text("Invalid File")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(parseErrorMessage)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showFileImporter = true
            } label: {
                Text("Try Another File")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)

            Spacer()
        }
        .navigationTitle("Import")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Logic

    private func handleFileResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let parseResult = CSVImporter.parseCSV(from: url)
            switch parseResult {
            case .success(let entries):
                if entries.isEmpty {
                    parseErrorMessage = "The file was read successfully but no valid mood entries were found. Check that the mood column contains values like: good, bad, meh, rad, or awful."
                    step = .error
                } else {
                    parsedEntries = entries
                    duplicateIndices = CSVImporter.findDuplicates(
                        in: entries,
                        existingEntries: Array(existingEntries)
                    )
                    step = .preview
                }
            case .failure(let error):
                switch error {
                case .fileAccessDenied:
                    parseErrorMessage = "Could not access the file. Please try again and grant permission when prompted."
                case .unreadableFile:
                    parseErrorMessage = "The file could not be read. Make sure it is a valid text file with UTF-8 encoding."
                case .invalidFormat:
                    parseErrorMessage = "The file does not have the expected format. It must be a CSV with columns: full_date, time, and mood."
                }
                step = .error
            }
        case .failure:
            break
        }
    }

    private func importEntries(_ entries: [MoodEntry]) {
        for entry in entries {
            modelContext.insert(MoodEntry(moodState: entry.moodState, date: entry.date))
        }
        dismiss()
    }
}

// MARK: - Preview View

private struct CSVPreviewView: View {
    let entries: [MoodEntry]
    let duplicateIndices: Set<Int>
    let onImportAll: () -> Void
    let onImportExcludingDuplicates: () -> Void

    @AppStorage("weekStartDay") private var weekStartDay: Int = 2
    @State private var showDuplicatesOnly = false

    private var duplicateCount: Int { duplicateIndices.count }
    private var uniqueCount: Int { entries.count - duplicateCount }

    private var displayedEntries: [MoodEntry] {
        if showDuplicatesOnly {
            return entries.enumerated()
                .filter { duplicateIndices.contains($0.offset) }
                .map(\.element)
                .sorted { $0.date > $1.date }
        }
        return entries.sorted { $0.date > $1.date }
    }

    private var timelineRows: [TimelineRow] {
        buildTimeline(from: displayedEntries, weekStartDay: weekStartDay)
    }

    var body: some View {
        List {
            // Summary section
            Section {
                VStack(spacing: 8) {
                    Text("\(entries.count) moods found")
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    if duplicateCount > 0 {
                        Text("\(duplicateCount) duplicate\(duplicateCount == 1 ? "" : "s") already in your data")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            // Duplicate filter toggle
            if duplicateCount > 0 {
                Section {
                    Toggle("Show Duplicates Only", isOn: $showDuplicatesOnly)
                        .tint(.orange)
                }
            }

            // Import buttons section
            Section {
                Button {
                    onImportAll()
                } label: {
                    Label(
                        "Import All (\(entries.count) moods)",
                        systemImage: "square.and.arrow.down"
                    )
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
                }

                if duplicateCount > 0 {
                    Button {
                        onImportExcludingDuplicates()
                    } label: {
                        Label(
                            "Exclude Duplicates (\(uniqueCount) moods)",
                            systemImage: "square.and.arrow.down.on.square"
                        )
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    }
                }
            }

            // Mood card preview
            Section {
                if showDuplicatesOnly && duplicateCount == 0 {
                    Text("No duplicates found.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(timelineRows) { row in
                        switch row {
                        case .moodEntry(let entry, let position, let dayLabel, let nextColor):
                            MoodEntryRow(
                                entry: entry,
                                position: position,
                                dayLabel: dayLabel,
                                nextColor: nextColor
                            )
                            .listRowInsets(EdgeInsets(
                                top: position == .sole || position == .first ? 10 : 0,
                                leading: 16,
                                bottom: position == .sole || position == .last ? 10 : 0,
                                trailing: 16
                            ))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        case .monthDivider(let label, _):
                            MonthDividerView(label: label)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
            } header: {
                Text(showDuplicatesOnly ? "Duplicates" : "Preview")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Import Preview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

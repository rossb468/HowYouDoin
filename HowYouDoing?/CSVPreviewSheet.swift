//
//  CSVPreviewSheet.swift
//  HowYouDoing?
//

import SwiftUI
import SwiftData

struct CSVPreviewSheet: View {
    let entries: [MoodEntry]
    let onImport: () -> Void
    let onCancel: () -> Void

    @AppStorage("weekStartDay") private var weekStartDay: Int = 2

    private var timelineRows: [TimelineRow] {
        buildTimeline(from: entries.sorted { $0.date > $1.date }, weekStartDay: weekStartDay)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("\(entries.count) moods found")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

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
            .listStyle(.plain)
            .navigationTitle("Import Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import \(entries.count) Moods") {
                        onImport()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

//
//  CSVImporter.swift
//  HowYouDoing?
//

import Foundation
import SwiftData

struct CSVImporter {

    enum ParseError: Error {
        case fileAccessDenied
        case unreadableFile
        case invalidFormat
    }

    /// Parses a Daylio-format CSV and returns MoodEntry objects without inserting them.
    static func parseCSV(from url: URL) -> Result<[MoodEntry], ParseError> {
        guard url.startAccessingSecurityScopedResource() else {
            return .failure(.fileAccessDenied)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return .failure(.unreadableFile)
        }

        let lines = contents.components(separatedBy: .newlines)
        guard lines.count > 1 else { return .failure(.invalidFormat) }

        let header = parseCSVLine(lines[0])
        guard let fullDateIndex = header.firstIndex(of: "full_date"),
              let timeIndex = header.firstIndex(of: "time"),
              let moodIndex = header.firstIndex(of: "mood") else {
            return .failure(.invalidFormat)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd h:mm a"

        var entries: [MoodEntry] = []

        for line in lines.dropFirst() {
            let fields = parseCSVLine(line)
            guard fields.count > max(fullDateIndex, timeIndex, moodIndex) else { continue }

            let fullDate = fields[fullDateIndex]
            let time = fields[timeIndex]
            let moodString = fields[moodIndex]

            guard let moodState = MoodState.fromCSV(moodString) else { continue }

            let dateString = "\(fullDate) \(time)"
            guard let date = dateFormatter.date(from: dateString) else { continue }

            entries.append(MoodEntry(moodState: moodState, date: date))
        }

        return .success(entries)
    }

    /// Checks whether an imported entry duplicates an existing one.
    /// A duplicate has the same mood state and same date (to the minute).
    static func findDuplicates(
        in importedEntries: [MoodEntry],
        existingEntries: [MoodEntry]
    ) -> Set<Int> {
        let calendar = Calendar.current
        // Build a set of (moodState, dateToMinute) from existing entries
        let existingKeys: Set<String> = Set(existingEntries.map { entry in
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: entry.date
            )
            return "\(entry.moodState.rawValue)-\(components.year!)-\(components.month!)-\(components.day!)-\(components.hour!)-\(components.minute!)"
        })

        var duplicateIndices = Set<Int>()
        for (index, entry) in importedEntries.enumerated() {
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: entry.date
            )
            let key = "\(entry.moodState.rawValue)-\(components.year!)-\(components.month!)-\(components.day!)-\(components.hour!)-\(components.minute!)"
            if existingKeys.contains(key) {
                duplicateIndices.insert(index)
            }
        }

        return duplicateIndices
    }

    /// Simple CSV line parser that handles quoted fields.
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)
        return fields
    }
}

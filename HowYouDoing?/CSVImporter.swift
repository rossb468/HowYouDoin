//
//  CSVImporter.swift
//  HowYouDoing?
//

import Foundation
import SwiftData

struct CSVImporter {
    /// Parses a Daylio-format CSV and inserts MoodEntry objects into the given context.
    /// Returns the number of entries successfully imported.
    @discardableResult
    static func importCSV(from url: URL, into context: ModelContext) -> Int {
        guard url.startAccessingSecurityScopedResource() else { return 0 }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return 0 }

        let lines = contents.components(separatedBy: .newlines)
        guard lines.count > 1 else { return 0 }

        // Parse header to find column indices
        let header = parseCSVLine(lines[0])
        guard let fullDateIndex = header.firstIndex(of: "full_date"),
              let timeIndex = header.firstIndex(of: "time"),
              let moodIndex = header.firstIndex(of: "mood") else {
            return 0
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd h:mm a"

        var importedCount = 0

        for line in lines.dropFirst() {
            let fields = parseCSVLine(line)
            guard fields.count > max(fullDateIndex, timeIndex, moodIndex) else { continue }

            let fullDate = fields[fullDateIndex]
            let time = fields[timeIndex]
            let moodString = fields[moodIndex]

            guard let moodState = MoodState.fromCSV(moodString) else { continue }

            let dateString = "\(fullDate) \(time)"
            guard let date = dateFormatter.date(from: dateString) else { continue }

            let entry = MoodEntry(moodState: moodState, date: date)
            context.insert(entry)
            importedCount += 1
        }

        return importedCount
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

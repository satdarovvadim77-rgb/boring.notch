//
//  LyricsService.swift
//  boringNotch
//
//  Extracted from MusicManager.swift
//

import Foundation

@MainActor
final class LyricsService {
    static let shared = LyricsService()

    private static let lrcRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"\[(\d{1,2}):(\d{2})(?:\.(\d{1,2}))?\]"#
    )

    init() {}

    func fetchLyrics(
        bundleIdentifier: String?,
        title: String,
        artist: String
    ) async -> (plain: String, synced: [(time: Double, text: String)]) {
        if let bundleIdentifier = bundleIdentifier, bundleIdentifier.contains("com.apple.Music") {
            let script = """
            tell application "Music"
                if it is running then
                    if player state is playing or player state is paused then
                        try
                            set l to lyrics of current track
                            if l is missing value then
                                return ""
                            else
                                return l
                            end if
                        on error
                            return ""
                        end try
                    else
                        return ""
                    end if
                else
                    return ""
                end if
            end tell
            """
            if let result = try? await AppleScriptHelper.execute(script),
               let lyricsString = result.stringValue {
                let trimmed = lyricsString.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return (plain: trimmed, synced: [])
                }
            }
        }

        return await fetchLyricsFromWeb(title: title, artist: artist)
    }

    private func normalizedQuery(_ string: String) -> String {
        string
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "\u{FFFD}", with: "")
    }

    private func fetchLyricsFromWeb(
        title: String,
        artist: String
    ) async -> (plain: String, synced: [(time: Double, text: String)]) {
        let cleanTitle = normalizedQuery(title)
        let cleanArtist = normalizedQuery(artist)
        guard let encodedTitle = cleanTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedArtist = cleanArtist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://lrclib.net/api/search?track_name=\(encodedTitle)&artist_name=\(encodedArtist)") else {
            return ("", [])
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let first = jsonArray.first else {
                return ("", [])
            }

            let plain = (first["plainLyrics"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let synced = (first["syncedLyrics"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let resolved = plain.isEmpty ? synced : plain
            let parsedSynced = synced.isEmpty ? [] : parseLRC(synced)
            return (plain: resolved, synced: parsedSynced)
        } catch {
            return ("", [])
        }
    }

    func parseLRC(_ lrc: String) -> [(time: Double, text: String)] {
        guard let regex = Self.lrcRegex else { return [] }
        var result: [(Double, String)] = []

        for lineSub in lrc.split(separator: "\n") {
            let line = String(lineSub)
            let nsLine = line as NSString
            guard let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) else {
                continue
            }
            let minStr = nsLine.substring(with: match.range(at: 1))
            let secStr = nsLine.substring(with: match.range(at: 2))
            let csRange = match.range(at: 3)
            let centiStr = csRange.location != NSNotFound ? nsLine.substring(with: csRange) : "0"
            let minutes = Double(minStr) ?? 0
            let seconds = Double(secStr) ?? 0
            let centis = Double(centiStr) ?? 0
            let time = minutes * 60 + seconds + centis / 100.0
            let textStart = match.range.location + match.range.length
            let text = nsLine.substring(from: textStart).trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                result.append((time, text))
            }
        }
        return result.sorted { $0.0 < $1.0 }
    }

    func lyricLine(
        at elapsed: Double,
        in syncedLyrics: [(time: Double, text: String)],
        fallback: String
    ) -> String {
        guard !syncedLyrics.isEmpty else { return fallback }
        var low = 0
        var high = syncedLyrics.count - 1
        var idx = 0
        while low <= high {
            let mid = (low + high) / 2
            if syncedLyrics[mid].time <= elapsed {
                idx = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return syncedLyrics[idx].text
    }
}

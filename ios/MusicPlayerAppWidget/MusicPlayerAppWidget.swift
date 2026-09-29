//
//  MusicPlayerAppWidget.swift
//  MusicPlayerAppWidget
//
//  Created by Daniil Lipatkin on 05.04.2025.
//

import WidgetKit
import SwiftUI
import AppIntents
import os

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MusicPlayerEntry {
        MusicPlayerEntry(date: Date(), songUri: nil, isPlaying: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (MusicPlayerEntry) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.nt4f04und.sweyer")
        let songUri = userDefaults?.string(forKey: "song")
        let isPlaying = userDefaults?.bool(forKey: "playing") ?? false
        let entry = MusicPlayerEntry(date: Date(), songUri: songUri, isPlaying: isPlaying)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        getSnapshot(in: context) { entry in
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct MusicPlayerEntry: TimelineEntry {
    let date: Date
    let songUri: String?
    let isPlaying: Bool
}

struct MusicPlayerAppWidgetEntryView : View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.nt4f04und.sweyer",
        category: "MusicPlayerAppWidget"
    )

    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            // Album art (if available)
            if let songUri = entry.songUri,
               let url = URL(string: songUri),
               let image = loadImageFromFileURL(url) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Fallback logo when no song or album art is available
                Image("AppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            }
            
            // Control buttons at the bottom
            VStack {
                Spacer()
                
                // Button bar with semi-transparent background (matches Android)
                HStack {
                    // Only show previous button in medium and large widgets
                    if family != .systemSmall {
                        Button(
                            intent: BackgroundIntent(
                                url: URL(string: "sweyer://widget/previous"),
                                appGroup: "group.com.nt4f04und.sweyer"
                            )
                        ) {
                            controlImage(systemName: "backward.fill")
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Play/Pause button
                    Button(
                        intent: BackgroundIntent(
                            url: URL(string: "sweyer://widget/playPause"),
                            appGroup: "group.com.nt4f04und.sweyer"
                        )
                    ) {
                        controlImage(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.plain)

                    // Only show next button in medium and large widgets
                    if family != .systemSmall {
                        Button(
                            intent: BackgroundIntent(
                                url: URL(string: "sweyer://widget/next"),
                                appGroup: "group.com.nt4f04und.sweyer"
                            )
                        ) {
                            controlImage(systemName: "forward.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.76))
                .cornerRadius(8)
                .padding(8)
            }
        }
        .containerBackground(for: .widget) {
            Color(red: 124/255, green: 77/255, blue: 255/255)
        }
        .widgetURL(URL(string: "sweyer://widget"))
    }

    private func controlImage(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20))
            .foregroundColor(.black)
            .frame(width: 48, height: 48)
    }
    
    // Load image from file URL
    func loadImageFromFileURL(_ url: URL) -> UIImage? {
        do {
            let data = try Data(contentsOf: url)
            return UIImage(data: data)
        } catch {
            Self.logger.error("Failed to load album art: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}

struct MusicPlayerAppWidget: Widget {
    static let kind = "MusicPlayerAppWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: Provider()) { entry in
            MusicPlayerAppWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Music Player")
        .description("Control your music playback.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    MusicPlayerAppWidget()
} timeline: {
    MusicPlayerEntry(date: .now, songUri: nil, isPlaying: false)
    MusicPlayerEntry(date: .now, songUri: "file://example", isPlaying: true)
}

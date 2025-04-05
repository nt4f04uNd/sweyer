//
//  MusicPlayerAppWidget.swift
//  MusicPlayerAppWidget
//
//  Created by Daniil Lipatkin on 05.04.2025.
//

import WidgetKit
import SwiftUI
import AppIntents
import home_widget

// Define the intent for widget interactions
@available(iOS 16, *)
struct MusicPlayerAppWidgetIntent: AppIntent {
    static public var title: LocalizedStringResource = "HomeWidget Background Intent"
    
    @Parameter(title: "Widget URI")
    var url: URL?
    
    @Parameter(title: "AppGroup")
    var appGroup: String?
    
    public init() {}
    
    public init(url: URL?, appGroup: String?) {
        self.url = url
        self.appGroup = appGroup
    }
    
    public func perform() async throws -> some IntentResult {
        await HomeWidgetBackgroundWorker.run(url: url, appGroup: appGroup!)
        
        return .result()
    }
}

@available(iOS 16, *)
@available(iOSApplicationExtension, unavailable)
extension MusicPlayerAppWidgetIntent: ForegroundContinuableIntent {}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), songUri: nil, isPlaying: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), songUri: nil, isPlaying: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.nt4f04und.sweyer")
        let songUri = userDefaults?.string(forKey: "song")
        let isPlaying = userDefaults?.bool(forKey: "playing") ?? false
        
        let entry = SimpleEntry(date: Date(), songUri: songUri, isPlaying: isPlaying)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let songUri: String?
    let isPlaying: Bool
}

struct MusicPlayerAppWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            // Background color (matches Android's main color #7C4DFF)
            Color(red: 124/255, green: 77/255, blue: 255/255)
            
            // Album art (if available)
            if let songUri = entry.songUri, let url = URL(string: songUri) {
                if let image = loadImageFromFileURL(url) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Fallback logo when no album art
                    Image("AppIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
            } else {
                // Fallback logo when no song
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
                        if #available(iOS 16, *) {
                            Button(
                                intent: MusicPlayerAppWidgetIntent(
                                    url: URL(string: "sweyer://widget/previous"),
                                    appGroup: "group.com.nt4f04und.sweyer"
                                )
                            ) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                                    .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(action: {
                                playPreviousTrack()
                            }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                                    .frame(width: 48, height: 48)
                            }
                        }
                    }
                    
                    // Play/Pause button
                    if #available(iOS 16, *) {
                        Button(
                            intent: MusicPlayerAppWidgetIntent(
                                url: URL(string: "sweyer://widget/playPause"),
                                appGroup: "group.com.nt4f04und.sweyer"
                            )
                        ) {
                            Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: {
                            togglePlayPause()
                        }) {
                            Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                                .frame(width: 48, height: 48)
                        }
                    }
                    
                    // Only show next button in medium and large widgets
                    if family != .systemSmall {
                        if #available(iOS 16, *) {
                            Button(
                                intent: MusicPlayerAppWidgetIntent(
                                    url: URL(string: "sweyer://widget/next"),
                                    appGroup: "group.com.nt4f04und.sweyer"
                                )
                            ) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                                    .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(action: {
                                playNextTrack()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                                    .frame(width: 48, height: 48)
                            }
                        }
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.76))
                .cornerRadius(8)
                .padding(8)
            }
        }
        .cornerRadius(16)
        .widgetURL(URL(string: "sweyer://widget"))
    }
    
    // Load image from file URL
    func loadImageFromFileURL(_ url: URL) -> UIImage? {
        do {
            let data = try Data(contentsOf: url)
            return UIImage(data: data)
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }
    
    // Media control functions
    func togglePlayPause() {
        widgetPerformAction(action: "playPause")
    }
    
    func playNextTrack() {
        widgetPerformAction(action: "next")
    }
    
    func playPreviousTrack() {
        widgetPerformAction(action: "previous")
    }
    
    func widgetPerformAction(action: String) {
        if let url = URL(string: "sweyer://widget/\(action)") {
            // Use UserDefaults method for all iOS versions
            openURL(url)
        }
    }
    
    func openURL(_ url: URL) {
        let userDefaults = UserDefaults(suiteName: "group.com.nt4f04und.sweyer")
        userDefaults?.set(url.absoluteString, forKey: "widgetAction")
        userDefaults?.synchronize()
        
        WidgetCenter.shared.reloadTimelines(ofKind: "MusicPlayerAppWidget")
    }
}

struct MusicPlayerAppWidget: Widget {
    let kind: String = "MusicPlayerAppWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
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
    SimpleEntry(date: .now, songUri: nil, isPlaying: false)
    SimpleEntry(date: .now, songUri: "file://example", isPlaying: true)
}

import Foundation

/// Configuration for HelpKit help screen
struct BerlinTransportMapHelpTopicsConfiguration {
    static let allTopics = [
        HelpTopic(
            section: "Getting Started",
            title: "Understanding the Map View",
            icon: "map.fill",
            content: "The map shows real-time positions of Berlin's public transport vehicles. You can see S-Bahn, U-Bahn, trams, and buses with their current locations and line numbers.",
            keywords: ["map", "view", "transport", "vehicles"]
        ),
        HelpTopic(
            section: "Getting Started",
            title: "Finding Transit Stops",
            icon: "location.fill",
            content: "Transit stops are marked on the map. Tap any stop marker to see upcoming departures for that station. The map will automatically load nearby stops as you zoom in.",
            keywords: ["stop", "station", "find", "location"]
        ),
        HelpTopic(
            section: "Live Tracking",
            title: "Tracking Live Vehicles",
            icon: "tram.fill",
            content: "Colored markers show live vehicles on the map. Each color represents a different transport type (red for S-Bahn, green for U-Bahn, etc.). Tap a vehicle to see more details including its route and destination.",
            keywords: ["vehicle", "tracking", "live", "position"]
        ),
        HelpTopic(
            section: "Live Tracking",
            title: "Viewing Vehicle Routes",
            icon: "arrow.triangle.2.circlepath",
            content: "When you tap on a vehicle and view its details, you can tap 'Show Route' to see the full line route displayed on the map. This helps you understand the vehicle's complete path through Berlin.",
            keywords: ["route", "line", "path", "direction"]
        ),
        HelpTopic(
            section: "Departures",
            title: "Checking Departures",
            icon: "clock.fill",
            content: "Tap any stop to see its departures. The list shows upcoming vehicles with their line numbers, destinations, and departure times. Real-time updates show you exactly when vehicles will arrive.",
            keywords: ["departure", "schedule", "timetable", "next"]
        ),
        HelpTopic(
            section: "Departures",
            title: "Understanding Delay Information",
            icon: "exclamationmark.circle.fill",
            content: "Some departures may show delay information in real-time. A red indicator means there's a delay, and the details will show the estimated delay in minutes.",
            keywords: ["delay", "late", "wait time", "alert"]
        ),
        HelpTopic(
            section: "Navigation",
            title: "Centering on Your Location",
            icon: "location.north.fill",
            content: "The location button in the bottom right corner allows you to center the map on your current position. You'll need to grant the app location permission in Settings first.",
            keywords: ["location", "center", "gps", "position"]
        ),
        HelpTopic(
            section: "Navigation",
            title: "Zooming and Panning",
            icon: "magnifyingglass.circle.fill",
            content: "Use pinch-to-zoom to zoom in and out of the map. You can also use two fingers or double-tap to zoom in. As you zoom in closer, more detailed stop and vehicle information appears.",
            keywords: ["zoom", "pan", "navigate", "scale"]
        ),
        HelpTopic(
            section: "Features",
            title: "Real-Time Updates",
            icon: "arrow.clockwise.circle.fill",
            content: "The map updates in real-time to show current vehicle positions. Updates happen automatically - you don't need to manually refresh. The app continues updating even when you're viewing departures.",
            keywords: ["update", "real-time", "live", "refresh"]
        ),
        HelpTopic(
            section: "Troubleshooting",
            title: "Map Not Loading",
            icon: "exclamationmark.triangle.fill",
            content: "If the map won't load:\n1. Check your internet connection\n2. Make sure location permission is granted (for user location)\n3. Try closing and reopening the app\n4. Check if BVG services are available",
            keywords: ["error", "loading", "map", "blank"]
        ),
        HelpTopic(
            section: "Troubleshooting",
            title: "No Vehicles Showing",
            icon: "magnifyingglass.fill",
            content: "If you don't see any vehicles:\n1. Make sure you're zoomed in enough to see details\n2. Check that you're viewing a transit area with active service\n3. Some vehicles may not be available during off-peak hours\n4. Try refreshing by reopening the app",
            keywords: ["vehicles", "missing", "not", "showing"]
        ),
        HelpTopic(
            section: "Troubleshooting",
            title: "Departures Not Updating",
            icon: "sync.circle.fill",
            content: "If departures seem outdated:\n1. Close and reopen the departures sheet\n2. Try tapping a different stop\n3. Check your internet connection\n4. The data source (BVG) might be experiencing delays",
            keywords: ["departures", "update", "stale", "old"]
        ),
        HelpTopic(
            section: "Privacy & Data",
            title: "Location Data Privacy",
            icon: "lock.shield.fill",
            content: "This app only uses your location when you explicitly tap the location button. Your location is not stored or sent to any server. All map data comes from public BVG APIs.",
            keywords: ["privacy", "location", "data", "security"]
        )
    ]
}

struct HelpTopic: Identifiable {
    let id = UUID()
    let section: String
    let title: String
    let icon: String
    let content: String
    let keywords: [String]
}

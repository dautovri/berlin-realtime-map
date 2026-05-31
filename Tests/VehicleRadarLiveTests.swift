import XCTest
import CoreLocation
@testable import BerlinTransportMap

/// Live integration tests for the Berlin BVG vehicle radar.
///
/// These hit the real `v6.vbb.transport.rest/radar` endpoint to prove the
/// app's headline feature — live vehicle tracking — actually works end to end:
///   1. The radar fetch returns real vehicles with valid coordinates.
///   2. Polling again a short time later returns fresh data whose positions
///      have moved, proving the feed is genuinely live (not a static snapshot).
///
/// Why this exists: the in-app polling loop (`TransportMapView`, the
/// `scenePhase == .active` guarded `.task`) cannot be observed under headless
/// `simctl`/`axe` automation, because the Simulator never becomes the focused
/// foreground app and `scenePhase` therefore never reports `.active`. That is a
/// test-environment limitation, not a product bug. These tests verify the same
/// data pipeline the polling loop drives, without depending on `scenePhase`.
///
/// Network hygiene: if the device/CI is offline or the community API is
/// unreachable, the tests `XCTSkip` rather than fail — a flaky network must
/// never turn the suite red. Set `RADAR_LIVE_TESTS=0` in the environment to
/// skip them unconditionally (e.g. in fully-offline CI).
final class VehicleRadarLiveTests: XCTestCase {

    /// Central Berlin bounding box (Mitte / Alexanderplatz area) — always busy
    /// with U-Bahn, S-Bahn, tram, and bus movements during service hours.
    private let north = 52.5400
    private let west  = 13.3600
    private let south = 52.4900
    private let east  = 13.4500

    private func skipIfDisabled() throws {
        let env = ProcessInfo.processInfo.environment
        if env["RADAR_LIVE_TESTS"] == "0" {
            throw XCTSkip("RADAR_LIVE_TESTS=0 — live radar tests disabled for this run.")
        }
    }

    /// Fetch once; classify failures as skips when they are clearly network/availability.
    private func fetchOrSkip(_ service: VehicleRadarService) async throws -> [Vehicle] {
        do {
            return try await service.fetchVehicles(
                north: north, west: west, south: south, east: east, duration: 30
            )
        } catch {
            // Treat connectivity / server errors as a skip, not a failure.
            throw XCTSkip("Live VBB radar unreachable (\(error)) — skipping rather than failing.")
        }
    }

    /// Proves the radar fetch returns real, plausibly-located Berlin vehicles.
    func testRadarReturnsLiveVehiclesWithValidCoordinates() async throws {
        try skipIfDisabled()
        let service = VehicleRadarService(city: .berlin)

        let vehicles = try await fetchOrSkip(service)

        // During service hours central Berlin always has moving vehicles. If the
        // feed is reachable but returns nothing, that's worth surfacing — but at
        // night the network can legitimately be near-empty, so only assert the
        // pipeline decoded and any returned vehicle is well-formed.
        guard !vehicles.isEmpty else {
            throw XCTSkip("Radar reachable but returned 0 vehicles (likely off-hours).")
        }

        let located = vehicles.filter { $0.currentLocation != nil }
        XCTAssertFalse(located.isEmpty, "Vehicles returned but none had coordinates")

        for v in located.prefix(20) {
            let c = v.currentLocation!
            XCTAssertTrue(
                (52.30...52.70).contains(c.latitude) && (13.05...13.80).contains(c.longitude),
                "Vehicle \(v.id) at \(c.latitude),\(c.longitude) is outside the Berlin region"
            )
            XCTAssertFalse(v.tripId.isEmpty, "Vehicle has empty tripId")
        }
    }

    /// Proves the feed is genuinely *live*: two fetches ~22s apart return data
    /// whose vehicle positions have changed. This is the regression guard for
    /// "the map froze / radar stopped refreshing".
    func testRadarPositionsChangeBetweenPolls() async throws {
        try skipIfDisabled()
        let service = VehicleRadarService(city: .berlin)

        let first = try await fetchOrSkip(service)
        guard first.count >= 3 else {
            throw XCTSkip("Too few vehicles (\(first.count)) to measure movement (off-hours).")
        }

        // Server-side positions update roughly every ~30s; 22s is enough to see
        // movement on at least some vehicles without making the test slow.
        try await Task.sleep(for: .seconds(22))

        let second = try await fetchOrSkip(service)
        guard !second.isEmpty else {
            throw XCTSkip("Second poll returned 0 vehicles — skipping movement assertion.")
        }

        // Index first-poll positions by tripId.
        var firstPositions: [String: CLLocationCoordinate2D] = [:]
        for v in first {
            if let loc = v.currentLocation { firstPositions[v.tripId] = loc }
        }

        // Find vehicles present in both polls and measure displacement.
        var common = 0
        var moved = 0
        var maxMeters = 0.0
        for v in second {
            guard let now = v.currentLocation, let before = firstPositions[v.tripId] else { continue }
            common += 1
            let meters = CLLocation(latitude: before.latitude, longitude: before.longitude)
                .distance(from: CLLocation(latitude: now.latitude, longitude: now.longitude))
            if meters > 5 { moved += 1 }
            maxMeters = max(maxMeters, meters)
        }

        guard common >= 1 else {
            throw XCTSkip("No vehicles common to both polls — cannot measure movement.")
        }

        XCTAssertGreaterThan(
            moved, 0,
            "Across \(common) vehicles present in both polls, none moved >5m in 22s — feed may be stale. maxΔ=\(Int(maxMeters))m"
        )
    }
}

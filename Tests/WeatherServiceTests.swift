import XCTest
@testable import BerlinTransportMap

final class TransportModelBehaviorTests: XCTestCase {

    func testVehicleNextStopSkipsDepartureOnlyCurrentStop() throws {
        let vehicle = Vehicle(
            tripId: "trip-3",
            line: nil,
            direction: "Zoologischer Garten",
            location: VehicleLocation(latitude: 52.5, longitude: 13.4),
            when: nil,
            nextStopovers: [
                VehicleStopoverEntry(
                    stop: VehicleStopInfo(
                        id: "current-stop",
                        name: "Current Stop",
                        location: VehicleLocation(latitude: 52.5001, longitude: 13.4001)
                    ),
                    arrival: nil,
                    plannedArrival: nil,
                    departure: "2099-03-20T11:31:00+01:00",
                    plannedDeparture: "2099-03-20T11:31:00+01:00"
                ),
                VehicleStopoverEntry(
                    stop: VehicleStopInfo(
                        id: "next-stop",
                        name: "Next Stop",
                        location: VehicleLocation(latitude: 52.5015, longitude: 13.4050)
                    ),
                    arrival: "2099-03-20T11:37:00+01:00",
                    plannedArrival: "2099-03-20T11:37:00+01:00",
                    departure: "2099-03-20T11:37:00+01:00",
                    plannedDeparture: "2099-03-20T11:37:00+01:00"
                )
            ]
        )

        let coordinate = try XCTUnwrap(vehicle.nextStopCoordinate)

        XCTAssertEqual(coordinate.latitude, 52.5015, accuracy: 0.0001)
        XCTAssertEqual(coordinate.longitude, 13.4050, accuracy: 0.0001)
        XCTAssertNotNil(vehicle.nextStopArrival)
    }

    func testVehicleNextStopFallsBackToDepartureWhenArrivalMissing() throws {
        let vehicle = Vehicle(
            tripId: "trip-4",
            line: nil,
            direction: "Leopoldplatz",
            location: VehicleLocation(latitude: 52.5, longitude: 13.4),
            when: nil,
            nextStopovers: [
                VehicleStopoverEntry(
                    stop: VehicleStopInfo(
                        id: "future-stop",
                        name: "Future Stop",
                        location: VehicleLocation(latitude: 52.5009, longitude: 13.4012)
                    ),
                    arrival: nil,
                    plannedArrival: nil,
                    departure: "2099-03-20T11:45:00+01:00",
                    plannedDeparture: "2099-03-20T11:45:00+01:00"
                )
            ]
        )

        let coordinate = try XCTUnwrap(vehicle.nextStopCoordinate)

        XCTAssertEqual(coordinate.latitude, 52.5009, accuracy: 0.0001)
        XCTAssertEqual(coordinate.longitude, 13.4012, accuracy: 0.0001)
        XCTAssertNotNil(vehicle.nextStopArrival)
    }

    func testVbbStopIdParsesLIdentifierFormat() {
        let stop = TransportStop(
            id: "1|2345|L=900000100003@123",
            name: "Alexanderplatz",
            latitude: 52.5219,
            longitude: 13.4132
        )

        XCTAssertEqual(stop.vbbStopId, "900000100003")
    }

    func testVbbStopIdParsesColonSeparatedFormat() {
        let stop = TransportStop(
            id: "de:11000:900100003",
            name: "Alexanderplatz",
            latitude: 52.5219,
            longitude: 13.4132
        )

        XCTAssertEqual(stop.vbbStopId, "900100003")
    }

    func testTransportProductUnknownFallbackUsesNeutralPresentation() {
        XCTAssertEqual(TransportProduct.unknown.displayName, "Other")
        XCTAssertEqual(TransportProduct.unknown.color, "#666666")
    }

    func testRestDepartureDelayMinutesConvertsSeconds() {
        let departure = RESTDeparture(
            tripId: "trip-1",
            stop: nil,
            when: nil,
            plannedWhen: "2026-03-19T12:00:00+01:00",
            delay: 180,
            platform: "1",
            direction: "Hermannstraße",
            line: nil,
            cancelled: nil
        )

        XCTAssertEqual(departure.delayMinutes, 3)
    }

    func testRestDepartureUsesPlannedTimeWhenRealtimeIsMissing() {
        let departure = RESTDeparture(
            tripId: "trip-2",
            stop: nil,
            when: nil,
            plannedWhen: "2026-03-19T12:00:00+01:00",
            delay: nil,
            platform: nil,
            direction: "Pankow",
            line: nil,
            cancelled: nil
        )

        XCTAssertNotNil(departure.displayTime)
    }
}
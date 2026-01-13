import Testing
@testable import BerlinTransportMapFeature

@Test("vbbStopId extracts L=... from HAFAS format")
func vbbStopIdExtractsLParam() {
    let stop = TransportStop(
        id: "A=1@O=Station Name@X=13404953@Y=52520008@U=86@L=900100003@",
        name: "Station Name",
        place: "Berlin",
        latitude: 52.52,
        longitude: 13.40,
        products: []
    )

    #expect(stop.vbbStopId == "900100003")
}

@Test("vbbStopId extracts L=... even without trailing @")
func vbbStopIdExtractsLParamWithoutAt() {
    let stop = TransportStop(
        id: "A=1@O=Station Name@L=900140016",
        name: "Station Name",
        place: nil,
        latitude: 0,
        longitude: 0,
        products: []
    )

    #expect(stop.vbbStopId == "900140016")
}

@Test("vbbStopId extracts last component for colon-separated IDs")
func vbbStopIdExtractsFromColonFormat() {
    let stop = TransportStop(
        id: "de:11000:900140016",
        name: "Station Name",
        place: nil,
        latitude: 0,
        longitude: 0,
        products: []
    )

    #expect(stop.vbbStopId == "900140016")
}

@Test("vbbStopId returns ID as-is when no known encoding")
func vbbStopIdReturnsAsIs() {
    let stop = TransportStop(
        id: "900140016",
        name: "Station Name",
        place: nil,
        latitude: 0,
        longitude: 0,
        products: []
    )

    #expect(stop.vbbStopId == "900140016")
}

@Test("TransportError descriptions are stable")
func transportErrorDescriptions() {
    #expect(TransportError.invalidStation.errorDescription == "Invalid station")
    #expect(TransportError.invalidLocation.errorDescription == "Invalid location")
    #expect(TransportError.noData.errorDescription == "No data available")
    #expect(TransportError.networkError("boom").errorDescription == "Network error: boom")
}

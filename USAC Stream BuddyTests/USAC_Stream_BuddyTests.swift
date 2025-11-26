import Foundation
import Testing

@testable import USAC_Stream_Buddy

extension CategoryResultsViewModel {
    @usableFromInline
    func _test_handleBoulderingResponse(data: Data) async throws -> [OnWall] {
        try await self.handleBoulderingResponse(data: data)
    }

    @usableFromInline
    func _test_handleLeadResponse(data: Data) async throws -> [OnWall] {
        try await self.handleLeadResponse(data: data)
    }
}

private final class _BundleToken {}

private func jsonData(resource: String) -> Data {
    let bundle = Bundle(for: _BundleToken.self)
    guard
        let url = bundle.url(
            forResource: resource,
            withExtension: "json"
        )
    else {
        fatalError(
            "Missing test fixture: boulder-response.json in USAC Stream BuddyTests target"
        )
    }
    do {
        return try Data(contentsOf: url)
    } catch {
        fatalError("Failed to load boulder-response.json: \(error)")
    }
}

private func makeViewModel(routes: [Int]) -> CategoryResultsViewModel {
    let routes: [Route] =
        routes
        .enumerated()
        .map { index, id in
            Route(id: id, name: String(index + 1), startListURL: "")
        }
    let round = CategoryRound(
        id: 4586,
        discipline: .boulder,
        round: .final,
        status: "active",
        category: "F17",
        routes: routes
    )
    return CategoryResultsViewModel(categoryRound: round)
}

@Suite
struct USAC_Stream_BuddyTests {

    @Test(
        "handleBoulderingResponse returns expected OnWall entries for active athletes"
    )
    func testHandleBoulderingResponse() async throws {
        let vm = makeViewModel(routes: [
            113328, 113329, 113330, 113331, 113332, 113338, 113339, 113342,
        ])
        let onWall = try await vm._test_handleBoulderingResponse(
            data: jsonData(resource: "boulder-response-1")
        )
        let dict: [String: String] = Dictionary(
            uniqueKeysWithValues: onWall.map { ($0.route, $0.name) }
        )
        #expect(dict["F174"] == "#101 Rexeisen Anna")
        #expect(dict["F173"] == "#102 KNIGHTS Penny")
        #expect(dict["F172"] == "#103 WACHTER Olivia")
        #expect(dict["F171"] == "#104 MCINTOSH Lauren")
    }

    @Test(
        "handleLeadResponse returns expected OnWall entries for active athletes"
    )
    func testLeadBoulderingResponse() async throws {
        let vm = makeViewModel(routes: [65681, 65682, 65683])
        let onWall = try await vm._test_handleLeadResponse(
            data: jsonData(resource: "lead-response-1")
        )
        let dict: [String: String] = Dictionary(
            uniqueKeysWithValues: onWall.map { ($0.route, $0.name) }
        )

        // These haven't started yet
        #expect(dict["F171"] == "#1403 ROSS Eliza")
        #expect(dict["F172"] == "#1415 CHOI Katherine")
    }
}

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

private func makeViewModel(
    routes: [Int],
    category: String,
    discipline: Discipline
) -> CategoryResultsViewModel {
    let routes: [Route] =
        routes
        .enumerated()
        .map { index, id in
            Route(id: id, name: String(index + 1), startListURL: "")
        }
    let round = CategoryRound(
        id: 4586,
        discipline: discipline,
        round: .final,
        status: "active",
        category: category,
        routes: routes
    )
    return CategoryResultsViewModel(categoryRound: round)
}

@Suite
struct USAC_Stream_BuddyTests {

    @Test(
        "handleBoulderingResponse returns expected OnWall entries for active athletes"
    )
    @MainActor
    func testHandleBoulderingResponse() async throws {
        let vm = makeViewModel(
            routes: [
                113328, 113329, 113330, 113331, 113332, 113338, 113339, 113342,
            ],
            category: "F17",
            discipline: .boulder
        )
        let onWall = try await vm._test_handleBoulderingResponse(
            data: jsonData(resource: "boulder-response-1")
        )
        let dict: [String: OnWall] = Dictionary(
            uniqueKeysWithValues: onWall.map { ($0.route, $0) }
        )
        #expect(dict["F171"]?.name == "#104 MCINTOSH Lauren")
        #expect(dict["F172"]?.name == "#103 WACHTER Olivia")
        #expect(dict["F173"]?.name == "#102 KNIGHTS Penny")
        #expect(dict["F174"]?.name == "#101 Rexeisen Anna")
        #expect(dict["F175"]?.name == "#101 REXEISEN Anna")
        
        // Now we check the scores
        #expect(dict["F171"]?.score == "LPPPPPPP")
        #expect(dict["F172"]?.score == "0ZPPPPPP")
        #expect(dict["F173"]?.score == "ZTZPPPPP")
        #expect(dict["F174"]?.score == "TTZLPPPP")
        #expect(dict["F175"]?.score == "TTZLPPPP")
    }

    @Test(
        "handleLeadResponse returns expected OnWall entries for active athletes real event"
    )
    @MainActor
    func testLeadRealResponse() async throws {
        let vm = makeViewModel(
            routes: [65681, 65682, 65683],
            category: "F17",
            discipline: .lead
        )
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

    @Test(
        "handleLeadResponse test event"
    )
    @MainActor
    func testLeadTestResponse() async throws {
        let vm = makeViewModel(
            routes: [
                68910, 68911, 68912,
            ],
            category: "M19",
            discipline: .lead
        )
        let onWall = try await vm._test_handleLeadResponse(
            data: jsonData(resource: "lead-response-test-event")
        )
        let dict: [String: String] = Dictionary(
            uniqueKeysWithValues: onWall.map { ($0.route, $0.name) }
        )
        #expect(dict["M191"] == "#2 KRAJNIK Logan")
        #expect(dict["M192"] == "#3 PHAM Owen")
        #expect(dict["M193"] == "#3 PHAM Owen")
    }
}


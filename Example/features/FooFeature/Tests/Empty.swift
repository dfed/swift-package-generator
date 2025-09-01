import XCTest

final class ExampleTests: XCTestCase {
	func test_weakIsolated() async throws {
		actor TestActor {}
		var testActor: TestActor? = TestActor()
		let task: Task<Void, Error> = if let testActor {
			Task {
				try await receiveActor(testActor)
			}
		} else {
			Task {}
		}
		testActor = nil
		try await task.value
	}

	func receiveActor(_: isolated Actor) async throws {
		//        weak var weakActor = actor
		try await Task.sleep(nanoseconds: 1_000_000_000)
		//        XCTAssertNil(weakActor)
	}
}

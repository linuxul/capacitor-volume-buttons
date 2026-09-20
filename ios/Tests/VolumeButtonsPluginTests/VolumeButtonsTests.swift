import XCTest
@testable import VolumeButtonsPlugin

class VolumeButtonsTests: XCTestCase {

    func testBridgedMethods() {
        let plugin = VolumeButtonsPlugin()

        XCTAssertEqual(plugin.jsName, "VolumeButtons")
        XCTAssertEqual(plugin.pluginMethods.map { $0.name }, ["isWatching", "watchVolume", "clearWatch"])
        XCTAssertEqual(plugin.pluginMethods.map { $0.returnType }, [.promise, .callback, .promise])
    }
}

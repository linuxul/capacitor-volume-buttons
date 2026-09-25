import XCTest
import Capacitor
@testable import VolumeButtonsPlugin

class VolumeButtonsTests: XCTestCase {

    func testBridgedMethods() {
        let plugin = VolumeButtonsPlugin()

        XCTAssertEqual(plugin.jsName, "VolumeButtons")
        XCTAssertEqual(plugin.pluginMethods.map { $0.name }, ["isWatching", "watchVolume", "clearWatch"])
        XCTAssertEqual(plugin.pluginMethods.map { $0.returnType }, [.promise, .callback, .promise])
    }

    func testIsWatchingBeforeLoadThrows() {
        assertThrows("Volume handler has not been initialized yet") { try VolumeButtonsPlugin().isWatching($0) }
    }

    func testIsWatchingAfterLoadResolvesFalse() throws {
        let plugin = VolumeButtonsPlugin()
        plugin.load()
        var value: Bool?
        let call = CAPPluginCall(callbackId: "test", methodName: "isWatching", options: [:], success: { result, _ in
            value = result.data?["value"] as? Bool
        }, error: { _ in
            XCTFail("isWatching must resolve")
        })
        try plugin.isWatching(call)
        XCTAssertEqual(value, false)
    }

    func testClearWatchWithoutAWatchThrows() {
        let plugin = VolumeButtonsPlugin()
        plugin.load()
        assertThrows("Volume buttons has not been been watched") { try plugin.clearWatch($0) }
    }

    private func assertThrows(_ message: String, line: UInt = #line, _ method: (CAPPluginCall) throws -> Void) {
        let call = CAPPluginCall(callbackId: "test", methodName: "test", options: [:], success: { _, _ in
            XCTFail("must not resolve", line: line)
        }, error: { _ in
            XCTFail("answers by throwing", line: line)
        })
        XCTAssertThrowsError(try method(call), line: line) { error in
            XCTAssertEqual((error as? CAPPluginError)?.message, message, line: line)
            XCTAssertNil((error as? CAPPluginError)?.code, line: line)
        }
    }
}

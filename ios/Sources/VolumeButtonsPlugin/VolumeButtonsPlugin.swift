//
//  VolumeButtonsPlugin.swift
//
//  Created by Alex Ryltsov on 12/26/23.
//

import Foundation
import Capacitor
import MediaPlayer

@objc(VolumeButtonsPlugin)
public class VolumeButtonsPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "VolumeButtonsPlugin"
    public let jsName = "VolumeButtons"
    // The methods stay synchronous: watchVolume keeps its call alive, and the bridge queue keeps watchVolume and
    // clearWatch in the order of the calls.
    public let pluginMethods: [CAPPluginMethod] = [
        .promise("isWatching", VolumeButtonsPlugin.isWatching),
        .callback("watchVolume", VolumeButtonsPlugin.watchVolume),
        .promise("clearWatch", VolumeButtonsPlugin.clearWatch)
    ]

    private var savedCallID: String?
    private var volumeHandler: VolumeButtonsHandler!

    override public func load() {
        volumeHandler = VolumeButtonsHandler()
    }

    func isWatching(_ call: CAPPluginCall) throws {

        guard volumeHandler != nil else {
            throw CAPPluginError("Volume handler has not been initialized yet")
        }

        call.resolve([
            "value": volumeHandler.isStarted
        ])
    }

    func watchVolume(_ call: CAPPluginCall) throws {

        guard !volumeHandler.isStarted else {
            throw CAPPluginError("Volume buttons has already been watched")
        }

        let disableSystemVolumeHandler = call.getBool("disableSystemVolumeHandler", false)

        call.keepAlive = true
        savedCallID = call.callbackId

        volumeHandler.startHandler(disableSystemVolumeHandler)

        let handlerBlock: VolumeButtonBlock = { [weak self] direction in
            if let self, let id = self.savedCallID, let savedCall = self.bridge?.savedCall(withID: id) {
                var jsObject = JSObject()
                jsObject["direction"] = direction
                savedCall.resolve(jsObject)
            }
        }
        volumeHandler.handlerBlock = handlerBlock

    }

    func clearWatch(_ call: CAPPluginCall) throws {

        guard volumeHandler.isStarted else {
            throw CAPPluginError("Volume buttons has not been been watched")
        }

        if let id = savedCallID {
            volumeHandler.stopHandler()
            if let savedCall = bridge?.savedCall(withID: id) {
                bridge?.releaseCall(savedCall)
            }
            savedCallID = nil
            call.resolve()
        }

    }

}

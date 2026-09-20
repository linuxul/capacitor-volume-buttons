/*
 * @capacitor-community/volume-buttons plugin
 *
 * This software contains code derived from or inspired by the following sources:
 *
 * 1. Original code from the CapacitorVolumeButtonsPlugin.java
 *    - Original code URL: https://github.com/thiagobrez/capacitor-volume-buttons
 *    - Original code authors: Thiago Brezinski
 *
 * 2. Modifications made by Alex Ryltsov to the original code:
 *    - changed to use watchVolume/clearWatch plugin methods instead of the load method to setup/tear down the hardware volume buttons events listener
 *
 */

package com.ryltsov.alex.plugins.volume.buttons

import android.view.KeyEvent
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin

@CapacitorPlugin(name = "VolumeButtons")
public class VolumeButtonsPlugin : Plugin() {
    private var savedCall: PluginCall? = null
    private var isStarted = false

    private var suppressVolumeIndicator = false

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    public fun isWatching(call: PluginCall) {
        val ret = JSObject()
        ret.put("value", isStarted)
        call.resolve(ret)
    }

    @PluginMethod(returnType = PluginMethod.RETURN_CALLBACK)
    public fun watchVolume(call: PluginCall) {
        if (isStarted) {
            call.reject("Volume buttons has already been watched")
            return
        }

        suppressVolumeIndicator = call.getBoolean("suppressVolumeIndicator", true) == true

        call.keepAlive = true
        savedCall = call

        bridge.webView.setOnKeyListener { _, keyCode, event ->
            if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
                val isKeyUp = event.action == KeyEvent.ACTION_UP
                if (isKeyUp) {
                    val ret = JSObject()
                    ret.put("direction", if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) "up" else "down")
                    call.resolve(ret)
                }
                // NOTE: we return suppressVolumeIndicator value for volume buttons event actions only
                // therefore, when suppressVolumeIndicator is true, for a key event that typically controls the system volume,
                // the system volume indicator will not be displayed by default.
                // This is because returning true from onKey() indicates that your application has consumed
                // the key event and no system-level action should occur in response to that event.
                return@setOnKeyListener suppressVolumeIndicator
            }

            false
        }

        isStarted = true
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    public fun clearWatch(call: PluginCall) {
        if (!isStarted) {
            call.reject("Volume buttons has not been been watched")
            return
        }

        bridge.webView.setOnKeyListener(null)

        savedCall?.let { bridge.releaseCall(it) }
        savedCall = null

        isStarted = false

        call.resolve()
    }
}

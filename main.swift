import Foundation
import IOKit.hid

/*
codeList
0x808080800F00, No Input

0x808080800100, Top Arrow
0x808080800300, Right Arrow
0x808080800500, Bottom Arrow
0x808080800700, Left Arrow

0x808080801F00, Top Button
0x808080802F00, Right Button
0x808080800600, Bottom Button
0x808080808F00, Left Button

0x808080800F04, Back Left Top Button
0x808080800F01, Back Left Bottom Button

0x808080800F08, Back Right Top Button
0x808080800F02, Back Right Bottom Button
*/

/*
key
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h


*/

//キーダウン
func keyboardKeyDown(key: CGKeyCode) {
    let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
    let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true) 
    event?.post(tap: CGEventTapLocation.cghidEventTap)
}

//キーアップ 
func keyboardKeyUp(key: CGKeyCode) {
    let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
    let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
    event?.post(tap: CGEventTapLocation.cghidEventTap)
}

let manager = IOHIDManagerCreate(kCFAllocatorDefault, 0)
let matching = [kIOHIDVendorIDKey: 0x1dd8, kIOHIDProductIDKey: 0x000f]

// ID検索
IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary?)

var beforeKey: CGKeyCode = 0

// コネクション確率
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

// コネクション確立時のコールバック
let matchingCallback: IOHIDDeviceCallback = {context, result, sender, device in

    // コネクション確率
    IOHIDDeviceOpen(device, 0)

    // クライアント側のrun loopにデバイスを登録
    // IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

    let reportCallback : IOHIDReportCallback = { _, _, _, _, _, report, reportLength in
        let data = Data(bytes: report, count: reportLength)
        let code_str = data.map { String(format: "%02x", $0) }.joined()
        let code = Int64(code_str, radix: 16)!
        // print(difference)
        // print(String(format: "0x%llX", difference))

        var key: CGKeyCode = 100
        var haveKey = true

        if (code == 0x808080800100) { // Top Arrow
            // keyboardKeyDown(key: 0x0D) // w
            key = 0x0D // w
            // keyboardKeyUp(key: 0x0D)
        } else if (code == 0x808080800300) { // Right Arrow 
            // keyboardKeyDown(key: 0x02) // d
            key = 0x02
            // keyboardKeyUp(key: 0x02)            
        } else if (code == 0x808080800500) { // Bottom Arrow
            // keyboardKeyDown(key: 0x01) // s
            key = 0x01
            // keyboardKeyUp(key: 0x01)              
        } else if (code == 0x808080800700) { // Left Arrow
            // keyboardKeyDown(key: 0x00) // a
            // keyboardKeyUp(key: 0x00)    
            key = 0x00            
        } else {
            haveKey = false
        }

        if (haveKey) {
            // print(beforeKey, key)
            if (beforeKey == key) {
                print("donw", beforeKey)
                keyboardKeyDown(key: beforeKey)
            }
        } else {
            if (beforeKey != key) {
                print("up", code, beforeKey, key)
                keyboardKeyUp(key: beforeKey)  
            }
        }

        beforeKey = key
        
    }

    let report = UnsafeMutablePointer<UInt8>.allocate(capacity: 6)
    IOHIDDeviceRegisterInputReportCallback(device, report, 6, reportCallback, nil)
}

IOHIDManagerRegisterDeviceMatchingCallback(manager, matchingCallback, nil)

CFRunLoopRun()

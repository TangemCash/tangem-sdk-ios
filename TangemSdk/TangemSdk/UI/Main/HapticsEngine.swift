//
//  HapticsEngine.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import CoreHaptics
import UIKit
import AVFoundation

class HapticsEngine {
    private var engine: CHHapticEngine?
    private var engineNeedsStart = true
    
    private lazy var supportsHaptics: Bool = {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }()
    
    func playSuccess() {
        if supportsHaptics {
            do {
                let filePath = filePath(forResource: "Success")

                guard let path = Bundle.sdkBundle.path(forResource: filePath, ofType: "ahap") else {
                    return
                }
                
                try engine?.playPattern(from: URL(fileURLWithPath: path))
            } catch let error {
                Log.error("Error creating a haptic transient pattern: \(error)")
            }
        } else {
            AudioServicesPlaySystemSound(SystemSoundID(1520))
        }
    }
    
    func playError() {
        if supportsHaptics {
            do {
                let filePath = filePath(forResource: "Error")

                guard let path = Bundle.sdkBundle.path(forResource: filePath, ofType: "ahap") else {
                    return
                }
                
                try engine?.playPattern(from: URL(fileURLWithPath: path))
            } catch let error {
                Log.error("Error creating a haptic transient pattern: \(error)")
            }
        } else {
            AudioServicesPlaySystemSound(SystemSoundID(1102))
        }
    }
    
    func playTick() {
        if supportsHaptics {
            do {
                // Create an event (static) parameter to represent the haptic's intensity.
                let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity,
                                                                value: 0.75)
                
                // Create an event (static) parameter to represent the haptic's sharpness.
                let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness,
                                                                value: 0.5)
                
                // Create an event to represent the transient haptic pattern.
                let event = CHHapticEvent(eventType: .hapticTransient,
                                          parameters: [intensityParameter, sharpnessParameter],
                                          relativeTime: 0)
                
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                
                // Create a player to play the haptic pattern.
                let player = try engine?.makePlayer(with: pattern)
                try player?.start(atTime: CHHapticTimeImmediate) // Play now.
            } catch let error {
                Log.error("Error creating a haptic transient pattern: \(error)")
            }
        } else {
            AudioServicesPlaySystemSound(SystemSoundID(1519))
        }
    }
    
    func stop() {
        guard supportsHaptics else {
            return
        }
        
        engine?.stop(completionHandler: {[weak self] error in
            if let error = error {
                Log.error("Haptic Engine Shutdown Error: \(error)")
                return
            }
            self?.engineNeedsStart = true
        })
    }
    
    func start() {
        guard supportsHaptics && engineNeedsStart else {
            return
        }
        
        engine?.start(completionHandler: {[weak self] error in
            if let error = error {
                Log.error("Haptic Engine Start Error: \(error)")
                return
            }
            self?.engineNeedsStart = false
        })
    }
    
    func create() {
        guard supportsHaptics else {
            return
        }
        
        /// We need to instantiate `CHHapticEngine` on a background thread
        /// because on the Main thread I/O operations can cause UI unresponsiveness
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                self.engine = try CHHapticEngine()
                self.engine!.playsHapticsOnly = true
                self.engine!.stoppedHandler = { [weak self] reason in
                    Log.debug("CHHapticEngine stop handler: The engine stopped for reason: \(reason.rawValue)")
                    self?.engineNeedsStart = true
                }
                self.engine!.resetHandler = { [weak self] in
                    Log.debug("Reset Handler: Restarting the engine.")
                    do {
                        // Try restarting the engine.
                        try self?.engine?.start()
                        
                        // Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
                        self?.engineNeedsStart = false
                        
                    } catch {
                        Log.error("Failed to start the engine with error: \(error)")
                    }
                }
            } catch {
                Log.error("CHHapticEngine error: \(error)")
            }
        }
    }

    /// SPM preserves folder structure for resources, unlike Cocoapods.
    /// Therefore, a full file path with all intermediate directories must be constructed.
    private func filePath(forResource resource: String) -> String {
#if SWIFT_PACKAGE
        return [
            "Haptics",
            resource,
        ].joined(separator: "/")
#else
        return resource
#endif  // SWIFT_PACKAGE
    }
}

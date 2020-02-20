//
//  Vibration.swift
//  Challenge
//
//  Created by Felipe Semissatto on 11/07/19.
//  Copyright © 2019 Felipe Luna Tersi. All rights reserved.
//

import AVFoundation
import UIKit


public enum Vibration {
    case error
    case success
    case warning
    case light
    case medium
    case heavy
    case selection
    case oldSchool
        
    func vibrate() {
        
        switch self {
        case .error: //Use notification feedback generators
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
                
        case .success: //Use notification feedback generators
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
                
        case .warning: //Use notification feedback generators
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
                
        case .light: //user interface object collides with something or snaps into place
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
                
        case .medium: //user interface object collides with something or snaps into place
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
                
        case .heavy: //user interface object collides with something or snaps into place
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
                
        case .selection: //indicate a change in selection
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            
        case .oldSchool:
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
}

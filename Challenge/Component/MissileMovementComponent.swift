//
//  MissileMovementComponent.swift
//  Challenge
//
//  Created by Felipe Semissatto on 10/03/20.
//  Copyright © 2020 Felipe Luna Tersi. All rights reserved.
//

import Foundation
import RealityKit
import UIKit
import ARKit

class MissileMovementComponent: Component {
    
    // implemented a basic initializer
    init(to target: Transform, relativeTo referenceEntity: Entity?, duration: TimeInterval) {
        
    }
    
    // required method to achieve compliance
    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
}

//
//  CollisionComponent.swift
//  Challenge
//
//  Created by Felipe Semissatto on 11/03/20.
//  Copyright © 2020 Felipe Luna Tersi. All rights reserved.
//

import Foundation
import RealityKit
import UIKit

class CollisionComponent: Component {
    
    // property to hold the geometry on this component
    var collision = CollisionComponent()
    
    // implemented a basic initializer
    init(mesh: MeshResource, materials: [Material] = []) {
        collision = ModelEntity(mesh: mesh, materials: materials)
    }
    
    // required method to achieve compliance
    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
}

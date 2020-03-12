//
//  GeometryComponent.swift
//  Challenge
//
//  Created by Felipe Semissatto on 10/03/20.
//  Copyright © 2020 Felipe Luna Tersi. All rights reserved.
//

import Foundation
import RealityKit
import UIKit

class GeometryComponent: Component {
    
    // property to hold the geometry on this component
    var geometry = ModelEntity()
    
    // implemented a basic initializer
    init(mesh: MeshResource, materials: [Material] = []) {
        geometry = ModelEntity(mesh: mesh, materials: materials)
    }
    
    // required method to achieve compliance
    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
}

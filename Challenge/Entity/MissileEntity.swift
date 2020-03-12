//
//  MissileEntity.swift
//  Challenge
//
//  Created by Felipe Semissatto on 10/03/20.
//  Copyright © 2020 Felipe Luna Tersi. All rights reserved.
//

import RealityKit
import UIKit
import Combine

class MissileEntity: Entity, HasModel, HasAnchoring, HasCollision {
    
    // array that holds the collision subscriptions for the entities
    var collisionSubs: [Cancellable] = []
    
    required init() {
        super.init()
        
        self.components[ModelComponent] = ModelComponent(
          mesh: MeshResource.generateSphere(radius: 0.03),
          materials: [SimpleMaterial(color: .green, isMetallic: false)]
        )
        
//        GeometryComponent.registerComponent()
//        // add geometry component to the missile entity
//        let geometryComponent = GeometryComponent(mesh: MeshResource.generateSphere(radius: 0.03), materials: [SimpleMaterial(color: .green, isMetallic: false)])
//        self.components[GeometryComponent.self] = geometryComponent
        
        // add initial position component to the missile entity
//        self.position = [0, 0, -0.2]
        
        // add USD component to the missile entity
//        let usdComponent = LoadUSDComponent(named: "missile")
//        self.components[LoadUSDComponent.self] = usdComponent
        
        // add collision component to the missile entity
        self.components[CollisionComponent] = CollisionComponent(
                shapes: [.generateSphere(radius: 0.03)],
                   mode: .trigger,
                 filter: CollisionFilter(group: CollisionGroup(rawValue: 2), mask: CollisionGroup(rawValue: 1)) //missile can collide with drones, barriers and aim
        )
    }
    
//    convenience init(color: UIColor, position: SIMD3<Float>) {
//        self.init(color: color)
//
//        self.position = position
//    }
    
//    required init() {
//        fatalError("init() has not been implemented")
//    }
}


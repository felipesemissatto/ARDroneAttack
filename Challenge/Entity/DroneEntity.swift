//
//  DroneEntity.swift
//  Challenge
//
//  Created by Felipe Semissatto on 10/03/20.
//  Copyright © 2020 Felipe Luna Tersi. All rights reserved.
//

import RealityKit
import UIKit
import ARKit
import Combine

class DroneEntity: Entity, HasModel, HasAnchoring, HasCollision {
    
    // array that holds the collision subscriptions for the entities
    var collisionSubs: [Cancellable] = []
    
    required init(participantAnchor: ARParticipantAnchor) {
        super.init()
        
//        // add geometry component to the drone entity
//        let geometryComponent = GeometryComponent(mesh: MeshResource.generateBox(size: 0.05), materials: [SimpleMaterial(color: .red, isMetallic: true)])
//        self.components[GeometryComponent.self] = geometryComponent
//
        
        self.components[ModelComponent] = ModelComponent(
                 mesh: MeshResource.generateBox(size: 0.05),
                 materials: [SimpleMaterial(color: .red, isMetallic: true)] )
        
        // add USD component to the drone entity
//        let usdComponent = LoadUSDComponent(named: "drone")
//        self.components[LoadUSDComponent.self] = usdComponent
        
//        // add movement component to the drone entity
//        let movementComponent = DroneMovementComponent()
//        self.components[DroneMovementComponent.self] = movementComponent
//        
//        // add collision component to the drone entity
//        self.components[CollisionComponent] = CollisionComponent(
//                   shapes: [.generateBox(size: [0.05,0.05,0.05])],
//                   mode: .trigger,
//                 filter: CollisionFilter(group: CollisionGroup(rawValue: 1), mask: CollisionGroup(rawValue: 2)) //drone can only collide with missile
//        )
//        
//        // add life component to the drone entity
//        let lifeComponent = LifeComponent()
//        self.components[LifeComponent.self] = lifeComponent
    }
    
//    convenience init(color: UIColor, position: SIMD3<Float>) {
//        self.init(color: color)
//
//        self.position = position
//    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}

extension DroneEntity {
      func addCollisions() {
        guard let scene = self.scene else {
            return
        }

        collisionSubs.append(scene.subscribe(to: CollisionEvents.Began.self, on: self) { event in
            guard let boxA = event.entityA as? DroneEntity else {
                return
            }

            boxA.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
            Vibration.oldSchool.vibrate()
        }
        )
        collisionSubs.append(scene.subscribe(to: CollisionEvents.Ended.self, on: self) { event in
            guard let boxA = event.entityA as? DroneEntity else {
            return
          }
          boxA.model?.materials = [SimpleMaterial(color: .yellow, isMetallic: false)]
        })
      }
}

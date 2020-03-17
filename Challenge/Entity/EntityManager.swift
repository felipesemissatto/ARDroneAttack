//
//  EntityManager.swift
//  Challenge
//
//  Created by Felipe Semissatto on 10/03/20.
//  Copyright © 2020 Felipe Luna Tersi. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit
import RealityKit

class EntityManager {

      // keep a reference to all entities in the game, along with the arview.scene
      var entities = Set<Entity>()
      let arView: ARView

      // stores the arView
      init(arView: ARView) {
        self.arView = arView
      }

      // adding entities to game
      func add(_ entity: Entity) {
        entities.insert(entity)

        if let anchor = entity.anchor {
//            GeometryComponent.registerComponent()
            arView.scene.addAnchor(anchor)
        }
      }

      // removing entities to game
      func remove(_ entity: Entity) {
        if let anchor = entity.anchor {
            arView.scene.addAnchor(anchor)
        }

        entities.remove(entity)
      }
    
    // missile movement (initial position to aim)
    func shootMissile(missileEntity: AnchorEntity, aimEntity: ModelEntity){
        let frame = self.arView.session.currentFrame
        let cameraAnchor = AnchorEntity(world: (frame?.camera.transform)!)
//        let cameraAnchor = AnchorEntity(.camera)
        cameraAnchor.addChild(missileEntity)
        arView.scene.addAnchor(cameraAnchor)
        
        missileEntity.move(to: aimEntity.transform, relativeTo: cameraAnchor, duration: 1)
    }
}

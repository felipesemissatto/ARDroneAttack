//
//  drone.swift
//  Challenge
//
//  Created by Bruno Cardoso Ambrosio on 10/07/19.
//  Copyright © 2019 Felipe Luna Tersi. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit

class Drone : Equatable{
    static func == (a: Drone, b: Drone) -> Bool {
        if let aNode = a.node, let bNode = b.node{
            return aNode.isEqual(bNode)
        }
        return false
    }
    
    var lifePoints : Float = 0.0
    var node : SCNNode? = nil
    var shootNode: SCNNode!
    
    init(_ lifePoints: Float,_ node: SCNNode, shootNode :SCNNode) {
        self.lifePoints = lifePoints
        self.node = node
        self.shootNode = shootNode
        
    }
    func droneShoot(_ sceneView: ARSCNView, _ target: SCNNode){
        let node = shootNode.clone()
        
        //using case statement to allow variations of scale and rotations
        
        node.scale = SCNVector3(0.01,0.02,0.02)
        node.name = "shoot"
        
        //the physics body governs how the object interacts with other objects and its environment
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.isAffectedByGravity = false
        
        //these bitmasks used to define "collisions" with other objects
        node.physicsBody?.categoryBitMask = CollisionCategory.shootCategory.rawValue
        node.physicsBody?.contactTestBitMask = CollisionCategory.cameraCategory.rawValue
        node.physicsBody?.collisionBitMask = CollisionCategory.cameraCategory.rawValue
        
        //get the users position and direction
        node.worldPosition = self.node!.worldPosition
        
        //add node to scene
        sceneView.scene.rootNode.addChildNode(node)
        
        let move = SCNAction.move(to: target.worldPosition, duration: 2)
        node.runAction(move, completionHandler: {
            node.removeFromParentNode()
        })
    }
}

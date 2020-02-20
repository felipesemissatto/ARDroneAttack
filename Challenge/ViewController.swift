//
//  ViewController.swift
//  Challenge
//
//  Created by Felipe Luna Tersi on 02/07/19.
//  Copyright © 2019 Felipe Luna Tersi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

// MARK: Collision Struct
struct CollisionCategory: OptionSet {
    let rawValue: Int
    static let missileCategory  = CollisionCategory(rawValue: 1) //the missiles = 1
    static let targetCategory = CollisionCategory(rawValue: 2) //the drones = 2
    static let cameraCategory = CollisionCategory(rawValue: 4) //the camera = 4
    static let powerUpsCategory = CollisionCategory(rawValue: 8) //the power up = 8
    static let domoCategory = CollisionCategory(rawValue: 16) //the domo = 16
    static let shootCategory = CollisionCategory(rawValue: 32) //the shoot = 32
    static let droneRangeCategory = CollisionCategory(rawValue: 64) //the domo = 64
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate{
    // MARK: Outlets
    @IBOutlet weak var ammoLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var crosshair: UIImageView!
    @IBOutlet weak var timer: UIImageView!
    @IBOutlet weak var logLabel: UILabel!
    @IBOutlet weak var shootButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var scoreTitle: UILabel!
    @IBOutlet weak var energyTitle: UIImageView!
    @IBOutlet weak var shootTitle: UIImageView!
    @IBOutlet weak var tutorialImage: UIImageView!
    @IBOutlet weak var hudTop: UIImageView!
    @IBOutlet weak var hudBottom: UIImageView!
    @IBOutlet weak var defeatHud: UIImageView!
    @IBOutlet weak var imageHit: UIImageView!
    
    // MARK: Global Variables
    var trackerNode: SCNNode?
    var foundSurface = false
    var tracking = true
    var city: SCNNode!
    var ammoReference: SCNNode!
    var dome: SCNNode!
    var shoot: SCNNode!
    var camera: SCNNode!
    var drones: [SCNNode] = []
    var droneObjectList: [Drone] = []
    var ammos: [SCNNode] = []
    var score = 0
    var ammo = 100
    var domeLife = 100
    var screenCenter =  CGPoint.zero
    var canAnchorCity = false
    var currTimer = Timer()
    var shootNode: SCNNode!
    var player: AVAudioPlayer?
    var audioNode = SCNNode()
    
    // MARK: IBActions
    @IBAction func fireButton(_ sender: Any) {
        if ammo > 0 {
            ammo -= 1
            fireMissile()
        }
        updateAmmo()
    }
    
    @IBAction func resetGame(_ sender: Any) {
        initGame()
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        initGame()
        
        screenCenter = CGPoint(x: self.view.frame.midX,
                               y: self.view.frame.midY)
        
        if let shootScene = SCNScene(named: "Assets.scnassets/drone-shoot.dae") {
            shootNode = shootScene.rootNode.childNode(withName: "Cube_001", recursively: true)!
        }
        
        
        self.view.bringSubviewToFront(self.imageHit)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: Renderer
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        guard tracking else { return } //1
        
        let hitTest = self.sceneView.hitTest(screenCenter, types: .featurePoint) //2
        guard let result = hitTest.first else { return }
        let translation = SCNMatrix4(result.worldTransform)
        let position = SCNVector3Make(translation.m41, translation.m42, translation.m43) //3
        
        let plane = SCNPlane(width: 0.7, height: 0.7)
        
        var diffuseContent = UIImage(named: "tap-wrong.png")
        if (sceneView.session.currentFrame?.rawFeaturePoints?.points.count)! >= 35 {
            diffuseContent = UIImage(named: "tap.png")
            self.canAnchorCity = true
        } else {
            diffuseContent = UIImage(named: "tap-wrong.png")
            self.canAnchorCity = false
        }
        
        if trackerNode == nil { //1
            plane.firstMaterial?.diffuse.contents = diffuseContent
            plane.firstMaterial?.isDoubleSided = true
            trackerNode = SCNNode(geometry: plane) //2
            trackerNode?.eulerAngles.x = -.pi * 0.5 //3
            self.sceneView.scene.rootNode.addChildNode(self.trackerNode!) //4
            foundSurface = true
        } else {
            self.trackerNode!.geometry?.firstMaterial?.diffuse.contents = diffuseContent
        }
       
        self.trackerNode?.position = position //5
        
    }
    
    // MARK: Interface adjusts
    fileprivate func hideHud(_ hide: Bool){
        self.timer.isHidden = hide
        self.ammoLabel.isHidden = hide
        self.scoreLabel.isHidden = hide
        self.scoreTitle.isHidden = hide
        self.energyTitle.isHidden = hide
        self.shootTitle.isHidden = hide
        self.shootButton.isHidden = hide
        self.hudTop.isHidden = hide
        self.hudBottom.isHidden = hide
        self.crosshair.isHidden = hide
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return UIRectEdge.bottom
    }
    
    // MARK: Game Results
    fileprivate func victory() {
        self.playSound(sound: "victory", format: "wav")
        DispatchQueue.main.async {
            self.hideHud(true)
            self.defeatHud.image = UIImage(named: "victory")
            self.defeatHud.isHidden = false
            self.resetButton.setImage(UIImage(named: "restart.png"), for: .normal)
            self.resetButton.isHidden = false
            self.camera.physicsBody?.categoryBitMask = 0
            self.currTimer.invalidate()
            self.logLabel.isHidden = true
        }
    }
    
    fileprivate func gameOver() {
        self.playSound(sound: "gameOver", format: "wav")
        DispatchQueue.main.async {
            self.hideHud(true)
            self.defeatHud.image = UIImage(named: "defeat")
            self.defeatHud.isHidden = false
            self.resetButton.setImage(UIImage(named: "restart-defeat.png"), for: .normal)
            self.resetButton.isHidden = false
            self.camera.physicsBody?.categoryBitMask = 0
            self.currTimer.invalidate()
            self.logLabel.isHidden = true
        }
    }
    
    func updateAmmo(){
        if ammo <= 0{
            ammo = 0
            gameOver()
        }
        DispatchQueue.main.async {
            if self.ammo <= 5 && self.ammo>0{
                self.playSound(sound: "warning", format: "wav")
                Vibration.warning.vibrate()
                self.logLabel.isHidden = false  // trocar para animacao
            } else {
                self.logLabel.isHidden = true
            }
            self.ammoLabel.text = String(format: "%03d", self.ammo)
        }
    }
    
    func countScore(_ object: SCNNode ){
        
        playSound(sound: "enemyDown", format: "wav")
        let ( cameraPosition) = self.getUserVector().1
        let node1Pos = SCNVector3ToGLKVector3(cameraPosition)
        let node2Pos = SCNVector3ToGLKVector3(object.presentation.worldPosition)
        let distance = GLKVector3Distance(node1Pos, node2Pos)
        score = score + Int((5 * distance.rounded()))
        DispatchQueue.main.async {
            self.scoreLabel.text = String(self.score)
        }
        
    }
    
    // MARK: Setup
    fileprivate func setUpGame(_ trackingPosition: SCNVector3) {
        
        guard sceneView.session.currentFrame != nil
            else { return }
        
        let scene = SCNScene(named: "Assets.scnassets/world/world.scn")!
        sceneView.scene = scene
        sceneView.scene.physicsWorld.contactDelegate = self
        screenCenter = CGPoint(x: self.view.frame.midX,
                               y: self.view.frame.midY)
        
        //node that represents de camera
        let ball = SCNSphere(radius: 0.02)
        camera = SCNNode(geometry: ball)
        camera.position = SCNVector3Make(0, 0, -0.2)
        
        let sphereBodyShape = SCNPhysicsShape(geometry: ball,
                                              options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox])
        let sphereBody = SCNPhysicsBody(type: .kinematic, shape: sphereBodyShape)
        
        camera.physicsBody = sphereBody
        camera.physicsBody?.categoryBitMask = CollisionCategory.cameraCategory.rawValue
        camera.physicsBody?.contactTestBitMask = CollisionCategory.powerUpsCategory.rawValue
        camera.physicsBody?.collisionBitMask = CollisionCategory.powerUpsCategory.rawValue
        camera.opacity = 0.0
        sceneView.pointOfView?.addChildNode(camera)
        
        city = sceneView.scene.rootNode.childNode(withName: "city reference", recursively: false)!
        city.position = trackingPosition
        city.isHidden = false
        
        
        ammos = city.childNodes.flatMap { (node) -> [SCNNode] in
            return node.childNodes
        }
        
        ammos.forEach { (ammo) in
            if ammo.name == "ammo"{
                let boxBodyShape = SCNPhysicsShape(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0),
                                                   options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox])
                let boxBody = SCNPhysicsBody(type: .kinematic, shape: boxBodyShape)
                
                ammo.physicsBody = boxBody
                ammo.physicsBody?.categoryBitMask = CollisionCategory.powerUpsCategory.rawValue
                ammo.physicsBody?.contactTestBitMask = CollisionCategory.cameraCategory.rawValue
                ammo.physicsBody?.collisionBitMask = CollisionCategory.cameraCategory.rawValue
            }
        }
        self.addAudioNode()

        dome = sceneView.scene.rootNode.childNode(withName: "dome reference", recursively: false)!
        dome.position = trackingPosition
        dome.isHidden = false
    
        let rotate = SCNAction.rotateBy(x: 0, y: 90, z: 0, duration: 120.0)
        let spin = SCNAction.repeatForever(rotate)
        dome.runAction(spin)
        
        drones = dome.childNodes.flatMap { (node) -> [SCNNode] in
            return node.childNodes
        }
        
        drones.forEach { (drone) in
            if drone.name == "dome_glass reference" {
                drones.remove(at: drones.firstIndex(of: drone)!)
            } else {
                let boxBodyShape = SCNPhysicsShape(geometry: SCNBox(width: 0.2, height: 0.1, length: 0.1, chamferRadius: 0),
                                                   options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox])
                let boxBody = SCNPhysicsBody(type: .kinematic, shape: boxBodyShape)
                
                drone.physicsBody = boxBody
                drone.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue
                drone.physicsBody?.contactTestBitMask = CollisionCategory.missileCategory.rawValue
                drone.physicsBody?.collisionBitMask = CollisionCategory.missileCategory.rawValue
                droneObjectList.append(Drone(100.0,drone, shootNode: shootNode))
            }
        }
        
    currTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block:
        { timer in
            self.ammo-=3
            if self.ammo < 0{
                self.ammo = 0
                timer.invalidate()
            }
            self.updateAmmo()
        })
    }
    
    func initGame(){
        score = 0
        drones.removeAll()
        droneObjectList.removeAll()
        ammos.removeAll()
        ammo = 100
        domeLife = 100
        canAnchorCity = false
        tracking = true
        foundSurface = false
        self.hideHud(true)
        self.defeatHud.isHidden = true
        tutorialImage.isHidden = false
        self.resetButton.isHidden = true
        trackerNode = nil
        sceneView.session.pause()
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        sceneView.session.run(ARWorldTrackingConfiguration(), options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: Gesture
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if crosshair.isHidden && canAnchorCity {
            let trackingPosition = trackerNode!.position //2
            trackerNode?.removeFromParentNode()
            setUpGame(trackingPosition)
            updateAmmo()
            self.hideHud(false)
            tutorialImage.isHidden = true
            tracking = false //4
            canAnchorCity = false
        }
    }
    
    // MARK: Shooting Methods
    func getUserVector() -> (SCNVector3, SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            var translation = matrix_identity_float4x4
            translation.columns.0.x = cos(.pi)
            translation.columns.0.y = -sin(.pi)
            translation.columns.1.x = sin(.pi)
            translation.columns.1.y = cos(.pi)
            
            let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // orientation of camera in world space
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
            
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }
    
    func fireMissile(){
        var node = SCNNode()
        //create node
        node = createMissile()
        
        //get the users position and direction
        let (direction, position) = self.getUserVector()
        node.position = position
        var nodeDirection = SCNVector3()
       
        nodeDirection  = SCNVector3(direction.x*4,direction.y*4,direction.z*4)
        node.physicsBody?.applyForce(nodeDirection, at: SCNVector3(0.1,0,0), asImpulse: true)
        
        //move node
        node.physicsBody?.applyForce(nodeDirection , asImpulse: true)
        
        //add node to scene
        sceneView.scene.rootNode.addChildNode(node)
        playSound(sound: "laser", format: "wav")
    }
    
    //creates nodes
    func createMissile()->SCNNode{
        let node = shootNode.clone()
        node.scale = SCNVector3(0.01,0.02,0.02)
        node.name = "tiro"
        
        //the physics body governs how the object interacts with other objects and its environment
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.isAffectedByGravity = false
        
        //these bitmasks used to define "collisions" with other objects
        node.physicsBody?.categoryBitMask = CollisionCategory.missileCategory.rawValue
        node.physicsBody?.contactTestBitMask = CollisionCategory.targetCategory.rawValue
        node.physicsBody?.collisionBitMask = CollisionCategory.targetCategory.rawValue
        
        return node
    }
    
    // MARK: Physics Contact
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        var collisionType = 0  // 1 - player shot; 2 - power up; 3 - drones range; 4 - drone shoot;
        var missle: SCNNode! //missile or camera
        var object: SCNNode! //drones or power ups
        
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.missileCategory.rawValue &&
            (contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue ||
             contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.domoCategory.rawValue) {
            missle = contact.nodeA //missile
            object = contact.nodeB //drone or domo
            collisionType = 1
        } else if contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.missileCategory.rawValue  &&
            (contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue ||
                contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.domoCategory.rawValue){
            missle = contact.nodeB //missile
            object = contact.nodeA //drone or domo
            collisionType = 1
        } else if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.cameraCategory.rawValue &&
            contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.powerUpsCategory.rawValue{
            missle = contact.nodeA //camera
            object = contact.nodeB //power ups
            collisionType = 2
        } else if contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.cameraCategory.rawValue  &&
            contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.powerUpsCategory.rawValue{
            missle = contact.nodeB //camera
            object = contact.nodeA //power ups
            collisionType = 2
        }else if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.cameraCategory.rawValue &&
            contact.nodeB.physicsBody?.categoryBitMask ==
            CollisionCategory.droneRangeCategory.rawValue{
            missle = contact.nodeA// camera
            object = contact.nodeB// Drone range
            collisionType = 3
        }else if contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.droneRangeCategory.rawValue &&
            contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.cameraCategory.rawValue{
            missle = contact.nodeB// camera
            object = contact.nodeA// Drone range
            collisionType = 3
            
        }else if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.shootCategory.rawValue &&
            contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.cameraCategory.rawValue{
            missle = contact.nodeA// shoot
            object = contact.nodeB// camera
            collisionType = 4
        }else if contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.shootCategory.rawValue &&
            contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.cameraCategory.rawValue{
            missle = contact.nodeB// shoot
            object = contact.nodeA// camera
            collisionType = 4
        }else { // useless cases
            return
        }
        
        if missle.parent == nil{
            return
        }
        
        switch collisionType{
        case 1: //firing missile
            DispatchQueue.main.async {
                missle.removeFromParentNode()
            }
            
            if object.physicsBody?.categoryBitMask == CollisionCategory.domoCategory.rawValue {
                if droneObjectList.count == 0 {
                    if self.domeLife < 10 {
                        if object.parent != nil {
                            let  explosion = SCNParticleSystem(named: "Explosion.scnp", inDirectory: nil)!
                            object.addParticleSystem(explosion)
                            
                            self.playSound(sound: "explosion", format: "wav")
                            
                            object.removeFromParentNode()
                            
                            self.victory()
                        }
                    } else {
                        let  explosion = SCNParticleSystem(named: "Explosion.scnp", inDirectory: nil)!
                        object.addParticleSystem(explosion)
                        
                        self.domeLife -= 10
                    }
                }
            }
            
            // check if it object is a drone
            if object.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue {
                let  explosion = SCNParticleSystem(named: "Explosion.scnp", inDirectory: nil)!
                object.addParticleSystem(explosion)
                DispatchQueue.main.async {
                    self.droneObjectList.forEach({ (drone) in
                        if let droneNode = drone.node{
                            if (droneNode.isEqual(object)){
                                drone.lifePoints = drone.lifePoints - 50
                                if(drone.lifePoints<=0.0){
                                    self.droneObjectList.remove(at: self.droneObjectList.firstIndex(of: drone)!)
                                    self.countScore(object)
                                    object.removeFromParentNode()
                                }
                            }
                        }
                    })
                }
            }
            break
        case 2://collision between camera and power up
            DispatchQueue.main.async {
                object.removeFromParentNode() //remove power up from view
                self.ammo += 5
                Vibration.heavy.vibrate()
                self.playSound(sound: "powerup", format: "wav")
            }
            self.updateAmmo()
            break
        case 3: //player in drone range
            DispatchQueue.main.async {
                if let droneHitted = object.parent?.parent{
                    self.droneObjectList.forEach({ (drone) in
                        if let droneNode = drone.node{
                            if (droneNode.isEqual(droneHitted)){
                                drone.droneShoot(self.sceneView,self.camera)
                                return
                            }
                        }
                    })
                }
            }
            break
        case 4: //drone shoot hits the user
            DispatchQueue.main.async {
                missle.removeFromParentNode()
                self.imageHit.isHidden = false
                self.imageHit.alpha = 1.0
                UIView.animate(withDuration: 0.2, animations: {
                    self.imageHit.alpha = 0.0
                }, completion: { (success) in
                    UIView.animate(withDuration: 0.2, animations: {
                        self.imageHit.alpha = 1.0
                    }, completion: { (success) in
                        self.imageHit.alpha = 1.0
                        self.imageHit.isHidden = true
                    })
                })
                self.ammo -= 5
                self.updateAmmo()
                Vibration.oldSchool.vibrate()
            }
            break
        default:
            break
        }
    }
    
    // MARK: Sound Effects
    func playSound(sound : String, format: String) {
        
        guard let url = Bundle.main.url(forResource: sound, withExtension: format) else {
            return
        }
        guard let audiosource = SCNAudioSource(url: url ) else { return }
        let effect = SCNAction.playAudio(audiosource, waitForCompletion: false)
        audioNode.runAction(effect)
    }
    
    func addAudioNode(){
        
        let audioSource = SCNAudioSource(fileNamed: "overtake.mp3")!
        audioSource.volume = 0.0
        let audioPlayer = SCNAudioPlayer(source: audioSource)
        
        audioNode.addAudioPlayer(audioPlayer)
        
        let play = SCNAction.playAudio(audioSource, waitForCompletion: false)
        audioNode.runAction(play)
        sceneView.scene.rootNode.addChildNode(audioNode)
    }
}

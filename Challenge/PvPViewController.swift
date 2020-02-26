//
//  PvPViewController.swift
//  Challenge
//
//  Created by Felipe Luna Tersi on 18/02/20.
//  Copyright © 2020 Felipe Luna Tersi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity

class PvPViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate {
    
    // MARK: - IBOutlets

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var messageLabel: MessageLabel!
    @IBOutlet weak var shootButton: UIButton!
    @IBOutlet weak var ammoLabel: UILabel!
    
    @IBOutlet weak var hudTopImage: UIImageView!
    @IBOutlet weak var crosshairImage: UIImageView!
    @IBOutlet weak var hudBottomImagem: UIImageView!
    @IBOutlet weak var imageHit: UIImageView!
    @IBOutlet weak var timer: UIImageView!
    
    // MARK: - Global Variables
    
    var shootNode: SCNNode!
    var audioNode = SCNNode()
    var myDroneNode: SCNNode!
    
    var ammo = 100
    
    var multipeerSession: MultipeerSession!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        // Load the missile asset
        if let shootScene = SCNScene(named: "Assets.scnassets/drone-shoot.dae") {
            shootNode = shootScene.rootNode.childNode(withName: "Cube_001", recursively: true)!
        }
        
        // Start multipeer session
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
        
        messageLabel.isHidden = false
        shootButton.isHidden = false
         
        //node that represents my drone
        let sceneURL = Bundle.main.url(forResource: "drone", withExtension: "scn", subdirectory: "Assets.scnassets/drone")!
        let myDroneNode = SCNReferenceNode(url: sceneURL)!
        myDroneNode.load()
        
        let ball = SCNSphere(radius: 0.02)
        myDroneNode.position = SCNVector3Make(0, 0, 0.5)
        
        let sphereBodyShape = SCNPhysicsShape(geometry: ball,
                                              options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox])
        let sphereBody = SCNPhysicsBody(type: .kinematic, shape: sphereBodyShape)
        
        myDroneNode.physicsBody = sphereBody
        myDroneNode.physicsBody?.categoryBitMask = CollisionCategory.cameraCategory.rawValue
        myDroneNode.physicsBody?.contactTestBitMask = CollisionCategory.shootCategory.rawValue
        myDroneNode.physicsBody?.collisionBitMask = CollisionCategory.shootCategory.rawValue
        sceneView.pointOfView?.addChildNode(myDroneNode)
        
        sceneView.scene.physicsWorld.contactDelegate = self
        
        self.addAudioNode()
        
        let anchor1 = ARAnchor(name: "myDrone", transform: simd_float4x4(myDroneNode.worldTransform))
        //guard let anchor = sceneView.anchor(for: node) else { fatalError("can't find anchor") }
        sceneView.session.add(anchor: anchor1)
                
        // Send the anchor info to peers, so they can place the same content.
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor1, requiringSecureCoding: true)
                else { fatalError("can't encode anchor") }
        self.multipeerSession.sendToAllPeers(data)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        // Start the view's AR session.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's AR session.
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let name = anchor.name, name.hasPrefix("tiro") {
            node.addChildNode(shootNode)
        }
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        switch frame.worldMappingStatus {
//        case .notAvailable, .limited:
//            sendMapButton.isEnabled = false
//        case .extending:
//            sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
//        case .mapped:
//            sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
//
//        messageLabel.text = frame.worldMappingStatus.description
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        messageLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        messageLabel.text = "Session interruption ended"
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        messageLabel.text = "Session failed: \(error.localizedDescription)"
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking()
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Multiuser shared session
    var mapProvider: MCPeerID?

    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        
        do {
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                
                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
            }
            else
            if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
                // Add anchor to the session, ARSCNView delegate adds visible content.
                sceneView.session.add(anchor: anchor)
            }
            else {
                print("unknown data recieved from \(peer)")
            }
        } catch {
            print("can't decode data recieved from \(peer)")
        }
    }
    
    // MARK: - AR session management
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            message = "Connected with \(peerNames)."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            message = "Received map from \(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        
        messageLabel.text = message
        messageLabel.isHidden = message.isEmpty
    }
    // MARK: - IBActions
    @IBAction func fireButton(_ sender: Any) {
        fireMissile()
    }
    
    // MARK: - Private Methods
    
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
        
        //get the missile ARAnchor to share
        let anchor1 = ARAnchor(name: "tiro", transform: simd_float4x4(node.worldTransform))
//        guard let anchor = sceneView.anchor(for: node) else { fatalError("can't find anchor") }
        sceneView.session.add(anchor: anchor1)
        
        // Send the anchor info to peers, so they can place the same content.
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor1, requiringSecureCoding: true)
            else { fatalError("can't encode anchor") }
        self.multipeerSession.sendToAllPeers(data)
        
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
        node.physicsBody?.categoryBitMask = CollisionCategory.shootCategory.rawValue
        node.physicsBody?.contactTestBitMask = CollisionCategory.cameraCategory.rawValue
        node.physicsBody?.collisionBitMask = CollisionCategory.cameraCategory.rawValue
            
        return node
    }
    
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
    
    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
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
        case 2://collision between camera and power up
            DispatchQueue.main.async {
                object.removeFromParentNode() //remove power up from view
                self.ammo += 5
                Vibration.heavy.vibrate()
                self.playSound(sound: "powerup", format: "wav")
            }
            self.updateAmmo()
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
    
    func updateAmmo(){
        if ammo <= 0{
            ammo = 0
        }
        DispatchQueue.main.async {
            if self.ammo <= 5 && self.ammo>0{
                self.playSound(sound: "warning", format: "wav")
                Vibration.warning.vibrate()
//                self.logLabel.isHidden = false  // trocar para animacao
            } else {
//                self.logLabel.isHidden = true
            }
            self.ammoLabel.text = String(format: "%03d", self.ammo)
        }
    }
    
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
    
    // MARK: - Status Bar Methods
    override var prefersStatusBarHidden: Bool {
        // Request that iOS hide the status bar to improve immersiveness of the AR experience.
        return true
    }
        
    override var prefersHomeIndicatorAutoHidden: Bool {
        // Request that iOS hide the home indicator to improve immersiveness of the AR experience.
        return true
    }
}

//
//  ViewController.swift
//  MagicTrick
//
//  Created by Leonardo Vinicius Kaminski Ferreira on 05/12/17.
//  Copyright © 2017 Leonardo Vinicius Kaminski Ferreira. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class SceneViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var magicButton: DesignableButton!
    
    private var planeNode: SCNNode?
    private var placedHat = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.antialiasingMode = .multisampling4X
        
        addUITapGestureForHitTest()
        enableMagicButton(false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal
        configuration.worldAlignment = .gravity
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Actions
    
    @IBAction func magicPressed(_ sender: Any) {
        
        guard let button = sender as? UIButton else {
            return
        }
        
        if button.titleLabel?.text == "Magic" {
            button.setTitle("Doing Magic 🎩", for: .normal)
            
            sceneView.scene.rootNode.enumerateChildNodes {node, _ in
                if isBallInsideBoundingBox(node) {
                    node.geometry?.firstMaterial?.transparencyMode = .rgbZero
                }
            }
        } else {
            button.setTitle("Magic", for: .normal)
            
            sceneView.scene.rootNode.enumerateChildNodes {node, _ in
                if isBallInsideBoundingBox(node) {
                    node.geometry?.firstMaterial?.transparencyMode = SCNTransparencyMode(rawValue: 0)!
                }
            }
        }
        
    }
    
    @IBAction func throwPressed(_ sender: Any) {
        
        let sphere = SCNSphere(radius: 0.015)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.lightingModel = .physicallyBased
        sphere.materials = [material]
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = "ball"
        
        sphereNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        sphereNode.physicsBody?.isAffectedByGravity = true
        sphereNode.physicsBody?.mass = 0.5
        sphereNode.physicsBody?.restitution = 0.5
        sphereNode.physicsBody?.friction = 0.5
        
        let camera = self.sceneView.pointOfView!
        let position = SCNVector3(x: 0, y: 0, z: -0.20)
        sphereNode.position = camera.convertPosition(position, to: nil)
        sphereNode.rotation = camera.rotation
        
        let direction = getCameraDirection()
        let sphereDirection = direction
        sphereNode.physicsBody?.applyForce(sphereDirection, asImpulse: true)
        
        sceneView.scene.rootNode.addChildNode(sphereNode)
    }
    
    @IBAction func didTapView(_ sender: UITapGestureRecognizer) {
        
        let tapLocation = sender.location(in: sceneView)
        
        let results = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        if let result = results.first, !placedHat {
            placedHat = true
            addHat(withResult: result)
            addFloor(withResult: result)
        }
    }
    
    func addHat(withResult result: ARHitTestResult) {
        
        let transform = result.worldTransform
        
        let planePosition = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        
        let hatNode = createHatForScene(inPosition: planePosition)!
        hatNode.name = "hat"
        sceneView.scene.rootNode.addChildNode(hatNode)
        enableMagicButton(true)
        
    }
    
    private func createHatForScene(inPosition position: SCNVector3) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: "art.scnassets/magic-hat", withExtension: "scn") else {
            NSLog("Could not find hat scene")
            return nil
        }
        guard let node = SCNReferenceNode(url: url) else {
            return nil
        }
        
        node.load()
        
        node.position = position
        
        return node
    }
    
    func addFloor(withResult result: ARHitTestResult) {
        
        let transform = result.worldTransform
        
        let planePosition = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        
        let floorNode = createFloorForScene(inPosition: planePosition)!
        sceneView.scene.rootNode.addChildNode(floorNode)
        
    }
    
    private func createFloorForScene(inPosition position: SCNVector3) -> SCNNode? {
        
        let floorNode = SCNNode()
        let floor = SCNFloor()
        floorNode.geometry = floor
        floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        floorNode.position = position
        
        return floorNode
    }
    
}

// MARK: - ARSCNViewDelegate

extension SceneViewController {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let _ = anchor as? ARPlaneAnchor else {
            return nil
        }
        
        planeNode = SCNNode()
        return planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3)
        plane.materials = [planeMaterial]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 1.5, 1.5, 0, 0)
        
        node.addChildNode(planeNode)
        
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
}

// MARK: - UITapGestureRecognizer

extension SceneViewController {
    
    func addUITapGestureForHitTest() {
        let tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 1
        tap.addTarget(self, action: #selector(didTapView(_:)))
        sceneView.addGestureRecognizer(tap)
    }
    
}

// MARK: - Get user direction

extension SceneViewController {
    func getCameraDirection() -> SCNVector3 {
        
        if let frame = self.sceneView.session.currentFrame {
            
            let mat = SCNMatrix4(frame.camera.transform)
            
            let dir = SCNVector3(-2 * mat.m31, -2 * mat.m32, -2 * mat.m33)
            
            return dir
        }
        return SCNVector3(0, 0, -1)
    }
}

// MARK: - Magic Button Configuration

extension SceneViewController {
    func enableMagicButton(_ enabled: Bool) {
        magicButton.isEnabled = enabled
    }
}

// MARK: - Ball inside bounding box verification

extension SceneViewController {
    func isBallInsideBoundingBox(_ node: SCNNode) -> Bool {
        
        guard let hat = sceneView.scene.rootNode.childNode(withName: "hat", recursively: true) else {
            return false
        }
        
        let min = hat.convertPosition((hat.boundingBox.min), to: sceneView.scene.rootNode)
        let max = hat.convertPosition((hat.boundingBox.max), to: sceneView.scene.rootNode)
        
        if node.presentation.position.x < 0.99*(max.x) && node.presentation.position.x > 0.99*(min.x) && node.presentation.position.y < 0.99*(max.y) && node.presentation.position.y > 0.99*(min.y) && node.presentation.position.z < 0.99*(max.z) && node.presentation.position.z > 0.99*(min.z) {
            return true
        }
        
        return false
    }
}

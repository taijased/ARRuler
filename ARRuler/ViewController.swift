//
//  ViewController.swift
//  ARRuler
//
//  Created by Maxim Spiridonov on 07/05/2019.
//  Copyright © 2019 Maxim Spiridonov. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    let arrow = SCNScene(named: "art.scnassets/arrow.scn")!.rootNode
    
    var center: CGPoint!
    var positions = [SCNVector3]()
    var isFirstPoint = true
    
    var points = [SCNNode]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        center = view.center
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
//        // Create a new scene
//        let scene = SCNScene()
//
//        // Set the scene to the view
//        sceneView.scene = scene
//
         sceneView.scene.rootNode.addChildNode(arrow)
       
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        center = view.center
    }
}


extension ViewController: ARSCNViewDelegate {
  
    
//    ставим точку на плоскости
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let sphereGeometry = SCNSphere(radius: 0.005)
        let sphereNode = SCNNode(geometry: sphereGeometry)
        sphereNode.position = arrow.position
        sceneView.scene.rootNode.addChildNode(sphereNode)
        points.append(sphereNode)
        
        
        if isFirstPoint {
            isFirstPoint = false
        } else {
//            calculate the disrance
            let pointA = points[points.count - 2]
            guard let pointB = points.last else { return }
            let d = distance(float3(pointA.position), float3(pointB.position))
            
//            add line
            let line = SCNGeometry.line(from: pointA.position, to: pointB.position)
            print(d.description)
            let lineNode = SCNNode(geometry: line)
            sceneView.scene.rootNode.addChildNode(lineNode)
            
//            add midPoint
            
            let midPoint = (float3(pointA.position) + float3(pointB.position)) / 2
            let midPointGeometry = SCNSphere(radius: 0.003)
            midPointGeometry.firstMaterial?.diffuse.contents = UIColor.red
            let midPointNode = SCNNode(geometry: midPointGeometry)
            midPointNode.position = SCNVector3Make(midPoint.x, midPoint.y, midPoint.z)
            sceneView.scene.rootNode.addChildNode(midPointNode)
            
//            add text
            
            let textGeometry = SCNText(string: String(format: "%.0f", d * 100) + "cm", extrusionDepth: 1)
            let textNode = SCNNode(geometry: textGeometry)
            textNode.scale = SCNVector3Make(0.005, 0.005, 0.01)
            textGeometry.flatness = 0.2
            midPointNode.addChildNode(textNode)
            
//            bilboard constraint
            
            let constrints = SCNBillboardConstraint()
            constrints.freeAxes = .all
            midPointNode.constraints = [constrints]
            
            isFirstPoint = true
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let hitTest = sceneView.hitTest(center, types: .featurePoint)
        let result = hitTest.last
        guard let transform = result?.worldTransform else { return }
        let thirdColumn = transform.columns.3
        let position = SCNVector3Make(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        positions.append(position)
        let lastTenPosition = positions.suffix(10)
        arrow.position = getAveragePosition(from: lastTenPosition)
    }
    
    func getAveragePosition(from positions: ArraySlice<SCNVector3>) -> SCNVector3{
        var avarageX: Float = 0
        var avarageY: Float = 0
        var avarageZ: Float = 0
        
        for position in positions {
            avarageX += position.x
            avarageY += position.y
            avarageZ += position.z
        }
        let count = Float(positions.count)
        return SCNVector3Make(avarageX / count, avarageY / count, avarageZ / count)
    }
        
}

extension SCNGeometry {
    class func line(from vectorA: SCNVector3, to vectorB: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vectorA, vectorB])
        let elements = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [elements])
    }
}

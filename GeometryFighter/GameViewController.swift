import UIKit
import SceneKit

class GameViewController: UIViewController {
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var spawnTime: TimeInterval = 0
    var game = GameHelper.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        setupHUD()
    }
    
    //MARK: Setup
    func setupView() {
        scnView = self.view as! SCNView
        
        scnView.showsStatistics = true
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        
        scnView.delegate = self
        scnView.play(nil)
    }
    
    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.background.contents = "GeometryFighter/GeometryFighter.scnassets/Textures/Background_Diffuse.png"
    }
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    //MARK: Spawns
    func spawnShape() {
        var geometry:SCNGeometry

        switch ShapeType.random() {
        default:
            geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0,
                              chamferRadius: 0.0)
        }

        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        
        let randomX = Float.random(-2, max: 2)
        let randomY = Float.random(10, max: 18)
        let force = SCNVector3(x: randomX, y: randomY , z: 0)
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        geometryNode.physicsBody?.applyForce(force, at: position,
                                             asImpulse: true)
        let trailEmitter = createTrail(color: color, geometry: geometry)
        geometryNode.addParticleSystem(trailEmitter)
        if color == UIColor.black {
            geometryNode.name = "BAD"
        } else {
            geometryNode.name = "GOOD"
        }

        scnScene.rootNode.addChildNode(geometryNode)
    }
    
    func cleanScene() {
        for node in scnScene.rootNode.childNodes {
            if node.presentation.position.y < -2 {
                node.removeFromParentNode()
            }
        }
    }
    
    func createTrail(color: UIColor, geometry: SCNGeometry) ->
        SCNParticleSystem {
            let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
            trail.particleColor = color
            trail.emitterShape = geometry
            return trail
    }
    
    func setupHUD() {
        game.hudNode.position = SCNVector3(x: 0.0, y: 10.0, z: 0.0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
    func handleTouchFor(node: SCNNode) {
        if node.name == "GOOD" {
            game.score += 1
            node.removeFromParentNode()
        } else if node.name == "BAD" {
            game.lives -= 1
            node.removeFromParentNode()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: scnView)
        let hitResults = scnView.hitTest(location, options: nil)
        if hitResults.count > 0 {
            let result = hitResults.first!
            handleTouchFor(node: result.node)
        }
    }
}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        cleanScene()
        if time > spawnTime {
            spawnShape()
            spawnTime = time + TimeInterval(Float.random(0.2, max: 1.5))
        }
        game.updateHUD()
    }
}

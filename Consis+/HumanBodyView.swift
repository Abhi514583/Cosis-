import SwiftUI
import SceneKit

struct HumanBodyView: View {
    let onPartSelected: (String) -> Void
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    var body: some View {
        SNCBodyView(onPartSelected: onPartSelected)
            .environmentObject(dataManager)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .background(Theme.Colors.surfaceContainerLow)
            .ghostBorder(radius: 32)
    }
}

struct SNCBodyView: UIViewRepresentable {
    let onPartSelected: (String) -> Void
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        
        let scene = SCNScene()
        scnView.scene = scene
        
        // Setup Body
        let modelNode = SCNNode()
        scene.rootNode.addChildNode(modelNode)
        
        // Torso
        modelNode.addChildNode(createNode(name: "CHEST", geometry: SCNBox(width: 1.0, height: 1.2, length: 0.6, chamferRadius: 0.2), position: SCNVector3(0, 0.5, 0)))
        modelNode.addChildNode(createNode(name: "ABS", geometry: SCNBox(width: 0.8, height: 0.8, length: 0.5, chamferRadius: 0.2), position: SCNVector3(0, -0.4, 0)))
        
        // Shoulders
        modelNode.addChildNode(createNode(name: "SHOULDERS", geometry: SCNSphere(radius: 0.3), position: SCNVector3(-0.7, 0.9, 0)))
        modelNode.addChildNode(createNode(name: "SHOULDERS", geometry: SCNSphere(radius: 0.3), position: SCNVector3(0.7, 0.9, 0)))
        
        // Arms
        modelNode.addChildNode(createNode(name: "BICEPS", geometry: SCNCylinder(radius: 0.2, height: 1.0), position: SCNVector3(-0.8, 0.2, 0)))
        modelNode.addChildNode(createNode(name: "BICEPS", geometry: SCNCylinder(radius: 0.2, height: 1.0), position: SCNVector3(0.8, 0.2, 0)))
        
        // Legs
        modelNode.addChildNode(createNode(name: "LEGS", geometry: SCNCylinder(radius: 0.3, height: 1.8), position: SCNVector3(-0.4, -1.8, 0)))
        modelNode.addChildNode(createNode(name: "LEGS", geometry: SCNCylinder(radius: 0.3, height: 1.8), position: SCNVector3(0.4, -1.8, 0)))
        
        // Head
        modelNode.addChildNode(createNode(name: "HEAD", geometry: SCNSphere(radius: 0.35), position: SCNVector3(0, 1.6, 0)))
        
        // Rotation
        let rotate = CABasicAnimation(keyPath: "rotation")
        rotate.fromValue = NSValue(scnVector4: SCNVector4(0, 1, 0, 0))
        rotate.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
        rotate.duration = 20
        rotate.repeatCount = .infinity
        modelNode.addAnimation(rotate, forKey: "rotation")
        
        // Hit-test gesture
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tap)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createNode(name: String, geometry: SCNGeometry, position: SCNVector3) -> SCNNode {
        let node = SCNNode(geometry: geometry)
        node.name = name
        node.position = position
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white.withAlphaComponent(0.1)
        material.roughness.contents = 0.1
        material.metalness.contents = 1.0
        material.transparency = 0.6
        material.lightingModel = .physicallyBased
        material.emission.contents = dataManager.primaryColor.uiColor().withAlphaComponent(0.2)
        
        geometry.materials = [material]
        return node
    }
    
    class Coordinator: NSObject {
        var parent: SNCBodyView
        
        init(_ parent: SNCBodyView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let p = gesture.location(in: scnView)
            let hits = scnView.hitTest(p, options: nil)
            
            if let hit = hits.first, let name = hit.node.name {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                parent.onPartSelected(name)
            }
        }
    }
}
extension Color {
    func uiColor() -> UIColor {
        return UIColor(self)
    }
}

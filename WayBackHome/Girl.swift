//
//  Girl.swift
//  WayBackHome
//
//  Created by Ivan Sadovich on 17.01.22.
//

import SpriteKit

class Girl: SKSpriteNode {
    var velocity = CGPoint.zero
    var minimumY: CGFloat = 0.0
    var jumpSpeed: CGFloat = 20.0
    var isOnGround = true
func setupPhysicsBody() {
    if let girlTexture = texture {
        physicsBody = SKPhysicsBody(texture: girlTexture, size: size)
        physicsBody?.isDynamic = true
        physicsBody?.density = 6.0
        physicsBody?.allowsRotation = true
        physicsBody?.angularDamping = 19.0
        physicsBody?.categoryBitMask = PhysicsCategory.girl
        physicsBody?.collisionBitMask = PhysicsCategory.brick
        physicsBody?.contactTestBitMask = PhysicsCategory.brick | PhysicsCategory.gem
    }
}
    func createSparks() {
        let particleEmitter = SKEmitterNode(fileNamed: "sparks")!
        
            particleEmitter.position = CGPoint(x: 0.0, y: -50.0)
            addChild(particleEmitter)
        let waitAction = SKAction.wait(forDuration: 0.5)
        let removeAction = SKAction.removeFromParent()
        let waitThenRemove = SKAction.sequence([waitAction, removeAction])
        particleEmitter.run(waitThenRemove)
        }
    }



//
//  GameScene.swift
//  WayBackHome
//
//  Created by Ivan Sadovich on 17.01.22.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let girl: UInt32 = 0x1 << 0
    static let brick: UInt32 = 0x1 << 1
    static let gem: UInt32 = 0x1 << 2
}
//////
struct AppUtility {

    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
    
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }

    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
   
        self.lockOrientation(orientation)
    
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }

}
///////
class GameScene: SKScene, SKPhysicsContactDelegate {
    enum BrickLevel: CGFloat {
        case low = 0.0
        case high = 100.0
    }
    enum GameState {
        case notRunning
        case running
    }
    var bricks = [SKSpriteNode]()
    var gems = [SKSpriteNode]()
    var brickSize = CGSize.zero
    var brickLevel = BrickLevel.low
    var gameState = GameState.notRunning
    let startingScrollSpeed: CGFloat = 5.0
    var scrollSpeed: CGFloat = 5.0
    let gravitySpeed: CGFloat = 1.5
    var score: Int = 0
    var highScore: Int = 0
    var lastScoreUpdateTime: TimeInterval = 0.0
    var lastUpdateTime: TimeInterval?
    let girl = Girl(imageNamed: "girl")
    
    override func didMove(to view: SKView) {
        AppUtility.lockOrientation(.landscapeRight)
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -9.0)
        physicsWorld.contactDelegate = self
        anchorPoint = CGPoint.zero
        let background = SKSpriteNode(imageNamed: "background")
        let xMid = frame.midX
        let yMid = frame.midY
        
        background.position = CGPoint(x: xMid, y: yMid)
        addChild(background)
        
        setupLabels()
      //  resetGirl()
        
        girl.setupPhysicsBody()
        addChild(girl)
        let tapMethod = #selector(GameScene.handleTap(tap:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
        // Get label node from scene and store it for use later
        let menuBackgroundColor = UIColor.black.withAlphaComponent(0.4)
        let menuLayer = MenuLayer(color: menuBackgroundColor, size: frame.size)
        menuLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        menuLayer.position = CGPoint(x: 0.0, y: 0.0)
        menuLayer.zPosition = 20
        menuLayer.name = "menuLayer"
        menuLayer.display(message: "Нажмите, чтобы играть", score: nil)
        addChild(menuLayer)
    }
    func resetGirl() {
    let girlX = frame.midX / 2.0
    let girlY = girl.frame.height / 2.0 + 55.0
    girl.position = CGPoint(x:girlX, y:girlY)
    girl.zPosition = 10
    girl.minimumY = girlY
        girl.zRotation = 0.0
        girl.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        girl.physicsBody?.angularVelocity = 0.0
    }
    func setupLabels() {
        let scoreTextLabel: SKLabelNode = SKLabelNode (text:"очки")
        scoreTextLabel.position = CGPoint(x:14.0, y: frame.size.height - 20.0)
        scoreTextLabel.horizontalAlignmentMode = .left
        scoreTextLabel.fontName = "Courier - Bold"
        scoreTextLabel.fontSize = 16.0
        scoreTextLabel.zPosition = 20
        addChild(scoreTextLabel)
        
        let scoreLabel:SKLabelNode = SKLabelNode (text: "0")
        scoreLabel.position = CGPoint(x: 14.0, y:frame.size.height - 40.0)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.fontName = "Corier - Bold"
        scoreLabel.fontSize = 20.0
        scoreLabel.name = "scoreLabel"
        scoreLabel.zPosition = 20
        addChild(scoreLabel)
        
        let highScoreTextLabel: SKLabelNode = SKLabelNode(text: "лучший результат")
        highScoreTextLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 20.0)
        highScoreTextLabel.horizontalAlignmentMode = .right
        highScoreTextLabel.fontName = "Courier - Bold"
        highScoreTextLabel.fontSize = 16.0
        highScoreTextLabel.zPosition = 20.0
        addChild(highScoreTextLabel)
        
        let highScoreLabel:SKLabelNode = SKLabelNode(text: "0")
        highScoreLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 40.0)
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.fontName = "Courier - Bold"
        highScoreLabel.fontSize = 20.0
        highScoreLabel.zPosition = 20.0
        highScoreLabel.name = "highScoreLabel"
        addChild(highScoreLabel)
    }
    func updateScoreLabelText() {
        if let scoreLabel = childNode(withName: "scoreLabel") as?
            SKLabelNode {
            scoreLabel.text = String(format: "%04d", score)
        }
    }
    func updateHighScoreLabelText() {
        if let highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode {
            highScoreLabel.text = String(format:"%04d", highScore)
        }
    }
    func startGame() {
       
        gameState = .running
        resetGirl()
        score = 0
        scrollSpeed = startingScrollSpeed
        brickLevel = .low
        lastUpdateTime = nil
        for brick in bricks {
            brick.removeFromParent()
        }
        bricks.removeAll(keepingCapacity: true)
        for gem in gems {
            removeGem(gem)
        }
    }
    func gameOver() {
        gameState = .notRunning
        if score > highScore {
            highScore = score
            updateHighScoreLabelText()
        }
        let menuBackgroundColor = UIColor.black.withAlphaComponent(0.4)
        let menuLayer = MenuLayer(color: menuBackgroundColor, size: frame.size)
        menuLayer.anchorPoint = CGPoint.zero
        menuLayer.position = CGPoint.zero
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        menuLayer.display(message: "Игра окончена!", score: score)
        addChild(menuLayer)
    }
    func spawnBrick (atPosition position: CGPoint) -> SKSpriteNode {
        let brick = SKSpriteNode(imageNamed: "sidewalk")
        brick.position = position
        brick.zPosition = 8
        addChild(brick)
        brickSize = brick.size
        bricks.append(brick)
        let center = brick.centerRect.origin
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size, center: center)
        brick.physicsBody?.affectedByGravity = false
        brick.physicsBody?.categoryBitMask = PhysicsCategory.brick
        brick.physicsBody?.collisionBitMask = 0
        return brick
        
    }
    func spawnGem (atPosition position: CGPoint) {
    let gem = SKSpriteNode(imageNamed: "gem")
        gem.position = position
        gem.zPosition = 9
        addChild(gem)
        gem.physicsBody = SKPhysicsBody(rectangleOf: gem.size, center: gem.centerRect.origin)
        gem.physicsBody?.categoryBitMask = PhysicsCategory.gem
        gem.physicsBody?.affectedByGravity = false
        gems.append(gem)
    }
    func removeGem(_ gem: SKSpriteNode) {
        gem.removeFromParent()
        if let gemIndex = gems.firstIndex(of: gem) {
            gems.remove(at: gemIndex)
        }
    }
    
    ///////////////////////////////////////
   
    func updateBricks(withScrollAmount currentScrollAmount: CGFloat) {
    
        var farthestRightBrickX: CGFloat = 0.0
        
        for brick in bricks {
            let newX = brick.position.x - currentScrollAmount
            if newX < -brickSize.width {
                brick.removeFromParent()
                if let brickIndex = bricks.firstIndex(of:brick) {
                    bricks.remove(at: brickIndex)
                }
            } else {
                brick.position = CGPoint(x: newX, y: brick.position.y)
                if brick.position.x > farthestRightBrickX  {
                    farthestRightBrickX = brick.position.x
                }
            }
        }
        
        while farthestRightBrickX < frame.width {
            var brickX = farthestRightBrickX + brickSize.width + 1.0
            let brickY = (brickSize.height / 2.0) + brickLevel.rawValue
            

            let randomNumber = arc4random_uniform(99)
            if randomNumber < 5 {
                let gap = 20.0 * scrollSpeed
                brickX += gap
                let randomGemYAmount = CGFloat(arc4random_uniform(150))
                let newGemY = brickY + girl.size.height + randomGemYAmount
                let newGemX = brickX - gap / 2.0
                spawnGem(atPosition: CGPoint(x: newGemX, y: newGemY))
            }
            
            else  if randomNumber < 7 {
                if brickLevel == .high {
                    brickLevel = .low
                }
                else if brickLevel == .low {
                    brickLevel = .high
                }
            }
            
            

            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
            farthestRightBrickX = newBrick.position.x
            }
            
        }
        func updateGems(withScrollAmount currentScrollAmount: CGFloat) {
            for gem in gems {
                let thisGemX = gem.position.x - currentScrollAmount
                gem.position = CGPoint(x:thisGemX, y: gem.position.y)
                if gem.position.x < 0.0 {
                    removeGem(gem)
                }
            }
        }
    //////////////////
        func updateBricksWithoutRandom(withScrollAmount currentScrollAmount: CGFloat) {
         
        
            var farthestRightBrickX: CGFloat = 0.0
            
            for brick in bricks {
                let newX = brick.position.x - currentScrollAmount
                if newX < -brickSize.width {
                    brick.removeFromParent()
                    if let brickIndex = bricks.firstIndex(of:brick) {
                        bricks.remove(at: brickIndex)
                    }
                } else {
                    brick.position = CGPoint(x: newX, y: brick.position.y)
                    if brick.position.x > farthestRightBrickX  {
                        farthestRightBrickX = brick.position.x
                    }
                }
            }
            
            while farthestRightBrickX < frame.width {
                let brickX = farthestRightBrickX + brickSize.width + 1.0
                let brickY = (brickSize.height / 2.0) + brickLevel.rawValue
                

                

                let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
                farthestRightBrickX = newBrick.position.x
                }
                
            }
    
    ////////////////////////////////////////////////////////
    func updateGirl() {
    /* if !girl.isOnGround {
        let velocityY = girl.velocity.y - gravitySpeed
        girl.velocity = CGPoint(x: girl.velocity.x, y:velocityY)
        let newGirlY: CGFloat = girl.position.y + girl.velocity.y
        girl.position = CGPoint(x: girl.position.x, y: newGirlY)
        
        if girl.position.y < girl.minimumY {
            girl.position.y = girl.minimumY
            girl.velocity = CGPoint.zero
            girl.isOnGround = true
        } */
        if let velocityY = girl.physicsBody?.velocity.dy {
            if velocityY < -100.0 || velocityY > 100.0 {
                girl.isOnGround = false
            }
    }
        let isOffScreen = girl.position.y < 0.0 || girl.position.x < 0.0
        let maxRotation = CGFloat(GLKMathDegreesToRadians(75.0))
        let isTippedOver = girl.zRotation > maxRotation || girl.zRotation < -maxRotation
        
        if isOffScreen || isTippedOver {
            gameOver()
        }
    }
    
    func updateScore(withCurrentTime currentTime: TimeInterval) {
        let elapsedTime = currentTime - lastScoreUpdateTime
        if elapsedTime > 1.0 {
            score += Int(scrollSpeed)
            lastScoreUpdateTime = currentTime
            updateScoreLabelText()
        }
    }
        // Called before each frame is rendered
    override func update(_ currentTime: TimeInterval) {
        if gameState != .running {
            return
        }
        scrollSpeed += 0.001
        var elapsedTime: TimeInterval = 0.0
        if let lastTimeStamp = lastUpdateTime {
            elapsedTime = currentTime - lastTimeStamp
        }
        lastUpdateTime = currentTime
        let expectedElapsedTime: TimeInterval = 1.0 / 60.0
        let ScrollAdjustment = CGFloat(elapsedTime / expectedElapsedTime)
        let currentScrollAmount = scrollSpeed * ScrollAdjustment
        
        if elapsedTime < 0.0005 {
        updateBricksWithoutRandom(withScrollAmount: currentScrollAmount)
            updateGirl()
            updateGems(withScrollAmount: currentScrollAmount)
            updateScore(withCurrentTime: currentTime)
        } else {
                updateBricks(withScrollAmount: currentScrollAmount)
        
        updateGirl()
            updateGems(withScrollAmount: currentScrollAmount)
            updateScore(withCurrentTime: currentTime)
        }
        
        
        
    
        
    }
    @objc func handleTap(tap tapGesture: UITapGestureRecognizer) {
        if gameState == .running {
       if girl.isOnGround {
           // girl.velocity = CGPoint(x: 0.0, y: girl.jumpSpeed)
           // girl.isOnGround = false
           girl.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 260.0))
           run(SKAction.playSoundFileNamed("jump.mp3", waitForCompletion: false))
       }
        } else {
            if let menuLayer: SKSpriteNode = childNode(withName: "menuLayer") as? SKSpriteNode {
                menuLayer.removeFromParent()
            }
            startGame()
        }
    }
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == PhysicsCategory.girl && contact.bodyB.categoryBitMask == PhysicsCategory.brick {
            if let velocityY = girl.physicsBody?.velocity.dy {
                if !girl.isOnGround && velocityY < 100.0 {
                    girl.createSparks()
                }
            }
            girl.isOnGround = true
        } else if contact.bodyA.categoryBitMask == PhysicsCategory.girl && contact.bodyB.categoryBitMask == PhysicsCategory.gem {
            if let gem = contact.bodyB.node as? SKSpriteNode {
                removeGem(gem)
                score += 50
                updateScoreLabelText()
                run(SKAction.playSoundFileNamed("gem.mp3", waitForCompletion: false))
            }
        }
        
    }
    

}

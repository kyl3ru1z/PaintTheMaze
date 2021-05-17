//
//  GameScene.swift
//  Paint The Maze
//
//  Created by Student User on 11/7/20.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var ball = SKSpriteNode()
    var innerBall = SKSpriteNode()
    var movesLabel = SKLabelNode()
    var winLabel = SKLabelNode()
    let emitter = SKEmitterNode(fileNamed: "ConfettiParticle")
    let colors = [SKColor.purple, SKColor.green, SKColor.red, SKColor.yellow, SKColor.blue, SKColor.systemPink]
    let swipeSound = SKAction.playSoundFileNamed("swipe_sound.mp3", waitForCompletion: false)
    let winSound = SKAction.playSoundFileNamed("Ta Da.mp3", waitForCompletion: true)
    
    var swipeAllowed: Bool = true
    var initialTouch: CGPoint = CGPoint.zero
    var initialPosition: CGPoint = CGPoint.zero
    let minimumDistance: CGFloat = 90
    var moveAmtX: CGFloat = 0
    var moveAmtY: CGFloat = 0

    let swipeLeft = SKAction.moveBy(x: -700, y: 0, duration: 0.4)
    let swipeRight = SKAction.moveBy(x: 700, y: 0, duration: 0.4)
    let swipeUp = SKAction.moveBy(x: 0, y: -700, duration: 0.4)
    let swipeDown = SKAction.moveBy(x: 0, y: 700, duration: 0.4)
    
    var numFloorTiles: Int = 0
    var numMoves: Int = 0

    override func didMove(to view: SKView) {
        ball = self.childNode(withName: "ball") as! SKSpriteNode
        innerBall = ball.childNode(withName: "innerBall") as! SKSpriteNode
        movesLabel = self.childNode(withName: "movesLabel") as! SKLabelNode
        winLabel = self.childNode(withName: "winLabel") as! SKLabelNode
        
        self.physicsWorld.contactDelegate = self
        
        for node in self.children {
            if node.name == "border" {
                if let someTileMap: SKTileMapNode = node as? SKTileMapNode {
                    giveTileMapPhysicsBody(map: someTileMap)
                    someTileMap.removeFromParent()
                }
            }
            if node.name == "floor" {
                numFloorTiles += 1
            }
        }
    
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody?.restitution = 0
        self.backgroundColor = .black
        
        movesLabel.text = "Moves: \(numMoves)"
        winLabel.text = "You Win!"
        winLabel.isHidden = true
        self.addChild(emitter!)
        emitter?.position = CGPoint(x: 0, y: 630)
        emitter?.isHidden = true
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swipeAllowed = true
        numMoves += 1
        for touch in touches {
            initialTouch = touch.location(in: self)
            initialPosition = self.position
            run(swipeSound)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let movingPoint: CGPoint = touch.location(in: self)
            moveAmtX = movingPoint.x - initialTouch.x
            moveAmtY = movingPoint.y - initialTouch.y
        }
    }
    
    func enableSwipe() {
        swipeAllowed = true
        ball.isUserInteractionEnabled = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard swipeAllowed else {return}
        swipeAllowed = false
        ball.isUserInteractionEnabled = false
        if abs(moveAmtX) > minimumDistance {
            if moveAmtX < 0 {
                ball.run(swipeLeft, completion: enableSwipe)
            }
            else {
                ball.run(swipeRight, completion: enableSwipe)
            }
        }
        else if abs(moveAmtY) > minimumDistance {
            if moveAmtY < 0 {
                ball.run(swipeUp, completion: enableSwipe)
            }
            else {
                ball.run(swipeDown, completion: enableSwipe)
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else {return}
        guard let nodeB = contact.bodyB.node else {return}
        if nodeA == innerBall {
            ballCollided(with: nodeB)
        } else if nodeB == innerBall {
            ballCollided(with: nodeA)
        }
    }

    func ballCollided (with node: SKNode) {
        if node.name == "floor" {
            node.removeFromParent()
            numFloorTiles -= 1
        }
    }
    
    func giveTileMapPhysicsBody(map: SKTileMapNode) {
        let tileMap = map
        let startingLocation: CGPoint = tileMap.position
        let tileSize = tileMap.tileSize
        let halfWidth = CGFloat(tileMap.numberOfColumns) / 2.0 * tileSize.width
        let halfHeight = CGFloat(tileMap.numberOfRows) / 2.0 * tileSize.height

        for col in 0..<tileMap.numberOfColumns {
            for row in 0..<tileMap.numberOfRows {
                if let tileDefinition = tileMap.tileDefinition(atColumn: col, row: row) {
                    let tileArray = tileDefinition.textures
                    let tileTexture = tileArray[0]
                    let x = CGFloat(col) * tileSize.width - halfWidth + (tileSize.width/2)
                    let y = CGFloat(row) * tileSize.height - halfHeight + (tileSize.height/2)
                    _ = CGRect(x: 0, y: 0, width: tileSize.width, height: tileSize.height)

                    let tileNode = SKSpriteNode(texture: tileTexture)
                    tileNode.position = CGPoint(x: x, y: y)
                    tileNode.physicsBody = SKPhysicsBody(texture: tileTexture, size: CGSize(width: (tileTexture.size().width), height: (tileTexture.size().height)))
                    tileNode.physicsBody?.linearDamping = 0
                    tileNode.physicsBody?.affectedByGravity = false
                    tileNode.physicsBody?.allowsRotation = false
                    tileNode.physicsBody?.restitution = 0.0
                    tileNode.physicsBody?.isDynamic = false
                    tileNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)

                    tileNode.physicsBody?.categoryBitMask = 2
                    tileNode.physicsBody?.contactTestBitMask = 1
                    tileNode.physicsBody?.collisionBitMask = 1
                    
                    tileNode.position = CGPoint(x: tileNode.position.x + startingLocation.x, y: tileNode.position.y + startingLocation.y)
                    self.addChild(tileNode)
                }
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        movesLabel.text = "Moves: \(numMoves)"
        if numFloorTiles == 0 {
            run(winSound)
            movesLabel.isHidden = true
            winLabel.position = movesLabel.position
            winLabel.isHidden = false
            ball.isUserInteractionEnabled = false
            
            emitter?.isHidden = false
            emitter?.particleColorSequence = nil
            emitter?.particleColorBlendFactor = 1.0
            let action = SKAction.run({ [self] in
                let random = Int.random(in: 0..<self.colors.count)
                self.emitter?.particleColor = self.colors[random];
            })
            let wait = SKAction.wait(forDuration: 0.5)
            self.run(SKAction.repeatForever(SKAction.sequence([action,wait])))
        }
    }
}

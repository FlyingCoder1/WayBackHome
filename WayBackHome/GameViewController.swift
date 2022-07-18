//
///
//  GameViewController.swift
//  WayBackHome
//
//  Created by Ivan Sadovich on 17.01.22.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
         override   func viewDidLoad() {
                   super.viewDidLoad()
                   
               if let view = self.view as! SKView? {
                       // Load the SKScene from 'GameScene.sks'
                       if let scene = SKScene(fileNamed: "GameScene") {
                           // Set the scale mode to scale to fit the window
                           scene.scaleMode = .aspectFill
                           let width = view.bounds.width
                           let height = view.bounds.height
                           scene.size = CGSize(width:width, height:height)
                           // Present the scene
                           view.presentScene(scene)
                       }
                       
                       view.ignoresSiblingOrder = true
                       
                       view.showsFPS = false
                       view.showsNodeCount = false
                   }
               }
      


    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .landscapeRight
        } else {
            return .landscapeRight
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}


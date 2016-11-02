//
//  InterfaceController.swift
//  24Watch Extension
//
//  Created by Belinda Zeng on 10/25/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate{

    @IBOutlet var puzzleLabel: WKInterfaceLabel!
    
    private let session : WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    private let defaults: UserDefaults! = UserDefaults(suiteName: "group.bunnylemon.24")
    
    override init() {
        super.init()
        
        session?.delegate = self
        session?.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Check the shared storage for any messages.
        if let puzzle = defaults.object(forKey: "puzzle") as? [Int: Int] {
            setPuzzleLabel(puzzle: puzzle)
        }
        else {
        // Configure interface objects here. Eventually, do something a bit fancier -- maybe
        // generate a good puzzle here (ie, include the logic in the watch app), and send it to the iOS app.
            puzzleLabel.setText("New puzzle!")
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let msg = message["puzzle"] as? [Int:Int] {
            print(msg)
            print("received message")
            
            setPuzzleLabel(puzzle: msg)
            
        }
    }
    
    func setPuzzleLabel(puzzle: [Int:Int]) -> Void{
        var puzzleString = ""
        for (_, puzzleNumber) in puzzle {
            puzzleString = puzzleString + " " + String(puzzleNumber) + " "
        }
        
        self.puzzleLabel.setText(puzzleString)
        
    }
}

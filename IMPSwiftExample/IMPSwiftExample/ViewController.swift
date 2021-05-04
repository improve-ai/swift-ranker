//
//  ViewController.swift
//  IMPSwiftExample
//
//  Created by PanHongxi on 4/30/21.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let url = URL(string: "http://192.168.1.101/TestModel.mlmodel3.gz")
        let variants = ["Hello, World!", "Hello World", "Hello world"]
        
        var greeting = DecisionModel.load(url!).choose(from: variants).get();
        if greeting != nil {
            print("load, greeting: \(greeting!)")
        }
        
        greeting = DecisionModel.loadAsync(url!, completion: { (_ model: DecisionModel?, _ err: Error?) in
            greeting = model?.choose(from: variants).get()
            if greeting != nil {
                print("loadAsync, greeting: \(greeting!)")
            }
        })
        
    }
}


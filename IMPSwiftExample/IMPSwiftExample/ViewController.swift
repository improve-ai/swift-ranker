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
        
        let modelUrl = URL(fileURLWithPath: "/Users/phx/Documents/improve-ai/TestModel.mlmodel")
//        let modelUrl = URL(string: "http://192.168.1.101/TestModel.mlmodel3.gz")!
        let variants = ["Hello, World!", "Hello World", "Hello world"]
        let given = ["language": "cowboy"]
        
        var greeting = try? DecisionModel.load(modelUrl).chooseFrom(variants).given(given).get();
        if greeting != nil {
            print("load, greeting: \(greeting!)")
        }
        
        DecisionModel("hello").loadAsync(modelUrl) { (model, err) in
            greeting = model?.chooseFrom(variants).given(given).get()
            if greeting != nil {
                print("loadAsync, greeting: \(greeting!)")
            }
        }
    }
}


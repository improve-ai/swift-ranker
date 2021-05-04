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
        
        let modelUrl = URL(string: "http://192.168.1.101/TestModel.mlmodel3.gz")!
        let variants = ["Hello, World!", "Hello World", "Hello world"]

        // greeting = DecisionModel.load(modelUrl).chooseFrom([“Hello World”, “Howdy World”, “Hi World”]).given({“language”: “cowboy”}).get()
        
        var greeting = DecisionModel.load(modelUrl).chooseFrom(variants).get();
        if greeting != nil {
            print("load, greeting: \(greeting!)")
        }
        
        
        greeting = DecisionModel.loadAsync(modelUrl, completion: { (_ model: DecisionModel?, _ err: Error?) in
            greeting = model?.chooseFrom(variants).get()
            if greeting != nil {
                print("loadAsync, greeting: \(greeting!)")
            }
        })
        
    }
}


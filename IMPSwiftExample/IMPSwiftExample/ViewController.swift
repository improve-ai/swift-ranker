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
        let greeting = DecisionModel.load(url!).choose(from: ["Hello, World!", "Hello World", "Hello world"]).get();
        if greeting != nil {
            print("greeting: \(greeting!)")
        }
    }
}


//
//  ViewController.swift
//  AlamofireDemo
//
//  Created by Yudiz on 12/14/16.
//  Copyright © 2016 Yudiz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        KPWebCall.call.simpleGetApiCall { (json, statusCode) in
            jprint(items: json)
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


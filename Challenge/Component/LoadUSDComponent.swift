//
//  LoadUSDZComponent.swift
//  Challenge
//
//  Created by Felipe Semissatto on 10/03/20.
//  Copyright © 2020 Felipe Luna Tersi. All rights reserved.
//

import Foundation
import RealityKit
import UIKit

class LoadUSDComponent: Component {
    
    // property to hold the USD on this component
    var entity = Entity()
    
    // implemented a basic initializer - loading Synchronously
    init(named: String) {
        let url = URL(fileURLWithPath: "path/to/\(named).usdz")
        self.entity = try! Entity.load(contentsOf: url)
    }
    
    // required method to achieve compliance
    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
}

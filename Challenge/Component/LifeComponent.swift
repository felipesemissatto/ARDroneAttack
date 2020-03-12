//
//  LifeComponent.swift
//  Challenge
//
//  Created by Felipe Semissatto on 11/03/20.
//  Copyright © 2020 Felipe Luna Tersi. All rights reserved.
//

import Foundation
import RealityKit
import UIKit

class LifeComponent: Component {
    
    // property to hold the life on this component
    var life: Int = 100
    
    func dealDamage(value: Int){
        self.life -= value
    }
    
//    // required method to achieve compliance
//    required init?(coder aDecoder: NSCoder) {
//      fatalError("init(coder:) has not been implemented")
//    }
}

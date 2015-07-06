//
//  Stage.swift
//  ViaAlpina
//
//  Created by Chris Eidhof on 04/07/15.
//  Copyright © 2015 objc.io. All rights reserved.
//

import Foundation

struct Stage {
    let number: Int
    
    init(number: Int) {
        self.number = number
    }
    
    static var max: Int {
        return 160
    }
    
    var path: String {
        return NSBundle.mainBundle().resourcePath?.stringByAppendingPathComponent("kml/\(number).kml") ?? ""
        
    }
    
    var next: Stage? {
        guard number < Stage.max else { return nil }
        return Stage(number: number+1)
    }
    
    lazy var kmlInfo: KMLInfo? = { parseKML(self.path) }()

}

extension Stage {
}

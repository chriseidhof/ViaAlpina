//
//  AltitudeViewController.swift
//  ViaAlpina
//
//  Created by Chris Eidhof on 05/07/15.
//  Copyright © 2015 objc.io. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

extension CollectionType {
    func reduceWithPrevious<R>(initial: R, combine f: (result: R, previous: Self.Generator.Element, element: Self.Generator.Element) -> R) -> R {
        guard !self.isEmpty else { return initial }
        return reduce((initial, self[startIndex]), combine: { (x, element) in
            (f(result: x.0, previous: x.1, element: element), element)
        }).0
    }
}

struct AltitudeProfileForDisplay {
    let altitudes: AltitudeProfile
    
    init(altitudes: AltitudeProfile) {
        self.altitudes = altitudes
        minAltitude = 0 // altitudes.reduce(Int.max) { x, coord in min(x, coord.altitude) }
        maxAltitude = 3000 //altitudes.reduce(Int.min) { x, coord in max(x, coord.altitude) }
        (altitudeGain, altitudeLoss) = altitudes.reduceWithPrevious((0,0), combine: { r, previous, element in
            let diff = element.altitude - previous.altitude
            return (diff > 0) ? (r.0 + diff, r.1) : (r.0, r.1 - diff)
        })
    }
    
    
    let minAltitude: Int
    let maxAltitude: Int
    let altitudeGain: Int
    let altitudeLoss: Int
    
    var normalizedAltitudes: [(x: Double, y: Double)] {
        guard !altitudes.isEmpty else { return [] }
        let scale = Double(maxAltitude - minAltitude)
        let maxDistance = altitudes.last!.distance
        return altitudes.map { alt in
            return (normalizedDistance: alt.distance/maxDistance, normalizedAltitude: Double(alt.altitude-minAltitude)/scale)
        }
    }


}

class AltitudeLocationManager: NSObject, CLLocationManagerDelegate {
    let manager: CLLocationManager
    var altitudeProfile: AltitudeProfile
    var locationChangedCallback: (AltitudeAndLocation, CLLocation) -> ()
    
    init(profile: AltitudeProfile, callback: (AltitudeAndLocation, CLLocation) -> ()) {
        altitudeProfile = profile
        manager = CLLocationManager()
        locationChangedCallback = callback
        super.init()
        manager.delegate = self
        
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        if let l = manager.location {
            updateForLocation(l)
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        updateForLocation(newLocation)
    }
    
    func updateForLocation(location: CLLocation) {
        if let closest = altitudeProfile.sort({ (l1, l2) in
            l1.location.distanceFromLocation(location) < l2.location.distanceFromLocation(location)
        }).first {
            locationChangedCallback(closest, location)
        }
    }
    
    deinit {
        manager.stopUpdatingLocation()
    }
}

class AltitudeViewController: UIViewController {
    @IBOutlet weak var altitudeProfileView: AltitudeView!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var maxLabel: UILabel!
    
    var altitudes: AltitudeProfile = [] {
        didSet {
            let profile = AltitudeProfileForDisplay(altitudes: altitudes)
            altitudeProfileView?.profile = profile.normalizedAltitudes
            minLabel?.text = "\(profile.minAltitude) m"
            maxLabel?.text = "\(profile.maxAltitude) m"
            navigationItem.title = "↗️ \(profile.altitudeGain) ↘️ \(profile.altitudeLoss)"
        }
    }
    
    override func viewDidLoad() {
        altitudes = altitudes + [] // trigger reload of data
    }
    
    var locationManager: AltitudeLocationManager?
    
    override func viewDidAppear(animated: Bool) {
        locationManager = AltitudeLocationManager(profile: altitudes) { [unowned self] (closest, newLocation) in
            print(closest.location.distanceFromLocation(newLocation))
            print((closest, newLocation))
            let index = self.altitudes.indexOf { el in
                el.location == closest.location
            }
            self.altitudeProfileView.highlightedIndex = index
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        locationManager = nil
    }
}

extension CGContextRef {
    func drawLine(var points: [CGPoint], color: UIColor = UIColor.blackColor(), width: CGFloat = 1) {
        guard !points.isEmpty else { return }
        color.set()
        CGContextSetLineWidth(self, width)
        CGContextBeginPath(self)
        let startingPoint = points.removeAtIndex(0)
        CGContextMoveToPoint(self, startingPoint.x, startingPoint.y)
        for point in points {
            CGContextAddLineToPoint(self, point.x, point.y)
        }
        CGContextStrokePath(self)
        
    }

}

class AltitudeView: UIView {
    var profile: [(x: Double, y: Double)] = [] // Need to all be between 0 and 1
    var numDivisions = 3
    var subDivisions = 10
    var highlightedIndex: Int? {
        didSet {
            setNeedsDisplay()
        }
    }

    var context: CGContextRef {
        return UIGraphicsGetCurrentContext()
    }
    
    override func drawRect(rect: CGRect) {
        plotSubDivisions()
        plotDivisions()
        plotProfile()
        plotHighlight()
    }
    
    func plotSubDivisions() {
        for x in 1..<(numDivisions*subDivisions) {
            let startingPoint = CGPoint(x: 0, y: bounds.height * (CGFloat(x) / CGFloat(numDivisions*subDivisions)))
            let endPoint = CGPoint(x: bounds.width, y: startingPoint.y)
            context.drawLine([startingPoint, endPoint], color: UIColor.lightGrayColor(), width: 0.5)
        }
  
    }
    
    func plotDivisions() {
        for x in 1..<numDivisions {
            let startingPoint = CGPoint(x: 0, y: bounds.height * (CGFloat(x) / CGFloat(numDivisions)))
            let endPoint = CGPoint(x: bounds.width, y: startingPoint.y)
            context.drawLine([startingPoint, endPoint], color: UIColor.grayColor())
        }
    }
    
    func toCGPoint(point: (x: Double, y: Double)) -> CGPoint {
        return CGPoint(x: CGFloat(point.x)*bounds.width, y: CGFloat(1-point.y)*bounds.height)
    }
    
    func plotProfile() {
        context.drawLine(profile.map(toCGPoint))
    }
    
    func plotHighlight() {
        guard let index = highlightedIndex else { return }
        
        let point = profile[index]
        let cgPoint = toCGPoint(point)
        var origin = cgPoint
        origin.y = bounds.height
        
        context.drawLine([origin, cgPoint], color: UIColor.redColor(), width: 1)
    }
}
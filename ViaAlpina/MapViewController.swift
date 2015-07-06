//
//  MapViewController.swift
//  ViaAlpina
//
//  Created by Chris Eidhof on 23/06/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import UIKit
import MapKit

class MapDelegate: NSObject, MKMapViewDelegate {
    
    var i = 0
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        assert(overlay is MKPolyline)
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = i++ % 2 == 0 ? UIColor.blueColor() : UIColor.redColor()
        renderer.lineWidth = 2
        return renderer
    }
}

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    let delegate = MapDelegate()
    
    var stage: Stage?
    let numNext = 10
        
    lazy var locationManager: CLLocationManager = CLLocationManager()
    
    func authorize() {
        if CLLocationManager.authorizationStatus() != .AuthorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.authorize()
    }
    
    struct Line {
        let line: MKPolyline
        let name: String
        let distance: CLLocationDistance
    }
    
    override func viewDidLoad() {
        guard var stage = stage else { return }
        var stages: [Stage] = []
        var theStage = stage
        for _ in 0..<numNext {
            stages.append(theStage)
            guard let next = theStage.next else { break }
            theStage = next
        }
        let lines: [Line] = stages.map { (var stage) in
            let parsed = stage.kmlInfo
            let coords = parsed?.coordinates ?? []
            var mapPoints: [MKMapPoint] = coords.map { (c: Coordinate) -> MKMapPoint in
                MKMapPointForCoordinate(c.location.coordinate)
            }
            let coords2 = coords.map { $0.location }
            let distanceCoord = (distance: CLLocationDistance(0), lastLocation: coords2[0])
            let distance = coords2.reduce(distanceCoord, combine: { (intermediate: (distance: CLLocationDistance, lastLocation: CLLocation), coord: CLLocation) in
                return (distance: intermediate.distance + intermediate.lastLocation.distanceFromLocation(coord), coord)
            }).distance
            
            return Line(line: MKPolyline(points: &mapPoints, count: mapPoints.count), name: parsed?.name ?? "", distance: distance)
        }

        lines.map { mapView.addOverlay($0.line) }
        
        let d = Int(round(lines[0].distance / 1000))
                
        navigationItem.title = "\(d)km " + lines[0].name
        mapView.visibleMapRect = mapView.mapRectThatFits(lines[0].line.boundingMapRect)
        mapView.delegate = delegate
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let altitudeViewController = segue.destinationViewController as? AltitudeViewController,
        let altitudes = stage?.kmlInfo?.altitudeProfile {
            altitudeViewController.altitudes = altitudes
        }
    }
    
}
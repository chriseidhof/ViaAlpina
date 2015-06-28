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
    let numNext = 5
    
    var kmlInfo: KMLInfo? {
        return stage.flatMap { parseKML($0.path) }
    }
    
    lazy var locationManager: CLLocationManager = CLLocationManager()
    
    func authorize() {
        if CLLocationManager.authorizationStatus() != .AuthorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.authorize()
    }
    
    override func viewDidLoad() {
        guard var stage = stage else { return }
        var stages: [Stage] = []
        for _ in 0..<numNext {
            stages.append(stage)
            stage = stage.next
        }
        let lines: [(MKPolyline, String)] = stages.map { stage in
            let parsed = parseKML(stage.path)
            let coords = parsed?.coordinates ?? []
            var mapPoints: [MKMapPoint] = coords.map { (c: Coordinate) -> MKMapPoint in
                MKMapPointForCoordinate(c.location)
            }
            
            return (MKPolyline(points: &mapPoints, count: mapPoints.count), parsed?.name ?? "")
        }

        lines.map { mapView.addOverlay($0.0) }
        
        navigationItem.title = lines[0].1
        mapView.visibleMapRect = mapView.mapRectThatFits(lines[0].0.boundingMapRect)
        mapView.delegate = delegate
    }
    
}
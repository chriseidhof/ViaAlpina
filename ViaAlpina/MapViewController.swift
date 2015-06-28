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
    
    override func viewDidLoad() {
        guard var stage = stage else { return }
        var stages: [Stage] = []
        for _ in 0..<numNext {
            stages.append(stage)
            stage = stage.next
        }
        let lines: [MKPolyline] = stages.map { stage in
            let coords = parseKML(stage.path)?.coordinates ?? []
            var mapPoints: [MKMapPoint] = coords.map { (c: Coordinate) -> MKMapPoint in
                MKMapPointForCoordinate(c.location)
            }
            
            return MKPolyline(points: &mapPoints, count: mapPoints.count)
        }

        lines.map(mapView.addOverlay)
        
        mapView.visibleMapRect = mapView.mapRectThatFits(lines[0].boundingMapRect)
        mapView.delegate = delegate
    }
    
}
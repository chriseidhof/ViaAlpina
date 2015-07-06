//
//  KMLParser.swift
//  ViaAlpina
//
//  Created by Chris Eidhof on 28/06/15.
//  Copyright © 2015 objc.io. All rights reserved.
//

import Foundation
import CoreLocation

struct Coordinate {
    let location: CLLocation
    let altitudeInMeters: Int
}

private func parseCoordinate(s: String) -> Coordinate? {
    let parts = s.componentsSeparatedByString(",")
    guard parts.count == 3,
        let lon = Double(parts[0]),
        let lat = Double(parts[1]),
        let altitude = Int(parts[2])
        else { return nil }
    let loc = CLLocation(latitude: lat, longitude: lon)
    return Coordinate(location: loc, altitudeInMeters: altitude)
}

private func parseCoordinates(s: String) -> [Coordinate] {
    let lines = s.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
    return lines.flatMap(parseCoordinate)
}

@objc private class KMLDelegate: NSObject, NSXMLParserDelegate {
    var inPlaceMark = false
    var inName = false
    var inCoordinates = true
    var nameString = ""
    var coordinates = ""
    
    @objc func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "Placemark" {
            inPlaceMark = true
        } else if elementName == "name" && inPlaceMark {
            inName = true
        } else if elementName == "coordinates" {
            inCoordinates = true
        }
    }
    
    @objc func parser(parser: NSXMLParser, foundCharacters string: String) {
        if inName {
            nameString += string
        } else if inCoordinates {
            coordinates += string
        }
    }
    
    @objc func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Placemark" {
            inPlaceMark = false
        } else if elementName == "name" && inName {
            inName = false
        } else if elementName == "coordinates"  {
            inCoordinates = false
        }
    }
}

struct KMLInfo {
    let name: String
    let coordinates: [Coordinate]
}

func parseKML(filePath: String) -> KMLInfo? {
    let url = NSURL(fileURLWithPath: filePath)
    if let parser = NSXMLParser(contentsOfURL: url)
    {
        let delegate = KMLDelegate()
        parser.delegate = delegate
        parser.parse()
        let name = delegate.nameString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        return KMLInfo(name: name, coordinates: parseCoordinates(delegate.coordinates))
    }
    return nil
}

typealias AltitudeAndLocation = (distance: CLLocationDistance, altitude: Int, location: CLLocation)

typealias AltitudeProfile = [AltitudeAndLocation]

extension KMLInfo {
    var altitudeProfile: AltitudeProfile {
        let result = coordinates.reduce((coordinates[0], CLLocationDistance(0), AltitudeProfile())) { (intermediateResult, coord) in
            let previousCoord = intermediateResult.0
            var distances = intermediateResult.2
            let distance = coord.location.distanceFromLocation(previousCoord.location)
            let totalDistance = intermediateResult.1 + distance
            distances.append((distance: totalDistance, altitude: coord.altitudeInMeters, location: coord.location))
            return (coord, totalDistance, distances)
        }
        return result.2
    }
}
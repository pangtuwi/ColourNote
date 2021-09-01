//
//  ActivityMapViewController.swift
//  eFit
//
//  Created by Paul Williams on 13/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import UIKit
import MapKit

class ActivityMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    let initialLocation = CLLocation(latitude: 53.4807, longitude: 2.2426)
    var regionRadius: CLLocationDistance = 10000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self as MKMapViewDelegate
        centerMapOnLocation(location: initialLocation)
    } //viewDidLoad
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        mapView.removeOverlays(mapView.overlays)
        //print("Map View appeared - load data")
        
        if let myActivity = ActivityRecords.instance.getActivity(searchActivityId: Globals.sharedInstance.activityIDToDisplay) ?? ActivityRecords.instance.getLatestActivity() {
            DataLoader.sharedInstance.loadTrackPoints(whenDone: displayRoute, ActivityId : myActivity.activityId)}
    } //viewDidAppear
    
    
    func displayRoute (trackPoints : [TrackPoint]) -> Void {
        var hasFirstCoordinate = false
        var oldCoordinates = initialLocation.coordinate
        var newCoordinates = initialLocation.coordinate
        
        var minlat = oldCoordinates.latitude
        var maxlat = oldCoordinates.latitude
        var minlong = oldCoordinates.longitude
        var maxlong = oldCoordinates.longitude
        
        DispatchQueue.main.async {
            //print ("drawing map route with coordinates")
            for tp in trackPoints {

                if !hasFirstCoordinate {
                    oldCoordinates = CLLocationCoordinate2D(latitude: tp.Lat, longitude: tp.Long)
                    minlat = oldCoordinates.latitude
                    maxlat = oldCoordinates.latitude
                    minlong = oldCoordinates.longitude
                    maxlong = oldCoordinates.longitude
                    if (tp.Lat) != 0.0 && (tp.Long != 0.0) {
                        self.centerMapOn2DLocation(location: oldCoordinates)
                        hasFirstCoordinate = true
                    }
                } else {
                    if (tp.Lat) != 0.0 && (tp.Long != 0.0) {
                        newCoordinates = CLLocationCoordinate2D(latitude: tp.Lat, longitude: tp.Long)
                        minlong = min(minlong, newCoordinates.longitude)
                        maxlong = max(maxlong, newCoordinates.longitude)
                        minlat = min (minlat, newCoordinates.latitude)
                        maxlat = max (maxlat, newCoordinates.latitude)
                        var area = [oldCoordinates, newCoordinates]
                        let polyline = MKPolyline(coordinates: &area, count: area.count)
                        self.mapView.addOverlay(polyline)
                        //func mapView(MKMapView, didAdd: [MKOverlayRenderer])
                        oldCoordinates = newCoordinates
                    }
                }
            }
            self.regionRadius = max (maxlat-minlat, maxlong-minlong) * 111111
            let newCentre = CLLocationCoordinate2D(latitude: minlat + (maxlat-minlat)/2, longitude: minlong+(maxlong-minlong)/2)
             self.centerMapOn2DLocation(location: newCentre)
            
            if !hasFirstCoordinate {  //
                self.centerMapOn2DLocation(location: oldCoordinates)
                
            }
        }
        
        
    } //displayRoute
    
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func centerMapOn2DLocation (location : CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegion(center: location,
                                                  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
}

extension ActivityMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let temp = MKOverlayRenderer()
        if (overlay is MKPolyline) {
            let pr = MKPolylineRenderer(overlay: overlay)
            pr.strokeColor = UIColor.blue //UIColor.redColor()
            pr.lineWidth = 5
            return pr
        }
        return temp
    }  // renderer for Overlay of MKPolyLine
}

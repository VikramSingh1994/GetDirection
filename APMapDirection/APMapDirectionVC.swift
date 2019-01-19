//
//  APMapDirectionVC.swift
//  APMapDirection
//
//  Created by Mac on 04/08/18.
//  Copyright © 2018 Mac. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import SwiftyJSON
import Alamofire

enum Location {
    case startLocation
    case destinationLocation
}

class APMapDirectionVC: UIViewController {
    var googleAPIKey = "AIzaSyBjElloyn_NOkxGkoLtUK89GMjTUN4Jv"
    @IBOutlet weak var googleMaps: GMSMapView!
    @IBOutlet weak var destinationLocation: UITextField!
    @IBOutlet weak var bntDirection: UIButton!

    var locationManager = CLLocationManager()
    var locationSelected = Location.startLocation
    
    var locationStart = CLLocation()
    var locationEnd = CLLocation()
    var locationCurrent  = CLLocation()

    var markerStart = GMSMarker()
    var markerEnd = GMSMarker()

    override func viewDidLoad() {
        bntDirection.isEnabled = false
        bntDirection.alpha = 0.4
        super.viewDidLoad()
        settings()
    }
    
    private func settings() {
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startMonitoringSignificantLocationChanges()
        
        //Your map initiation code
        let camera = GMSCameraPosition.camera(withLatitude: 22.719569, longitude: 75.857726, zoom: 15.0)
        
        self.googleMaps.camera = camera
        self.googleMaps.delegate = self
        self.googleMaps?.isMyLocationEnabled = true
        self.googleMaps.settings.myLocationButton = true
        self.googleMaps.settings.compassButton = true
        self.googleMaps.settings.zoomGestures = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Action
    // MARK: when destination location tap, this will open the search location
    @IBAction func openDestinationLocation(_ sender: UIButton) {
        
        let autoCompleteController = GMSAutocompleteViewController()
        autoCompleteController.delegate = self
        
        // selected location
        locationSelected = .destinationLocation
        
        // Change text color
        UISearchBar.appearance().setTextColor(color: UIColor.black)
        self.locationManager.stopUpdatingLocation()
        self.present(autoCompleteController, animated: true, completion: nil)
    }
    
    // MARK: SHOW DIRECTION WITH BUTTON
    @IBAction func showDirection(_ sender: UIButton) {
        
        for p in (0 ..< aryOldPolyLine.count) {//remove old polyline
            aryOldPolyLine[p].map = nil
        }
        //Set start point
        setStartPointByCurrentLocation()
        
        // when button direction tapped, must call drawpath func
        self.drawPath(startLocation: locationStart, endLocation: locationEnd)
    }

    // MARK: function for create a marker pin on map
    func createMarker(titleMarker: String, iconMarker: UIImage, latitude: CLLocationDegrees, longitude: CLLocationDegrees)->GMSMarker {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(latitude, longitude)
        marker.title = titleMarker
        marker.icon = iconMarker
        return marker
    }
    
    //MARK: - this is function for create direction path, from start location to desination location
    var aryOldPolyLine = [GMSPolyline]()
    func drawPath(startLocation: CLLocation, endLocation: CLLocation) {
        let origin = "\(startLocation.coordinate.latitude),\(startLocation.coordinate.longitude)"
        let destination = "\(endLocation.coordinate.latitude),\(endLocation.coordinate.longitude)"
        
        
        //let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving"
        
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&key=\(googleAPIKey)&mode=driving"
        
        Alamofire.request(url).responseJSON { response in
            
            print(response.request as Any)  // original URL request
            print(response.response as Any) // HTTP URL response
            print(response.data as Any)     // server data
            print(response.result as Any)   // result of response serialization
            
            do {
                var   json = try JSON(data: response.data!)
                
                let routes = json["routes"].arrayValue
                // print route using Polyline
                
                self.aryOldPolyLine = [GMSPolyline]()
                for route in routes   {
                    let routeOverviewPolyline = route["overview_polyline"].dictionary
                    let points = routeOverviewPolyline?["points"]?.stringValue
                    let path = GMSPath.init(fromEncodedPath: points!)
                    let polyline = GMSPolyline.init(path: path)
                    polyline.strokeWidth = 4
                    polyline.strokeColor = UIColor.blue
                    polyline.map = self.googleMaps
                    self.aryOldPolyLine.append(polyline)
                }
                 self.focasOnTwoPoint()
                
            } catch _ {
                
            }
        }
    }
    
    func focasOnTwoPoint() {
        var bounds = GMSCoordinateBounds()
        bounds = bounds.includingCoordinate(markerStart.position)
        bounds = bounds.includingCoordinate(markerEnd.position)
        let update = GMSCameraUpdate.fit(bounds, withPadding: 60)
        googleMaps.animate(with: update)
    }
}


//MARK: - Locetion Delegate

extension APMapDirectionVC: CLLocationManagerDelegate {
    //MARK: - Location Manager delegates
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error to get location : \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // 3
        guard status == .authorizedWhenInUse else {
            return
        }
        // 4
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        if location != nil {
            locationCurrent  = location!
            let camera = GMSCameraPosition.camera(withLatitude: (locationCurrent.coordinate.latitude), longitude: (locationCurrent.coordinate.longitude), zoom: 13.0)
            self.googleMaps.animate(to: camera)
        }
        self.locationManager.stopUpdatingLocation()
    }
}

// MARK: - GMSMapViewDelegate
extension APMapDirectionVC:  GMSMapViewDelegate{
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        googleMaps.isMyLocationEnabled = true
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        googleMaps.isMyLocationEnabled = true
        
        if (gesture) {
            mapView.selectedMarker = nil
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        googleMaps.isMyLocationEnabled = true
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("COORDINATE \(coordinate)") // when you tapped coordinate
    }
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        googleMaps.isMyLocationEnabled = true
        googleMaps.selectedMarker = nil
        
        let camera = GMSCameraPosition.camera(withLatitude: (locationCurrent.coordinate.latitude), longitude: (locationCurrent.coordinate.longitude), zoom: 13.0)
        self.googleMaps.animate(to: camera)
        return true
    }
}

// MARK: - GMS Auto Complete Delegate, for autocomplete search location
extension APMapDirectionVC: GMSAutocompleteViewControllerDelegate {
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error \(error)")
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        // Change map location
        let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 16.0)
        
        // set coordinate to text
        if locationSelected == .startLocation {
            
        } else {
            
            let endd = "\(place.coordinate.latitude), \(place.coordinate.longitude)"
            destinationLocation.text = endd
            
            let location = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            
            fetchCityAndCountry(from: location) { city, country, error in
                guard let city = city, let country = country, error == nil else { return }
                print(city + ", " + country)  // Rio de Janeiro, Brazil
                self.destinationLocation.text = city + ", " + country + ", " + endd
            }
            
            
            bntDirection.isEnabled = true
            bntDirection.alpha = 1.0
            locationEnd = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            markerEnd.map = nil

           let markerNew = createMarker(titleMarker: "Destination", iconMarker: #imageLiteral(resourceName: "mapspin"), latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            markerEnd = markerNew
            markerEnd.map = googleMaps
        }
        
        self.googleMaps.camera = camera
        self.dismiss(animated: true, completion: nil)
    }
    
    func setStartPointByCurrentLocation() {
        locationStart = CLLocation(latitude: locationCurrent.coordinate.latitude, longitude: locationCurrent.coordinate.longitude)
        markerStart.map = nil
        let markerNew = createMarker(titleMarker: "Source", iconMarker: #imageLiteral(resourceName: "mapspin"), latitude: locationCurrent.coordinate.latitude, longitude: locationCurrent.coordinate.longitude)
        markerStart = markerNew
        markerStart.map = googleMaps
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func fetchCityAndCountry(from location: CLLocation, completion: @escaping (_ city: String?, _ country:  String?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            completion(placemarks?.first?.locality,
                       placemarks?.first?.country,
                       error)
        }
    }
}

public extension UISearchBar {
    public func setTextColor(color: UIColor) {
        let svs = subviews.flatMap { $0.subviews }
        guard let tf = (svs.filter { $0 is UITextField }).first as? UITextField else { return }
        tf.textColor = color
    }
}

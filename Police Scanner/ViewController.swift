//
//  ViewController.swift
//  Police Scanner
//
//  Created by Emin Ademi on 8/28/19.
//  Copyright © 2019 triCore. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import AVFoundation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var dismissTracking: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var radarButton: UIButton!
    @IBOutlet weak var buttonOne: UIButton!
    
    var zones = [Zone]()
    var regionArray = [CLRegion: Zone]()
    var locationManager = CLLocationManager()
    var shouldCenterUserOnMap = true
    let systemSoundID: SystemSoundID = 1010
    var soundEnable = true
    let colorOne = UIColor(red:0.86, green:0.32, blue:0.32, alpha:1.0)
    let colorTwo = UIColor(red:0.91, green:0.45, blue:0.15, alpha:1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUI()
        checkLocationServices()
        FIRFirestoreService.shared.read(from: .zones, returning: Zone.self) { (zones) in
            self.zones = zones
            self.generateRegions()
        }
    }
    
    func createAlertForZone(zone: Zone){
        if let id = zone.id {
            if soundEnable == true {
                AudioServicesPlaySystemSound (systemSoundID)
            }
            let alert = UIAlertController(title: "ВНИМАНИЕ!", message: "Влеговте во РАДАР зона.\nДали оваа информација е точна?\nID = \(id)", preferredStyle: .alert)
            let button1 = UIAlertAction(title: "НЕ", style: .destructive, handler: { action in
                FIRFirestoreService.shared.delete(zone, in: .zones)
            })
            let button2 = UIAlertAction(title: "ДА", style: .default, handler: nil)
            alert.addAction(button1)
            alert.addAction(button2)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func setUI(){
        backgroundView.setGradientBackground(colorOne: colorTwo, colorTwo: colorOne)
        buttonOne.setBackgroundImage(UIImage(named: "sound-on"), for: .normal)
    }
    
    func checkLocationServices(){
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            mapView.delegate =  self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationPermissions()
        } else {
            // show pop up to turn on locations
        }
    }
    
    func checkLocationPermissions(){
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            break
        case .restricted:
            // show pop up that locations are restricted
            self.alertLocationAccessNeeded()
            break
        case .denied:
            // show pop up to redirect to settings
            self.alertLocationAccessNeeded()
            break
        case .authorizedAlways:
            // start tracking user location
            startTrackingUserOnMap()
            break
        case .authorizedWhenInUse:
            // show pop up to redirect to settings
            self.alertLocationAccessNeeded()
            break
        @unknown default:
            exit(0)
            break
        }
    }
    
    func alertLocationAccessNeeded() {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
        
        let alert = UIAlertController(
                   title: "Need Location Access",
                   message: "Allways Allow is required for Location access and draw zones ",
                   preferredStyle: UIAlertController.Style.alert
            )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
            exit(0)
        }))
        alert.addAction(UIAlertAction(title: "Allways Allow", style: .cancel, handler: { (alert) -> Void in
            UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
        }))
        present(alert, animated: true, completion: nil)
        }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationPermissions()
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        locationManager.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if shouldCenterUserOnMap == true {
            if locations.isEmpty == false {
                let location = locations.first
                if let coordinate = location?.coordinate {
                    let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
                    mapView.setRegion(region, animated: true)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == .inside {
            if let zone = regionArray[region]{
                createAlertForZone(zone: zone)
            }
        }
    }
    
    func startTrackingUserOnMap(){
        mapView.showsUserLocation = true
        locationManager.startUpdatingLocation()
        centerUserOnMap()
    }
    
    func centerUserOnMap(){
        if let location = locationManager.location?.coordinate{
            let region = MKCoordinateRegion(center: location, latitudinalMeters: 400, longitudinalMeters: 400)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func generateRegions(){
        if zones.isEmpty == false {
            mapView.removeOverlays(mapView.overlays)
            for zone in zones {
                if let id = zone.id {
                    let coordinate = CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude)
                    let region = CLCircularRegion(center: coordinate, radius: Double(100), identifier: id)
                    locationManager.startMonitoring(for: region)
                    regionArray[region] = zone
                    let circle = MKCircle(center: coordinate, radius: Double(100))
                    mapView.addOverlay(circle)
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circleOverlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(circle: circleOverlay)
            circleRenderer.fillColor = UIColor.black
            circleRenderer.strokeColor = UIColor.red
            circleRenderer.alpha = 0.3
            return circleRenderer
        } else {
            return MKOverlayRenderer()
        }
    }
    
    @IBAction func resetPressed(_ sender: Any) {
        shouldCenterUserOnMap = true
        dismissTracking.isEnabled = true
    }
    
    @IBAction func annotationPointPressed(_ sender: UIButton) {
        let coordinate = Zone(longitude: locationManager.location!.coordinate.longitude, latitude: locationManager.location!.coordinate.latitude)
        FIRFirestoreService.shared.create(for: coordinate, in: .zones)
    }
    
    @IBAction func longGesturePressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let touchLocation = sender.location(in: mapView)
            let coordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            let alert = UIAlertController(title: "Додадете Радар!", message: "Селектиравте зона за додавање.\nДали оваа информација е точна?", preferredStyle: .alert)
            let button1 = UIAlertAction(title: "НЕ", style: .destructive, handler: nil)
            let button2 = UIAlertAction(title: "ДА", style: .default, handler: { action in
                let coordsOpened = Zone(longitude: coordinate.longitude, latitude: coordinate.latitude)
                FIRFirestoreService.shared.create(for: coordsOpened, in: .zones)
            })
            alert.addAction(button1)
            alert.addAction(button2)
            present(alert, animated: true, completion: nil)
            
        }
    }
    @IBAction func mapButton(_ sender: UIButton) {
        dismissTracking.isEnabled = false
        shouldCenterUserOnMap = false
    }
    
    @IBAction func panRecognized(_ sender: UIPanGestureRecognizer) {
        shouldCenterUserOnMap = false
    }
    
    @IBAction func soundButtonPressed(_ sender: UIButton) {
        if sender.isSelected {
            soundEnable = true
        } else {
            soundEnable = false
        }
        sender.isSelected = !sender.isSelected
        buttonOne.setBackgroundImage(UIImage(named: "sound-off"), for: .selected)
        buttonOne.setBackgroundImage(UIImage(named: "sound-on"), for: .normal)
    }
}

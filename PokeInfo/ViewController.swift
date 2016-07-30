//
//  ViewController.swift
//  PokeInfo
//
//  Created by Nicholas D'hondt on 22/07/16.
//  Copyright © 2016 Nicholas D'hondt. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import Alamofire_SwiftyJSON
import SwiftyJSON
import AVFoundation

class ViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var pokeMap: MKMapView!
    var locations = [MKPointAnnotation]()
    var descriptionStored = String();
    var timer = NSTimer();
    var wildArr = [String]();
    var nearbyArr = [String]();
    var catchableArr = [String]();
    var currentLocation = CLLocation();
    var oldLocation = CLLocation();
    
    var allPokemons = [Pokemon]();
    var player: AVQueuePlayer!
    var initizalized = false;
    var pokemonsInArea = [Double : Pokemon]();
    
    

    
    lazy var locationManager: CLLocationManager! = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.pausesLocationUpdatesAutomatically = true;
        return manager
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.startUpdatingLocation()
        pokeMap.delegate = self

        var helloWorldTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(ViewController.fireCalls), userInfo: nil, repeats: true)

        
        var error: NSError?
        
        var success: Bool
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSessionCategoryPlayAndRecord,
                withOptions: .DefaultToSpeaker)
            success = true
        } catch var error1 as NSError {
            error = error1
            success = false
        }
        if !success {
            NSLog("Failed to set audio session category.  Error: \(error)")
        }
        let songNames = ["higher"]
        let songs = songNames.map { AVPlayerItem(URL:
            NSBundle.mainBundle().URLForResource($0, withExtension: "mp3")!) }
        
        player = AVQueuePlayer(items: songs)
        player.actionAtItemEnd = .Advance
        player.play();
        player.volume = 0.00001;
        

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func accuracyChanged(sender: UISegmentedControl) {
        let accuracyValues = [
            kCLLocationAccuracyBestForNavigation,
            kCLLocationAccuracyBest,
            kCLLocationAccuracyNearestTenMeters,
            kCLLocationAccuracyHundredMeters,
            kCLLocationAccuracyKilometer,
            kCLLocationAccuracyThreeKilometers]
        
        locationManager.desiredAccuracy = accuracyValues[sender.selectedSegmentIndex];
    }
    
    @IBAction func changed(sender: UISwitch) {
        if (sender.on) {
            //locationManager.startUpdatingLocation()
            player.play()
        } else {
            //locationManager.stopUpdatingLocation()
            player.pause()
        }
    }
    
    
    
    func sendNotification(description:String){
        // create a corresponding local notification
        if descriptionStored != description {
        let notification = UILocalNotification()
        notification.alertBody = description // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = NSDate.init(timeIntervalSinceNow: NSTimeInterval.init(0))  // todo item due date (when notification will be fired)
        notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        //notification.userInfo = ["title": item.title, "UUID": item.UUID] // assign a unique identifier to the notification so that we can retrieve it later
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
            descriptionStored = description;
        }
    }
    
    func showOnMap(pokemon: Pokemon){
        print (pokemon.pokemon_name);
        
        // Sometimes there is no latitude or longitude so I check if latitude exists
            let lat = pokemon.latitude
            let lng = pokemon.longitude;
            let annotation = MKPointAnnotation()
            let locatie = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            annotation.coordinate = locatie;
            annotation.title = pokemon.pokemon_id.description;
            print (annotation.title)
          
            
            self.pokeMap.addAnnotation(annotation)
            //self.pokeMap.showAnnotations(self.pokeMap.annotations, animated: true)
            self.pokeMap.zoomEnabled = true;
            self.showAnnotations();
            //self.pokeMap.selectAnnotation(self.pokeMap.annotations[0], animated: true)
            //self.pokeMap.selectAnnotation(self.pokeMap.annotations[self.pokeMap.annotations.count], animated: true)
        
        
        
    }
    
    func mapView(mapView: MKMapView!,
                 viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let pokemonId = annotation.title!
        let reuseId = pokemonId
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId!)
        if pinView == nil {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            let image = UIImage(named:pokemonId!)!
            pinView!.image = image
            
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }

    
    // Transform json to Pokemon Object
    func makePokemon (json:JSON)-> Pokemon{
        print(json);
         let pokemon = Pokemon (pokemon_name: json["pokemon_name"].string!, pokemon_id: json["pokemon_id"].double!,spawnpoint_id: json["spawnpoint_id"].string!, longitude: json["longitude"].double!,latitude: json["latitude"].double!, time_till_hidden_ms: json["time_till_hidden_ms"].double!)
        return pokemon
    }
    
    
    
    // Function to check if the pokemon is already added to the array or not
    func addToPokemonArray(pokemon:Pokemon){
        
    }
    
    func fireCalls(){
        
        let newLocation = currentLocation;
        
        // Show pokemons on map
        let urlPathPokemon:String = "http://37.139.15.120:5000/nearby";
        Alamofire.request(.POST,urlPathPokemon, parameters: ["auth_service": "ptc","username":"nxmap123","password" : "Azerty123", "lat" : newLocation.coordinate.latitude.description, "lng" :  newLocation.coordinate.longitude.description])
            .responseJSON { response in
                let json = JSON(data : response.data!)
                print(json)
                
                if let wild = json["wild"].array {
                    var tempWild = [String]();
                    for var pokemon in wild{
                        if !self.wildArr.contains(pokemon["pokemon_name"].string!){

                            if UIApplication.sharedApplication().applicationState == .Active {
                        
                            } else {
                                self.sendNotification(pokemon["pokemon_name"].string! + " is wild");
                            }
                        }
                        
                        tempWild.append(pokemon["pokemon_name"].string!);
                        let wild = self.makePokemon(pokemon)
                        self.pokemonsInArea[pokemon["encounter_id"].double!] = wild;
                    }
                    // Overwrite global wildArr with new updated one
                    self.wildArr = tempWild;
                    
                    
                }
                self.showPokemonsAndDeleteOldOnes()

                
        };
        
        
        
        // Spin pokestops
        let urlPathPokemonForts:String = "http://37.139.15.120:5000/forts";
        Alamofire.request(.POST,urlPathPokemonForts, parameters: ["auth_service": "ptc","username":"nxmap123","password" : "Azerty123", "lat" : newLocation.coordinate.latitude.description, "lng" :  newLocation.coordinate.longitude.description])
            .responseJSON { response in
                let json = JSON(data : response.data!)
                print (json);
                if let result = json[0]["result"].double {
                    if result == 1{
                        
                        
                        if UIApplication.sharedApplication().applicationState == .Active {
                            // create the alert
                            let alert = UIAlertController(title: "Pokestop Spinned", message: "50 XP and some items Gained", preferredStyle: UIAlertControllerStyle.Alert)
                            
                            // add an action (button)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                            
                            // show the alert
                            self.presentViewController(alert, animated: true, completion: nil)
                            
                        } else {
                            self.sendNotification("Pokestop spinned");
                        }
                    }
                    else if result == 4 {
                        if UIApplication.sharedApplication().applicationState == .Active {
                            // create the alert
                            let alert = UIAlertController(title: "Pokestop Spinned", message: "50 XP and some items Gained", preferredStyle: UIAlertControllerStyle.Alert)
                            
                            // add an action (button)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                            
                            // show the alert
                            self.presentViewController(alert, animated: true, completion: nil)
                            
                        } else {
                            self.sendNotification("Pokestop spinned: Bag is full");
                        }
                    }
                }
                print (json);
                
        };
    }
    
    func showPokemonsAndDeleteOldOnes(){
        deleteAnnotations();
        for (encounterID, pokemon) in pokemonsInArea {
            if (pokemon.availableTill.isGreaterThanDate(NSDate())){
                showOnMap(pokemon)
            }
            else {
            pokemonsInArea[encounterID] = nil;
            }
        }
    }
    func locationHandler(newLocation: CLLocation){
        currentLocation = newLocation;
    
    }
    
    func showAnnotations(){
        for var annotation in self.pokeMap.annotations{
            //pokeMap.selectAnnotation(annotation, animated: true)
        }
    }
    
    func deleteAnnotations(){
        for var annotation in self.pokeMap.annotations{
            pokeMap.removeAnnotation(annotation);
        }
    }
    
    /*
    func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError!) {
        // Stop deferring updates
        self.deferringUpdates = false
        
        // Adjust for the next goal
    }
 */

    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        
        
            var interval  = NSTimeInterval();
            interval = 30;
            
        
        
            // Check  every 10 meters
            var distance = CLLocationDistance();
            distance = 10;
            locationManager.distanceFilter = distance;
        
        
        
     
        // Zoom to user location
        self.pokeMap.showsUserLocation = true
        
        if (!initizalized){
            initizalized = true;
        
        var latDelta:CLLocationDegrees = 0.005
        
        var lonDelta:CLLocationDegrees = 0.005
        
        var span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        
        var location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude)
        
        var region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        
        self.pokeMap.setRegion(region, animated: true)
        }
        
        do {
            print(newLocation);
            self.locationHandler(newLocation)
        } catch {
            NSLog("No location found yet");
        }

        
        if UIApplication.sharedApplication().applicationState == .Active {
            
        } else {
            NSLog("App is backgrounded. New location is %@", newLocation)
        }
    }


}
extension NSDate {
    func isGreaterThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    func isLessThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending {
            isLess = true
        }
        
        //Return Result
        return isLess
    }
    
    func equalToDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isEqualTo = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedSame {
            isEqualTo = true
        }
        
        //Return Result
        return isEqualTo
    }
    
    func addDays(daysToAdd: Int) -> NSDate {
        let secondsInDays: NSTimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded: NSDate = self.dateByAddingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    func addHours(hoursToAdd: Int) -> NSDate {
        let secondsInHours: NSTimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded: NSDate = self.dateByAddingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}


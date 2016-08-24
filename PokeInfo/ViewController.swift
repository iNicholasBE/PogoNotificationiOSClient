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
    
    @IBOutlet weak var connectedLabel: UILabel!
    var allPokemons = [Pokemon]();
    var audioPlayer = AVAudioPlayer()
    var initizalized = false;
    var pokemonsInArea = [Double : Pokemon]();
    
    
    lazy var locationManager: CLLocationManager! = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.allowsBackgroundLocationUpdates = true;
        //manager.pausesLocationUpdatesAutomatically = true;
        return manager
    }()

    
    override func viewDidDisappear(animated: Bool) {
        //Check if connection is still oké, otherwise let them login again.
        fireCalls();
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if user is loged-in otherwise show login-screen
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.objectForKey("userLoggedIn") == nil {
            if let loginController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as? LoginViewController {
                self.navigationController?.presentViewController(loginController, animated: true, completion: nil)
            }
        }
        
        locationManager.startUpdatingLocation()
        pokeMap.delegate = self
        
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        playBackgroundMusic("sea.mp3")
        
        var helloWorldTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(ViewController.fireCalls), userInfo: nil, repeats: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        //
        self.pokeMap.showsUserLocation = true
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func startAudio() {
        let filePath = NSBundle.mainBundle().pathForResource("sea", ofType: "mp3")
        let fileURL = NSURL.fileURLWithPath(filePath!)
        do {
            audioPlayer = try AVAudioPlayer.init(contentsOfURL: fileURL, fileTypeHint: AVFileTypeMPEGLayer3)
            audioPlayer.numberOfLoops = -1
            audioPlayer.volume = 0.2
        } catch {
            self.presentViewController(UIAlertController.init(title: "Error", message: "Error Message", preferredStyle: .Alert), animated: true, completion: nil)
        }
        audioPlayer.play()
        
    }

    
    @IBAction func switchChanged(sender: UISwitch) {
        
        if sender.on{
            //audioPlayer.play()
            timer.fire()
            locationManager.startUpdatingLocation()
        }
        else{
            //audioPlayer.pause()
            timer.invalidate()
            locationManager.stopUpdatingLocation()
        }
        
    }
    
    func changeConnectionStatus(connected : Bool){
        if connected == true {
            
            connectedLabel.textColor = UIColor.greenColor()
            connectedLabel.text = "Connected";
        }
        else {
            connectedLabel.textColor = UIColor.redColor()
            connectedLabel.text = "Disconnected";
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
        
            let lat = pokemon.latitude
            let lng = pokemon.longitude;
            let annotation = MKPointAnnotation()
            let locatie = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            annotation.coordinate = locatie;
            annotation.title = pokemon.pokemon_id.description;
            print (annotation.title)

            self.pokeMap.addAnnotation(annotation)
            self.pokeMap.zoomEnabled = true;
            self.showAnnotations();
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
        print(json);
         let pokemon = Pokemon (pokemon_name: json["pokemon_name"].string!, pokemon_id: json["pokemon_id"].double!,spawnpoint_id: json["spawn_point_id"].string!, longitude: json["longitude"].double!,latitude: json["latitude"].double!, time_till_hidden_ms: json["time_till_hidden_ms"].double!)
        return pokemon
    }
    

    func fireCalls(){
        
        let newLocation = currentLocation;
        
        // Show pokemons on map
        let urlPathPokemon:String = "http://37.139.15.120:5000/nearby";
        print("New Location latitude: " + newLocation.coordinate.latitude.description);
        Alamofire.request(.POST,urlPathPokemon, parameters: ["lat" : newLocation.coordinate.latitude.description, "lng" :  newLocation.coordinate.longitude.description, "radius" : 3])
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
                    self.changeConnectionStatus(true)
                }
                else {
                    self.changeConnectionStatus(false)
                }
                self.showPokemonsAndDeleteOldOnes()
        };
        
        
        
        // Spin pokestops
        let urlPathPokemonForts:String = "http://37.139.15.120:5000/forts";
        Alamofire.request(.POST,urlPathPokemonForts, parameters: ["lat" : newLocation.coordinate.latitude.description, "lng" :  newLocation.coordinate.longitude.description])
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
    }
    
    func deleteAnnotations(){
        for var annotation in self.pokeMap.annotations{
            pokeMap.removeAnnotation(annotation);
        }
    }
    
    func setMapToUserLocation(newLocation: CLLocation){
        let latDelta:CLLocationDegrees = 0.005
        let lonDelta:CLLocationDegrees = 0.005
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        self.pokeMap.setRegion(region, animated: true)
        self.pokeMap.showsUserLocation = true
    }
    
    
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
            setMapToUserLocation(newLocation)
        }
        
        do {
            //print(newLocation);
            self.currentLocation = newLocation
            //self.locationHandler(newLocation)
        } catch {
            NSLog("No location found yet");
        }

        
        if !(UIApplication.sharedApplication().applicationState == .Active) {
             NSLog("App is backgrounded. New location is %@", newLocation)
        }
    }


}

import AVFoundation

var backgroundMusicPlayer = AVAudioPlayer()

func playBackgroundMusic(filename: String) {
//NSBundle.mainBundle().URLForResource(<#T##name: String?##String?#>, withExtension: <#T##String?#>)
    let url = NSBundle.mainBundle().URLForResource(filename, withExtension: nil)
    guard let newURL = url else {
        print("Could not find file: \(filename)")
        return
    }
    do {
        backgroundMusicPlayer = try AVAudioPlayer(contentsOfURL: newURL)
        backgroundMusicPlayer.numberOfLoops = -1
        backgroundMusicPlayer.prepareToPlay()
        backgroundMusicPlayer.play()
    } catch let error as NSError {
        print(error.description)
    }
}

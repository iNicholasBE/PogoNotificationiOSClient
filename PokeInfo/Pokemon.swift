//
//  Pokemon.swift
//  PokeInfo
//
//  Created by Nicholas D'hondt on 24/07/16.
//  Copyright © 2016 Nicholas D'hondt. All rights reserved.
//

import Foundation
import MapKit

class Pokemon {
    var pokemon_name:String
    var pokemon_id : Double
    var spawnpoint_id:String
    var longitude:Double
    var latitude:Double
    var coordinate:CLLocation
    var time_till_hidden_ms:Double
    var availableTill:NSDate
    
    init (pokemon_name:String,pokemon_id : Double,spawnpoint_id:String,longitude:Double,latitude:Double, time_till_hidden_ms:Double  = 0){
        self.pokemon_name = pokemon_name
        self.pokemon_id = pokemon_id
        self.spawnpoint_id = spawnpoint_id
        self.longitude = longitude
        self.latitude = latitude
        self.coordinate = CLLocation(latitude: latitude, longitude: longitude)
        self.time_till_hidden_ms = time_till_hidden_ms;
        self.availableTill = NSDate().dateByAddingTimeInterval(time_till_hidden_ms/1000);
    }
    
    
}

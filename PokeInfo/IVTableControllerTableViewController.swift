//
//  IVTableControllerTableViewController.swift
//  PokeInfo
//
//  Created by Nicholas D'hondt on 31/07/16.
//  Copyright © 2016 Nicholas D'hondt. All rights reserved.
//

import UIKit
import Alamofire
import Alamofire_SwiftyJSON
import SwiftyJSON

class IVTableControllerTableViewController: UITableViewController {

    @IBOutlet var fullTable: UITableView!
  
    let textCellIdentifier = "pokemonCell"
    
    var allPokemons = [PokemonIV]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData();
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsetsMake(60,0,0,0);
    }
    
    override func viewDidAppear(animated: Bool) {
        loadData();
        tableView.reloadData()
    }
    
    func loadData(){
        
        // Show pokemons IV
        let urlPathPokemon:String = "http://37.139.15.120:5000/pokemons";
        Alamofire.request(.POST,urlPathPokemon, parameters: [:])
            .responseJSON { response in
                let json = JSON(data : response.data!)
                print(json)
                if json.count == 0 || json["success"].bool == false {
                    return;
                }
                self.allPokemons.removeAll()
                for pokemon in json.array! {
                    let tempPokemon = PokemonIV();
                    tempPokemon.name = pokemon["pokemon_name"].string!
                    tempPokemon.id = pokemon["pokemon_id"].int!
                    tempPokemon.cp = pokemon["cp"].int!
                    tempPokemon.attack = pokemon["individual_attack"].int!
                    tempPokemon.stamina = pokemon["individual_stamina"].int!
                    tempPokemon.defense = pokemon["individual_defense"].int!
                    self.allPokemons.append(tempPokemon);

                }
               self.tableView.reloadData();
            }
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allPokemons.count;
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("detaillcell") as! pokemenCellTableViewCell
        
        cell.pokemonName.text = allPokemons[indexPath.row].name;
        cell.ivs.text = String(allPokemons[indexPath.row].attack) + "/" +  String(allPokemons[indexPath.row].defense) + "/" +  String(allPokemons[indexPath.row].stamina);

        cell.perfection.text = String(allPokemons[indexPath.row].perfection()) + "%"
        return cell;
    }

    
}

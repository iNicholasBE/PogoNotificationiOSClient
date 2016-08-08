//
//  LogoutViewController.swift
//  PokeInfo
//
//  Created by Nicholas D'hondt on 31/07/16.
//  Copyright © 2016 Nicholas D'hondt. All rights reserved.
//

import Foundation
import UIKit



class LogoutViewController: UIViewController{

    
    @IBAction func LogoutTouched(sender: UIButton) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey("userLoggedIn")
        defaults.synchronize()
        if let loginController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as? LoginViewController {
            self.navigationController?.presentViewController(loginController, animated: true, completion: nil)
        }
    }

}

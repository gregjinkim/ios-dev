//
//  ViewController.swift
//  photo_tutorial
//
//  Created by Greg J. Kim on 6/14/16.
//  Copyright © 2016 Greg Kim. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    private let dataURL = "https://photo-tutorial.firebaseio.com"
    
    var imagePicker: UIImagePickerController!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
    }

    @IBOutlet weak var imageView: UIImageView!

    @IBAction func takePhoto(sender: UIButton) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        if (UIImagePickerController.isSourceTypeAvailable(.Camera)) {
            imagePicker.sourceType = .Camera
            presentViewController(imagePicker, animated: true, completion: nil)

        }
    }
    
    @IBAction func loginWithFacebook(sender: AnyObject) {
        let facebookLogin = FBSDKLoginManager()
        print("Logging In")
        facebookLogin.logInWithReadPermissions(["user_friends", "public_profile"],
            fromViewController: self, handler:{(facebookResult, facebookError) -> Void in
            if facebookError != nil { print("Facebook login failed. Error \(facebookError)")
            } else if facebookResult.isCancelled { print("Facebook login was cancelled.")
            } else {
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                    // ...
                }
            }
        });
    }
}


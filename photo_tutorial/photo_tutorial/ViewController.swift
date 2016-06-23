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
    //let storage = FIRStorage.storage()
    //let databaseRef = FIRDatabase.database().reference()
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Opens view controller to allow user to pick photo from library
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Need to upload pickedImage to firebase
            let imageData: NSData = UIImagePNGRepresentation(pickedImage)!
            let storage = FIRStorage.storage()
            let storageRef = storage.referenceForURL("gs://photo-tutorial.appspot.com")
            let imagesRef = storageRef.child("images")
            let imageName = "user1.png"
            let userImagesRef = imagesRef.child(imageName)
            userImagesRef.putData(imageData, metadata: nil) { metadata, error in
                if (error != nil) {
                    print("Fuck error")
                } else {
                    print("yay it worked")
                    self.loadRandomPicture()
                }
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func loadRandomPicture() {
        let storage = FIRStorage.storage()
        let imagesRef = storage.referenceForURL("gs://photo-tutorial.appspot.com/images")
        let imageName = "user1.png"
        let imageRef = imagesRef.child(imageName)
        imageRef.dataWithMaxSize(100 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                print("error with downloading image from Firebase: \(error.debugDescription)")
            } else {
                let image: UIImage! = UIImage(data: data!)
                
                self.imageView.contentMode = UIViewContentMode.ScaleAspectFill
                self.imageView.clipsToBounds = false
                self.imageView.layer.masksToBounds = true
                self.imageView.image = image
                
            }
        }    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func takePhoto(sender: UIButton) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        
        presentViewController(imagePicker, animated: true, completion: nil)
        
    }
    
    @IBAction func loginWithFacebook(sender: AnyObject) {
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logInWithReadPermissions(["user_friends", "public_profile", "email"],
            fromViewController: self, handler:{(facebookResult, facebookError) -> Void in
            if facebookError != nil { print("Facebook login failed. Error \(facebookError)")
            } else if facebookResult.isCancelled { print("Facebook login was cancelled.")
            } else {
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                    // ...
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        print("successfully logged in")
                        let photoTakerController = (self.storyboard?.instantiateViewControllerWithIdentifier("PhotoTaker"))!
                            as UIViewController
                        
                        self.presentViewController(photoTakerController, animated: true, completion: nil)
                    }
                }
            }
        });
    }
}


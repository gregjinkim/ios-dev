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
    
    // Opens view controller to allow user to pick photo from library
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Need to upload pickedImage to firebase
            let targetSize = CGSize(width: 350.0, height: 400.0)
            let resizedImage = self.ResizeImage(pickedImage, targetSize: targetSize)
            let imageData: NSData = UIImagePNGRepresentation(resizedImage)!
            
            let storage = FIRStorage.storage()
            let imagesURL = "gs://photo-tutorial.appspot.com/images"
            let imagesRef = storage.referenceForURL(imagesURL)
            
            let defaults = NSUserDefaults.standardUserDefaults()
            let uid = defaults.stringForKey("uid")!
            let randomNum = arc4random_uniform(1024 * 1024)
            let imageName = uid + "_" + String(randomNum) + ".jpeg"
            let userImagesRef = imagesRef.child(imageName)
            userImagesRef.putData(imageData, metadata: nil) { metadata, error in
                if (error != nil) {
                    print("Fuck error")
                } else {
                    print("yay it worked")
                    self.loadRandomPicture()
                }
            }
            
            let databaseRef = FIRDatabase.database().reference()
            databaseRef.child("imageLocations").setValue(["imageURL": imagesURL + imageName])
            let key = databaseRef.child("userImages").child(uid).childByAutoId().key
            let imagePost = ["imageURL" : imagesURL + imageName]
            let imageUpdate = ["/userImages/\(uid)/\(key)/": imagePost]
            databaseRef.updateChildValues(imageUpdate)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func ResizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSizeMake(size.width * heightRatio, size.height * heightRatio)
        } else {
            newSize = CGSizeMake(size.width * widthRatio,  size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRectMake(0, 0, newSize.width, newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func loadRandomPicture() {
        let storage = FIRStorage.storage()
        let imagesRef = storage.referenceForURL("gs://photo-tutorial.appspot.com/images")
        let imageName = "user1.jpeg"
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
    
    @IBAction func uploadPhoto(sender: UIButton) {
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
                        print("successfully logged in user: \(user!.uid)")
                        
                        // save user id as default variable in app
                        let defaults = NSUserDefaults.standardUserDefaults()
                        defaults.setValue(user!.uid, forKey: "uid")
                        defaults.synchronize()
                        
                        // saved user id to database
                        let databaseRef = FIRDatabase.database().reference()
                        databaseRef.child("users").setValue(["userId": user!.uid])
                        
                        let photoTakerController = (self.storyboard?.instantiateViewControllerWithIdentifier("PhotoTaker"))!
                            as UIViewController
                        
                        self.presentViewController(photoTakerController, animated: true, completion: nil)
                    }
                }
            }
        });
    }
}


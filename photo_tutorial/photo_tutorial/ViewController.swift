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

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate {
    private let dataURL = "https://photo-tutorial.firebaseio.com"
    private var currentImageURL = ""
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    // Opens view controller to allow user to pick photo from library
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Need to upload pickedImage to firebase
            let targetSize = CGSize(width: 350.0, height: 320.0)
            let resizedImage = self.ResizeImage(pickedImage, targetSize: targetSize)
            let imageData: NSData = UIImagePNGRepresentation(resizedImage)!
            
            self.uploadImageView.contentMode = UIViewContentMode.ScaleAspectFill
            self.uploadImageView.clipsToBounds = false
            self.uploadImageView.layer.masksToBounds = true
            self.uploadImageView.image = resizedImage
            
            let storage = FIRStorage.storage()
            let imagesURL = "gs://photo-tutorial.appspot.com/images/"
            let imagesRef = storage.referenceForURL(imagesURL)
            
            let defaults = NSUserDefaults.standardUserDefaults()
            let uid = defaults.stringForKey("uid")!
            
            let databaseRef = FIRDatabase.database().reference()
            let key = databaseRef.child("imagesInfo").childByAutoId().key
            //let randomNum = arc4random_uniform(1024 * 1024)
            let imageName = key + ".jpeg"
            
            
            let userImagesRef = imagesRef.child(imageName)
            userImagesRef.putData(imageData, metadata: nil) { metadata, error in
                if (error != nil) {
                    print("Fuck error")
                } else {
                    print("yay it worked")
                    //self.loadRandomPicture()
                }
            }
            
            //let databaseRef = FIRDatabase.database().reference()
            //let key = databaseRef.child("imagesInfo").childByAutoId().key
            
            let userImagePost = ["imageURL" : imagesURL + imageName]
            let imagesInfoPost = ["imageURL": imagesURL + imageName, "uid": uid]
            let update = ["/userImages/\(uid)/\(key)/": userImagePost, "/imagesInfo/\(key)/": imagesInfoPost]

            databaseRef.updateChildValues(update)
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
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child("imagesInfo").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            let childrenCount = snapshot.childrenCount
            var randomImageIndex = arc4random_uniform(UInt32(childrenCount))
            

            let children = snapshot.children.allObjects
            var imageURL: String? = nil
            var tries = 0
            while (imageURL == nil && tries < 10) {
                let child = children[Int(randomImageIndex)]
                let imageUserId = child.value!["uid"] as! String
                if (self.canShowImage(imageUserId)) {
                    imageURL = child.value!["imageURL"] as? String
                }
                randomImageIndex = arc4random_uniform(UInt32(childrenCount))
                tries += 1
            }
            
            if (imageURL != nil) {
            
                let storage = FIRStorage.storage()
                let imageRef = storage.referenceForURL(imageURL!)
                imageRef.dataWithMaxSize(100 * 1024 * 1024) { (data, error) -> Void in
                    if (error != nil) {
                        print("error with downloading image from Firebase: \(error.debugDescription)")
                    } else {
                        let image: UIImage! = UIImage(data: data!)
                        
                        self.randomImageView.contentMode = UIViewContentMode.ScaleAspectFill
                        self.randomImageView.clipsToBounds = false
                        self.randomImageView.layer.masksToBounds = true
                        
                        self.randomImageView.image = image
                        self.currentImageURL = imageURL!
                    }
                }
            }

        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func canShowImage(imageUserId: String) -> Bool {
        //let defaults = NSUserDefaults.standardUserDefaults()
        //let uid = defaults.stringForKey("uid")!
        /*let friends = defaults.arrayForKey("friends")!
        for friend in friends {
            if (imageUserId == friend as! String) {
                return false
            }
        }
        
        if (uid == imageUserId) {
            return false
        }*/
        return true
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBOutlet weak var uploadImageView: UIImageView!
    
    @IBOutlet weak var randomImageView: UIImageView!
    
    @IBOutlet weak var ratingScore: UILabel!
    
    @IBOutlet weak var myRating: UILabel!
    
    @IBOutlet weak var raterImageView: UIImageView!
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        let rating = Int(sender.value)
        self.ratingScore.text = "\(rating)"
    }
    
    @IBAction func rateImage(sender: AnyObject) {
        let scoreString = self.ratingScore.text
        if let scoreInt = Int(scoreString!) {
            if (scoreInt >= 0 && scoreInt <= 100) {
                let databaseRef = FIRDatabase.database().reference()
                let key = databaseRef.child("imageRatings").childByAutoId().key
                let imageURL = self.currentImageURL
                
                let defaults = NSUserDefaults.standardUserDefaults()
                let uid = defaults.stringForKey("uid")!
                let ratingPost = ["rating" : scoreInt, "uid" : uid]
                let imageId = self.getImageIdFromURL(imageURL)
                let update = ["/imageRatings/\(imageId)/\(key)/": ratingPost]
                
                databaseRef.updateChildValues(update)
                
                loadRandomPicture()
            } else {
                self.showErrorForRating()
            }
        } else {
            self.showErrorForRating()
        }
    }
    
    func getImageIdFromURL(imageURL: String) -> String {
        return imageURL.componentsSeparatedByString(".")[2].componentsSeparatedByString("/")[2]
    }
    
    @IBAction func showNextRating(sender: AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        let uid = defaults.stringForKey("uid")!
        
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child("userImages").child(uid).queryLimitedToLast(1).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if (snapshot.childrenCount > 0) {
                let imagePost = snapshot.children.nextObject()
                let imageURL = imagePost!.value!["imageURL"] as! String
                let imageId = self.getImageIdFromURL(imageURL)
                databaseRef.child("imageRatings").child(imageId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                    if (snapshot.childrenCount > 0) {
                        let currentRatingPost = snapshot.children.nextObject()
                        let currentRating = currentRatingPost!.value!["rating"] as! Int
                        self.myRating.text = String(currentRating)
                        self.accumulateAndDeleteRating(imageId, rating: currentRating)

                        let raterId = currentRatingPost!.value!["uid"] as! String
                        let databaseRef = FIRDatabase.database().reference()
                        
                        databaseRef.child("userImages").child(String(raterId)).queryLimitedToLast(1).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                            if (snapshot.childrenCount > 0) {
                                let imagePost = snapshot.children.nextObject()
                                let imageURL = imagePost!.value!["imageURL"] as! String
                                
                                let storage = FIRStorage.storage()
                                let imageRef = storage.referenceForURL(imageURL)
                                imageRef.dataWithMaxSize(100 * 1024 * 1024) { (data, error) -> Void in
                                    if (error != nil) {
                                        print("error with downloading image from Firebase: \(error.debugDescription)")
                                    } else {
                                        let image: UIImage! = UIImage(data: data!)
                                        
                                        self.raterImageView.contentMode = UIViewContentMode.ScaleAspectFill
                                        self.raterImageView.clipsToBounds = false
                                        self.raterImageView.layer.masksToBounds = true
                                        
                                        self.raterImageView.image = image
                                    }
                                }
                            }
                        }) { (error) in
                            print(error.localizedDescription)
                        }
                    }
                }) { (error) in
                    print(error.localizedDescription)
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func accumulateAndDeleteRating(imageId: String, rating: Int) {
        // put the rating into this user's average and then delete the post from imageRatings so user doesn't see same rating twice.
    }
    
    func showErrorForRating() {
        // show error message for inputing invalid rating
    }
    
    @IBAction func uploadPhoto(sender: UIButton) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        
        presentViewController(imagePicker, animated: true, completion: nil)
        
    }
    
    @IBAction func viewNextImage(sender: AnyObject) {
        loadRandomPicture()
    }
    
    @IBAction func loginWithFacebook(sender: AnyObject) {
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logOut()
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
                        
                        if((FBSDKAccessToken.currentAccessToken()) != nil){
                            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id"], tokenString: FBSDKAccessToken.currentAccessToken().tokenString, version: nil, HTTPMethod: "GET").startWithCompletionHandler({ (connection, result, error) -> Void in
                                if (error == nil){
                                    let idData = result as! NSDictionary
                                    
                                    defaults.setValue(idData.objectForKey("id")! as! String, forKey: "uid")
                                    defaults.synchronize()
                                    
                                    // saved user id to database
                                    let databaseRef = FIRDatabase.database().reference()
                                    
                                    let key = databaseRef.child("users").childByAutoId().key
                                    
                                    let userPost = ["userId" : idData.objectForKey("id")! as! String]
                                    let update = ["/users/\(key)/": userPost]
                                    
                                    databaseRef.updateChildValues(update)
                                } else {
                                    print("error \(error)")
                                }
                            })
                            FBSDKGraphRequest(graphPath: "me/friends", parameters: ["fields": "user_friends"], tokenString: FBSDKAccessToken.currentAccessToken().tokenString, version: nil, HTTPMethod: "GET").startWithCompletionHandler({ (connection, result, error) -> Void in
                                if (error == nil){
                                    let friendsData = result as! NSDictionary
                                    let friendIdsDict = friendsData.objectForKey("data")! as! NSArray
                                    var friendsArray = [String]()
                                    for friendIdData in friendIdsDict {
                                        let friendId = friendIdData as! NSDictionary
                                        friendsArray.append(friendId.objectForKey("id")! as! String)
                                    }
                                    defaults.setValue(friendsArray, forKey: "friends")
                                    defaults.synchronize()
                                } else {
                                    print("error \(error)")
                                }
                            })
                        }
                        
                        let photoTakerController = (self.storyboard?.instantiateViewControllerWithIdentifier("PhotoTaker"))!
                            as UIViewController
                        
                        self.presentViewController(photoTakerController, animated: true, completion: nil)
                        
                        if((FBSDKAccessToken.currentAccessToken()) != nil){
                            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "user_friends"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                                if (error == nil){
                                    print("friends \(result)")
                                }
                            })
                        }
                    }
                }
            }
        });
    }
}


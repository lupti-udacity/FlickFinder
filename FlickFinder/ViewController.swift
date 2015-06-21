//
//  ViewController.swift
//  FlickFinder
//
//  Created by Online Training on 6/20/15.
//  Copyright (c) 2015 Mitch Salcido. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    // Flickr params
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "3bc85d1817c25bfd73b8a05ff26a01c3"
    let EXTRAS = "url_m"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"

    // outlets to storyBoard objects
    @IBOutlet weak var flickImageView: UIImageView!
    @IBOutlet weak var searchByPhraseTextField: UITextField!
    @IBOutlet weak var searchByLatTextField: UITextField!
    @IBOutlet weak var searchByLongTextField: UITextField!
    @IBOutlet weak var imageTitleLabel: UILabel!
    @IBOutlet weak var searchByPhraseButton: UIButton!
    @IBOutlet weak var searchByGeoButton: UIButton!
    
    // tap recognizer, used to dismiss keyboard
    var tapRecognizer: UITapGestureRecognizer!

    // declare a computed property for search by phrase dictionary
    var phaseSearchDictionary: [String: AnyObject] {
        get {
            
            // create dictionary with Flickr search params
            let parameters = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "text": searchByPhraseTextField.text,
                "safe_search": SAFE_SEARCH,
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "nojsoncallback": NO_JSON_CALLBACK,
                "per_page": "100"
            ]
            return parameters
        }
    }
    
    // declare a computed property for search by geography dictionary
    var geoSearchDictionary: [String: AnyObject] {
        get {
            
            // create dictionary with Flickr search params
            let parameters = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "bbox": getBboxString(),
                "safe_search": SAFE_SEARCH,
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "nojsoncallback": NO_JSON_CALLBACK,
                "per_page": "100"
            ]
            return parameters
        }
    }
    
    // current search dictionary
    var searchDictionary: [String: AnyObject]!
    
    //var phaseSearchDictionary =
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // create gr
        tapRecognizer = UITapGestureRecognizer(target: self, action: "tapDetected:")
        tapRecognizer.numberOfTapsRequired = 1
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        subscribeToKeyboardNotifications()
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        unsubscribeToKeyboardNotifications()
    }
    
    // subscribe to keyboard notifications
    func subscribeToKeyboardNotifications() {
        
        /*
        These notifications are used to detect when typing in a textField is beginning/ending
        and the keyboard is about to show/hide
        */
        
        // add self as observer for keyboard show notifications
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "keyboardWillShow:",
            name: UIKeyboardWillShowNotification,
            object: nil)
        
        // add self as observer for keyboard hide notifications
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "keyboardWillHide:",
            name: UIKeyboardWillHideNotification,
            object: nil)
    }
    
    // unsubscribe to keyboard notifications
    func unsubscribeToKeyboardNotifications() {
        
        // remove self as observer for keyboard show notifications
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: UIKeyboardWillShowNotification,
            object: nil)
        
        // remove self as observer for keyboard hide notifications
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: UIKeyboardWillHideNotification,
            object: nil)
    }
    
    // notification fuction..keyboard about to show
    func keyboardWillShow(notification: NSNotification) {
        
        // keyboard is about to show.
        
        // animate out
        UIView.animateWithDuration(0.3, animations: {() -> Void in
            
            self.view.superview?.frame.origin.y -= getKeyboardHeight(notification)
        })
        
        // add gr to view..used to detect tap to initiat dismiss
        self.view.addGestureRecognizer(tapRecognizer)
        
        // disable search buttons while editing
        searchByPhraseButton.enabled = false
        searchByGeoButton.enabled = false
    }
    
    // notification fuction..keyboard about to hide
    func keyboardWillHide(notification: NSNotification) {
        
        
        // keyboard is about to hide
        
        // animate in
        UIView.animateWithDuration(0.3, animations: {() -> Void in
            
            self.view.superview?.frame.origin.y += getKeyboardHeight(notification)
        })
        
        // remove gr from view..no longer needed since keyboard is gone
        self.view.removeGestureRecognizer(tapRecognizer)
        
        // enable search buttons, no longer editing
        searchByPhraseButton.enabled = true
        searchByGeoButton.enabled = true
    }
    
    // get height of keyboard
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        
        // Use notification to retrieve keyboard info, key for size
        
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.CGRectValue().height
    }
    
    // tap detected
    func tapDetected(gr: UIGestureRecognizer) {
     
        // end editing, force textFields to resign first responder
        self.view.endEditing(true)
    }
    
    // delegate, detect return button
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func searchByPhraseButtonPressed(sender: UIButton) {
        
        // test for valid phrase
        if searchByPhraseTextField.text == "" {
            
            // invalid phrase, place message in imageTitle and return
            imageTitleLabel.text = "Enter Valid Phrase"
            return;
        }
        
        // get an image
        getImageFromFlickr(phaseSearchDictionary)
    }

    @IBAction func searchByGeoButtonPressed(sender: UIButton) {
        
        // get an image
        getImageFromFlickr(geoSearchDictionary)
    }
    
    // function t0 create valid long/lat for bbox Flickr search term
    func getBboxString() -> String {
        
        let delta: Float = 0.1 // degrees +/- for bbox
        let long = (searchByLongTextField.text as NSString).floatValue
        let lat = (searchByLatTextField.text as NSString).floatValue
        let longMin = long - delta
        let longMax = long + delta
        let latMin = lat - delta
        let latMax = lat + delta
        
        return "\(longMin),\(latMin), \(longMax),\(latMax)"
    }
    
    func getImageFromFlickr(parameters: [String: AnyObject]) {
        
        // get session, url. Create NSURL and request
        let session = NSURLSession.sharedSession()
        let urlStr = BASE_URL + apiCallStringFromDictionary(parameters)
        let url = NSURL(string: urlStr)!
        let request = NSURLRequest(URL: url)
        
        // create a data task..use completion handler defined below...
        let task = session.dataTaskWithRequest(request, completionHandler: dataTaskCompletionHandler)

        // resume (begin) data task
        task.resume()
    }
    
    /* function to convert a dictionary of Flickr key/value params into a search string suitable
       for use in a url */
    func apiCallStringFromDictionary(parameters: [String: AnyObject]) -> String {
        
        // create an array of stings
        var urlVars = [String]()
        
        // iterate thru parameters
        for (key, value) in parameters {
            
            // Make sure that it is a string value
            let stringValue = "\(value)"
            
            // force to allowed character
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        
        // join result in urlVars array by compbining by "&", return
        let retString = (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
        return retString
    }
    
    // completion handler for dataTaskWithRequest
    func dataTaskCompletionHandler(data: NSData?, response: NSURLResponse?, downloadError: NSError?) {
        
        if let error = downloadError {
            println("Could not complete the request \(error)")
        } else {
            
            // valid response, get JSON data
            var parsingError: NSError? = nil
            let parsedResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
            
            // begin parsing data
            if let photosDict = parsedResult["photos"] as? [String: AnyObject] {
                
                println(photosDict["pages"])
                // declare a photos count, begin at 0, then read "total" key for # of photos
                var count = 0
                if let photosCount = photosDict["total"] as? String {
                    count = (photosCount as NSString).integerValue
                }
                
                // test for photos
                if count > 0 {
                    
                    // read in array of photo dictionaries
                    if let photosArray = photosDict["photo"] as? [[String: AnyObject]] {
                        
                        // get a random photo
                        let randomIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                        let randomPhoto = photosArray[randomIndex] as [String: AnyObject]
                        let randomUrlStr = randomPhoto["url_m"] as? String
                        let imageUrl = NSURL(string: randomUrlStr!)
                        
                        // get image title
                        var title = ""
                        if let imageTitle = randomPhoto["title"] as? String {
                            
                            title = imageTitle
                        }
                        
                        // get image data object
                        if let imageData = NSData(contentsOfURL: imageUrl!) {
                            
                            // good image, convert to UIImage object
                            let image = UIImage(data: imageData)
                            dispatch_async(dispatch_get_main_queue(),  {
                                
                                // update UI
                                self.flickImageView.image = image
                                self.imageTitleLabel.text = title
                            })
                        }
                        else {
                            
                            // bad image
                        }
                    }
                }
                else {
                    
                    dispatch_async(dispatch_get_main_queue(),  {
                        
                        self.flickImageView.image = UIImage(named: "SearchAgain")
                        self.imageTitleLabel.text = "No Image Found..search again"
                    })
                }
            }
        }
    }
}


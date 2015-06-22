//
//  ViewController.swift
//  FlickFinder
//
//  Created by Online Training on 6/20/15.
//  Copyright (c) 2015 Mitch Salcido. All rights reserved.
//
/*
Info:
ViewController is the main VC for this app. After a search button is pressed (search by phrase or by geography),
the function "getImageFromFlickr()" is called. This method is called recursively, first to retrieve page info and select
a random page from available pages, and called again to retrieve the photo using a new dataTask that includes the
key "page".

Notes:
optional "searchPage" is used to steer the search for random page or random photo from page.
*/

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    // defs for geography search
    let MAX_LATITUDE = 90.0
    let MIN_LATITUDE = -90.0
    let MAX_LONGITUDE = 180.0
    let MIN_LONGITUDE = -180.0
    let GEO_DELTA = 0.1 // +/- for search
    
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
    
    // current search dictionary..is created/assigned when search button is pressed
    var searchDictionary: [String: AnyObject]!
    
    // search page..used to steer search for page/photo
    var searchPage: Int? = nil
    
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
        
        // assign search dictionary
        self.searchDictionary = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "text": searchByPhraseTextField.text,
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "per_page": "100"
        ]
        
        // get an image
        getImageFromFlickr()
    }

    @IBAction func searchByGeoButtonPressed(sender: UIButton) {
        
        // get bbox string
        if let bboxString = getBboxString() {
            
            // assign search dictionary
            self.searchDictionary = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "bbox": bboxString,
                "safe_search": SAFE_SEARCH,
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "nojsoncallback": NO_JSON_CALLBACK,
                "per_page": "100"
            ]
            
            // get an image
            getImageFromFlickr()
        }
        else {
            imageTitleLabel.text = "Enter Valid lat/long values"
        }
    }
    
    // function to create valid long/lat for bbox Flickr search term
    func getBboxString() -> String? {
        
        let delta: Float = 0.1 // degrees +/- for bbox
        let long = (searchByLongTextField.text as NSString).floatValue
        let lat = (searchByLatTextField.text as NSString).floatValue
        let longMin = long - delta
        let longMax = long + delta
        let latMin = lat - delta
        let latMax = lat + delta
        
        return "\(longMin),\(latMin), \(longMax),\(latMax)"
    }
    
    // heler function to test for valid float..returns float or nil if bad value (e.g. contains a non-numeric char)
    func floatFromString(string: String) -> Float? {
        
        // test for more than one decimal point
        var testStr = ""
        testStr += string
        var decimalCount = 0
        while testStr.rangeOfString(".") != nil {
            decimalCount++
            testStr.removeRange(testStr.rangeOfString(".")!)
        }
        // more than one decimal..return nil
        if decimalCount > 1 {
            return nil
        }
        
        // test for only valid numerals
        let validNumerals = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        for str in validNumerals {
            
            // remove all instances of valid numerals from testStr
            while testStr.rangeOfString(str) != nil {
                testStr.removeRange(testStr.rangeOfString(str)!)
            }
        }
        
        
        // testStr should now have zero length
        if (testStr as NSString).length > 0 {
            return nil
        }
        
        return (string as NSString).floatValue
    }
    
    func getImageFromFlickr() {
        
        // get session, url. Create NSURL and request
        let session = NSURLSession.sharedSession()
        let urlStr = BASE_URL + apiCallStringFromDictionary(self.searchDictionary)
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
        
        var foundImage = UIImage(named: "SearchAgain")
        var foundImageTitle = "No Image Found..search again"
        
        if let error = downloadError {
            println("Could not complete the request \(error)")
        } else {
            
            // valid response, get JSON data
            var parsingError: NSError? = nil
            let parsedResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
            
            // begin parsing data
            if let photosDict = parsedResult["photos"] as? [String: AnyObject] {
                
                // test for valid page
                if let page = self.searchPage as Int? {
                    
                    // valid random page has already been selected..this pass selects random image
                    
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
                            
                            foundImageTitle = imageTitle
                        }
                        
                        // get image data object
                        if let imageData = NSData(contentsOfURL: imageUrl!) {
                            
                            // good image, convert to UIImage object
                            foundImage = UIImage(data: imageData)
                        }
                    }
                    
                    // set to nil in preparation for next search
                    self.searchPage = nil
                }
                else {
                    
                    // 1. get a random page
                    // 2. assign self.searchPage to this random page
                    // 3. add "page" key to search dictionary
                    // 4. call function getImageFromFlickr()
                    if let pages = photosDict["pages"] as? Int {

                        self.searchPage = Int(arc4random_uniform(UInt32(pages))) + 1
                        self.searchDictionary["page"] = self.searchPage
                        getImageFromFlickr()
                    }
                }
            }
        }
        
        // on second pass thru, searchPage has been reset to nil..OK up update UI
        if (self.searchPage == nil) {
            
            dispatch_async(dispatch_get_main_queue(),  {
                
                // update UI
                self.flickImageView.image = foundImage
                self.imageTitleLabel.text = foundImageTitle
            })
        }
    }
}


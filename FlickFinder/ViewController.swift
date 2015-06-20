//
//  ViewController.swift
//  FlickFinder
//
//  Created by Online Training on 6/20/15.
//  Copyright (c) 2015 Mitch Salcido. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "3bc85d1817c25bfd73b8a05ff26a01c3"
    let EXTRAS = "url_m"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    
    // hardcoded version
    let urlHardCodedStr = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=3bc85d1817c25bfd73b8a05ff26a01c3&text=baby+asian+elephant&format=json&nojsoncallback=1"
    
    @IBOutlet weak var flickImageView: UIImageView!
    @IBOutlet weak var searchByPhraseTextField: UITextField!
    @IBOutlet weak var searchByLatTextField: UITextField!
    @IBOutlet weak var searchByLongTextField: UITextField!
    @IBOutlet weak var imageTitleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func searchByPhraseButtonPressed(sender: UIButton) {
        
        getImageFromFlickr()
    }

    @IBAction func searchByGeoButtonPressed(sender: UIButton) {
    }
    
    func getImageFromFlickr() {
        
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "text": "baby asian elephant",
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        let session = NSURLSession.sharedSession()
        let urlStr = BASE_URL + apiCallStringFromDictionary(methodArguments)
        let url = NSURL(string: urlStr)!
        //let url = NSURL(string: urlHardCodedStr)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
            } else {

                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDict = parsedResult["photos"] as? [String: AnyObject] {
                    
                    var count = 0
                    if let photosCount = photosDict["total"] as? String {
                        count = (photosCount as NSString).integerValue
                    }
                    
                    if count > 0 {
                        
                        if let photosArray = photosDict["photo"] as? [[String: AnyObject]] {
                            
                            let randomIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                            let randomPhoto = photosArray[randomIndex] as [String: AnyObject]
                            let randomUrlStr = randomPhoto["url_m"] as? String
                            let imageUrl = NSURL(string: randomUrlStr!)
                            
                            var title = ""
                            if let imageTitle = randomPhoto["title"] as? String {
                                
                                title = imageTitle
                            }
                            if let imageData = NSData(contentsOfURL: imageUrl!) {
                                
                                // good image
                                let image = UIImage(data: imageData)
                                dispatch_async(dispatch_get_main_queue(),  {
                                    
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
        
        task.resume()
    }
    
    func apiCallStringFromDictionary(parameters: [String: AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        let retString = (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
        return retString
    }
}


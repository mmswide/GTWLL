//
//  RealmStack.swift
//  Copyright © 2016 Get Well Company. All rights reserved.
//

import RealmSwift
import SwiftyJSON
import SDWebImage

protocol StackDelegate {
    func regionImportDone()
    func sliderImportDone()
    func regionDistanceDone()
    func delegateUpdate()
}

class RealmStack: NSObject {
    
    static let sharedStack = RealmStack()
    
    private let realm = try! Realm()
    let sharedUI        = UIManager.sharedManager
    let sharedAPI       = APIManager.sharedManager
    let locationManager = LocationManager.sharedManager
    
    var defaultRegion : Region!
    var queries: Results<Query>?
    var regions: Results<Region>?
    
    var hasRegions = false
    var hasQueries = false
    
    var source = [SlideObject]()
    var processedRegions = [Region]()
    var alphabetRegions = [Region]()
    
    var delegate: StackDelegate? {
        didSet { update() }
    }
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(sliderImportFinished), name: Constants.Notification.Slider, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(regionImportFinished), name: Constants.Notification.Region, object: nil)
        var tT = NSUserDefaults.standardUserDefaults().integerForKey("rT")
        tT += 1;
        NSUserDefaults.standardUserDefaults().setInteger(tT, forKey: "rT")
        if tT > sharedUI.pageSize {
            realm.deleteAll()
        }
        
        regions = realm.objects(Region).filter("lastSeen == false").sorted("counter")
        queries = realm.objects(Query).filter("lastSeen == false").sorted("counter")
        
        print(Realm.Configuration.defaultConfiguration.fileURL?.absoluteString)
        
        let defRegion = realm.objects(DefaultRegion).first
        defaultRegion = defRegion?.generateRegion()
        
        if regions!.count == 0 {
            initializeRegion()
            sharedAPI.importRegions()
        }
        else {
            sharedAPI.importRegions()
        }
        
        if queries!.count == 0 {
            initializeSlideObject()
            sharedAPI.importQueries()
        }
        else {
            sharedAPI.importQueries()
        }
        
        sharedAPI.retrieveFeaturedVenues()
    }
    
    func update() {
        delegate?.delegateUpdate()
    }
    
    func sliderImportFinished() {
        if !hasQueries {
            hasQueries = true
            queries = realm.objects(Query).filter("lastSeen == false").sorted("counter")
            prepareSliderObjects()
        }
    }
    
    func regionImportFinished() {
        if !hasRegions {
            hasRegions = true
            regions = realm.objects(Region)
            alphabetRegions = Array(regions!.toArray())
            prepareRegions()
        }
    }
    func initializeDefaultRegion() {
        self.realm.beginWrite()
        self.realm.delete(self.realm.objects(DefaultRegion))
        try! self.realm.commitWrite()
    }
    func initializeRegion() {
        self.realm.beginWrite()
        self.realm.delete(self.realm.objects(Region))
        try! self.realm.commitWrite()
    }
    func initializeSlideObject(){
        self.realm.beginWrite()
        self.realm.delete(self.realm.objects(Query))
        try! self.realm.commitWrite()
    }
    func refreshRealmDb() {
        self.realm.beginWrite()
        self.realm.delete(self.realm.objects(Region))
        self.realm.delete(self.realm.objects(Query))
        try! self.realm.commitWrite()
        
    }
    func relocateRegions(){
        let regionobjects = realm.objects(Region)
        alphabetRegions = Array(regionobjects.toArray())
        var processed: [Region] = []
        if alphabetRegions.count > 0 {
            if self.defaultRegion != nil {
                processed.append(defaultRegion)
                let index = getIndexFromArray(alphabetRegions, region: defaultRegion)
                for i in 0  ..< alphabetRegions.count  {
                    if i != index {
                        let regItem = alphabetRegions[i]
                        processed.append(regItem)
                    }
                }
            } else {
                processed = alphabetRegions
            }
        }
        if processed.count > 5 {
            var cuttedRegions = [Region]();
            for i in 0 ..< processed.count {
                if i < 5 {
                    cuttedRegions.append(processed[i])
                }
            }
            processed = cuttedRegions
        }
        var URLs = [NSURL]()
        for region in processed {
            URLs.append(NSURL(string: region.image)!)
            let URL = NSMutableString(string: region.image)
            if URL != "" {
                URL.insertString(sharedUI.ratio, atIndex: 50)
                URLs.append(NSURL(string: URL as String)!)
            }
            realm.beginWrite()
            region.counter  += 1
            region.lastSeen = true
            try! realm.commitWrite()
        }
        SDWebImagePrefetcher.sharedImagePrefetcher().prefetchURLs(URLs)
        processedRegions.removeAll()
        processedRegions = processed
    }
    func refresh() {
        
        sharedAPI.importRegions()
        prepareSliderObjects()
        sharedAPI.retrieveFeaturedVenues()
    }
    func prepareSliderObjects() {
        hasQueries = true
        var order = Set(realm.objects(Query).valueForKey("category") as! [String]).sort()
        swap(&order[1], &order[4])
        swap(&order[2], &order[3])
        swap(&order[3], &order[4])
        try! realm.write { realm.objects(Query).setValue(false, forKey: "lastSeen") }
        var venues = [Venue]()
        source.removeAll()
        for category in order {
            let query = queries!.filter("category == '\(category)'").first
            realm.beginWrite()
            query!.counter  += 1
            query!.lastSeen = true
            try! realm.commitWrite()
            
            let references = query?.references.characters.split{$0 == ","}.map(String.init)
            for ref in references! {
                if let venue: Venue? = realm.objects(Venue).filter("id == '\(ref)'").first! {
                    venues.append(venue!)
                }
            }
            source.append(SlideObject(query: query, objects: venues))
            venues.removeAll()
        }
        delegate?.sliderImportDone()
    }
    
    func prepareRegions() {
        hasRegions = true
        try! realm.write { realm.objects(Region).setValue(false, forKey: "lastSeen") }
        let processed: [Region] = Array(regions!.toArray().prefix(5))
        var URLs = [NSURL]()
        for region in processed {
            URLs.append(NSURL(string: region.image)!)
            let URL = NSMutableString(string: region.image)
            if URL != "" {
                URL.insertString(sharedUI.ratio, atIndex: 50)
                URLs.append(NSURL(string: URL as String)!)
            }
            realm.beginWrite()
            region.counter  += 1
            region.lastSeen = true
            try! realm.commitWrite()
        }
        SDWebImagePrefetcher.sharedImagePrefetcher().prefetchURLs(URLs)
        processedRegions.removeAll()
        processedRegions = processed
        if locationManager.currentLocation != nil {
            calculateRegionDistance()
        }
        else {
            delegate?.regionImportDone()
        }
    }
    func getIndexFromArray(arry: [Region], region: Region) -> Int {
        for i in 0  ..< arry.count  {
            let reg = arry[i]
            if region.name == reg.name {
                return i;
            }
        }
        return 0
    }
    func calculateRegionDistance() {
        var processed = processedRegions
        for region in processed {
            let id = region.id
            let distance = locationManager.returnDistance(region.latitude, lng: region.longitude)
            let values: [String: AnyObject] = [
                "id"       : id,
                "distance" : distance
            ]
            realm.beginWrite()
            realm.create(Region.self, value: values, update: true)
            
            try! realm.commitWrite()
        }
        processed.sortInPlace({ $0.distance < $1.distance })
        processedRegions = processed
        delegate?.regionDistanceDone()
    }
    
    func checkVenue(venue: Venue, completionHandler:(venue: Venue) -> ()) {
        if let existingVenue = realm.objectForPrimaryKey(Venue.self, key: venue.id) {
            completionHandler(venue: existingVenue)
        }
        else {
            realm.beginWrite()
            let newVenue = realm.create(Venue.self, value: venue, update: true)
            try! realm.commitWrite()
            completionHandler(venue: newVenue)
        }
    }
    
    func venuesForRegion(regionID: String) -> Results<Venue>? {
        return realm.objects(Venue).filter("regionID == '\(regionID)'")
    }
    
    func favoriteVenues() -> Results<Venue>? {
        return realm.objects(Venue).filter("favorite == true")
    }
    
    func featuredVenues() -> Results<Venue>? {
        return realm.objects(Venue).filter("featured == true")
    }
    
    func favoriteCheck(venue: Venue!) {
        realm.beginWrite()
        if !venue.favorite {
            venue.favorite = true
        }
        else {
            venue.favorite = false
        }
        try! realm.commitWrite()
    }

}

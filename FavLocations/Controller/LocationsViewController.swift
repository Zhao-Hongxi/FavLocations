//
//  LocationsViewController.swift
//  FavLocations
//
//  Created by ivan on 2021/12/15.
//

import UIKit
import GoogleMaps
import SwiftyJSON
import Alamofire
import RealmSwift
import Firebase
import KeychainSwift
import PromiseKit

class LocationsViewController: UIViewController {

    // View for search result
    @IBOutlet weak var searchResultTableView: UITableView!
    // View for google map
    @IBOutlet weak var googleMapView: GMSMapView!
    // View for favorite(saved) locations
    @IBOutlet weak var favLocationsTableView: UITableView!
    // Default Latitude
    var centerLatitude : Double = 37.480948
    // Default Longitude
    var centerLongitude : Double = -122.182030
    // init Geocoder
    let geocoder = GMSGeocoder()
    // Array to store search result, also is data source of search result tableview
    var searchResult : [PlaceInfo] = []
    // store fav locations, data source of favLocationsTableView
    var favLocations : [PlaceInfo] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        googleMapView.delegate = self
        // move camera to center
        googleMapView.animate(to: GMSCameraPosition(latitude: self.centerLatitude, longitude: self.centerLongitude, zoom: 14.0))
        searchResultTableView.delegate = self
        searchResultTableView.dataSource = self
        favLocationsTableView.delegate = self
        favLocationsTableView.dataSource = self
        // searchResultTableView styling
        searchResultTableView.isHidden = true
        searchResultTableView.separatorColor = UIColor.clear
        // load Data
        getPlacesFromDB()
    }
    // log out button
    @IBAction func logoutButtonAction(_ sender: Any) {
        do{
            try Auth.auth().signOut()
            // clear key chain
            Keychain().key.clear()
            self.navigationController?.popViewController(animated: true)
            
        }catch{
            print(error.localizedDescription)
        }
    }
    // get latitude and longitude with given place id
    func getPlaceGeoInfo(placeID : String) -> Promise<(Double, Double)>{
        return Promise< (Double, Double) > { seal -> Void in
           // useing google place detail api
            let url = "\(placeDetailsBaseUrl)?fields=geometry&place_id=\(placeID)&key=\(apiKey)"
            
            AF.request(url).responseJSON { response in
        
                if response.error != nil {
                    seal.reject(response.error as! Error)
                }
                
                let res = JSON(response.data!).dictionaryValue["result"]
                let geo = JSON(res).dictionaryValue["geometry"]
                let location = JSON(geo).dictionaryValue["location"]
                let lng = location!["lng"].doubleValue
                let lat = location!["lat"].doubleValue
                seal.fulfill((lat, lng))
            }
        }
    }
    
    // using google place autocomplete api and center longitude and latitude to get search result
    // radius = 50000
    func getSearchResult(searchText: String) -> Void {
        let location = "\(self.centerLatitude)%2C\(self.centerLongitude)"
        let url = autocompleteBaseUrl + "?input=\(searchText)&location=\(location)&key=\(apiKey)"
        AF.request(url).responseJSON { response in
            if response.error != nil {
                print(response.error?.localizedDescription)
                return
            }
            
            let prediction = JSON(response.data!).dictionaryValue["predictions"]
            // clear searchResult array
            self.searchResult = []
            for pre in JSON(prediction).arrayValue {
                let place = PlaceInfo()
                place.placeDescription = pre["description"].stringValue
                place.place_id = pre["place_id"].stringValue
                place.main_text = pre["structured_formatting"].dictionaryValue["main_text"]!.stringValue
                place.secondary_text = pre["structured_formatting"].dictionaryValue["secondary_text"]!.stringValue
                // append into array
                self.searchResult.append(place)
            }
            // searchResultTableView reload
            self.searchResultTableView.reloadData()
        }
    }
    // add place id to user.savedLocations list
    func addPlaceInfotoUser(placeInfo : PlaceInfo) {
        do {
            let realm = try Realm()
            let keychain = Keychain().key
            if realm.object(ofType: UserInfo.self, forPrimaryKey: keychain.get("uid")) == nil {
                return
            }
            
            if realm.object(ofType: PlaceInfo.self, forPrimaryKey: placeInfo.place_id) == nil {
                addPlaceInfotoDB(placeInfo)
            }

            let user = realm.object(ofType: UserInfo.self, forPrimaryKey: keychain.get("uid"))!
            try realm.write {
                user.savedLocations.append(placeInfo.place_id)
                realm.add(user, update: .modified)
            }
        } catch {
            print("addPlaceInfotoUser")
            print("Error in getting values from DB \(error)")
        }
    }
    
    // add place into Realm.Place
    func addPlaceInfotoDB(_ placeInfo : PlaceInfo){
        do{
            let realm = try Realm()
            try realm.write {
                realm.add(placeInfo, update: .modified)
            }
        }catch{
            print("addPlaceInfotoDB")
            print("Error in getting values from DB \(error)")
        }
    }
    //
    func getPlacesFromDB() {
        do {
            let realm = try Realm()
            let keychain = Keychain().key
            print(keychain.get("uid"))
            
            if realm.object(ofType: UserInfo.self, forPrimaryKey: keychain.get("uid")) == nil {
                return
            }
            // get current userInfo
            let user = realm.object(ofType: UserInfo.self, forPrimaryKey: keychain.get("uid"))!
            // clear favLocations
            favLocations = []
            // use placeids in the savedLocations to get placeInfo objects from realm
            for placeID in user.savedLocations {
                let place = realm.object(ofType: PlaceInfo.self, forPrimaryKey: placeID)
                // append into favLocations
                favLocations.append(place!)
            }
            // reload favLocationsTableView
            self.favLocationsTableView.reloadData()
        } catch {
            print("getPlacesFromDB")
            print("Error in getting values from DB \(error)")
        }
    }
    // check if current user saved this place
    func placeInfoExistInUser(placeInfo : PlaceInfo) -> Bool {
        do{
            let realm = try Realm()
            let keychain = Keychain().key
            // check if user exists
            if realm.object(ofType: UserInfo.self, forPrimaryKey: keychain.get("uid")) == nil {
                print("Cannot get UserInfo")
                return true
            }
            // get current userInof
            let user = realm.object(ofType: UserInfo.self, forPrimaryKey: keychain.get("uid"))!
            // check if place id in savedLocations
            if user.savedLocations.contains(placeInfo.place_id) {
                print("Location saved")
                return true
            }
            return false
            
        }catch{
            print("placeInfoExistInUser")
            print("Error in getting values from DB \(error)")
        }
        return false
    }

}

extension LocationsViewController : UISearchBarDelegate {
    
    // begin editing
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // hide
        favLocationsTableView.isHidden = true
        googleMapView.isHidden = true
        // show searchResultTableView
        searchResultTableView.isHidden = false
    
        searchBar.showsCancelButton = true
        searchResultTableView.reloadData()
    }
        
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        favLocationsTableView.isHidden = false
        googleMapView.isHidden = false
        searchResultTableView.isHidden = true
        getPlacesFromDB()
        searchBar.endEditing(true)
        searchResult = []
        searchBar.text = ""
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count < 3 {
            searchResult = []
            searchResultTableView.reloadData()
            return 
        }
    
        getSearchResult(searchText: searchText)
        
    }
}

extension LocationsViewController : GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        mapView.clear()
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        // update center location
        self.centerLatitude = position.target.latitude
        self.centerLongitude = position.target.longitude
        // create center marker
        let marker = GMSMarker()
        marker.position = position.target
        marker.map = self.googleMapView
        
        
    }
    
}

extension LocationsViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == searchResultTableView {
            // rows of search result
            return searchResult.count
        } else {
            // rows of favorite locations
            return favLocations.count
        }
    }
    // tableview cell delegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == searchResultTableView {
            // tableview cell for searchResultTable
            let cell = Bundle.main.loadNibNamed("SearchResultTableViewCell", owner: self, options: nil)?.first as! SearchResultTableViewCell
            cell.mainTextLabel.text = searchResult[indexPath.row].main_text
            cell.secondaryTextLabel.text = searchResult[indexPath.row].secondary_text
            cell.containerView.backgroundColor = UIColor(red: 0.91, green: 0.76, blue: 0.76, alpha: 1.00)
            cell.containerView.layer.cornerRadius = 10
            // if saved, color is blue
            if placeInfoExistInUser(placeInfo: searchResult[indexPath.row]) == true {
                cell.containerView.backgroundColor = UIColor(red: 0.15, green: 0.85, blue: 0.87, alpha: 1.00)
            }
            return cell
            
        } else {
            // tableview cell for favLocationTableView
            let cell = tableView.dequeueReusableCell(withIdentifier: "favLocationCell", for: indexPath)
            cell.textLabel?.text = favLocations[indexPath.row].placeDescription
            return cell
        }
    }
    // table view cell height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    // when row is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == searchResultTableView {
            // if searchResultTableView cell is selected
            let placeInfo = searchResult[indexPath.row]
            // check if current user already saved this place
            if placeInfoExistInUser(placeInfo: placeInfo) {
                print("Place already saved")
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
            // append to favlocations
            favLocations.append(searchResult[indexPath.row])
//            addPlaceInfotoDB(placeInfo)
            // add to Realm
            addPlaceInfotoUser(placeInfo: placeInfo)
            //reload
            searchResultTableView.reloadData()
            
        } else {
            // if favLocationTableVIew is selected
            let placeInfo = favLocations[indexPath.row]
            // get lat, lng
            getPlaceGeoInfo(placeID: placeInfo.place_id).done { lat, lng in
                // move camera
                self.googleMapView.animate(to: GMSCameraPosition(latitude: lat, longitude: lng, zoom: 14.0))
            }
            
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}

//UIColor(red: 0.91, green: 0.76, blue: 0.76, alpha: 1.00)

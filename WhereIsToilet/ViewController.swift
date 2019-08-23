//
//  ViewController.swift
//  WhereIsToilet
//
//  Created by 송시온 on 07/08/2019.
//  Copyright © 2019 송시온. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    @IBOutlet var btnMyLocation: UIButton!
    
    var disposeBag:DisposeBag = DisposeBag()
    
    var gMapView: GMSMapView? = nil
    var locationManager = CLLocationManager()
    var placesClient: GMSPlacesClient!
    @IBOutlet var collectionView: UICollectionView!
    
    var markers = [GMSMarker]()
    var toiletList:[ToiletInfo] = []
    {
        didSet(oldVal)
        {
            clearMarkers()
            for var toilet in toiletList
            {
                let lat = CGFloat(NSString(string: toilet.lat ?? "0").floatValue)
                let lng = CGFloat(NSString(string: toilet.lng ?? "0").floatValue)
                
                
                DispatchQueue.main.async {
                    self.setMarker(lat: lat, lng: lng, title: toilet.name ?? "")
                }
            }
            
            collectionView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //맵뷰 및 데이터 불러오기
        setMapView()
        setLocationManger()
        setCollectionView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    
    // 마커 추가하기
    private func setMarker(lat:CGFloat, lng:CGFloat, title:String)
    {
        print("testing")
        print(title + "/" + String(describing: lat) + ", " + String(describing: lng))
        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lng))
        marker.title = title
        marker.map = gMapView

        //marker.icon = UIImage(named:"map_marker")
        
        markers.append(marker)
    }
    
    // 맵뷰 생성
    func setMapView()
    {
        guard let cordinate = locationManager.location?.coordinate else
        {
            return
        }
        let camera = GMSCameraPosition.camera(withTarget: cordinate, zoom: 18.0)
        self.gMapView = GMSMapView.map(withFrame: self.view.bounds, camera: camera)
        self.view.addSubview(self.gMapView!)
        self.gMapView?.isMyLocationEnabled = true
//        self.gMapView?.settings.myLocationButton = true
        Util.setAnchor(baseView: self.view, newView: gMapView!)
        
        btnMyLocation.layer.cornerRadius = btnMyLocation.frame.width / 2
        
        btnMyLocation.addTarget(self, action: #selector(goMyLocation), for: .touchUpInside)
        
        self.view.bringSubviewToFront(btnMyLocation)

        self.view.bringSubviewToFront(collectionView)
        
        gMapView?.delegate = self
    }
    
    private func clearMarkers() {
        gMapView?.clear()
        markers.removeAll()
    }

    
    private func setCollectionView()
    {
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    // 근처에 있는 화장실 갯수
    func getToiletList(_ lat:Float, _ lng:Float)
    {
        let req = URLRequest(url: URL(string: "http://178.128.65.76:3000/test/getTotalNearToilets/\(lat)/\(lng)")!)
        
        let responseJSON = URLSession.shared.rx.json(request: req)
        responseJSON
            .observeOn(ConcurrentDispatchQueueScheduler.init(qos: .default))
            .filter { $0 is [NSDictionary] }
            .map({ (obj) -> [ToiletInfo] in
                let jsonObj = try JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
                let decoder = JSONDecoder()
                //print("completed\(self.toiletList)")
                
                return try decoder.decode([ToiletInfo].self, from: jsonObj)
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (toiletList) in
                do
                {
                    self.toiletList = toiletList
                }
                catch
                {
                    print("Excepted\(error)")
                }
            }).disposed(by: disposeBag)
    }
    
    func setLocationManger() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        locationManager.requestWhenInUseAuthorization()
    }

    @objc func goMyLocation()
    {
        let latitude = Float((locationManager.location?.coordinate.latitude)!)
        let longitude = Float((locationManager.location?.coordinate.longitude)!)
        let zoom = 16
        
        // 내위치로 카메라 이동
        let camera = GMSCameraPosition.camera(withLatitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude), zoom: Float(zoom))
        self.gMapView?.animate(to: camera)
    }
    
    
    func goToiletLocation(toilet: ToiletInfo)
    {
        guard let latitude = Float(toilet.lat) else { return }
        guard let longitude = Float(toilet.lng) else { return }
        let zoom = 16
        
        
        // 내위치로 카메라 이동
        let camera = GMSCameraPosition.camera(withLatitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude), zoom: Float(zoom))
        self.gMapView?.animate(to: camera)
    }

}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            print("Location WhenInUse")
            if(gMapView == nil)
            {
                setMapView()
            }
            
            gMapView?.isMyLocationEnabled = true
            goMyLocation()
            
            if(toiletList.count == 0)
            {
                let latitude = Float((locationManager.location?.coordinate.latitude)!)
                let longitude = Float((locationManager.location?.coordinate.longitude)!)

                getToiletList(latitude, longitude)
            }
            
            break
        case .denied:
            print("Location Denied")
            let message = "설정 -> 응답하라경기북부 앱 -> 위치 접근 권한을 허용으로 바꿔야 사용하실 수 있습니다."
            
            let alert = UIAlertController(title: "위치정보 거절", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "확인", style: UIAlertAction.Style.default, handler: { (action) in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true, completion:{
                //self.navigationController?.dismiss(animated: true, completion: nil)
            })
            
            break
        // 아직 결정 X
        case .notDetermined:
            print("Location notDetermined")
            break
        case .restricted:
            print("Location restricted")
            //gMapView.isMyLocationEnabled = false
            //locationManager.stopUpdatingLocation()
            //isLocation = false
            break
        default:
            print("default")
            //isLocation = false
            break
        }
        //reload()
    }
}

extension ViewController: UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return toiletList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ToiletCollectionViewCell", for: indexPath) as? ToiletCollectionViewCell else {
            return UICollectionViewCell() }
        cell.toiletInfo = toiletList[indexPath.row]
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        print(currentPage)
        
        gMapView?.selectedMarker = markers[currentPage]
        goToiletLocation(toilet: toiletList[currentPage])
    }
}

extension ViewController:GMSMapViewDelegate
{
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        var indexNum = 0
        for mark in markers {
            if marker == mark {
                break
            }
            indexNum += 1
        }
        collectionView.scrollToItem(at: IndexPath(row: indexNum, section: 0), at: .left, animated: true)
        
        return false
    }
}



class ToiletCollectionViewCell: UICollectionViewCell
{
    @IBOutlet var labelTitle: UILabel!
    @IBOutlet var labelUnisex: UILabel!
    @IBOutlet var labelType: UILabel!
    @IBOutlet var labelOpen: UILabel!
    @IBOutlet var view: UIView!
    
    var toiletInfo:ToiletInfo? = nil {
        willSet(newValue)
        {
            
            let dist = newValue?.dist ?? 0
            var strDist = ""
            if (dist < 1000)
            {
                strDist = String(Int(dist)) + "m"
            }
            else
            {
                strDist = String(format: "%.1fkm", arguments: [(dist / 1000)])
            }
            
            labelTitle.text = newValue?.name
            labelType.text = "(\(newValue?.type ?? ""), \(strDist))"
            if(newValue?.unisex == "Y")
            {
                labelUnisex.text = "남녀공용 O"
            }
            else
            {
                labelUnisex.text = "남녀공용 X"
            }
            labelOpen.text = newValue?.open_time
        }
    }
}

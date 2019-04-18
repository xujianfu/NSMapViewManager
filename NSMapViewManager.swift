//
//  NSMapViewManager.swift
//  10000114CarProject
//
//  Created by 张晓滨 on 2019/4/18.
//  Copyright © 2019 一万一一四. All rights reserved.
//

import Foundation

enum AnnotationViewStype {
    case MaintainStype //洗车商户
    case PetrolStationStype //加油站商户
}

class NSMapViewManager : NSObject {

    static var sharedInstance : NSMapViewManager {
        struct Static {
            static let instance : NSMapViewManager = NSMapViewManager()
        }
        return Static.instance
    }
    
    lazy var reloadView : UIImageView = {
        let reloadView = UIImageView(frame: CGRect(x: SCREEN_WIDTH - 70, y: SCREEN_HEIGHT -  CGFloat(CommonUseClass._sharedManager.navigationBarHeight()) - 30 - 70, width: 58, height:58))
        reloadView.image = UIImage.init(named: "reloadMapView")
        reloadView.isUserInteractionEnabled = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(loadingMapView))
        reloadView.addGestureRecognizer(tap)
        return reloadView
    }()
    
    lazy var zoomBtnsView : UIView  = {
        let zoomBtnsView = UIView(frame: CGRect(x: 20, y: SCREEN_HEIGHT -  CGFloat(CommonUseClass._sharedManager.navigationBarHeight()) - 97 - 40, width: 36, height: 97))
        zoomBtnsView.backgroundColor = .white
        zoomBtnsView.isUserInteractionEnabled = true
        
        let btn1 = UIButton(frame: CGRect(x: 6, y: 12, width: 24, height: 24))
        btn1.setImage(UIImage.init(named: "ic_map_+"), for: .normal)
        btn1.tag = 10
        btn1.addTarget(self, action: #selector(btnClickAction(button:)), for: .touchUpInside)
        zoomBtnsView.addSubview(btn1)
        
        let view = UIView(frame: CGRect(x: 6, y: 48, width: 12, height: 1))
        view.backgroundColor = colorWithHexString("0xf5f5f5")
        zoomBtnsView.addSubview(view)
        
        let btn2 = UIButton(frame: CGRect(x: 6, y: 61, width: 24, height: 24))
        btn2.setImage(UIImage.init(named: "ic_map_-"), for: .normal)
        btn2.tag = 11
        btn2.addTarget(self, action: #selector(btnClickAction(button:)), for: .touchUpInside)
        zoomBtnsView.addSubview(btn2)
        
        return zoomBtnsView
    }()
    
    var viewController : UIViewController = UIViewController()
    lazy var contentSearch : NACustomizedSearchBar = NACustomizedSearchBar()
    
    //百度地图
    var userLocation : BMKUserLocation!
    var locationService : BMKLocationService!
    var mapView : BMKMapView!
    var geocodesearch : BMKGeoCodeSearch!
    
    lazy var poiSearch : BMKPoiSearch = {
        let poiSearch = BMKPoiSearch()
        poiSearch.delegate = self
        return poiSearch
    }()
    
    //全局变量
    var searchText : String?
    var annotationStype : AnnotationViewStype?
    
    //改变缩放比例
    @objc func btnClickAction(button : UIButton) -> Void {
        var lv = mapView.zoomLevel
        if button.tag == 10 {
            lv += 1
        }
        else if button.tag == 11 {
            lv -= 1
        }
        mapView.zoomLevel = lv
    }
    
    @objc func loadingMapView() {
        locationService.startUserLocationService()
    }
    
    func addAnnotation() -> Void {
        let ary1:NSArray = ["116.70097","116.68516","116.705282"]
        let ary2:NSArray = ["23.367908","23.357159","23.357822"]
        
        var coor: CLLocationCoordinate2D = CLLocationCoordinate2D.init()
        
        for i in 0..<ary1.count {
            let pointAnnotation = BMKPointAnnotation() //必须放在循环里初始化
            coor.latitude  = (ary2[i] as AnyObject).doubleValue
            coor.longitude = (ary1[i] as AnyObject).doubleValue
            pointAnnotation.coordinate = coor
            pointAnnotation.title = "哈喽"
            mapView.addAnnotation(pointAnnotation)
        }
        
    }
}

extension NSMapViewManager : BMKMapViewDelegate{
    func setMapView() -> Void {
        mapView = BMKMapView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT -  CGFloat(CommonUseClass._sharedManager.navigationBarHeight())))
        mapView.zoomLevel = 15.1
        mapView.isZoomEnabled = true
        mapView.showsUserLocation = true
        mapView.delegate = self
        mapView.showMapScaleBar = true
        mapView.mapScaleBarPosition = CGPoint(x: SCREEN_WIDTH - 60 , y: SCREEN_HEIGHT -  CGFloat(CommonUseClass._sharedManager.navigationBarHeight()) - 30)

        viewController.view.addSubview(mapView)
        viewController.view.addSubview(reloadView)
        viewController.view.addSubview(zoomBtnsView)
        setSearchBar()
        
        let param = BMKLocationViewDisplayParam()
        param.isAccuracyCircleShow = false
        param.locationViewImgName = "ic_my_acby_address"
        param.locationViewOffsetX = 0
        param.locationViewOffsetY = 0
        mapView.updateLocationView(with: param)

        //开启定位服务
        startlocationService()
    }

    
    //MARK:定位代理方法
    //处理位置坐标更新
    func didUpdate(_ userLocation: BMKUserLocation!) {
        mapView.showsUserLocation = true
        mapView.updateLocationData(userLocation)
        
        mapView.centerCoordinate = userLocation.location.coordinate
        
        let reverseGeocodeSearchOption = BMKReverseGeoCodeOption()
        reverseGeocodeSearchOption.reverseGeoPoint = userLocation.location.coordinate
        
        let flage : Bool = geocodesearch.reverseGeoCode(reverseGeocodeSearchOption)
        if flage {
            //            print("反geo检索发送成功")
        } else {
            print("发geo检索发送失败")
        }
        
    }

    //可自定义大头针与气泡类型
    func mapView(_ mapView: BMKMapView!, viewFor annotation: BMKAnnotation!) -> BMKAnnotationView! {
        if annotation.isKind(of: BMKPointAnnotation.self) {
            let annotationViewID = "annotationView"
            var annotationView:BMKPinAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: annotationViewID) as? BMKPinAnnotationView
            if(annotationView == nil){
                annotationView = BMKPinAnnotationView.init(annotation:annotation, reuseIdentifier:annotationViewID)
            }
            
            annotationView!.animatesDrop = true
            //设置不可拖拽
            annotationView!.isDraggable = false
            if annotationStype == .MaintainStype {
                annotationView!.image = UIImage(named:"ic_my_acby_xiche")
            } else if annotationStype == .PetrolStationStype {
                annotationView!.image = UIImage.init(named: "ic_fujin_jiayou")
            }
            
            return annotationView
        }
        return nil
    }
    
    //获取大头针的操作
    func mapView(_ mapView: BMKMapView!, didSelect view: BMKAnnotationView!) {
        if view.isKind(of: BMKAnnotationView.self) {
            
        }
    }
    
    //地图状态更改
    func mapStatusDidChanged(_ mapView: BMKMapView!) {
        mapView.mapScaleBarPosition = CGPoint(x: SCREEN_WIDTH - mapView.mapScaleBarSize.width - 20 , y: SCREEN_HEIGHT -  CGFloat(CommonUseClass._sharedManager.navigationBarHeight()) - 30)
    }
}

extension NSMapViewManager : BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate {
    
    func startlocationService() -> Void {
        geocodesearch = BMKGeoCodeSearch()
        geocodesearch.delegate = self
        startLocation()
    }
    
    //开启定位
    func startLocation(){
        locationService = BMKLocationService()
        locationService.delegate = self
        locationService.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationService.startUserLocationService()
    }
    
    //处理方向变更信息
    func didUpdateUserHeading(_ userLocation: BMKUserLocation!) {
        print(userLocation.heading)
    }
    
    //定位失败
    func didFailToLocateUserWithError(_ error: Error!) {
        print("定位失败:\(String(describing: error))")
    }
    
    //MARK:地址反编码代理方法
    func onGetReverseGeoCodeResult(_ searcher: BMKGeoCodeSearch!, result: BMKReverseGeoCodeResult!, errorCode error: BMKSearchErrorCode) {
//                print("地址详情：\(String(describing: result.addressDetail))-----------地址：\(String(describing: result.address))")
//        print("层次化地址信息:\(String(describing: result.)")
        //addressDetail:     层次化地址信息
        //address:    地址名称
        //businessCircle:  商圈名称
        // location:  地址坐标
        //  poiList:   地址周边POI信息，成员类型为BMKPoiInfo
        
    }
}

extension NSMapViewManager : BMKPoiSearchDelegate {
    
    //POI检索
    func setPoiSearch() -> Void {
        let citySearchOption = BMKCitySearchOption()
        citySearchOption.pageIndex = 0
        citySearchOption.pageCapacity = 20
        citySearchOption.city = "汕头"
        citySearchOption.keyword = searchText
        
        let flage : Bool = poiSearch.poiSearch(inCity: citySearchOption)
        if flage {
            print("城市内检索发送成功")
        } else {
            print("城市内检索发送失败")
        }
    }
    
    func onGetPoiResult(_ searcher: BMKPoiSearch!, result poiResult: BMKPoiResult!, errorCode: BMKSearchErrorCode) {
        //清楚地图中的所有annotation
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
        
        if errorCode == BMK_SEARCH_NO_ERROR {
            let newAnnotations = NSMutableArray()
            for idx in 0..<poiResult.poiInfoList.count {
                let poi : BMKPoiInfo = poiResult.poiInfoList![idx] as! BMKPoiInfo
                let item : BMKPointAnnotation = BMKPointAnnotation()
                item.coordinate = poi.pt
                item.title = poi.name
                newAnnotations.add(item)
            }
            
            mapView.addAnnotations(newAnnotations as? [Any])
            mapView.showAnnotations(newAnnotations as? [Any], animated: true)
        } else if errorCode == BMK_SEARCH_AMBIGUOUS_ROURE_ADDR {
            print("地点有歧义")
        } else {
            //...
        }

    }
}

extension NSMapViewManager : UISearchBarDelegate,UITextFieldDelegate{
    
    func setSearchBar() -> Void {
        contentSearch = NACustomizedSearchBar(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: 40), style: .contentStyle)
        contentSearch.showsCancelButton = false
        contentSearch.placeholder = "搜索位置"
        contentSearch.delegate = self
        
        viewController.view.addSubview(contentSearch)
        contentSearch.snp.makeConstraints { (make) in
            make.top.equalTo(10)
            make.width.equalTo(335)
            make.height.equalTo(40)
            make.centerX.equalToSuperview()
        }
    }
    
    //关键字搜索
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchText = searchBar.text
        setPoiSearch()
        contentSearch.resignFirstResponder()
    }
    
}

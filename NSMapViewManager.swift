//
//  NSMapViewManager.swift
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
        let reloadView = UIImageView(frame: CGRect(x: SCREEN_WIDTH - 70, y: SCREEN_HEIGHT -  CGFloat(CommonUseClass._sharedManager.navigationBarHeight()) - 70 - 40, width: 58, height:58))
        reloadView.image = UIImage.init(named: "reloadMapView")
        reloadView.isUserInteractionEnabled = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(loadingMapView))
        reloadView.addGestureRecognizer(tap)
        return reloadView
    }()
    
    lazy var zoomBtnsView : UIView  = {
        let zoomBtnsView = UIView(frame: CGRect(x: 16, y: SCREEN_HEIGHT -  CGFloat(CommonUseClass._sharedManager.navigationBarHeight()) - 97 - 40, width: 36, height: 97))
        zoomBtnsView.backgroundColor = .white
        zoomBtnsView.isUserInteractionEnabled = true
        
        let btn1 = UIButton(frame: CGRect(x: 6, y: 12, width: 24, height: 24))
        btn1.setImage(UIImage.init(named: "ic_map_+"), for: .normal)
        btn1.tag = 10
        btn1.addTarget(self, action: #selector(btnClickAction(button:)), for: .touchUpInside)
        zoomBtnsView.addSubview(btn1)
        
        let view = UIView(frame: CGRect(x: 6, y: 48, width: 24, height: 1))
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
    var destinationCoor : CLLocationCoordinate2D!   //目的地坐标
    var userCurrentCoor : CLLocationCoordinate2D!     //用户当前位置坐标
    
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
        mapView.mapScaleBarPosition = CGPoint(x: SCREEN_WIDTH - 41 , y: SCREEN_HEIGHT -  CGFloat(CommonUseClass._sharedManager.navigationBarHeight()) - 35)

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
        userCurrentCoor = userLocation.location.coordinate
        
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
            destinationCoor = view.annotation.coordinate
            setupDefaultData()
        }
    }
    
    func mapStatusDidChanged(_ mapView: BMKMapView!) {
        mapView.mapScaleBarPosition = CGPoint(x: SCREEN_WIDTH - mapView.mapScaleBarSize.width / 2 - 41 , y: SCREEN_HEIGHT -  CGFloat(CommonUseClass._sharedManager.navigationBarHeight()) - 35)
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
    
    func didUpdateUserHeading(_ userLocation: BMKUserLocation!) {
        print(userLocation.heading)
    }

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
    
    func setPoiSearch() -> Void {
        let citySearchOption = BMKCitySearchOption()
        citySearchOption.pageIndex = 0
        citySearchOption.pageCapacity = 20
        citySearchOption.city = "广东"
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


extension NSMapViewManager : BMKRouteSearchDelegate {

    func setupDefaultData() {
        
        //实例化驾车查询基础信息类对象
        let drivingRoutePlanOption = BMKDrivingRoutePlanOption()
        //实例化线路检索节点信息类对象
        let start = BMKPlanNode()
        //起点名称
//        start.name = ""
//        //起点所在城市
//        start.cityName = ""
        start.pt = userCurrentCoor
        //实例化线路检索节点信息类对象
        let end = BMKPlanNode()
        //终点名称
//        end.name = ""
//        //终点所在城市
//        end.cityName = ""
        end.pt = destinationCoor
        drivingRoutePlanOption.from = start
        drivingRoutePlanOption.to = end
        searchData(drivingRoutePlanOption)
    }
    
    func searchData(_ option: BMKDrivingRoutePlanOption) {
        
        //初始化BMKRouteSearch实例
        let drivingRouteSearch = BMKRouteSearch()
        //设置驾车路径的规划
        drivingRouteSearch.delegate = self
        /*
         线路检索节点信息类，一个路线检索节点可以通过经纬度坐标或城市名加地名确定
         实例化线路检索节点信息类对象
         */
        let start = BMKPlanNode()
        //起点坐标
        start.pt = userCurrentCoor
        //实例化线路检索节点信息类对象
        let end = BMKPlanNode()
        //终点坐标
        end.pt = destinationCoor
        //初始化请求参数类BMKDrivingRoutePlanOption的实例
        let drivingRoutePlanOption = BMKDrivingRoutePlanOption()
        //检索的起点，可通过关键字、坐标两种方式指定。cityName和cityID同时指定时，优先使用cityID
        drivingRoutePlanOption.from = start
        //检索的终点，可通过关键字、坐标两种方式指定。cityName和cityID同时指定时，优先使用cityID
        drivingRoutePlanOption.to = end
        //途经点
        drivingRoutePlanOption.wayPointsArray = option.wayPointsArray
        /*
         驾车策略，默认使用BMK_DRIVING_TIME_FIRST
         BMK_DRIVING_BLK_FIRST：躲避拥堵
         BMK_DRIVING_TIME_FIRST：最短时间
         BMK_DRIVING_DIS_FIRST：最短路程
         BMK_DRIVING_FEE_FIRST：少走高速
         */
        drivingRoutePlanOption.drivingPolicy = option.drivingPolicy
        /*
         路线中每一个step的路况，默认使用BMK_DRIVING_REQUEST_TRAFFICE_TYPE_NONE
         BMK_DRIVING_REQUEST_TRAFFICE_TYPE_NONE：不带路况
         BMK_DRIVING_REQUEST_TRAFFICE_TYPE_PATH_AND_TRAFFICE：道路和路况
         */
        drivingRoutePlanOption.drivingRequestTrafficType = option.drivingRequestTrafficType
        /**
         发起驾乘路线检索请求，异步函数，返回结果在BMKRouteSearchDelegate的onGetDrivingRouteResult中
         */
        let flag = drivingRouteSearch.drivingSearch(drivingRoutePlanOption)
        if flag {
            print("驾车检索成功")
        } else {
            print("驾车检索失败")
        }
    }
    
    func onGetDrivingRouteResult(_ searcher: BMKRouteSearch!, result: BMKDrivingRouteResult!, errorCode error: BMKSearchErrorCode) {
        
        mapView.removeOverlays(mapView.overlays)
//        mapView.removeAnnotations(mapView.annotations)
        
        //BMKSearchErrorCode错误码，BMK_SEARCH_NO_ERROR：检索结果正常返回
        if error == BMK_SEARCH_NO_ERROR {
            //+polylineWithPoints: count:坐标点的个数
            var pointCount = 0
            //获取所有驾车路线中第一条路线
            let routeline: BMKDrivingRouteLine = result.routes[0] as! BMKDrivingRouteLine
            //遍历驾车路线中的所有路段
            for (_, item) in routeline.steps.enumerated() {
                //获取驾车路线中的每条路段
                let step: BMKDrivingStep = item as! BMKDrivingStep
                //初始化标注类BMKPointAnnotation的实例
                let annotation = BMKPointAnnotation()
                //设置标注的经纬度坐标为子路段的入口经纬度
                annotation.coordinate = step.entrace.location
                //设置标注的标题为子路段的说明
                annotation.title = step.entraceInstruction
                /**
                 
                 当前地图添加标注，需要实现BMKMapViewDelegate的-mapView:viewForAnnotation:方法
                 来生成标注对应的View
                 @param annotation 要添加的标注
                 */
//                mapView.addAnnotation(annotation)     //暂时不需要路段节点的标注，先注释
                //统计路段所经过的地理坐标集合内点的个数
                pointCount += Int(step.pointsCount)
            }
            
            //+polylineWithPoints: count:指定的直角坐标点数组
            var points = [BMKMapPoint](repeating: BMKMapPoint(x: 0, y: 0), count: pointCount)
            var count = 0
            //遍历驾车路线中的所有路段
            for (_, item) in routeline.steps.enumerated() {
                //获取驾车路线中的每条路段
                let step: BMKDrivingStep = item as! BMKDrivingStep
                //遍历每条路段所经过的地理坐标集合点
                for index in 0..<Int(step.pointsCount) {
                    //将每条路段所经过的地理坐标点赋值给points
                    points[count].x = step.points[index].x
                    points[count].y = step.points[index].y
                    count += 1
                }
            }
            //根据指定直角坐标点生成一段折线
            let polyline = BMKPolyline(points: &points, count: UInt(pointCount))
            /**
             向地图View添加Overlay，需要实现BMKMapViewDelegate的-mapView:viewForOverlay:方法
             来生成标注对应的View
             
             @param overlay 要添加的overlay
             */
            mapView.add(polyline)
            //根据polyline设置地图范围
//            mapViewFitPolyline(polyline!, mapView)
        }
    }
    
    /**
     根据overlay生成对应的BMKOverlayView
     
     @param mapView 地图View
     @param overlay 指定的overlay
     @return 生成的覆盖物View
     */
    func mapView(_ mapView: BMKMapView!, viewFor overlay: BMKOverlay!) -> BMKOverlayView! {
        if overlay.isKind(of: BMKPolyline.self) {
            //初始化一个overlay并返回相应的BMKPolylineView的实例
            let polylineView = BMKPolylineView.init(overlay: overlay)
            //设置polylineView的填充色
            polylineView?.fillColor = UIColor.cyan.withAlphaComponent(1)
            //设置polylineView的画笔（边框）颜色
            polylineView?.strokeColor = UIColor.cyan.withAlphaComponent(0.7)
            //设置polygonView的线宽度
            polylineView?.lineWidth = 2.0
            return polylineView
        }
        return nil
    }
}

# NSMapViewManager
继承百度地图绘制、兴趣点、POI搜索


使用参考代码：
let manager : NSMapViewManager = NSMapViewManager.sharedInstance

manager.viewController = self
manager.annotationStype = .MaintainStype
manager.setMapView()
//插入大头针
manager.addAnnotation()

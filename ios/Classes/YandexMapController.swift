import CoreLocation
import Flutter
import UIKit
import YandexMapsMobile

public class YandexMapController: NSObject, FlutterPlatformView {
  
  private let methodChannel:    FlutterMethodChannel!
  private let pluginRegistrar:  FlutterPluginRegistrar!
  
  private let mapTapListener:             MapTapListener!
  private let mapObjectTapListener:       MapObjectTapListener!
  private var mapCameraListener:          MapCameraListener!
  private let mapSizeChangedListener:     MapSizeChangedListener!
  private var userLocationObjectListener: UserLocationObjectListener?
  
  private var collections: [YMKMapObjectCollection] = []
  private var clusterizedCollections: [YMKClusterizedPlacemarkCollection] = []
  
  private var userLocationLayer: YMKUserLocationLayer?
  
  private var cameraTarget: YMKPlacemarkMapObject?
  
  private var placemarks: [YMKPlacemarkMapObject] = []
  private var polylines:  [YMKPolylineMapObject] = []
  private var polygons:   [YMKPolygonMapObject] = []
  private var circles:    [YMKCircleMapObject] = []
  
  private var unstyledClustersQueue: [YMKCluster] = []
  
  public let mapView: YMKMapView

  public required init(id: Int64, frame: CGRect, registrar: FlutterPluginRegistrar) {
    
    self.pluginRegistrar = registrar
    
    self.mapView = YMKMapView(frame: frame)
    
    self.methodChannel = FlutterMethodChannel(
      name: "yandex_mapkit/yandex_map_\(id)",
      binaryMessenger: registrar.messenger()
    )
    
    self.mapTapListener = MapTapListener(channel: methodChannel)
    self.mapObjectTapListener = MapObjectTapListener(channel: methodChannel)
    self.mapSizeChangedListener = MapSizeChangedListener(channel: methodChannel)
    self.userLocationLayer = YMKMapKit.sharedInstance().createUserLocationLayer(with: mapView.mapWindow)

    super.init()

    weak var weakSelf = self
    self.methodChannel.setMethodCallHandler({ weakSelf?.handle($0, result: $1) })

    self.mapView.mapWindow.map.addInputListener(with: mapTapListener)
    self.mapView.mapWindow.addSizeChangedListener(with: mapSizeChangedListener)
  }

  public func view() -> UIView {
    return self.mapView
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "logoAlignment":
      logoAlignment(call)
      result(nil)
    case "toggleNightMode":
      toggleNightMode(call)
      result(nil)
    case "toggleMapRotation":
      toggleMapRotation(call)
      result(nil)
    case "showUserLayer":
      showUserLayer(call)
      result(nil)
    case "hideUserLayer":
      hideUserLayer()
      result(nil)
    case "setMapStyle":
      setMapStyle(call)
      result(nil)
    case "move":
      move(call)
      result(nil)
    case "setBounds":
      setBounds(call)
      result(nil)
    case "setFocusRect":
      setFocusRect(call)
      result(nil)
    case "clearFocusRect":
      clearFocusRect()
      result(nil)
    case "enableCameraTracking":
      let target = enableCameraTracking(call)
      result(target)
    case "disableCameraTracking":
      disableCameraTracking()
      result(nil)
    case "addCollection":
      addCollection(call)
      result(nil)
    case "addPlacemark":
      addPlacemark(call)
      result(nil)
    case "addPlacemarks":
      addPlacemarks(call)
      result(nil)
    case "clusterPlacemarks":
      clusterPlacemarks(call)
      result(nil)
    case "setClusterIcon":
      setClusterIcon(call)
      result(nil)
    case "removePlacemark":
      removePlacemark(call)
      result(nil)
    case "clear":
      clear(call)
      result(nil)
    case "addPolyline":
      addPolyline(call)
      result(nil)
    case "removePolyline":
      removePolyline(call)
      result(nil)
    case "addPolygon":
      addPolygon(call)
      result(nil)
    case "removePolygon":
      removePolygon(call)
      result(nil)
    case "addCircle":
      addCircle(call)
      result(nil)
      break;
    case "removeCircle":
      removeCircle(call)
      result(nil)
      break;
    case "zoomIn":
      zoomIn()
      result(nil)
    case "zoomOut":
      zoomOut()
      result(nil)
    case "isZoomGesturesEnabled":
      let isZoomGesturesEnabled = isZoomGesturesEnabled()
      result(isZoomGesturesEnabled)
    case "toggleZoomGestures":
      toggleZoomGestures(call)
      result(nil)
    case "getMinZoom":
      let minZoom = getMinZoom()
      result(minZoom)
    case "getMaxZoom":
      let maxZoom = getMaxZoom()
      result(maxZoom)
    case "getZoom":
      let zoom = getZoom()
      result(zoom)
    case "getTargetPoint":
      let targetPoint = getTargetPoint()
      result(targetPoint)
    case "getVisibleRegion":
      let region: [String: Any] = getVisibleRegion()
      result(region)
    case "getUserTargetPoint":
      let userTargetPoint = getUserTargetPoint()
      result(userTargetPoint)
    case "isTiltGesturesEnabled":
      let isTiltGesturesEnabled = isTiltGesturesEnabled()
      result(isTiltGesturesEnabled)
    case "toggleTiltGestures":
      toggleTiltGestures(call)
      result(nil)
    
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func toggleMapRotation(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    mapView.mapWindow.map.isRotateGesturesEnabled = (params["enabled"] as! NSNumber).boolValue
  }

  public func toggleNightMode(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    mapView.mapWindow.map.isNightModeEnabled = (params["enabled"] as! NSNumber).boolValue
  }

  public func setFocusRect(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let topLeftScreenPoint = params["topLeftScreenPoint"] as? [String: Any]
    let bottomRightScreenPoint = params["bottomRightScreenPoint"] as? [String: Any]
    let screenRect = YMKScreenRect(
      topLeft: YMKScreenPoint(
        x: (topLeftScreenPoint!["x"]  as! NSNumber).floatValue,
        y: (topLeftScreenPoint!["y"]  as! NSNumber).floatValue
      ),
      bottomRight: YMKScreenPoint(
        x: (bottomRightScreenPoint!["x"]  as! NSNumber).floatValue,
        y: (bottomRightScreenPoint!["y"]  as! NSNumber).floatValue
      )
    )

    mapView.mapWindow.focusRect = screenRect
    mapView.mapWindow.pointOfView = YMKPointOfView.adaptToFocusRectHorizontally
  }

  public func clearFocusRect() {
    mapView.mapWindow.focusRect = nil
    mapView.mapWindow.pointOfView = YMKPointOfView.screenCenter
  }

  public func logoAlignment(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let logoPosition = YMKLogoAlignment(
      horizontalAlignment: YMKLogoHorizontalAlignment(rawValue : params["x"] as! UInt)!,
      verticalAlignment: YMKLogoVerticalAlignment(rawValue : params["y"] as! UInt)!
    )
    mapView.mapWindow.map.logo.setAlignmentWith(logoPosition)
  }

  public func showUserLayer(_ call: FlutterMethodCall) {
    if (!hasLocationPermission()) { return }

    let params = call.arguments as! [String: Any]

    self.userLocationObjectListener = UserLocationObjectListener(
      pluginRegistrar: pluginRegistrar,
      iconName: params["iconName"] as! String,
      arrowName: params["arrowName"] as! String,
      userArrowOrientation: (params["userArrowOrientation"] as! NSNumber).boolValue,
      accuracyCircleFillColor: uiColor(
        fromInt: (params["accuracyCircleFillColor"] as! NSNumber).int64Value
      )
    )
    userLocationLayer?.setVisibleWithOn(true)
    userLocationLayer!.isHeadingEnabled = true
    userLocationLayer!.setObjectListenerWith(userLocationObjectListener!)
  }

  public func hideUserLayer() {
    if (!hasLocationPermission()) { return }

    userLocationLayer?.setVisibleWithOn(false)
  }

  public func setMapStyle(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let map = mapView.mapWindow.map
    map.setMapStyleWithStyle(params["style"] as! String)
  }

  public func zoomIn() {
    zoom(1)
  }

  public func zoomOut() {
    zoom(-1)
  }
  
  private func zoom(_ step: Float) {
    let point = mapView.mapWindow.map.cameraPosition.target
    let zoom = mapView.mapWindow.map.cameraPosition.zoom
    let azimuth = mapView.mapWindow.map.cameraPosition.azimuth
    let tilt = mapView.mapWindow.map.cameraPosition.tilt
    let currentPosition = YMKCameraPosition(
      target: point,
      zoom: zoom + step,
      azimuth: azimuth,
      tilt: tilt
    )
    mapView.mapWindow.map.move(
      with: currentPosition,
      animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 1),
      cameraCallback: nil
    )
  }
  
  public func isZoomGesturesEnabled() -> Bool {
    return mapView.mapWindow.map.isZoomGesturesEnabled
  }
  
  public func toggleZoomGestures(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let enabled = params["enabled"] as! Bool
    mapView.mapWindow.map.isZoomGesturesEnabled = enabled
  }
  
  public func getMinZoom() -> Float {
    return mapView.mapWindow.map.getMinZoom()
  }
  
  public func getMaxZoom() -> Float {
    return mapView.mapWindow.map.getMaxZoom()
  }

  public func getZoom() -> Float {
    return mapView.mapWindow.map.cameraPosition.zoom
  }

  public func move(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let paramsPoint = params["point"] as! [String: Any]
    let point = YMKPoint(
      latitude: (paramsPoint["latitude"] as! NSNumber).doubleValue,
      longitude: (paramsPoint["longitude"] as! NSNumber).doubleValue
    )
    let cameraPosition = YMKCameraPosition(
      target: point,
      zoom: (params["zoom"] as! NSNumber).floatValue,
      azimuth: (params["azimuth"] as! NSNumber).floatValue,
      tilt: (params["tilt"] as! NSNumber).floatValue
    )

    moveWithParams(params, cameraPosition)
  }

  public func setBounds(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let paramsSouthWestPoint = params["southWestPoint"] as! [String: Any]
    let paramsNorthEastPoint = params["northEastPoint"] as! [String: Any]
    let cameraPosition = mapView.mapWindow.map.cameraPosition(with:
      YMKBoundingBox(
        southWest: YMKPoint(
          latitude: (paramsSouthWestPoint["latitude"] as! NSNumber).doubleValue,
          longitude: (paramsSouthWestPoint["longitude"] as! NSNumber).doubleValue
        ),
        northEast: YMKPoint(
          latitude: (paramsNorthEastPoint["latitude"] as! NSNumber).doubleValue,
          longitude: (paramsNorthEastPoint["longitude"] as! NSNumber).doubleValue
        )
      )
    )

    moveWithParams(params, cameraPosition)
  }

  public func getTargetPoint() -> [String: Any] {
    let targetPoint = mapView.mapWindow.map.cameraPosition.target;
    let arguments: [String: Any] = [
      "latitude": targetPoint.latitude,
      "longitude": targetPoint.longitude
    ]
    return arguments
  }

  public func getUserTargetPoint() -> [String: Any]? {
    if (!hasLocationPermission()) { return nil }

    if let targetPoint = userLocationLayer?.cameraPosition()?.target {
      let arguments: [String: Any] = [
        "latitude": targetPoint.latitude,
        "longitude": targetPoint.longitude
      ]

      return arguments
    }

    return nil
  }
  
  public func addCollection(_ call: FlutterMethodCall) {
    
    let params = call.arguments as! [String: Any]
    
    let id            = (params["id"] as! NSNumber).intValue
    let parentId      = (params["parentId"] as? NSNumber)?.intValue
    let isClusterized = (params["isClusterized"] as? NSNumber)?.boolValue ?? false
    
    // Only plain (YMKMapObjectCollection) can be nested,YMKClusterizedPlacemarkCollection - can not
    guard let parentCollection = getCollectionById(parentId) as? YMKMapObjectCollection else {
      return
    }

    if !isClusterized {
      let collection = parentCollection.add()
      collection.userData = id
      collections.append(collection)
    } else {
      let collection = parentCollection.addClusterizedPlacemarkCollection(with: self)
      collection.userData = id
      clusterizedCollections.append(collection)
    }
  }
  
  private func getCollectionById(_ collectionId: Int?) -> YMKMapObject? {
    
    if collectionId == nil {
      return mapView.mapWindow.map.mapObjects
    }
    
    if let collection = collections.first(where: { $0.userData as? Int == collectionId }) {
      return collection
    }
    
    if let clusterizedCollection = clusterizedCollections.first(where: { $0.userData as? Int == collectionId }) {
      return clusterizedCollection
    }
    
    return nil
  }

  public func addPlacemark(_ call: FlutterMethodCall) {
    
    let params = call.arguments as! [String: Any]
    
    let collectionId = (params["collectionId"] as? NSNumber)?.intValue
    
    let paramsPoint = params["point"] as! [String: Any]
    
    let point = YMKPoint(
      latitude: (paramsPoint["latitude"] as! NSNumber).doubleValue,
      longitude: (paramsPoint["longitude"] as! NSNumber).doubleValue
    )
    
    var placemark: YMKPlacemarkMapObject
    
    let collection = getCollectionById(collectionId)
    
    if let plainCollection = collection as? YMKMapObjectCollection {
      placemark = plainCollection.addPlacemark(with: point)
    } else if let clusterizedCollection = collection as? YMKClusterizedPlacemarkCollection {
      placemark = clusterizedCollection.addPlacemark(with: point)
    } else {
      return
    }
    
    placemark.addTapListener(with: mapObjectTapListener)
    setupPlacemark(placemark: placemark, params: params)

    placemarks.append(placemark)
  }
  
  public func addPlacemarks(_ call: FlutterMethodCall) {
    
    let params = call.arguments as! [String: Any]
    
    let collectionId = (params["collectionId"] as? NSNumber)?.intValue
    
    guard let paramsPoint = params["points"] as? [[String: Any]] else {
      return
    }
    
    guard let ids = params["ids"] as? [Any] else {
      return
    }
    
    guard let paramsIcon  = params["icon"] as? [String: Any] else {
      return
    }
    
    var mapkitPoints: [YMKPoint] = []
    
    for p in paramsPoint {
        
      let point = YMKPoint(
        latitude: (p["latitude"] as! NSNumber).doubleValue,
        longitude: (p["longitude"] as! NSNumber).doubleValue
      )
      
      mapkitPoints.append(point)
    }
    
    guard let img = getIconImage(paramsIcon) else {
      return
    }
    
    var iconStyle = YMKIconStyle()
    
    if let iconStyleParam = paramsIcon["style"] as? [String: Any] {
      iconStyle = getIconStyle(iconStyleParam)
    }
    
    var newPlacemarks: [YMKPlacemarkMapObject] = []
    
    let collection = getCollectionById(collectionId)
    
    if let plainCollection = collection as? YMKMapObjectCollection {
      newPlacemarks = plainCollection.addPlacemarks(with: mapkitPoints, image: img, style: iconStyle)
    } else if let clusterizedCollection = collection as? YMKClusterizedPlacemarkCollection {
      newPlacemarks = clusterizedCollection.addPlacemarks(with: mapkitPoints, image: img, style: iconStyle)
    } else {
      return
    }
    
    for (i, p) in newPlacemarks.enumerated() {
      
      p.userData = ids[i] as! Int
      
      p.addTapListener(with: mapObjectTapListener)
    }

    placemarks.append(contentsOf: newPlacemarks)
  }
  
  public func removePlacemark(_ call: FlutterMethodCall) {
    
    let params = call.arguments as! [String: Any]
    
    let id = (params["id"] as! NSNumber).intValue
    
    guard let placemark = placemarks.first(where: { $0.userData as! Int == id }), let i = placemarks.firstIndex(of: placemark) else {
      return
    }
    
    // Strange, but placemark.parent is always of YMKMapObjectCollection type,
    // but indeed it can be of YMKClusterizedPlacemarkCollection type - in this case remove(with: placemark) throws an Exception
    // because of wrong signatue: remove(withPlacemark: placemark) is correct.
    // So, have to use a workaround - at first find the collection and then remove the placemark from it....
    
    let collection = getCollectionById(placemark.parent.userData as? Int )
    
    if let plainCollection = collection as? YMKMapObjectCollection {
      plainCollection.remove(with: placemark)
    } else if let clusterizedCollection = collection as? YMKClusterizedPlacemarkCollection {
      clusterizedCollection.remove(withPlacemark: placemark)
    } else {
      return
    }
    
    // Remove from local list
    placemarks.remove(at: i)
  }
  
  public func clear(_ call: FlutterMethodCall) {
    
    let params = call.arguments as! [String: Any]
    
    let collectionId = (params["collectionId"] as? NSNumber)?.intValue
    
    let collection = getCollectionById(collectionId)
    
    if let plainCollection = collection as? YMKMapObjectCollection {
      
      // If this is root collection (mapObjects) - just clear all objects, else - remove objects selectively from subtree of collections
      if (collectionId == nil) {
        
        collections             = []
        clusterizedCollections  = []
          
        placemarks.removeAll()
        polylines.removeAll()
        polygons.removeAll()
        circles.removeAll()
        
      } else {
        
        var nestedCollectionsIds: [Int] = []
        nestedCollectionsIds.append(collectionId!)
        
        // Get all plain (not clusterized) nested collections ids using recursive func
        nestedCollectionsIds = getNestedCollectionsIds(nestedCollectionsIds)
        
        // Add all clusterized placemark collections nested in plain collections (no recursion is needed because clusterized collections can't be nested itself)
        for cc in clusterizedCollections {
          
          guard let parentId = cc.parent.userData as? Int else { continue }
          
          if nestedCollectionsIds.contains(parentId) {
            nestedCollectionsIds.append(cc.userData as! Int)
          }
        }

        // Remove all placemarks which parents are in the nestedCollectionsIds list
        placemarks.removeAll(where: ({$0.parent.userData != nil && nestedCollectionsIds.contains($0.parent.userData as! Int)}))
        
        // Remove all nested collections except current one
        collections.removeAll(where: ({nestedCollectionsIds.contains($0.userData as! Int) && ($0.userData as! Int) != collectionId!}))
        clusterizedCollections.removeAll(where: ({nestedCollectionsIds.contains($0.userData as! Int) && ($0.userData as! Int) != collectionId!}))
        
        /*
         TODO: For now polylines, polygons and circles can be added only into the root collection (mapObjects),
         so there is no need to clear corresponding arrays, but should be implemented if addPolyline, addPolygon or addCircle
         will become to accept collectionId argument.
        */
        
      }
      
      // Clear mapkit collection
      plainCollection.clear()
      
    } else if let clusterizedCollection = collection as? YMKClusterizedPlacemarkCollection {
      
      // As clusterized collections can not be nested just remove all placemarks with parent = collectionId
      placemarks.removeAll(where: ({$0.parent.userData as? Int == collectionId}))
      
      // Clear mapkit collection
      clusterizedCollection.clear()
    }
  }
  
  private func getNestedCollectionsIds(_ nestedIds: [Int]) -> [Int] {
    
    var ids = nestedIds
    
    for c in collections {
      
      guard let id = c.userData as? Int, let parentId = c.parent.userData as? Int else {
        continue
      }
      
      if ids.contains(parentId) && !ids.contains(id) {
        ids.append(id)
        return getNestedCollectionsIds(ids)
      }
    }
    
    return ids
  }
  
  public func clusterPlacemarks(_ call: FlutterMethodCall) {
    
    let params = call.arguments as! [String: Any]
    
    let collectionId = (params["collectionId"] as? NSNumber)?.intValue
    
    if (collectionId == nil) {
      return
    }
    
    guard let clusterizedCollection = clusterizedCollections.first(where: { $0.userData as? Int == collectionId }) else {
      return
    }
    
    guard let clusterRadius = (params["clusterRadius"] as? NSNumber)?.doubleValue else {
      return
    }
    
    guard let minZoom = (params["minZoom"] as? NSNumber)?.uintValue else {
      return
    }
    
    clusterizedCollection.clusterPlacemarks(withClusterRadius: clusterRadius, minZoom: minZoom)
  }
  
  /// Finds cluster by hashValue in the unstyledClustersQueue and sets icon.
  /// Can be called only once on a single cluster - cluster removes from queue after it is handled.
  public func setClusterIcon(_ call: FlutterMethodCall) {
    
    let params = call.arguments as! [String: Any]
    
    let hashValue = (params["hashValue"] as! NSNumber).intValue
    
      if let i = unstyledClustersQueue.firstIndex(where: {$0.hashValue == hashValue}) {
      
      let cluster = unstyledClustersQueue[i]
      
      if let icon = params["icon"] as? [String: Any] {
        
        let img = getIconImage(icon)
        
        // Check for isValid to prevent crashes when cluster is not already showing (sometimes may be caused by Flutter interaction delay)
        if img != nil && cluster.isValid {
          cluster.appearance.setIconWith(img!)
        }
      }
      
      unstyledClustersQueue.remove(at: i)
    }
  }
  
  private func setupPlacemark(placemark: YMKPlacemarkMapObject, params: [String: Any]) {
    
    placemark.userData = (params["id"] as! NSNumber).intValue
    
    placemark.opacity     = (params["opacity"] as! NSNumber).floatValue
    placemark.isDraggable = (params["isDraggable"] as! NSNumber).boolValue
    placemark.direction   = (params["direction"] as! NSNumber).floatValue
    placemark.isVisible   = (params["isVisible"] as! NSNumber).boolValue
    
    if let zIndex = (params["zIndex"] as? NSNumber)?.floatValue {
      placemark.zIndex = zIndex
    }
    
    if let icon = params["icon"] as? [String: Any] {
      
      let img = getIconImage(icon)
      
      if img != nil {
        placemark.setIconWith(img!)
      }
      
      if let iconStyle = icon["style"] as? [String: Any] {
        let style = getIconStyle(iconStyle)
        placemark.setIconStyleWith(style)
      }
      
    } else if let composite = params["composite"] as? [String: Any] {
      
      for (name, iconData) in composite {
        
        guard let icon = iconData as? [String: Any] else {
          continue
        }
        
        guard let img = getIconImage(icon) else {
          continue
        }
        
        var style: YMKIconStyle = YMKIconStyle()
        
        if let iconStyle = icon["style"] as? [String: Any] {
          style = getIconStyle(iconStyle)
        }
        
        placemark.useCompositeIcon().setIconWithName(
          name,
          image: img,
          style: style
        )
      }
      
    }
  }
  
  private func getIconImage(_ iconData: [String: Any]) -> UIImage? {
   
    var img: UIImage?;
    
    if let iconName = iconData["iconName"] as? String {
      img = UIImage(named: pluginRegistrar.lookupKey(forAsset: iconName))
    } else if let rawImageData = iconData["rawImageData"] as? FlutterStandardTypedData {
      img = UIImage(data: rawImageData.data)
    }
    
    return img
  }
  
  private func getIconStyle(_ styleParams: [String: Any]) -> YMKIconStyle {
    
    let iconStyle = YMKIconStyle()

    let rotationType = (styleParams["rotationType"] as! NSNumber).intValue
    if (rotationType == YMKRotationType.rotate.rawValue) {
      iconStyle.rotationType = (YMKRotationType.rotate.rawValue as NSNumber)
    }
    
    let anchor = styleParams["anchor"] as! [String: Any]
    
    iconStyle.anchor = NSValue(cgPoint:
      CGPoint(
        x: (anchor["x"] as! NSNumber).doubleValue,
        y: (anchor["y"] as! NSNumber).doubleValue
      )
    )
    
    iconStyle.zIndex = (styleParams["zIndex"] as! NSNumber)
    iconStyle.scale = (styleParams["scale"] as! NSNumber)
    
    let tappableArea = styleParams["tappableArea"] as? [String: Any]
    
    if (tappableArea != nil) {
      
      let tappableAreaMin = tappableArea!["min"] as! [String: Any]
      let tappableAreaMax = tappableArea!["max"] as! [String: Any]
      
      iconStyle.tappableArea = YMKRect(
        min: CGPoint(
          x: (tappableAreaMin["x"] as! NSNumber).doubleValue,
          y: (tappableAreaMin["y"] as! NSNumber).doubleValue
        ),
        max: CGPoint(
          x: (tappableAreaMax["x"] as! NSNumber).doubleValue,
          y: (tappableAreaMax["y"] as! NSNumber).doubleValue
        )
      )
    }
    
    return iconStyle
  }

  public func getVisibleRegion() -> [String: Any] {
    let region = mapView.mapWindow.map.visibleRegion
    var arguments = [String: Any]()
    arguments["bottomLeftPoint"] = ["latitude": region.bottomLeft.latitude, "longitude": region.bottomLeft.longitude]
    arguments["bottomRightPoint"] = ["latitude": region.bottomRight.latitude, "longitude": region.bottomRight.longitude]
    arguments["topLeftPoint"] = ["latitude": region.topLeft.latitude, "longitude": region.topLeft.longitude]
    arguments["topRightPoint"] = ["latitude": region.topRight.latitude, "longitude": region.topRight.longitude]
    return arguments
  }

  public func disableCameraTracking() {
    if mapCameraListener != nil {
      mapView.mapWindow.map.removeCameraListener(with: mapCameraListener)
      mapCameraListener = nil

      if cameraTarget != nil {
        let mapObjects = mapView.mapWindow.map.mapObjects
        mapObjects.remove(with: cameraTarget!)
        cameraTarget = nil
      }
    }
  }

  public func enableCameraTracking(_ call: FlutterMethodCall) -> [String: Any] {
    
    if mapCameraListener == nil {
      mapCameraListener = MapCameraListener(controller: self, channel: methodChannel)
      mapView.mapWindow.map.addCameraListener(with: mapCameraListener)
    }

    let mapObjects = mapView.mapWindow.map.mapObjects
    
    if cameraTarget != nil {
      mapObjects.remove(with: cameraTarget!)
      cameraTarget = nil
    }

    let targetPoint = mapView.mapWindow.map.cameraPosition.target;
    
    if call.arguments != nil {
      
      let params = call.arguments as! [String: Any]
      
      if let placemarkTemplate = params["placemarkTemplate"] as? [String: Any] {
        
        let paramsPoint = placemarkTemplate["point"] as! [String: Any]
        
        let point = YMKPoint(
          latitude: (paramsPoint["latitude"] as! NSNumber).doubleValue,
          longitude: (paramsPoint["longitude"] as! NSNumber).doubleValue
        )
        
        let placemark = mapObjects.addPlacemark(with: point)
        setupPlacemark(placemark: placemark, params: placemarkTemplate)
      }
    }

    let arguments: [String: Any] = [
      "latitude": targetPoint.latitude,
      "longitude": targetPoint.longitude
    ]
    
    return arguments
  }

  private func addPolyline(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let paramsCoordinates = params["coordinates"] as! [[String: Any]]
    let paramsStyle = params["style"] as! [String: Any]
    let coordinatesPrepared = paramsCoordinates.map {
      YMKPoint(
        latitude: ($0["latitude"] as! NSNumber).doubleValue,
        longitude: ($0["longitude"] as! NSNumber).doubleValue
      )
    }
    let mapObjects = mapView.mapWindow.map.mapObjects
    let polyline = YMKPolyline(points: coordinatesPrepared)
    let polylineMapObject = mapObjects.addPolyline(with: polyline)
    polylineMapObject.userData = (params["hashCode"] as! NSNumber).intValue
    polylineMapObject.strokeColor = uiColor(fromInt: (paramsStyle["strokeColor"] as! NSNumber).int64Value)
    polylineMapObject.outlineColor = uiColor(fromInt: (paramsStyle["outlineColor"] as! NSNumber).int64Value)
    polylineMapObject.outlineWidth = (paramsStyle["outlineWidth"] as! NSNumber).floatValue
    polylineMapObject.strokeWidth = (paramsStyle["strokeWidth"] as! NSNumber).floatValue
    polylineMapObject.isGeodesic = (paramsStyle["isGeodesic"] as! NSNumber).boolValue
    polylineMapObject.dashLength = (paramsStyle["dashLength"] as! NSNumber).floatValue
    polylineMapObject.dashOffset = (paramsStyle["dashOffset"] as! NSNumber).floatValue
    polylineMapObject.gapLength = (paramsStyle["gapLength"] as! NSNumber).floatValue

    polylines.append(polylineMapObject)
  }

  private func removePolyline(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let hashCode = (params["hashCode"] as! NSNumber).intValue

    if let polyline = polylines.first(where: { $0.userData as! Int ==  hashCode}) {
      let mapObjects = mapView.mapWindow.map.mapObjects
      mapObjects.remove(with: polyline)
      polylines.remove(at: polylines.firstIndex(of: polyline)!)
    }
  }

  public func addPolygon(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let paramsOuterRingCoordinates = params["outerRingCoordinates"] as! [[String: Any]]
    let paramsInnerRingsCoordinates = params["innerRingsCoordinates"] as! [[[String: Any]]]
    let paramsStyle = params["style"] as! [String: Any]
    let outerRing = YMKLinearRing(points: paramsOuterRingCoordinates.map {
        YMKPoint(
          latitude: ($0["latitude"] as! NSNumber).doubleValue,
          longitude: ($0["longitude"] as! NSNumber).doubleValue
        )
      }
    )
    let innerRings = paramsInnerRingsCoordinates.map {
      YMKLinearRing(points: $0.map {
          YMKPoint(
            latitude: ($0["latitude"] as! NSNumber).doubleValue,
            longitude: ($0["longitude"] as! NSNumber).doubleValue
          )
        }
      )
    }
    let mapObjects = mapView.mapWindow.map.mapObjects
    let polylgon = YMKPolygon(outerRing: outerRing, innerRings: innerRings)
    let polygonMapObject = mapObjects.addPolygon(with: polylgon)

    polygonMapObject.userData = (params["hashCode"] as! NSNumber).intValue
    polygonMapObject.strokeColor = uiColor(fromInt: (paramsStyle["strokeColor"] as! NSNumber).int64Value)
    polygonMapObject.strokeWidth = (paramsStyle["strokeWidth"] as! NSNumber).floatValue
    polygonMapObject.isGeodesic = (paramsStyle["isGeodesic"] as! NSNumber).boolValue
    polygonMapObject.fillColor = uiColor(fromInt: (paramsStyle["fillColor"] as! NSNumber).int64Value)

    polygons.append(polygonMapObject)
  }

  public func removePolygon(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let hashCode = (params["hashCode"] as! NSNumber).intValue

    if let polygon = polygons.first(where: { $0.userData as! Int ==  hashCode}) {
      let mapObjects = mapView.mapWindow.map.mapObjects
      mapObjects.remove(with: polygon)
      polygons.remove(at: polygons.firstIndex(of: polygon)!)
    }
  }

  private func addCircle(_ call: FlutterMethodCall) {

    let params = call.arguments as! [String: Any]

    let paramsCenter = params["center"] as! [String: Any]
    let paramsRadius = params["radius"] as! NSNumber
    let paramsStyle = params["style"] as! [String: Any]

    let centerPrepared = YMKPoint(
      latitude: (paramsCenter["latitude"] as! NSNumber).doubleValue,
      longitude: (paramsCenter["longitude"] as! NSNumber).doubleValue
    )
  
    let radiusPrepared = paramsRadius.floatValue

    let mapObjects = mapView.mapWindow.map.mapObjects

    let circle = YMKCircle(center: centerPrepared, radius: radiusPrepared)
  
    let circleMapObject = mapObjects.addCircle(
      with: circle,
      stroke: uiColor(fromInt: (paramsStyle["strokeColor"] as! NSNumber).int64Value),
      strokeWidth: (paramsStyle["strokeWidth"] as! NSNumber).floatValue,
      fill: uiColor(fromInt: (paramsStyle["fillColor"] as! NSNumber).int64Value))

    circleMapObject.userData = (params["hashCode"] as! NSNumber).intValue
    circleMapObject.isGeodesic = (paramsStyle["isGeodesic"] as! NSNumber).boolValue
    
    circles.append(circleMapObject)
  }

  private func removeCircle(_ call: FlutterMethodCall) {
        
    let params = call.arguments as! [String: Any]
    let hashCode = (params["hashCode"] as! NSNumber).intValue

    if let circle = circles.first(where: { $0.userData as! Int == hashCode}) {
      let mapObjects = mapView.mapWindow.map.mapObjects
      mapObjects.remove(with: circle)
      circles.remove(at: circles.firstIndex(of: circle)!)
    }
  }

  private func moveWithParams(_ params: [String: Any], _ cameraPosition: YMKCameraPosition) {
    let paramsAnimation = params["animation"] as! [String: Any]

    if ((paramsAnimation["animate"] as! NSNumber).boolValue) {
      let type = (paramsAnimation["smoothAnimation"] as! NSNumber).boolValue ?
        YMKAnimationType.smooth :
        YMKAnimationType.linear
      let animationType = YMKAnimation(
        type: type,
        duration: (paramsAnimation["animationDuration"] as! NSNumber).floatValue
      )

      mapView.mapWindow.map.move(with: cameraPosition, animationType: animationType)
    } else {
      mapView.mapWindow.map.move(with: cameraPosition)
    }
  }

  private func hasLocationPermission() -> Bool {
    if CLLocationManager.locationServicesEnabled() {
      switch CLLocationManager.authorizationStatus() {
      case .notDetermined, .restricted, .denied:
        return false
      case .authorizedAlways, .authorizedWhenInUse:
        return true
      default:
        return false
      }
    } else {
      return false
    }
  }

  private func uiColor(fromInt value: Int64) -> UIColor {
    return UIColor(
      red: CGFloat((value & 0xFF0000) >> 16) / 0xFF,
      green: CGFloat((value & 0x00FF00) >> 8) / 0xFF,
      blue: CGFloat(value & 0x0000FF) / 0xFF,
      alpha: CGFloat((value & 0xFF000000) >> 24) / 0xFF
    )
  }

  internal class UserLocationObjectListener: NSObject, YMKUserLocationObjectListener {
    private let pluginRegistrar: FlutterPluginRegistrar!

    private let iconName: String!
    private let arrowName: String!
    private let userArrowOrientation: Bool!
    private var accuracyCircleFillColor: UIColor = UIColor(
        red: CGFloat(((0xFF69b04a as Int64) & 0xFF0000) >> 16) / 0xFF,
        green: CGFloat(((0xFF69b04a as Int64) & 0x00FF00) >> 8) / 0xFF,
        blue: CGFloat((0xFF69b04a as Int64) & 0x0000FF) / 0xFF,
        alpha: CGFloat(((0x1F000000) as Int64) >> 24) / 0xFF
      )

    public required init(
      pluginRegistrar: FlutterPluginRegistrar,
      iconName: String,
      arrowName: String,
      userArrowOrientation: Bool,
      accuracyCircleFillColor: UIColor
    ) {
      self.pluginRegistrar = pluginRegistrar
      self.iconName = iconName
      self.arrowName = arrowName
      self.userArrowOrientation = userArrowOrientation
      self.accuracyCircleFillColor = accuracyCircleFillColor
    }

    func onObjectAdded(with view: YMKUserLocationView) {
      view.pin.setIconWith(
        UIImage(named: pluginRegistrar.lookupKey(forAsset: self.iconName))!
      )
      view.arrow.setIconWith(
        UIImage(named: pluginRegistrar.lookupKey(forAsset: self.arrowName))!
      )
      if (userArrowOrientation) {
        view.arrow.setIconStyleWith(
          YMKIconStyle(
            anchor: nil,
            rotationType: YMKRotationType.rotate.rawValue as NSNumber,
            zIndex: nil,
            flat: nil,
            visible: nil,
            scale: nil,
            tappableArea: nil
          )
        )
      }
      view.accuracyCircle.fillColor = accuracyCircleFillColor
    }

    func onObjectRemoved(with view: YMKUserLocationView) {}

    func onObjectUpdated(with view: YMKUserLocationView, event: YMKObjectEvent) {}
  }

  internal class MapObjectTapListener: NSObject, YMKMapObjectTapListener {
    private let methodChannel: FlutterMethodChannel!

    public required init(channel: FlutterMethodChannel) {
      self.methodChannel = channel
    }

    func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
      let arguments: [String:Any?] = [
        "hashCode": mapObject.userData,
        "latitude": point.latitude,
        "longitude": point.longitude
      ]
      methodChannel.invokeMethod("onMapObjectTap", arguments: arguments)

      return true
    }
  }

  internal class MapTapListener: NSObject, YMKMapInputListener {
    private let methodChannel: FlutterMethodChannel!

    public required init(channel: FlutterMethodChannel) {
      self.methodChannel = channel
    }

    func onMapTap(with map: YMKMap, point: YMKPoint) {
      let arguments: [String:Any?] = [
        "latitude": point.latitude,
        "longitude": point.longitude
      ]
      methodChannel.invokeMethod("onMapTap", arguments: arguments)
    }

    func onMapLongTap(with map: YMKMap, point: YMKPoint) {
      let arguments: [String:Any?] = [
        "latitude": point.latitude,
        "longitude": point.longitude
      ]
      methodChannel.invokeMethod("onMapLongTap", arguments: arguments)
    }
  }

  internal class MapCameraListener: NSObject, YMKMapCameraListener {
    weak private var yandexMapController: YandexMapController!
    private let methodChannel: FlutterMethodChannel!

    public required init(controller: YandexMapController, channel: FlutterMethodChannel) {
      self.yandexMapController = controller
      self.methodChannel = channel
      super.init()
    }

    internal func onCameraPositionChanged(
      with map: YMKMap,
      cameraPosition: YMKCameraPosition,
      cameraUpdateReason: YMKCameraUpdateReason,
      finished: Bool
    ) {
      let targetPoint = cameraPosition.target

      yandexMapController.cameraTarget?.geometry = targetPoint

      let arguments: [String:Any?] = [
        "latitude": targetPoint.latitude,
        "longitude": targetPoint.longitude,
        "zoom": cameraPosition.zoom,
        "tilt": cameraPosition.tilt,
        "azimuth": cameraPosition.azimuth,
        "final": finished
      ]
      methodChannel.invokeMethod("onCameraPositionChanged", arguments: arguments)
    }
  }

  internal class MapSizeChangedListener: NSObject, YMKMapSizeChangedListener {
    private let methodChannel: FlutterMethodChannel!

    public required init(channel: FlutterMethodChannel) {
      self.methodChannel = channel
    }

    func onMapWindowSizeChanged(with mapWindow: YMKMapWindow, newWidth: Int, newHeight: Int) {
      let arguments: [String:Any?] = [
        "width": newWidth,
        "height": newHeight
      ]

      methodChannel.invokeMethod("onMapSizeChanged", arguments: arguments)
    }
  }
  
  public func isTiltGesturesEnabled() -> Bool {
    return mapView.mapWindow.map.isTiltGesturesEnabled
  }
    
  public func toggleTiltGestures(_ call: FlutterMethodCall) {
    let params = call.arguments as! [String: Any]
    let enabled = params["enabled"] as! Bool
    mapView.mapWindow.map.isTiltGesturesEnabled = enabled
  }
}

extension YandexMapController: YMKClusterListener {
  
  public func onClusterAdded(with cluster: YMKCluster) {
    
    unstyledClustersQueue.append(cluster)
    
    var placemarks: [Int] = []
    
    // Collect array or placemarks hashCodes stored in userData
    for p in cluster.placemarks {
      placemarks.append(p.userData as! Int)
    }
    
    let arguments: [String:Any] = [
      "hashValue": cluster.hashValue,
      "size": cluster.size,
      "appearance": [
        "opacity": cluster.appearance.opacity,
        "direction": cluster.appearance.direction,
        "zIndex": cluster.appearance.zIndex,
        "geometry": [
          "latitude": cluster.appearance.geometry.latitude,
          "longitude": cluster.appearance.geometry.longitude,
        ],
      ],
      "placemarks": placemarks
    ]
    
    methodChannel.invokeMethod("onClusterAdded", arguments: arguments)
    
    cluster.addClusterTapListener(with: self)
  }
}

extension YandexMapController: YMKClusterTapListener {
 
  public func onClusterTap(with cluster: YMKCluster) -> Bool {
    
    var placemarks: [Int] = []
    
    // Collect array or placemarks hashCodes stored in userData
    for p in cluster.placemarks {
      placemarks.append(p.userData as! Int)
    }
    
    let arguments: [String:Any] = [
      "hashValue": cluster.hashValue,
      "size": cluster.size,
      "appearance": [
        "opacity": cluster.appearance.opacity,
        "direction": cluster.appearance.direction,
        "zIndex": cluster.appearance.zIndex,
        "geometry": [
          "latitude": cluster.appearance.geometry.latitude,
          "longitude": cluster.appearance.geometry.longitude,
        ],
      ],
      "placemarks": placemarks
    ]
    
    methodChannel.invokeMethod("onClusterTap", arguments: arguments)

    return true
  }
}
  

//
//  Map.swift
//  OSM editor
//
//  Created by Arkadiy on 23.02.2023.
//

import GLMap
import GLMapCore
import UIKit
import XMLCoder

// Class for work with mapView. Later it is necessary to transfer all map objects to it
class MapClient {
    weak var delegate: MapClientProtocol?
    
    // Since the getSourceBbox data loading method is launched when the screen is shifted, we use lock to block simultaneous access to variables.
    let lock = NSLock()
    // A dictionary that stores the unique id of the upload operation
    var openOperations: [Int: Bool] = [:]
    // Variable to give each load operation a unique id
    var lastID: Int = 0
    var operationID: Int {
        let number = lastID + 1
        lastID = number
        return number
    }
    
    let fileManager = FileManager.default
    
    // All vector objects on the map are added to the array, to search for objects under the tap
    var tapObjects = GLMapVectorObjectArray()
        
    // Drawble objects and styles to display data on MapView
    // Layer with original OSM map data
    let sourceDrawble = GLMapVectorLayer(drawOrder: 0)
    let sourceStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.defaultStyle)
    //  Displays objects created but not sent to the server (orange color).
    let newDrawble = GLMapVectorLayer(drawOrder: 2)
    let newStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.newStyle)
    //  Displays objects that have been modified but not sent to the server (green).
    let savedDrawable = GLMapVectorLayer(drawOrder: 1)
    let savedStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.savedStyle)
    
    // Link to SavedNodesButton on MapViewController to update counter
    var savedNodeButtonLink: SavedObjectButton?
    
    // Latest options bbox loading raw map data
    var lastCenter: GLMapGeoPoint?
    // This is the default bbox size for loading OSM raw data. In case of receiving a response from the server "400" - too many objects in the bbox (may occur in regions with a high density of objects) is reduced by 25%
    var defaultBboxSize = 0.002
     
    init() {
        setAppSettingsClouser()
    }
    
    func setAppSettingsClouser() {
        // Every time AppSettings.settings.savedObjects is changed (this is the variable in which the modified or created objects are stored), a closure is called. In this case, when a short circuit is triggered, we update the illumination of saved and created objects.
        AppSettings.settings.mapVCClouser = { [weak self] in
            guard let self = self else { return }
            self.showSavedObjects()
        }
    }
    
    // The method is called from a closure on the MapViewController to load data in case the map moves out of the area of previously loaded data
    //    ---------latMax
    //   |           |
    //   |           |
    //   |           |
    // lonMin------lonMax/latMin
    func checkMapCenter(center: GLMapGeoPoint) async throws {
        if let lastCenter = lastCenter {
            let longMin = lastCenter.lon - defaultBboxSize
            let longMax = lastCenter.lon + defaultBboxSize
            let latMin = lastCenter.lat - defaultBboxSize
            let latMax = lastCenter.lat + defaultBboxSize
            if center.lon < longMin || center.lon > longMax || center.lat < latMin || center.lat > latMax {
                // When we call the new load method, we remove all values from the dictionary of operations to block them.
                try await startNewDownload(center: center)
            }
        } else {
            lastCenter = center
            try await startNewDownload(center: center)
        }
    }
    
    func startNewDownload(center: GLMapGeoPoint) async throws {
        lock.lock()
        openOperations.removeAll()
        lock.unlock()
        try await getSourceBbox(mapCenter: center)
    }
    
    // Loading the source data of the map in the bbox
    func getSourceBbox(mapCenter: GLMapGeoPoint) async throws {
        let id = operationID
        lock.lock()
        // Run indicator animation in MapViewController
        delegate?.startDownload()
        // Adding an operation to the dictionary of running operations
        openOperations[id] = true
        lock.unlock()
        // Setting a maximum bbox size to prevent getting a 400 error from the server
        let latitudeDisplayMin = mapCenter.lat - defaultBboxSize
        let latitudeDisplayMax = mapCenter.lat + defaultBboxSize
        let longitudeDisplayMin = mapCenter.lon - defaultBboxSize
        let longitudeDisplayMax = mapCenter.lon + defaultBboxSize
        // We check with such blocks of code whether it is possible to perform the operation further
        lock.lock()
        if openOperations[id] == nil {
            print("1-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        // Get data from server
        var nilData: Data?
        do {
            nilData = try await OsmClient().downloadOSMData(longitudeDisplayMin: longitudeDisplayMin, latitudeDisplayMin: latitudeDisplayMin, longitudeDisplayMax: longitudeDisplayMax, latitudeDisplayMax: latitudeDisplayMax)
        } catch OsmClientErrors.objectLimit {
            // Reduce bbox size to reduce the number of loaded objects
            lock.lock()
            defaultBboxSize = defaultBboxSize * 0.75
            openOperations.removeAll()
            lock.unlock()
            try await getSourceBbox(mapCenter: mapCenter)
        }
        lock.lock()
        if openOperations[id] == nil {
            print("2-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        // Write data to file
        guard let data = nilData else { throw "Error get data - nill data" }
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.getNodesFromXML(data: data)
        }
        lock.lock()
        try data.write(to: AppSettings.settings.inputFileURL)
        lock.unlock()
        lock.lock()
        if openOperations[id] == nil {
            print("3-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        // Convert OSM xml to geoJSON
        lock.lock()
        if let error = osmium_convert(AppSettings.settings.inputFileURL.path, AppSettings.settings.outputFileURL.path) {
            lock.unlock()
            throw "Error osmium convert: \(error)"
        }
        lock.unlock()
        lock.lock()
        if openOperations[id] == nil {
            print("4-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        lock.lock()
        let dataGeojson = try Data(contentsOf: AppSettings.settings.outputFileURL)
        lock.unlock()
        lock.lock()
        if openOperations[id] == nil {
            print("5-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        // Make vector objects from geoJSON
        let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
        lock.lock()
        if openOperations[id] == nil {
            print("6-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        // Add new objects to array for tap
        lock.lock()
        tapObjects = newObjects
        if openOperations[id] == nil {
            print("7-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        // Add layer on MapViewController
        delegate?.removeDrawble(layer: sourceDrawble)
        if let style = sourceStyle {
            lock.lock()
            sourceDrawble.setVectorObjects(newObjects, with: style, completion: nil)
            lock.unlock()
            delegate?.addDrawble(layer: sourceDrawble)
        }
        lock.lock()
        lastCenter = mapCenter
        if openOperations[id] == nil {
            print("8-", id)
            lock.unlock()
            return
        }
        lock.unlock()
    }
    
    //  In the background, we start indexing the downloaded data and saving them with the dictionary appSettings.settings.inputObjects for quick access to the object by its id.
    func getNodesFromXML(data: Data) {
        let id = operationID
        lock.lock()
        AppSettings.settings.inputObjects = [:]
        openOperations[id] = false
        lock.unlock()
        do {
            let xmlObjects = try XMLDecoder().decode(osm.self, from: data)
            lock.lock()
            if openOperations[id] == nil {
                print("12-", id)
                AppSettings.settings.inputObjects = [:]
                lock.unlock()
                return
            }
            lock.unlock()
            lock.lock()
            for node in xmlObjects.node {
                AppSettings.settings.inputObjects[node.id] = node
            }
            lock.unlock()
            lock.lock()
            if openOperations[id] == nil {
                print("13-", id)
                AppSettings.settings.inputObjects = [:]
                lock.unlock()
                return
            }
            lock.unlock()
            lock.lock()
            for way in xmlObjects.way {
                AppSettings.settings.inputObjects[way.id] = way
            }
            lock.unlock()
            delegate?.endDownload()
        } catch {
            lock.unlock()
            delegate?.endDownload()
            print(error)
        }
    }
    
    //  Get objects after tap
    func openObject(touchCoordinate: GLMapPoint, tmp: GLMapPoint) -> Set<Int> {
        var result: Set<Int> = []
        let maxDist = CGFloat(hypot(tmp.x, tmp.y))
        var nearestPoint = GLMapPoint()
        guard tapObjects.count > 0 else { return [] }
        for i in 0 ... tapObjects.count - 1 {
            let object = tapObjects[i]
            if object.findNearestPoint(&nearestPoint, to: touchCoordinate, maxDistance: maxDist) && (object.type.rawValue == 1 || object.type.rawValue == 2) {
                guard let id = object.getObjectID() else { continue }
                result.insert(id)
            }
        }
        return result
    }
    
    //  Displays created and modified objects.
    func showSavedObjects() {
        let savedObjects = GLMapVectorObjectArray()
        let newObjects = GLMapVectorObjectArray()
        for (id, osmObject) in AppSettings.settings.savedObjects {
            let object = osmObject.getVectorObject()
            // The ID is stored as a string in each vector object (feature of how osmium works). To recognize the id of the created object after the tap, assign it a number
            object.setValue(String(id), forKey: "@id")
            if id < 0 {
                newObjects.add(object)
            } else {
                savedObjects.add(object)
            }
        }
        if savedObjects.count > 0 {
            for i in 0 ... savedObjects.count - 1 {
                let object = savedObjects[i]
                tapObjects.add(object)
            }
        }
        if newObjects.count > 0 {
            for i in 0 ... newObjects.count - 1 {
                let object = newObjects[i]
                tapObjects.add(object)
            }
        }
        delegate?.removeDrawble(layer: savedDrawable)
        delegate?.removeDrawble(layer: newDrawble)
        if let savedStyle = savedStyle {
            savedDrawable.setVectorObjects(savedObjects, with: savedStyle, completion: nil)
        }
        if let newStyle = newStyle {
            newDrawble.setVectorObjects(newObjects, with: newStyle, completion: nil)
        }
        delegate?.addDrawble(layer: savedDrawable)
        delegate?.addDrawble(layer: newDrawble)
        // Update saveNodesButton counter
        if let button = savedNodeButtonLink {
            DispatchQueue.main.async {
                button.update()
            }
        }
    }
}

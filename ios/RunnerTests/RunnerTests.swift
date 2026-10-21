import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {
  func testDrawingShareErrorsNeverPresent() {
    let handler = DrawingShareHandler()
    var calls = 0
    var response: Any?
    let present: DrawingShareHandler.Present = { _,_,_,_ in calls += 1 }
    for args: Any? in [nil, [:], ["bytes": FlutterStandardTypedData(bytes: Data()), "anchor": ["x":0,"y":0,"width":Double.nan,"height":48]]] {
      handler.share(args, available: true, present: present) { response = $0 }
      XCTAssertTrue(response is FlutterError)
    }
    handler.share(nil, available: false, present: present) { response = $0 }
    XCTAssertTrue(response is FlutterError)
    XCTAssertEqual(calls,0)
  }

  func testDrawingPresentationFailureAndAnchorBounds() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let handler = DrawingShareHandler(directory: directory)
    let format = UIGraphicsImageRendererFormat(); format.scale = 1
    let data = UIGraphicsImageRenderer(size: CGSize(width:1024,height:1024),format:format).pngData { _ in }
    let args: [String:Any] = ["bytes": FlutterStandardTypedData(bytes:data), "anchor":["x":-20,"y":10,"width":48,"height":48]]
    var response: Any?
    handler.share(args,available:true,present:{ _,_,_,_ in throw NSError(domain:"test",code:1) }) { response = $0 }
    XCTAssertTrue(response is FlutterError)
    handler.share(args,available:true,present:{ file,_,opened,dismissed in
      XCTAssertTrue(FileManager.default.fileExists(atPath:file.path));opened();dismissed()
    }) { response = $0 }
    XCTAssertEqual((response as? [String:String])?["status"],"presented")
    let bounds = CGRect(x:0,y:0,width:400,height:800)
    XCTAssertEqual(DrawingShareHandler.safeAnchor(CGRect(x:-20,y:10,width:48,height:48),bounds:bounds),CGRect(x:0,y:10,width:28,height:48))
    XCTAssertTrue(bounds.contains(DrawingShareHandler.safeAnchor(CGRect(x:1000,y:1000,width:48,height:48),bounds:bounds)))
  }

  func testDrawingValidationAndCacheIsolation() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let handler = DrawingShareHandler(directory: directory)
    XCTAssertThrowsError(try handler.prepare(Data()))
    XCTAssertThrowsError(try handler.prepare(Data(repeating: 0, count: 12 * 1024 * 1024 + 1)))
    XCTAssertThrowsError(try handler.prepare(Data([137,80,78,71,13,10,26,10])))
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 1024), format: {
      let format = UIGraphicsImageRendererFormat(); format.scale = 1; return format
    }())
    let data = renderer.pngData { context in UIColor.white.setFill(); context.fill(CGRect(x: 0,y: 0,width: 1024,height: 1024)) }
    let old = directory.appendingPathComponent("old.png")
    try data.write(to: old)
    try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -90000)], ofItemAtPath: old.path)
    let unrelated = directory.appendingPathComponent("keep.txt")
    try Data([1]).write(to: unrelated)
    let first = try handler.prepare(data)
    let second = try handler.prepare(data)
    XCTAssertNotEqual(first,second)
    XCTAssertFalse(FileManager.default.fileExists(atPath: old.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: first.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: unrelated.path))
    XCTAssertTrue(first.lastPathComponent.hasSuffix(".png"))
  }

}

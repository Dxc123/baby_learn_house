import Flutter
import UIKit
import ImageIO

final class DrawingShareHandler {
  typealias Present = (URL, CGRect, @escaping () -> Void, @escaping () -> Void) throws -> Void
  let directory: URL
  private var busy = false
  init(directory: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("drawing_exports")) {
    self.directory = directory
  }
  func prepare(_ data: Data) throws -> URL {
    let signature: [UInt8] = [137,80,78,71,13,10,26,10]
    guard data.count >= 24, data.count <= 12*1024*1024, Array(data.prefix(8)) == signature,
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      (properties[kCGImagePropertyPixelWidth] as? Int) == 1024,
      (properties[kCGImagePropertyPixelHeight] as? Int) == 1024,
      CGImageSourceCreateImageAtIndex(source, 0, nil) != nil else {
      throw NSError(domain: "drawing",code: 1,userInfo: [NSLocalizedDescriptionKey:"无效PNG"])
    }
    let manager = FileManager.default
    try manager.createDirectory(at: directory, withIntermediateDirectories: true)
    for file in try manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey,.isRegularFileKey]) {
      let values = try file.resourceValues(forKeys: [.contentModificationDateKey,.isRegularFileKey])
      if file.pathExtension == "png", values.isRegularFile == true,
        let modified = values.contentModificationDate, Date().timeIntervalSince(modified) > 86400 {
        try? manager.removeItem(at: file)
      }
    }
    let file = directory.appendingPathComponent("drawing-\(UUID().uuidString).png")
    try data.write(to: file, options: .atomic)
    return file
  }
  func share(_ arguments: Any?, presenter: UIViewController?, result: @escaping FlutterResult) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { self.share(arguments,presenter: presenter,result: result) }; return
    }
    let available = presenter?.viewIfLoaded?.window != nil &&
      presenter?.view.window?.windowScene?.activationState == .foregroundActive &&
      presenter?.presentedViewController == nil
    share(arguments, available: available, present: { file,anchor,opened,dismissed in
      guard let presenter = presenter else { throw NSError(domain:"drawing",code:2) }
      let sheet = UIActivityViewController(activityItems: [file], applicationActivities: nil)
      if let popover = sheet.popoverPresentationController {
        popover.sourceView = presenter.view
        popover.sourceRect = Self.safeAnchor(anchor,bounds:presenter.view.bounds)
      }
      sheet.completionWithItemsHandler = { _,_,_,_ in dismissed() }
      presenter.present(sheet,animated:true,completion:opened)
    }, result: result)
  }
  static func safeAnchor(_ anchor: CGRect, bounds: CGRect) -> CGRect {
    let rect = anchor.intersection(bounds)
    return rect.isNull || rect.isEmpty ? CGRect(x:bounds.midX,y:bounds.midY,width:1,height:1) : rect
  }
  func share(_ arguments: Any?, available: Bool, present: Present, result: @escaping FlutterResult) {
    guard !busy, available else {
      result(FlutterError(code:"presenter_unavailable",message:"分享面板暂时无法打开",details:nil)); return
    }
    guard let args = arguments as? [String: Any], let typed = args["bytes"] as? FlutterStandardTypedData,
      let anchor = args["anchor"] as? [String: NSNumber],
      let x = anchor["x"]?.doubleValue, let y = anchor["y"]?.doubleValue,
      let width = anchor["width"]?.doubleValue, let height = anchor["height"]?.doubleValue,
      [x,y,width,height].allSatisfy({ $0.isFinite }), width > 0, height > 0 else {
      result(FlutterError(code:"invalid_arguments",message:"分享参数无效",details:nil)); return
    }
    do {
      let file = try prepare(typed.data)
      busy = true
      try present(file,CGRect(x:x,y:y,width:width,height:height),{ result(["status":"presented"]) },{ [weak self] in self?.busy = false })
    } catch {
      busy = false
      result(FlutterError(code:"drawing_share_failed",message:error.localizedDescription,details:nil))
    }
  }
}

import Foundation
import SwiftUI
import UIKit

final class ImageCache {
    static let shared = ImageCache()
    private let memory = NSCache<NSString, UIImage>()
    private let ioQueue = DispatchQueue(label: "imagecache.disk", qos: .utility)
    private let diskDirectory: URL
    
    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskDirectory = caches.appendingPathComponent("ProfileImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
        memory.countLimit = 100
        memory.totalCostLimit = 50 * 1024 * 1024 // ~50MB
    }
    
    private func fileURL(for url: URL) -> URL {
        let key = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        return diskDirectory.appendingPathComponent(key)
    }
    
    func image(for url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString
        if let cached = memory.object(forKey: key) { return cached }
        let path = fileURL(for: url)
        if let data = try? Data(contentsOf: path), let image = UIImage(data: data) {
            memory.setObject(image, forKey: key, cost: data.count)
            return image
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                memory.setObject(image, forKey: key, cost: data.count)
                ioQueue.async { [path] in try? data.write(to: path, options: .atomic) }
                return image
            }
        } catch { }
        return nil
    }
    
    func prefetch(url: URL) {
        Task { _ = await image(for: url) }
    }
}

struct CachedImageView: View {
    let url: URL
    let placeholder: () -> AnyView
    
    @State private var uiImage: UIImage? = nil
    
    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder()
            }
        }
        .task {
            if uiImage == nil {
                uiImage = await ImageCache.shared.image(for: url)
            }
        }
    }
}



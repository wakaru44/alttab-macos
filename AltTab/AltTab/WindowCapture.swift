//
//  WindowCapture.swift
//  AltTab — Windows-style Window Switcher for macOS
//
//  Modern window thumbnail capture using ScreenCaptureKit.
//  Requires macOS 14.0+ (Sonoma). Falls back to app icons on capture failure.
//
//  Author:  Sergio Farfan <sergio.farfan@gmail.com>
//  Version: 1.1.0
//  Date:    2026-03-17
//  License: MIT
//

import Cocoa
import ScreenCaptureKit

final class WindowCapture {

    private let thumbnailMaxWidth: CGFloat = 320
    private let thumbnailMaxHeight: CGFloat = 200
    private let cache = NSCache<NSNumber, NSImage>()

    /// Captures thumbnails for all windows asynchronously.
    /// Calls completion on main thread with updated WindowInfo array.
    ///
    /// Uses ScreenCaptureKit (macOS 14.0+) for modern, reliable window capture.
    /// System will prompt for Screen Recording permission on first use.
    func captureThumbnails(for windows: [WindowInfo], completion: @escaping ([WindowInfo]) -> Void) {
        NSLog("WindowCapture: captureThumbnails called - windowCount=\(windows.count)")

        // Apply cached thumbnails synchronously first
        var windowsWithCache = windows
        for (index, window) in windows.enumerated() where !window.isMinimized {
            if let cachedThumbnail = cache.object(forKey: NSNumber(value: window.windowID)) {
                windowsWithCache[index].thumbnail = cachedThumbnail
            }
        }

        // Return immediately with cached thumbnails (if any)
        completion(windowsWithCache)

        // Then capture fresh thumbnails in background for cache misses
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureWithScreenCaptureKit(windows: windowsWithCache, completion: completion)
        }
    }

    // MARK: - Thumbnail Capture via ScreenCaptureKit

    private func captureWithScreenCaptureKit(
        windows: [WindowInfo],
        completion: @escaping ([WindowInfo]) -> Void
    ) {
        NSLog("WindowCapture: captureWithScreenCaptureKit starting...")
        Task {
            var updatedWindows = windows

            do {
                NSLog("WindowCapture: Requesting SCShareableContent...")
                let content = try await SCShareableContent.current
                NSLog("WindowCapture: Got \(content.windows.count) shareable windows")
                let scWindowMap = Dictionary(uniqueKeysWithValues:
                    content.windows.map { ($0.windowID, $0) }
                )

                // Capture fresh thumbnails only for windows not already in cache
                for (index, window) in windows.enumerated() where !window.isMinimized {
                    // Skip if already have cached thumbnail
                    if cache.object(forKey: NSNumber(value: window.windowID)) != nil {
                        NSLog("WindowCapture: Window \(window.windowID) already cached, skipping")
                        continue
                    }

                    guard let scWindow = scWindowMap[window.windowID] else {
                        NSLog("WindowCapture: Window \(window.windowID) not found in shareable content")
                        continue
                    }

                    do {
                        NSLog("WindowCapture: Capturing window \(window.windowID)...")
                        let thumbnail = try await captureWindow(scWindow)
                        cache.setObject(thumbnail, forKey: NSNumber(value: window.windowID))
                        updatedWindows[index].thumbnail = thumbnail
                        NSLog("WindowCapture: Successfully captured window \(window.windowID)")
                    } catch {
                        NSLog("WindowCapture: Failed to capture window \(window.windowID): \(error.localizedDescription)")
                    }
                }
            } catch {
                NSLog("WindowCapture: ERROR - Failed to get shareable content: \(error.localizedDescription)")
            }

            NSLog("WindowCapture: Capture complete, calling completion handler")
            DispatchQueue.main.async {
                completion(updatedWindows)
            }
        }
    }

    private func captureWindow(_ scWindow: SCWindow) async throws -> NSImage {
        let filter = SCContentFilter(desktopIndependentWindow: scWindow)

        let config = SCStreamConfiguration()
        config.width = Int(thumbnailMaxWidth * 2)
        config.height = Int(thumbnailMaxHeight * 2)
        config.scalesToFit = true
        config.showsCursor = false

        let cgImage = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )

        return NSImage(
            cgImage: cgImage,
            size: NSSize(
                width: min(thumbnailMaxWidth, CGFloat(cgImage.width)),
                height: min(thumbnailMaxHeight, CGFloat(cgImage.height))
            )
        )
    }
}

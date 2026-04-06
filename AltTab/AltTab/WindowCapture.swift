//
//  WindowCapture.swift
//  AltTab — Windows-style Window Switcher for macOS
//
//  Modern window thumbnail capture using ScreenCaptureKit.
//  Requires macOS 13.2+ (Ventura). Falls back to app icons on capture failure.
//
//  Author:  Sergio Farfan <sergio.farfan@gmail.com>
//  Version: 1.1.0
//  Date:    2026-03-17
//  License: MIT
//

import Cocoa
import ScreenCaptureKit
import os.log

final class WindowCapture {

    private let thumbnailMaxWidth: CGFloat = 320
    private let thumbnailMaxHeight: CGFloat = 200
    private let cache = NSCache<NSNumber, NSImage>()
    private let logger = Logger(subsystem: "com.alttab.app", category: "WindowCapture")

    /// Captures thumbnails for all windows asynchronously.
    /// Calls completion on main thread with updated WindowInfo array.
    ///
    /// Uses ScreenCaptureKit (macOS 13.2+) for modern, reliable window capture.
    /// System will prompt for Screen Recording permission on first use.
    func captureThumbnails(for windows: [WindowInfo], completion: @escaping ([WindowInfo]) -> Void) {
        let captureEnabled = UserDefaults.standard.bool(forKey: "CaptureWindowScreenshots")

        if captureEnabled {
            // Capture on background thread to avoid blocking UI
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureWithScreenCaptureKit(windows: windows, completion: completion)
            }
        } else {
            // No capture - return immediately with app icons
            completion(windows)
        }
    }

    // MARK: - Thumbnail Capture via ScreenCaptureKit

    private func captureWithScreenCaptureKit(
        windows: [WindowInfo],
        completion: @escaping ([WindowInfo]) -> Void
    ) {
        Task {
            var updatedWindows = windows

            do {
                let content = try await SCShareableContent.current
                let scWindowMap = Dictionary(uniqueKeysWithValues:
                    content.windows.map { ($0.windowID, $0) }
                )

                for (index, window) in windows.enumerated() where !window.isMinimized {
                    guard let scWindow = scWindowMap[window.windowID] else { continue }

                    do {
                        let thumbnail = try await captureWindow(scWindow)
                        cache.setObject(thumbnail, forKey: NSNumber(value: window.windowID))
                        updatedWindows[index].thumbnail = thumbnail
                    } catch {
                        logger.warning("Failed to capture window \(window.windowID): \(error.localizedDescription)")
                    }
                }
            } catch {
                logger.error("Failed to get shareable content: \(error.localizedDescription)")
            }

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

import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// Commands that add a top-level "Utilities" menu with common developer utilities.
struct UtilitiesCommands: Commands {
    var body: some Commands {
        CommandMenu("Utilities") {
            Button("Process Images") {
                processImages()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])

            Button("Generate Templates") {
                generateTemplates()
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
        }
    }

    private func processImages() {
        let queue = OperationQueue()
        queue.name = "com.usac.image-writer"
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 6

        let fm = FileManager.default
        let directory = URL.documentsDirectory.appending(component: "Headshots")

        do {
            let items = try fm.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            )

            for item in items {
                if let imageSource = CGImageSourceCreateWithURL(
                    item as CFURL,
                    nil
                ) {
                    let imageProperties = CGImageSourceCopyPropertiesAtIndex(
                        imageSource,
                        0,
                        nil
                    )
                    if let dict = imageProperties as? [String: Any],
                        let tiffData = dict["{TIFF}"] as? [String: Any],
                        let copyright = tiffData["Copyright"] as? String
                    {
                        queue.addOperation {
                            self.writeData(
                                imageSource: imageSource,
                                bibNumber: copyright
                            )
                        }
                        if copyright.count != 4 {
                            print(item)

                        }
                    }
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print("error")
            print(error.localizedDescription)
        }
    }

    private func writeData(
        imageSource: CGImageSource,
        bibNumber: String,
        mapped: [String: String] = [:]
    ) {
        guard let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            print("unable to load image")
            return
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)

        let destinationURL: URL
        if mapped.isEmpty {
            destinationURL = URL.documentsDirectory.appending(
                component: "written/\(bibNumber).jpg"
            )
        } else {
            if let translatedBibNumber = mapped[bibNumber] {
                destinationURL = URL.documentsDirectory.appending(
                    component: "written/\(translatedBibNumber).jpg"
                )
            } else {
                return
            }
        }

        let thumbnailSize = Double(max(image.width, image.height)) * 0.15
        let options =
            [
                kCGImageSourceThumbnailMaxPixelSize: thumbnailSize,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
            ] as CFDictionary

        guard
            let destination = CGImageDestinationCreateWithURL(
                destinationURL as CFURL,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else {
            print("Unable to make destination")
            return
        }
        if let thumbnail = CGImageSourceCreateThumbnailAtIndex(
            imageSource,
            0,
            options
        ) {
            CGImageDestinationAddImage(destination, thumbnail, nil)
        } else {
            CGImageDestinationAddImage(destination, image, properties)
        }

        CGImageDestinationFinalize(destination)
    }

    private func generateTemplates() {
        let documentDirectory = URL.documentsDirectory
        let sourcePath = documentDirectory.appending(path: "Template.json")
        guard
            let rawTemplate = try? String(
                contentsOf: sourcePath,
                encoding: .utf8
            )
        else {
            debugPrint("Could not load template data")
            return
        }

        for category in ["13", "15", "17", "19", "20"] {
            for routeNumber in ["12", "34"] {
                var currentTemplate = rawTemplate
                let templateName = "\(category)-\(routeNumber)"
                currentTemplate = currentTemplate.replacingOccurrences(
                    of: "Template",
                    with: templateName
                )
                if routeNumber == "12" {
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "F131.",
                        with: "F\(category)1."
                    )
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "F132.",
                        with: "F\(category)2."
                    )
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "M131.",
                        with: "M\(category)1."
                    )
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "M132.",
                        with: "M\(category)2."
                    )

                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "U13F #1",
                        with: "U\(category)F #1"
                    )
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "U13F #2",
                        with: "U\(category)F #2"
                    )
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "U13M #1",
                        with: "U\(category)M #1"
                    )
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "U13M #2",
                        with: "U\(category)M #2"
                    )
                } else {
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "F131.",
                        with: "F\(category)3."
                    )
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "F132.",
                        with: "F\(category)4."
                    )
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "M131.",
                        with: "M\(category)3."
                    )
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "M132.",
                        with: "M\(category)4."
                    )

                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "U13F #1",
                        with: "U\(category)F #3"
                    )
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "U13F #2",
                        with: "U\(category)F #4"
                    )
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "U13M #1",
                        with: "U\(category)M #3"
                    )
                    currentTemplate = currentTemplate.replacingOccurrences(
                        of: "U13M #2",
                        with: "U\(category)M #4"
                    )
                }
                let resultPath = documentDirectory.appending(
                    path: "\(templateName).json"
                )
                do {
                    try currentTemplate.write(
                        to: resultPath,
                        atomically: true,
                        encoding: .utf8
                    )
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    private func generateRopeTemplates() {
        let documentDirectory = URL.documentsDirectory
        let sourcePath = documentDirectory.appending(path: "Template.json")
        guard
            let rawTemplate = try? String(
                contentsOf: sourcePath,
                encoding: .utf8
            )
        else {
            debugPrint("Could not load template data")
            return
        }

        for category in ["15", "17"] {
            for routeNumber in ["1"] {
                var currentTemplate = rawTemplate
                let templateName = "\(category)-\(routeNumber)"
                currentTemplate = currentTemplate.replacingOccurrences(
                    of: "Template",
                    with: templateName
                )
                currentTemplate = currentTemplate.replacingOccurrences(
                    of: "M131.",
                    with: "M\(category)\(routeNumber)."
                )
                currentTemplate = currentTemplate.replacingOccurrences(
                    of: "U13M #1",
                    with: "U\(category)M"
                )
                currentTemplate = currentTemplate.replacingOccurrences(
                    of: "F131.",
                    with: "F\(category)\(routeNumber)."
                )
                currentTemplate = currentTemplate.replacingOccurrences(
                    of: "U13F #1",
                    with: "U\(category)F"
                )
                let resultPath = documentDirectory.appending(
                    path: "\(templateName).json"
                )
                do {
                    try currentTemplate.write(
                        to: resultPath,
                        atomically: true,
                        encoding: .utf8
                    )
                } catch {
                    print(error.localizedDescription)
                }
            }
        }

        for category in ["F", "M"] {
            for routeNumber in ["1"] {
                var currentTemplate = rawTemplate
                let templateName = "\(category)1920-\(routeNumber)"
                currentTemplate = currentTemplate.replacingOccurrences(
                    of: "Template",
                    with: templateName
                )
                currentTemplate = currentTemplate.replacingOccurrences(
                    of: "M131.",
                    with: "\(category)19\(routeNumber)."
                )
                currentTemplate = currentTemplate.replacingOccurrences(
                    of: "U13M #1",
                    with: "U19\(category)"
                )
                currentTemplate = currentTemplate.replacingOccurrences(
                    of: "F131.",
                    with: "\(category)20\(routeNumber)."
                )
                currentTemplate = currentTemplate.replacingOccurrences(
                    of: "U13F #1",
                    with: "U20\(category)"
                )
                let resultPath = documentDirectory.appending(
                    path: "\(templateName).json"
                )
                do {
                    try currentTemplate.write(
                        to: resultPath,
                        atomically: true,
                        encoding: .utf8
                    )
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}


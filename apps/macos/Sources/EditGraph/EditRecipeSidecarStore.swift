import Foundation

struct EditRecipeSidecarStore: @unchecked Sendable {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func sidecarURL(for sourceURL: URL) -> URL {
        sourceURL.appendingPathExtension("xmp")
    }

    func loadRecipe(for sourceURL: URL) throws -> EditRecipe? {
        let url = sidecarURL(for: sourceURL)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try DarkRoomXMPRecipeCoder.decodeRecipe(from: data, sidecarURL: url)
    }

    func save(_ recipe: EditRecipe, for sourceURL: URL) throws {
        let sidecarURL = sidecarURL(for: sourceURL)

        if recipe.isNeutral {
            try removeRecipe(for: sourceURL)
            return
        }

        let xml = DarkRoomXMPRecipeCoder.encodeRecipe(
            recipe,
            sourceURL: sourceURL
        )
        try xml.write(to: sidecarURL, atomically: true, encoding: .utf8)
    }

    func removeRecipe(for sourceURL: URL) throws {
        let sidecarURL = sidecarURL(for: sourceURL)
        guard fileManager.fileExists(atPath: sidecarURL.path) else {
            return
        }

        try fileManager.removeItem(at: sidecarURL)
    }
}

enum EditRecipeSidecarError: LocalizedError {
    case invalidXMP(String)

    var errorDescription: String? {
        switch self {
        case .invalidXMP(let filename):
            "Could not read DarkRoom edit recipe from \(filename)."
        }
    }
}

private enum DarkRoomXMPRecipeCoder {
    private static let namespace = "https://darkroom.dev/ns/edit/1.0/"

    static func encodeRecipe(_ recipe: EditRecipe, sourceURL: URL) -> String {
        let light = recipe.light
        let now = ISO8601DateFormatter().string(from: Date())

        return """
        <?xpacket begin="" id="W5M0MpCehiHzreSzNTczkc9d"?>
        <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="DarkRoom">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
                xmlns:xmp="http://ns.adobe.com/xap/1.0/"
                xmlns:dr="\(namespace)"
                xmp:CreatorTool="DarkRoom"
                xmp:MetadataDate="\(escapeAttribute(now))"
                dr:RecipeVersion="1"
                dr:SourceFileName="\(escapeAttribute(sourceURL.lastPathComponent))"
                dr:ExposureEV="\(format(light.exposureEV))"
                dr:Contrast="\(format(light.contrast))"
                dr:Highlights="\(format(light.highlights))"
                dr:Shadows="\(format(light.shadows))" />
          </rdf:RDF>
        </x:xmpmeta>
        <?xpacket end="w"?>
        """
    }

    static func decodeRecipe(from data: Data, sidecarURL: URL) throws -> EditRecipe? {
        let parserDelegate = DarkRoomXMPRecipeParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = parserDelegate

        guard parser.parse() else {
            throw EditRecipeSidecarError.invalidXMP(sidecarURL.lastPathComponent)
        }

        guard let attributes = parserDelegate.darkRoomAttributes else {
            return nil
        }

        guard value(named: "RecipeVersion", in: attributes) == "1" else {
            throw EditRecipeSidecarError.invalidXMP(sidecarURL.lastPathComponent)
        }

        var recipe = EditRecipe.neutral
        recipe.light.exposureEV = try doubleValue(named: "ExposureEV", in: attributes, sidecarURL: sidecarURL)
        recipe.light.contrast = try doubleValue(named: "Contrast", in: attributes, sidecarURL: sidecarURL)
        recipe.light.highlights = try doubleValue(named: "Highlights", in: attributes, sidecarURL: sidecarURL)
        recipe.light.shadows = try doubleValue(named: "Shadows", in: attributes, sidecarURL: sidecarURL)

        return recipe
    }

    private static func doubleValue(
        named name: String,
        in attributes: [String: String],
        sidecarURL: URL
    ) throws -> Double {
        guard let rawValue = value(named: name, in: attributes),
              let value = Double(rawValue) else {
            throw EditRecipeSidecarError.invalidXMP(sidecarURL.lastPathComponent)
        }

        return value
    }

    private static func value(named name: String, in attributes: [String: String]) -> String? {
        attributes["dr:\(name)"] ?? attributes[name]
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), value)
    }

    private static func escapeAttribute(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

private final class DarkRoomXMPRecipeParserDelegate: NSObject, XMLParserDelegate {
    private(set) var darkRoomAttributes: [String: String]?

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String]
    ) {
        guard darkRoomAttributes == nil else {
            return
        }

        let hasDarkRoomRecipe = attributeDict["dr:RecipeVersion"] != nil
            || attributeDict["RecipeVersion"] != nil

        if hasDarkRoomRecipe {
            darkRoomAttributes = attributeDict
        }
    }
}

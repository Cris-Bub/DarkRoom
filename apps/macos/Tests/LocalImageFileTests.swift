import XCTest
@testable import DarkRoom

final class LocalImageFileTests: XCTestCase {
    func testSupportedImageExtensionsAreCaseInsensitive() {
        XCTAssertTrue(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/example.JPG")))
        XCTAssertTrue(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/example.jpe")))
        XCTAssertTrue(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/example.jfif")))
        XCTAssertTrue(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/example.heic")))
        XCTAssertTrue(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/example.tiff")))
    }

    func testCommonRawExtensionsAreSupported() {
        XCTAssertTrue(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/sony.ARW")))
        XCTAssertTrue(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/canon.CR2")))
        XCTAssertTrue(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/canon.CR3")))
        XCTAssertTrue(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/iphone-pro-raw.DNG")))
        XCTAssertTrue(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/nikon.NEF")))
        XCTAssertTrue(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/fuji.RAF")))
    }

    func testRawDetectionIsCaseInsensitiveAndSpecific() {
        XCTAssertTrue(LocalImageFile.isRaw(url: URL(fileURLWithPath: "/tmp/sony.ARW")))
        XCTAssertTrue(LocalImageFile.isRaw(url: URL(fileURLWithPath: "/tmp/iphone-pro-raw.DNG")))
        XCTAssertFalse(LocalImageFile.isRaw(url: URL(fileURLWithPath: "/tmp/export.JPG")))
    }

    func testUnsupportedImageExtensionsAreRejected() {
        XCTAssertFalse(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/example.mov")))
        XCTAssertFalse(LocalImageFile.isSupported(url: URL(fileURLWithPath: "/tmp/example.txt")))
    }

    func testOpenPanelHasImageContentTypes() {
        XCTAssertFalse(LocalImageFile.supportedContentTypes.isEmpty)
    }
}

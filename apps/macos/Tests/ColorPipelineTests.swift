import CoreGraphics
import XCTest
@testable import DarkRoom

final class ColorPipelineTests: XCTestCase {
    func testPreviewTargetsExposeExpectedOutputProfiles() {
        XCTAssertEqual(PreviewTarget.webInstagram.label, "Web / Instagram")
        XCTAssertEqual(PreviewTarget.webInstagram.profileName, "sRGB")
        XCTAssertEqual(PreviewTarget.appleDisplayP3.label, "Apple Display P3")
        XCTAssertEqual(PreviewTarget.appleDisplayP3.profileName, "Display P3")
    }

    func testWorkingColorSpaceIsLinearROMMRGB() {
        let colorSpace = WorkingColorSpace.linearROMMRGB

        XCTAssertEqual(WorkingColorSpace.displayName, "Linear ROMM RGB")
        XCTAssertTrue(CGColorSpaceUsesExtendedRange(colorSpace))
    }
}

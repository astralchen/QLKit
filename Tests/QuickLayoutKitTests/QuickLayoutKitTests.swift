import Testing
import QuickLayout
@testable import QuickLayoutKitCore

@Suite
struct QuickLayoutKitTests {

    @Test func maximumInsetsUseLargestDirectionalValue() {
        let insets = QuickLayout.EdgeInsets(top: 4, leading: 12, bottom: 18, trailing: 8)

        #expect(insets.maximumHorizontalInset == 12)
        #expect(insets.maximumVerticalInset == 18)
    }
}

//
//  DemoTests.swift
//  DemoTests
//
//  Created by Sondra on 2025/12/26.
//

import CoreGraphics
import Testing
import UIKit
import QuickLayout
import QuickLayoutKit

@MainActor
struct DemoTests {

    @Test func quickLayoutViewMeasuresHostedContent() {
        let label = UILabel()
        label.text = "QuickLayoutKit"
        label.font = .systemFont(ofSize: 17)

        let hostingView = QuickLayoutView {
            label
                .padding(.all, 12)
        }

        let measuredSize = hostingView.sizeThatFits(in: CGSize(width: 240, height: CGFloat.greatestFiniteMagnitude))

        #expect(measuredSize.width > 0)
        #expect(measuredSize.height > 17)
    }

    @Test func hostingControllerUsesReusableQuickLayoutView() {
        let label = UILabel()
        label.text = "Hosted"

        let viewController = QuickLayoutHostingController {
            label
                .padding(.all, 8)
        }

        viewController.loadViewIfNeeded()

        #expect(viewController.view is QuickLayoutView)
        #expect(viewController.sizeThatFits(in: CGSize(width: 200, height: CGFloat.greatestFiniteMagnitude)).height > 0)
    }

    @Test func scrollViewUpdatesContentAndScrollsToEdges() {
        let first = UIView()
        let second = UIView()
        let scrollView = QuickLayoutScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        scrollView.updateContent(axis: .vertical) {
            first.frame(height: 120)
            second.frame(height: 120)
        }
        scrollView.layoutIfNeeded()
        scrollView.scrollTo(.bottom, animated: false)

        #expect(scrollView.contentSize.height >= 240)
        #expect(scrollView.contentOffset.y > 0)
    }

    @Test func keyboardContextParsesUIKitNotification() throws {
        let frame = CGRect(x: 0, y: 320, width: 390, height: 240)
        let notification = Notification(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: frame,
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.25,
                UIResponder.keyboardAnimationCurveUserInfoKey: UInt(UIView.AnimationCurve.easeInOut.rawValue),
            ]
        )

        let context = try #require(QuickLayoutKeyboardContext(notification: notification))

        #expect(context.endFrame == frame)
        #expect(context.height == 240)
        #expect(context.animationDuration == 0.25)
        #expect(context.isVisible)
    }

    @Test func keyboardAvoiderPreservesBaseScrollInsets() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        scrollView.contentInset = UIEdgeInsets(top: 1, left: 2, bottom: 10, right: 4)
        scrollView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 5, left: 6, bottom: 7, right: 8)
        scrollView.horizontalScrollIndicatorInsets = UIEdgeInsets(top: 9, left: 10, bottom: 11, right: 12)

        let avoider = QuickLayoutKeyboardAvoider(
            scrollView: scrollView,
            observer: QuickLayoutKeyboardObserver(notificationCenter: NotificationCenter())
        )

        let visibleContext = QuickLayoutKeyboardContext(
            endFrame: CGRect(x: 0, y: 300, width: 320, height: 120),
            animationDuration: 0,
            animationOptions: [],
            isVisible: true
        )

        avoider.apply(visibleContext)

        #expect(scrollView.contentInset.bottom == 130)
        #expect(scrollView.verticalScrollIndicatorInsets.bottom == 127)
        #expect(scrollView.horizontalScrollIndicatorInsets.bottom == 131)

        avoider.apply(.hidden)

        #expect(scrollView.contentInset.bottom == 10)
        #expect(scrollView.verticalScrollIndicatorInsets.bottom == 7)
        #expect(scrollView.horizontalScrollIndicatorInsets.bottom == 11)
    }

    @Test func listCellMeasuresQuickLayoutContent() {
        let titleLabel = UILabel()
        titleLabel.text = "Title"
        let messageLabel = UILabel()
        messageLabel.text = "A long message that should wrap inside the proposed collection cell width."
        messageLabel.numberOfLines = 0

        let cell = QuickLayoutCollectionViewCell {
            VStack(alignment: .leading, spacing: 4) {
                titleLabel
                messageLabel
            }
            .padding(.all, 12)
        }

        cell.quickLayoutHorizontalFlexibility = .fixedSize
        cell.quickLayoutVerticalFlexibility = .fullyFlexible

        let size = cell.sizeThatFits(CGSize(width: 180, height: 44))

        #expect(size.width == 180)
        #expect(size.height > 44)
    }

    @Test func directionalEnvironmentHelpersRespectLayoutDirection() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
        view.semanticContentAttribute = .forceRightToLeft

        let margins = view.quickLayoutDirectionalLayoutMargins

        #expect(margins.top == 1)
        #expect(margins.leading == 2)
        #expect(margins.bottom == 3)
        #expect(margins.trailing == 4)
    }

    @Test func diagnosticsRecordsLayoutPasses() {
        QuickLayoutDiagnostics.reset()
        QuickLayoutDiagnostics.isEnabled = true
        QuickLayoutDiagnostics.recordLayoutPass(for: "TestView", measuredSize: CGSize(width: 10, height: 20))

        let snapshot = QuickLayoutDiagnostics.snapshot()

        #expect(snapshot.totalLayoutPasses == 1)
        #expect(snapshot.entries.first?.viewName == "TestView")

        QuickLayoutDiagnostics.isEnabled = false
        QuickLayoutDiagnostics.reset()
    }
}

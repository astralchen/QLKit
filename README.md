# QuickLayoutKit

QuickLayoutKit is a UIKit support package for
[QuickLayout](https://github.com/facebookincubator/QuickLayout). It provides a
small set of UIKit-focused building blocks so view controllers, scroll views,
safe-area spacing, and self-sizing cells can be written with QuickLayout's
declarative layout syntax.

The package exports three modules:

- `QuickLayoutKit` re-exports the public core and UIKit helpers.
- `QuickLayoutKitCore` contains shared QuickLayout extensions.
- `QuickLayoutKitUIKit` contains UIKit integration types.

## Requirements

- iOS 15.0 or later
- Swift 6.2 or later
- QuickLayout from `facebookincubator/QuickLayout`

## Installation

Add this repository to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/astralchen/QLKit.git", branch: "main")
]
```

Then add the `QuickLayoutKit` product to your app target:

```swift
.target(
    name: "App",
    dependencies: [
        "QuickLayoutKit"
    ]
)
```

Import both QuickLayout and QuickLayoutKit where you declare layouts:

```swift
import QuickLayout
import QuickLayoutKit
```

## Core APIs

### `QuickLayoutHostingController`

`QuickLayoutHostingController` is a `UIViewController` subclass whose root view
is driven by a QuickLayout `body`.

Use subclassing when the screen owns state, targets, delegates, or lifecycle
work:

```swift
import UIKit
import QuickLayout
import QuickLayoutKit

final class CounterViewController: QuickLayoutHostingController {

    private var count = 0 {
        didSet {
            counterLabel.text = "\(count)"
            setNeedsLayoutUpdate()
        }
    }

    private let counterLabel = UILabel()
    private let incrementButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        counterLabel.font = .systemFont(ofSize: 48, weight: .bold)
        counterLabel.textAlignment = .center
        counterLabel.text = "\(count)"

        incrementButton.setTitle("Increment", for: .normal)
        incrementButton.addTarget(self, action: #selector(increment), for: .touchUpInside)
    }

    override var body: Layout {
        VStack(alignment: .center, spacing: 24) {
            Spacer()
            counterLabel
            incrementButton
            Spacer()
        }
        .padding(.all, 24)
    }

    @objc private func increment() {
        count += 1
    }
}
```

Use the closure initializer for small hosted layouts:

```swift
let titleLabel = UILabel()
titleLabel.text = "Quick Setup"

let viewController = QuickLayoutHostingController {
    VStack(spacing: 12) {
        titleLabel
    }
    .padding(.all, 24)
}
```

Call `setNeedsLayoutUpdate()` after mutating state that changes `body`.

### `QuickLayoutScrollView`

`QuickLayoutScrollView` is a `UIScrollView` that measures QuickLayout content
and keeps its `contentSize` in sync during layout.

```swift
final class DynamicScrollViewController: QuickLayoutHostingController {

    private let scrollView = QuickLayoutScrollView()
    private var rows: [UIView] = []

    override var body: Layout {
        ScrollView(scrollView, axis: .vertical) {
            VStack(spacing: 12) {
                ForEach(rows) { row in
                    row.frame(height: 80)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, view.quickLayoutSafeAreaInsets.bottom)
        }
    }
}
```

The scroll view also supports direct construction:

```swift
let scrollView = QuickLayoutScrollView.vertical {
    headerView
    contentView
    footerView
}
```

For horizontal content, pass `axis: .horizontal` to `ScrollView` or use
`QuickLayoutScrollView.horizontal`.

### Safe-area helpers

`UIView.quickLayoutSafeAreaInsets` converts UIKit safe-area insets to
`QuickLayout.EdgeInsets` and respects the view's effective layout direction.
The core module also exposes convenience values for symmetric safe-area
padding:

```swift
override var body: Layout {
    contentView
        .padding(.horizontal, view.quickLayoutSafeAreaInsets.maximumHorizontalInset)
        .padding(.bottom, view.quickLayoutSafeAreaInsets.maximumVerticalInset)
}
```

Read safe-area values after the view has been laid out. In a hosting
controller body, they are commonly used as part of the layout pass.

### Collection view sizing helpers

`UICollectionViewCell.quickLayoutFlexibility(for:)` and
`quickLayoutSizeLimit(proposed:)` help self-sizing cells describe which axes are
fixed by the collection view layout and which axes should be measured by
QuickLayout.

```swift
@QuickLayout
final class MessageCell: UICollectionViewCell {

    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    var body: Layout {
        VStack(alignment: .leading, spacing: 4) {
            titleLabel
            messageLabel
        }
        .padding(.all, 12)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let proposedSize = quickLayoutSizeLimit(proposed: size)
        return _QuickLayoutViewImplementation.sizeThatFits(self, size: proposedSize) ?? size
    }

    override func quickLayoutFlexibility(for axis: Axis) -> Flexibility {
        switch axis {
        case .horizontal:
            return .fixedSize
        case .vertical:
            return .fullyFlexible
        }
    }
}
```

## Demo App

The `Demo` project contains examples for:

- Basic hosted screens
- Counters and state-driven relayout
- Vertical and horizontal scrolling
- Safe-area padding
- Dynamic content insertion
- Keyboard-aware scrolling
- Self-sizing collection view cells
- UIKit semantic content direction behavior

Open `Demo/Demo.xcodeproj` in Xcode and run the `Demo` scheme to explore the
examples.

## Testing

QuickLayoutKit is a UIKit package, so validate it with an iOS Simulator
destination from Xcode or `xcodebuild`:

```sh
xcodebuild -project Demo/Demo.xcodeproj -scheme Demo -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Run the demo app from Xcode when validating UIKit layout behavior visually.

## License

QuickLayoutKit is available under the MIT license. See `LICENSE` for details.

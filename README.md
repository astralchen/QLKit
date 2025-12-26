# QLKit

**QLKit** brings the declarative power and developer experience of SwiftUI to UIKit. Built on top of [QuickLayout](https://github.com/facebookincubator/QuickLayout), it allows you to build complex UI layouts using a syntax you already love, while keeping the full power and flexibility of UIKit components.

## Features

- 🏗 **Declarative Syntax**: Write UIKit layouts using `VStack`, `HStack`, `ZStack` and more, just like SwiftUI.
- 🔌 **Seamless UIKit Integration**: Use standard `UIView`, `UILabel`, `UIButton` directly in your declarative stacks.
- 📜 **Easy Scrolling**: `QLScrollView` makes creating scrollable content trivial.
- 🚀 **Hosting Controllers**: `QLHostingController` and `QLComposableHostingController` bridge the gap between declarative layouts and view controller lifecycles.
- 🧩 **Component-Oriented**: Encourage breaking down UI into smaller, reusable components.

## Requirements

- iOS 15.0+
- Swift 5.5+

## Installation

### Swift Package Manager

Add `QLKit` to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/QLKit.git", branch: "main")
]
```

## Usage

### 1. Basic Hosting Controller

Subclass `QLHostingController` to define your UI declaratively.

```swift
import UIKit
import QLKit
import QuickLayout

class MyViewController: QLHostingController {

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "Hello QLKit"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        
        subtitleLabel.text = "SwiftUI-like syntax for UIKit"
        subtitleLabel.textColor = .gray
    }

    // Define layout declaratively
    override var body: Layout {
        VStack(alignment: .center, spacing: 10) {
            titleLabel
            subtitleLabel
        }
        .padding(.all, 20)
    }
}
```

### 2. Composable Hosting Controller

For simple screens, avoid subclassing by using `QLComposableHostingController`.

```swift
let titleLabel = UILabel()
titleLabel.text = "Quick Setup"

let vc = QLComposableHostingController {
    VStack {
        titleLabel
    }
    .center()
}
.withTitle("Home")
.withBackgroundColor(.white)
```

### 3. Scroll Views

`QLScrollView` automatically manages content size and layout for you.

```swift
let scrollView = QLScrollView()
scrollView.axis = .vertical

// Add content declaratively
scrollView.children = [
    headerView,
    contentLabel,
    footerView
]
```

### 4. Complex Layout Example

Combine horizontal and vertical stacks to create complex dashboards.

```swift
override var body: Layout {
    VStack(spacing: 24) {
        // Header
        HStack(spacing: 12) {
            imageView
                .resizable()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                nameLabel
                statusLabel
            }
            Spacer()
        }
        .padding(.all, 16)
        .background {
             // Return a UIView for background
             let bg = UIView()
             bg.backgroundColor = .secondarySystemBackground
             bg.layer.cornerRadius = 12
             return bg
        }

        // Content
        Spacer()
    }
}
```

## License

QLKit is released under the MIT License. See [LICENSE](LICENSE) for details.

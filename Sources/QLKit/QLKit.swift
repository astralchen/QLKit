// The Swift Programming Language
// https://docs.swift.org/swift-book
import UIKit
import QuickLayout

extension UIView {

    /// Converts the view’s `safeAreaInsets` to `QuickLayout.EdgeInsets`.
    ///
    /// - Important:
    ///   Respects the view’s `effectiveUserInterfaceLayoutDirection`.
    ///
    /// - Note:
    ///   Access this value after layout (e.g. `viewDidLayoutSubviews`).
    public var safeAreaEdgeInsets: QuickLayout.EdgeInsets {
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft

        return .init(
            top: safeAreaInsets.top,
            leading: isRTL ? safeAreaInsets.right : safeAreaInsets.left,
            bottom: safeAreaInsets.bottom,
            trailing: isRTL ? safeAreaInsets.left : safeAreaInsets.right
        )
    }
}

extension QuickLayout.EdgeInsets {

    public var horizontal: CGFloat {
        max(leading, trailing)
    }

    public var vertical: CGFloat {
        max(top, bottom)
    }
}

/// Maps a list of `UIView` instances into a QuickLayout `FastExpression`.
///
/// This helper mirrors the common `ForEach` pattern by transforming each item into an `Element`
/// and grouping the results into a single expression that can be used inside layout builders
/// like `VStack`/`HStack`.
///
/// - Parameters:
///   - list: The source views to iterate over.
///   - map: A closure that converts each view into an `Element` (optionally applying modifiers).
/// - Returns: A `FastExpression` that contains the mapped elements in order.
public func ForEach<T>(_ list: [T], map: (T) -> Element) -> FastExpression where T: UIView {
    BlockExpression(expressions: list.map { ValueExpression<Element>(value: map($0)) })
}


extension UICollectionViewCell {

    /**
     返回 UICollectionViewCell 在指定轴向上的默认伸缩能力（Flexibility）。

     该方法用于布局系统在计算 cell 尺寸时，判断当前轴向：
     - 是否允许被拉伸或压缩
     - 是否由内容主导最终尺寸

     ### 默认规则
     - horizontal（宽度）：
       - `.fixedSize`
       - 宽度通常由 `UICollectionViewLayout`（列数 / itemSize）决定
     - vertical（高度）：
       - `.fullyFlexible`
       - 高度由内容决定，用于自适应高度的 cell

     - Parameter axis: 布局轴向（horizontal / vertical）
     - Returns: 当前轴向对应的 `Flexibility`
     */

    @objc open func flexibility(for axis: Axis) -> Flexibility {
        .fullyFlexible
    }

    /**
     根据 Flexibility 计算布局系统在某一方向上允许使用的尺寸上限。

     该方法不会直接决定最终尺寸，而是为 `layoutThatFits` / sizing 计算
     提供一个 **“可用尺寸约束（layout limit）”**。

     ### 不同 Flexibility 的行为说明

     - `.fixedSize`
       - 尺寸被完全固定
       - 布局计算必须使用 `proposed` 值

     - `.partial`
       - 尺寸存在上限
       - 允许在 `[minimum, proposed]` 区间内伸缩
       - 通常用于内容驱动、但不能无限拉伸的视图

     - `.fullyFlexible`
       - 不设置尺寸上限
       - 最终尺寸完全由内容或子布局决定
       - 返回 `.infinity` 表示“无限可用空间”

     ### 使用场景
     - UICollectionView 自适应高度 cell
     - QuickLayout / 自定义 layoutThatFits
     - 动态内容尺寸计算

     - Parameters:
       - proposed: 布局系统提供的建议尺寸（通常来自父布局）
       - minimum: `.partial` 情况下允许的最小尺寸，默认值为 `0`
       - flexibility: 当前轴向的伸缩能力
     - Returns: 布局计算阶段可使用的尺寸上限
     */
    public func layoutLimit(
        proposed: CGFloat,
        minimum: CGFloat = 0,
        flexibility: Flexibility
    ) -> CGFloat {

        switch flexibility {
        case .fixedSize:
            return proposed

        case .partial:
            return max(minimum, proposed)

        case .fullyFlexible:
            return .infinity
        }
    }
}

extension UICollectionViewCell {

    /// 根据 Cell 在不同轴向上的 `Flexibility`，
    /// 对外部传入的 proposed `CGSize` 进行约束，生成最终用于布局计算的尺寸。
    ///
    /// 该方法是对「宽高分别应用伸缩规则」的统一封装，避免在布局代码中
    /// 硬编码 `.fixedSize / .fullyFlexible` 等策略。
    ///
    /// - Design:
    ///   - 水平方向的伸缩能力由 `flexibility(for: .horizontal)` 决定
    ///   - 垂直方向的伸缩能力由 `flexibility(for: .vertical)` 决定
    ///   - 不同 Cell 子类可以通过 override `flexibility(for:)`
    ///     来声明自己的布局能力，而无需修改布局逻辑
    ///
    /// - Typical usage:
    ///   ```swift
    ///   let proposedSize = Self.layoutLimit(proposed: size)
    ///   ```
    ///
    /// - Parameter size:
    ///   外部布局系统（如 CollectionView / QuickLayout）
    ///   提供的建议尺寸（proposed size）
    ///
    /// - Returns:
    ///   一个已根据 Cell 伸缩能力处理后的 `CGSize`，
    ///   用于后续 `sizeThatFits` / `layoutThatFits` 等计算
    public func layoutLimit(
        proposed size: CGSize
    ) -> CGSize {
        CGSize(
            width: layoutLimit(
                proposed: size.width,
                flexibility: flexibility(for: .horizontal)
            ),
            height: layoutLimit(
                proposed: size.height,
                flexibility: flexibility(for: .vertical)
            )
        )
    }
}

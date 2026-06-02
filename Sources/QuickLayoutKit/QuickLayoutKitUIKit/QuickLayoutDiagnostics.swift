import CoreGraphics

/// Debug diagnostics for QuickLayoutKit layout work.
@MainActor
public enum QuickLayoutDiagnostics {

    /// One recorded layout pass.
    public struct Entry: Equatable, Sendable {
        /// The type or caller name associated with the layout pass.
        public let viewName: String

        /// The measured size reported by the caller.
        public let measuredSize: CGSize
    }

    /// A point-in-time diagnostics snapshot.
    public struct Snapshot: Equatable, Sendable {
        /// All recorded entries.
        public let entries: [Entry]

        /// The number of recorded layout passes.
        public var totalLayoutPasses: Int {
            entries.count
        }
    }

    /// A Boolean value indicating whether diagnostics are enabled.
    public static var isEnabled = false

    private static var entries: [Entry] = []

    /// Records a layout pass when diagnostics are enabled.
    ///
    /// - Parameters:
    ///   - viewName: The view or caller name.
    ///   - measuredSize: The size associated with the layout pass.
    public static func recordLayoutPass(for viewName: String, measuredSize: CGSize) {
        guard isEnabled else { return }
        entries.append(Entry(viewName: viewName, measuredSize: measuredSize))
    }

    /// Returns the current diagnostics snapshot.
    public static func snapshot() -> Snapshot {
        Snapshot(entries: entries)
    }

    /// Removes all recorded diagnostics entries.
    public static func reset() {
        entries.removeAll()
    }
}

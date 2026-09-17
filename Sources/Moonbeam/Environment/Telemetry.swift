import Foundation
import os

/// A lightweight wrapper for telemetry and non-fatal production logging.
public enum Telemetry {
    private static let loggerStorage = OSAllocatedUnfairLock(
        initialState: Logger(subsystem: "com.moonbeam", category: "Spectrum")
    )

    private static let (stream, continuation) = AsyncStream.makeStream(of: String.self)

    public static var logger: Logger {
        get { loggerStorage.withLock { $0 } }
        set { loggerStorage.withLock { $0 = newValue } }
    }

    /// A stream that emits non-fatal errors for consuming apps.
    public static var nonFatalErrors: AsyncStream<String> {
        stream
    }

    internal static func reportNonFatalError(_ message: String) {
        logger.error("Moonbeam configuration error: \(message, privacy: .public)")
        continuation.yield(message)
    }
}

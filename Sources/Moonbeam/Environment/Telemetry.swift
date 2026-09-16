import Foundation
import os
@preconcurrency import Combine

/// A lightweight wrapper for telemetry and non-fatal production logging.
public enum Telemetry {
    private static let loggerStorage = OSAllocatedUnfairLock(
        initialState: Logger(subsystem: "com.moonbeam", category: "Spectrum")
    )

    @MainActor
    private static let errorSubject = PassthroughSubject<String, Never>()

    public static var logger: Logger {
        get { loggerStorage.withLock { $0 } }
        set { loggerStorage.withLock { $0 = newValue } }
    }

    /// A publisher that emits non-fatal errors for consuming apps.
    @MainActor
    public static var nonFatalErrors: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    internal static func reportNonFatalError(_ message: String) {
        logger.error("Moonbeam configuration error: \(message, privacy: .public)")
        Task { @MainActor in
            errorSubject.send(message)
        }
    }
}

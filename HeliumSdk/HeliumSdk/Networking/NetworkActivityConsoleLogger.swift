// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// This logger prints console logs.
enum NetworkActivityConsoleLogger {
    
    private enum Source {
        case request
        case response
    }
    
    @Injected(\.jsonSerializer) private static var jsonSerializer

#if PRINT_NETWORK_ACTIVITY
    private static let isLoggingEnabled = true
#else
    private static let isLoggingEnabled = false
#endif
    
    /// A reusable instance for better performance.
    static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormatter.timeZone = .current
        return dateFormatter
    }()

    static func logURLRequest(_ urlRequest: URLRequest, logger: Logger) {
        guard isLoggingEnabled else { return }

        var log = """
+-------------------------------------------------------------------------------------+

HTTP Request
\n
"""
        log.appendLine(timestamp(for: .request))
        log.appendLine()
        log.appendLine("URL: \(urlRequest.url?.absoluteString ?? "nil")")
        log.appendLine("Method: \(urlRequest.httpMethod ?? "nil")")
        log.appendLine("Headers: \(urlRequest.allHTTPHeaderFields?.description ?? "nil")")
        if urlRequest.httpMethod == "POST", let data = urlRequest.httpBody {
            do {
                let prettyPrintedData = try jsonSerializer.reserialize(data, options: .prettyPrinted)
                let prettyPrintedJSON = String(data: prettyPrintedData, encoding: .utf8)
                log.appendLine("Body: \n\(prettyPrintedJSON ?? "nil")")
            } catch {
                log.appendLine("JSON error: \(error)")
            }
        }
        log.appendLine(".....................................................................................\n");
        logger.trace(log)
    }

    static func logURLResponse(_ urlResponse: URLResponse, data: Data?, logger: Logger) {
        guard isLoggingEnabled else { return }

        var log = """
+-------------------------------------------------------------------------------------+

HTTP Response
\n
"""
        log.appendLine(timestamp(for: .response))
        log.appendLine()
        log.appendLine("URL: \(urlResponse.url?.absoluteString ?? "nil")")
        if let httpURLResponse = urlResponse as? HTTPURLResponse {
            log.appendLine("Status code: \(httpURLResponse.statusCode)")
            log.appendLine("Status message: \(HTTPURLResponse.localizedString(forStatusCode: httpURLResponse.statusCode))")
            log.appendLine("Headers: \(httpURLResponse.allHeaderFields.description)")
        }

        if let data = data {
            do {
                let prettyPrintedData = try jsonSerializer.reserialize(data, options: .prettyPrinted)
                let prettyPrintedJSON = String(data: prettyPrintedData, encoding: .utf8)
                log.appendLine("Body: \n\(prettyPrintedJSON ?? "nil")")
            } catch {
                log.appendLine("JSON error: \(error)")
            }
        }

        log.appendLine(".....................................................................................\n");
        logger.trace(log)
    }

    private static func timestamp(for source: Source) -> String {
        let state: String
        switch source {
        case .request:
            state = "SENT"
        case .response:
            state = "RECEIVED"
        }

        return "\(state) at: \(dateFormatter.string(from: Date()))"
    }
}

private extension String {
    mutating func appendLine(_ line: String = "") {
        append("\(line)\n")
    }
}

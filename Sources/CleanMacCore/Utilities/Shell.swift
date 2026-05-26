import Foundation

public struct ShellResult: Equatable, Sendable {
    public var status: Int32
    public var output: String
    public var error: String

    public init(status: Int32, output: String, error: String = "") {
        self.status = status
        self.output = output
        self.error = error
    }
}

public protocol ShellRunning: Sendable {
    func run(_ executable: String, _ arguments: [String]) async throws -> ShellResult
}

public struct ProcessShellRunner: ShellRunning {
    public init() {}

    public func run(_ executable: String, _ arguments: [String]) async throws -> ShellResult {
        try await Task.detached(priority: .utility) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            try process.run()
            process.waitUntilExit()

            let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return ShellResult(status: process.terminationStatus, output: output.trimmingCharacters(in: .whitespacesAndNewlines), error: error)
        }.value
    }
}

public struct CommandSpec: Equatable, Sendable {
    public var executable: String
    public var arguments: [String]

    public init(_ executable: String, _ arguments: [String]) {
        self.executable = executable
        self.arguments = arguments
    }

    public var preview: String {
        ([executable] + arguments).joined(separator: " ")
    }
}

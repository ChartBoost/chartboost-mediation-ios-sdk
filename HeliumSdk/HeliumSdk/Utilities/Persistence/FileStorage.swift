// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Provides file read and write capabilities.
protocol FileStorage {
    
    // MARK: Predefined Helium directories
    
    /// URL for the directory where we store configuration-related files.
    var urlForHeliumConfigurationDirectory: URL { get throws }

    /// URL for file that stores the Chartboost ID (/Library/Chartboost/chartboost_identifier).
    var urlForChartboostIDFile: URL { get throws }
    
    // MARK: Files
    
    /// Indicates if a file exists at the specified URL.
    func fileExists(at url: URL) -> Bool
    /// Removes a file at the specified URL.
    func removeFile(at url: URL) throws
    
    /// Writes the data as a binary file to the specified URL.
    func write(_ data: Data, to url: URL) throws
    /// Read the data stored as a binary file at the specified URL.
    func readData(at url: URL) throws -> Data
    
    // MARK: Directories
    
    /// Indicates if a directory exists in the device file system at the specified URL.
    func directoryExists(at url: URL) -> Bool
    /// Creates a directory at the specified URL.
    func createDirectory(at url: URL) throws
    /// Removes a directory at the specified URL.
    func removeDirectory(at url: URL) throws
}

/// A `FileStorage` implementation that uses the file system to access and modify files.
struct FileSystemStorage: FileStorage {
    
    private let fileManager = FileManager.default

    var urlForHeliumConfigurationDirectory: URL {
        get throws {
            try url(forSystemDirectory: .cachesDirectory).appendingPathComponent("HeliumConfig")
        }
    }

    var urlForChartboostIDFile: URL {
        get throws {
            try url(forSystemDirectory: .libraryDirectory).appendingPathComponent("Chartboost/chartboost_identifier")
        }
    }
    
    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
    
    func removeFile(at url: URL) throws {
        if fileExists(at: url) {
            try fileManager.removeItem(at: url)
        }
    }
    
    func write(_ data: Data, to url: URL) throws {
        let directoryURL = url.deletingLastPathComponent()
        if !directoryExists(at: directoryURL) {
            try createDirectory(at: directoryURL)
        }
        try data.write(to: url, options: .atomic)
    }
    
    func readData(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }
    
    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            return isDirectory.boolValue
        } else {
            return false
        }
    }
    
    func createDirectory(at url: URL) throws {
        if !directoryExists(at: url) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    func removeDirectory(at url: URL) throws {
        if directoryExists(at: url) {
            try fileManager.removeItem(at: url)
        }
    }
    
    private func url(forSystemDirectory directory: FileManager.SearchPathDirectory) throws -> URL {
        try fileManager.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: false)
    }
}

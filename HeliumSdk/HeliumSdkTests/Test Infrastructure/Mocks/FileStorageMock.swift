// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class FileStorageMock: Mock<FileStorageMock.Method>, FileStorage {
    
    enum Method {
        case urlForHeliumConfigurationDirectory
        case urlForChartboostIDFile
        case fileExists
        case removeFile
        case write
        case readData
        case directoryExists
        case createDirectory
        case removeDirectory
    }
    
    override var defaultReturnValues: [Method: Any?] {
        [.urlForHeliumConfigurationDirectory: try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false),
         .urlForChartboostIDFile: try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Chartboost/chartboost_identifier"),
         .fileExists: true,
         .readData: "some content".data(using: .utf8)!,
         .directoryExists: true]
    }
    
    var urlForHeliumConfigurationDirectory: URL {
        get throws {
            try throwingRecord(.urlForHeliumConfigurationDirectory)
        }
    }

    var urlForChartboostIDFile: URL {
        get throws {
            try throwingRecord(.urlForChartboostIDFile)
        }
    }
    
    func fileExists(at url: URL) -> Bool {
        record(.fileExists, parameters: [url])
    }
    
    func removeFile(at url: URL) throws {
        try throwingRecord(.removeFile, parameters: [url])
    }
    
    func write(_ data: Data, to url: URL) throws {
        try throwingRecord(.write, parameters: [data, url])
    }
    
    func readData(at url: URL) throws -> Data {
        try throwingRecord(.readData, parameters: [url])
    }
    
    func directoryExists(at url: URL) -> Bool {
        record(.directoryExists, parameters: [url])
    }
    
    func createDirectory(at url: URL) throws {
        try throwingRecord(.createDirectory, parameters: [url])
    }
    
    func removeDirectory(at url: URL) throws {
        try throwingRecord(.removeDirectory, parameters: [url])
    }
}

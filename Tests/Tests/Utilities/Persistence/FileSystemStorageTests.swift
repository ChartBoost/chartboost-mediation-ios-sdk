// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class FileSystemStorageTests: ChartboostMediationTestCase {
    
    lazy var fileStorage = FileSystemStorage()
    
    private var fileURL: URL {
        try! FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true // This must be set to true when running on CI
        ).appendingPathComponent("testFile")
    }
    
    private var directoryURL: URL {
        try! FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true // This must be set to true when running on CI
        ).appendingPathComponent("testDirectory", isDirectory: true)
    }
    
    override func setUp() {
        super.setUp()
        
        // Clean up potential file system modifications by previous tests
        // Ignore errors, which may happen because the file or directory did not exists
        _ = try? FileManager.default.removeItem(at: fileURL)
        _ = try? FileManager.default.removeItem(at: directoryURL)
    }
    
    /// Validates that the file storage returns a proper value for the configuration directory url.
    func testURLForSDKConfigurationDirectory() throws {
        let url = try fileStorage.urlForSDKConfigurationDirectory
        let expectedURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("HeliumConfig")
        XCTAssertEqual(url, expectedURL)
    }

    /// Validates that the file storage returns a the /Library/Chartboost/chartboost_identifier directory URL.
    func testURLForChartboostIDFile() throws {
        let url = try fileStorage.urlForChartboostIDFile
        let expectedURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Chartboost/chartboost_identifier")
        XCTAssertEqual(url, expectedURL)
    }
    
    /// Validates that the file storage returns true or false depending on if a file exists at the url.
    func testFileExists() throws {
        // Check that file does not exist
        XCTAssertFalse(fileStorage.fileExists(at: fileURL))
        
        // Create the file, check that it does exist
        try "some content".write(to: fileURL, atomically: true, encoding: .utf8)
        XCTAssertTrue(fileStorage.fileExists(at: fileURL))
        
        // Remove the file, check that it does not exist
        try FileManager.default.removeItem(at: fileURL)
        XCTAssertFalse(fileStorage.fileExists(at: fileURL))
    }
    
    /// Validates that the file storage removes a file when asked.
    func testRemoveFile() throws {
        // Check that nothing happens if the file does not exist
        try fileStorage.removeFile(at: fileURL)
        
        // Create the file
        try "some content".write(to: fileURL, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        
        // Remove the file and check it no longer exists
        try fileStorage.removeFile(at: fileURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    /// Validates that the file storage `write(_:to:)` method writes the passed data into a file properly in an already existing directory.
    func testWriteDataIntoExistingDirectory() throws {
        // Write string data
        try fileStorage.write("some data".data(using: .utf8)!, to: fileURL)
        
        // Check the file exists and contains the persisted data
        XCTAssertEqual(try String(contentsOf: fileURL), "some data")
    }
    
    /// Validates that the file storage `write(_:to:)` method writes the passed data into a file properly in an non-existing directory, by creating such directory first.
    func testWriteDataIntoNonExistingDirectory() throws {
        // Write string data
        let fileURL = directoryURL.appendingPathComponent("testFile")
        try fileStorage.write("some data".data(using: .utf8)!, to: fileURL)
        
        // Check that the directory was created
        var isDirectory: ObjCBool = false
        let itemExists = FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory)
        XCTAssertTrue(itemExists && isDirectory.boolValue)
        // Check the file exists and contains the persisted data
        XCTAssertEqual(try String(contentsOf: fileURL), "some data")
        
        // Remove created file for cleanup
        try FileManager.default.removeItem(at: fileURL)
    }
    
    /// Validates that the file storage `readData(at:)` method returns the data contained in a file.
    func testReadData() throws {
        // Try to read data for a non-existing file to check an error is thrown
        XCTAssertThrowsError(try fileStorage.readData(at: fileURL))
        
        // Create the file
        let writtenData = "some content".data(using: .utf8)!
        try writtenData.write(to: fileURL, options: .atomic)
        
        // Read data and check it is the expected value
        let readData = try fileStorage.readData(at: fileURL)
        XCTAssertEqual(readData, writtenData)
    }
    
    /// Validates that the file storage returns true or false depending on if a directory exists at the url.
    func testDirectoryExists() throws {
        // Check that directory does not exist
        XCTAssertFalse(fileStorage.directoryExists(at: directoryURL))
        
        // Create the directory, check that it does exist
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: false)
        XCTAssertTrue(fileStorage.directoryExists(at: directoryURL))
        
        // Remove the directory, check that it does not exist
        try FileManager.default.removeItem(at: directoryURL)
        XCTAssertFalse(fileStorage.directoryExists(at: directoryURL))
    }
    
    /// Validates that the file storage creates a directory at the indicated url.
    func testCreateDirectory() throws {
        // Create a directory, check that it exists
        try fileStorage.createDirectory(at: directoryURL)
        var isDirectory: ObjCBool = false
        let itemExists = FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory)
        XCTAssertTrue(itemExists && isDirectory.boolValue)
        
        // Create the directory again, check that nothing happens
        try fileStorage.createDirectory(at: directoryURL)
        var isDirectory2: ObjCBool = false
        let itemExists2 = FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory2)
        XCTAssertTrue(itemExists2 && isDirectory2.boolValue)
    }
    
    /// Validates that the file storage removes a directory when asked.
    func testRemoveDirectory() throws {
        // Check that nothing happens if the directory does not exist
        try fileStorage.removeDirectory(at: directoryURL)
        
        // Create the directory
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: nil))
        
        // Remove the directory and check it no longer exists
        try fileStorage.removeDirectory(at: directoryURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: nil))
    }
}

// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Keywords are essentially key-value pairs used to enable real-time targeting on line items (and/or adgroups, placements, apps).
///
/// Helium SDK requests keywords from the Publisher App and sends them as part of the ad request to the Helium Auction server.
/// The Auction server uses the targeting rules defined by the publisher via Helium Dashboard to decide which line items
/// will participate in the auction.
@objc(HeliumKeywords)
public class HeliumKeywords: NSObject {
    // MARK: - Constants
    
    /// Maximum length for a keyword.
    private static let maxKeywordLength: Int = 64
    
    /// Maximum length for a keyword's value.
    private static let maxValueLength: Int = 256
    
    // MARK: - Properties
    
    /// The backing property to store the `keyword`:`value` pairs.
    @objc public private(set) var dictionary: [String: String] = [:]
    
    // MARK: - Initialization
    
    /// Initializes an empty `HeliumKeywords` instance.
    @objc public override init() {
        super.init()
    }
    
    /// Initializes `HeliumKeywords` with a dictionary of `keyword`:`value` pairs.
    /// - Parameter dictionary: Optional dictionary to use as the seed for the keywords.
    init?(_ dictionary: [String: String]? = nil) {
        super.init()
        
        guard let dictionary = dictionary else { return nil }
        self.dictionary = dictionary
    }
    
    // MARK: - Keyword Manipulation
    
    /// Sets the specified value for the keyword.
    ///
    /// In the event that the keyword already exists, it will overwrite the value if valid.
    /// - Parameter keyword: The keyword entry to set. The keyword is limited to 64 characters.
    /// - Parameter value: The value associated with the `keyword`. The value is limited to 256 characters.
    /// - Returns: `true` if the keyword was set successfully; otherwise `false` if the `keyword` or
    /// `value` exceed the maximum allowable characters.
    @objc(setKeyword:value:)
    @discardableResult public func set(keyword: String, value: String) -> Bool {
        guard keyword.count > 0 && keyword.count <= Self.maxKeywordLength else { return false }
        guard value.count <= Self.maxValueLength else { return false }
        
        self.dictionary[keyword] = value
        
        return true
    }

    /// Removes the specified keyword if it exists.
    /// - Parameter keyword: The keyword entry to remove. The keyword is limited to 64 characters.
    /// - Returns: The value of the keyword that was removed if it exists, otherwise `nil`.
    @objc(removeKeyword:)
    @discardableResult public func remove(keyword: String) -> String? {
        return dictionary.removeValue(forKey: keyword)
    }
    
    // MARK: - Equatable Override
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? Self else { return false }
        return object.dictionary == dictionary
    }
}

/*
** A String class polyfill for "Regex" replace and matches
**
** https://gist.github.com/apbendi/7515bc42249822d6da0d
*/

import Foundation

struct Regex {
  var pattern: String {
    didSet {
      updateRegex()
    }
  }
  var expressionOptions: NSRegularExpressionOptions {
    didSet {
      updateRegex()
    }
  }
  var matchingOptions: NSMatchingOptions

  var regex: NSRegularExpression?

  init(pattern: String, expressionOptions: NSRegularExpressionOptions, matchingOptions: NSMatchingOptions) {
    self.pattern = pattern
    self.expressionOptions = expressionOptions
    self.matchingOptions = matchingOptions
    updateRegex()
  }

  init(pattern: String) {
    self.pattern = pattern
    expressionOptions = NSRegularExpressionOptions(rawValue: 0)
    matchingOptions = NSMatchingOptions(rawValue: 0)
    updateRegex()
  }

  func exec(value: String) -> [String] {
    var results: [String]    = []
    var matches: [AnyObject] = []

    let range: NSRange = NSMakeRange(0, value.characters.count)

    if self.regex == nil {
      return results
    }

    matches = self.regex!.matchesInString(value, options: self.matchingOptions, range: range)

    for match in matches {
      results.append(match as! String)
    }

    return results
  }

  mutating func updateRegex() {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: expressionOptions) else {
      return
    }

    self.regex = regex
  }
}

extension String {
  func matchRegex(pattern: Regex) -> Bool {
    let range: NSRange = NSMakeRange(0, self.characters.count)
    if pattern.regex != nil {
        let matches = pattern.regex!.matchesInString(self, options: pattern.matchingOptions, range: range)
        return matches.count > 0
    }
    return false
  }

  func match(patternString: String) -> Bool {
    return self.matchRegex(Regex(pattern: patternString))
  }

  func replaceRegex(pattern: Regex, template: String) -> String {
    if self.matchRegex(pattern) {
      let range: NSRange = NSMakeRange(0, self.characters.count)
      if pattern.regex != nil {
        return pattern.regex!.stringByReplacingMatchesInString(self, options: pattern.matchingOptions, range: range, withTemplate: template)
      }
    }
    return self
  }

  func replace(pattern: String, template: String) -> String {
    return self.replaceRegex(Regex(pattern: pattern), template: template)
  }
}

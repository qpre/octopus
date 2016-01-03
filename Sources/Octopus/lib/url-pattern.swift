func escapeForRegex(str: String) -> String {
  return str.replace("/[-\/\\^$*+?.()|[\]{}]/g", "\\$&")
}

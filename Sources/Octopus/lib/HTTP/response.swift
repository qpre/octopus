/*
** @stru HTTPResponse
** A structure representing the response
*/
public struct HTTPResponse {
  var statusCode:    Int    = 200
  var statusMessage: String = "OK"

  var serverKind:  String = "Octopus"
  var contentType: String = "text-plain"

  var payload: String = ""
}

public func getResponseHeaders(response: HTTPResponse) -> String {
  var headers = ""

  headers += "HTTP/1.1 \(response.statusCode) \(response.statusMessage)\r\n"
  headers += "Server: \(response.serverKind)\n"
  headers += "Content-Length: \(response.payload.characters.count)\r\n"
  headers += "Content-type: \(response.contentType)\n"

  headers += "\r\n"

  return headers
}

public func getResponseAsString(response: HTTPResponse) -> String {
  var responseAsString = ""

  responseAsString += getResponseHeaders(response)
  responseAsString += response.payload

  return responseAsString
}

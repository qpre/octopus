/*
** @stru HTTPResponse
** A structure representing the response
*/
public class HTTPResponse {
  public var statusCode:    Int    = 200
  public var statusMessage: String = "OK"

  public var serverKind:  String = "Octopus"
  public var contentType: String = "text-plain"

  public var payload: String = ""
}

public func getResponseHeaders(response: HTTPResponse) -> String {
  var headers = ""

  headers += "HTTP/1.1 \(response.statusCode) \(response.statusMessage)\r\n"
  headers += "Server: \(response.serverKind)\n"
  headers += "Content-Length: \(response.payload.utf16.count)\r\n"
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

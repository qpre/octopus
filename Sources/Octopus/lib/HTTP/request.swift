/*
** @function parseRequest
** extracts request data from request string
*/
public func parseRequest(requestAsString: String) throws -> HTTPRequest {
  var request: HTTPRequest

  let params = requestAsString.characters.split {$0 == " "}.map(String.init)

  if (params.count < 3) {
    throw HTTPError.BadRequest
  }

  request = HTTPRequest(
    method: try! parseMethod(params[0]),
    uri: params[1],
    version: params[2]
  )

  return request
}

/*
** @function parseMethod
** extracts the HTTP method field from request string
*/
func parseMethod(string: String) throws -> HTTPMethod {
  let method: HTTPMethod

  switch string.uppercaseString {
    case "HEAD":
      method = HTTPMethod.HEAD
    case "GET":
      method = HTTPMethod.GET
    case "POST":
      method = HTTPMethod.POST
    default:
      throw HTTPError.NotSupported
  }

  return method
}

/*
** @enumeration HTTPMethod
** the different values an HTTP method can take
*/
public enum HTTPMethod {
  case GET
  case POST
}

/*
** @enumeration HTTPError
** the different values an HTTP error can take
*/
public enum HTTPError: ErrorType {
  case BadRequest
  case NotSupported
}

/*
** @struct HTTPRequest
** A structure representing the request
*/
public struct HTTPRequest {
  var method:  HTTPMethod
  var uri:     String = ""
  var version: String = ""
}

/*
** @function getHTTPErrorParams
** @returns a tuple with the error code and the error message
**   for the encountered error
*/
public func getHTTPErrorParams(error: HTTPError) -> (Int, String) {
  switch error {
    case .BadRequest:
      return (code: 400, message: "Bad Request")
    case .NotSupported:
      return (code: 505, message: "HTTP Version Not Supported")
  }
}

/*
** @function parseRequest
** extracts request data from request string
*/
public func parseRequest(requestAsString: String) throws -> HTTPRequest {
  var request: HTTPRequest

  let params = requestAsString.characters.split {$0 == " "}.map(String.init)

  print(params.count)

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
    case "GET":
      method = HTTPMethod.GET
    case "POST":
      method = HTTPMethod.POST
    default:
      throw HTTPError.NotSupported
  }

  return method
}

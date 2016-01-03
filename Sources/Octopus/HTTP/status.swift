/*
** @enumeration HTTPMethod
** the different values an HTTP method can take
*/
public enum HTTPMethod {
  case GET
  case POST
  case HEAD
}

/*
** @enumeration HTTPError
** the different values an HTTP error can take
*/
public enum HTTPError: ErrorType {
  case BadRequest
  case NotSupported
  case NotFound
}

/*
** @struct HTTPRequest
** A structure representing the request
*/
public struct HTTPRequest {
  var method:  HTTPMethod
  var uri:     String = ""
  var version: String = ""
  var params:  [String:String]
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
    case .NotFound:
      return (code: 404, message: "Not Found")
  }
}

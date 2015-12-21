public enum HTTPMethod {
  case GET
  case POST
}

public struct HTTPRequest {
  var method:  HTTPMethod
  var uri:     String = ""
  var version: String = ""
}

public enum HTTPRequestError: ErrorType {
  case BadRequest
  case NotSupported
}

public func getHTTPRequestErrorParams(error: HTTPRequestError) -> (Int, String) {
  switch error {
    case .BadRequest:
      return (code: 400, message: "Bad Request")
    case .NotSupported:
      return (code: 505, message: "HTTP Version Not Supported")
  }
}

public func parseRequest(requestAsString: String) throws -> HTTPRequest {
  var request: HTTPRequest

  print("parsing request")

  let params = requestAsString.characters.split {$0 == " "}.map(String.init)

  print(params.count)

  if (params.count < 3) {
    throw HTTPRequestError.BadRequest
  }

  print("finished parsing")

  request = HTTPRequest(
    method: try! parseMethod(params[0]),
    uri: params[1],
    version: params[2]
  )

  print("request object built")

  return request
}

func parseMethod(string: String) throws -> HTTPMethod {
  let method: HTTPMethod

  switch string.uppercaseString {
    case "GET":
      method = HTTPMethod.GET
    case "POST":
      method = HTTPMethod.POST
    default:
      throw HTTPRequestError.NotSupported
  }

  return method
}

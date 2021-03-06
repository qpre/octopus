/*
** @function getQueryParams
** extracts params from URI
*/
public func getQueryParams(uri: String) -> Dictionary<String, String>? {
  var res = [String:String]()
  let splitUri = uri.characters.split {$0 == "?"}.map(String.init)

  // no query params
  if splitUri.count < 2 {
    return res
  }

  let query = splitUri[1]
  let fullKeyValueString = query.characters.split {$0 == "&"}.map(String.init)

  for keyValueString in fullKeyValueString {
    let keyValue = keyValueString.componentsSeparatedByString("=")
    if keyValue.count > 1 {
        res.updateValue(keyValue[1], forKey: keyValue[0])
    }
  }

  return res
}

/*
** @function getQueryParams
** extracts params from URI
*/
public func getURIParams(req: HTTPRequest, route: Route) -> Dictionary<String, String>? {
  var res = [String:String]()
  var values: [String]

  values = route.regex.exec(req.uri)

  for (index, key) in route.params.enumerate() {
    if index > values.count - 1 {
      break
    }

    res.updateValue(values[index], forKey: key)
  }

  return res
}

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
    method:       try! parseMethod(params[0]),
    uri:          params[1],
    version:      params[2],
    queryParams:  getQueryParams(params[1])!,
    URIParams:    [String:String]()
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

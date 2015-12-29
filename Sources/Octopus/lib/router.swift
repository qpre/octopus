/*
** @type HTTPHandler
**
** HTTPHandlers get the state of the transaction as a request and a response,
** and return the transformed state.
*/
public typealias HTTPHandler = (req: HTTPRequest, res: HTTPResponse) -> HTTPResponse

/*
** @struct Route
**
** Defines a Route as a handler to be applied when a path
** is accessed using a specific method.
*/
public struct Route {
  var method:  String
  var path:    String
  var handler: HTTPHandler
}

/*
** @struct Router
**
** A wrapping structure for routing elements
*/
public struct Router {
  /*
  ** @dictionary
  ** Where all the currently available routes are stored
  */
  var routes = Dictionary<String, Route>()

  /*
  ** @function addRoute
  ** @param {String} method
  ** @param {String} path
  ** @param {Closure} handler
  **
  ** creates and stores a new Route to be used when resolving requests.
  **
  */
  mutating public func add(method: String, path: String, handler: HTTPHandler) {
    // creating a hashkey to easyly retrieve this path when resolving
    let hashKey: String = "\(method):\(path)"

    // instantiate a struct composed of this route's assets
    let route = Route(
      method:  method,
      path:    path,
      handler: handler
    )

    // adding it to current set of routes
    routes[hashKey] = route
  }

  /*
  ** @function get
  ** @param {String} method
  ** @param {String} path
  **
  ** shortcut to add a handler for a specific path when using 'get' method
  **
  */
  mutating public func get(path: String, handler: HTTPHandler) {
    add("GET", path: path, handler: handler)
  }

  /*
  ** @function resolve
  ** @param {String} method
  ** @param {String} path
  **
  ** applies all the handlers available for this route.
  **
  ** TODO: handle [url-pattern](https://github.com/snd/url-pattern/blob/master/src/url-pattern.coffee)-like paths
  */
  mutating public func resolve(req: HTTPRequest, res: HTTPResponse) throws -> HTTPResponse {
    let route = routes["\(req.method):\(req.uri)"]

    var response = res

    if route == nil {
      // route does not exist
      throw HTTPError.NotFound
    }

    response = route!.handler(req: req, res: res)

    return response
  }
}

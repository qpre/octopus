/*
** @type HTTPHandler
**
** HTTPHandlers get the state of the transaction as a request and a response,
** and return the transformed state.
*/
typealias HTTPHandler = (req: HTTPRequest, res: HTTPResponse) -> (req: HTTPRequest, res: HTTPResponse)

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
** @dictionary
** Where all the currently available routes are stored
*/
var routes = [String: Route]()

/*
** @function addRoute
** @param {String} method
** @param {String} path
** @param {Closure} handler
**
** creates and stores a new Route to be used when resolving requests.
**
*/
func addRoute(method: String, path: String, handler: HTTPHandler) {
  // creating a hashkey to easyly retrieve this path when resolving
  let hashKey: String = "\(method):\(path)"

  // instantiate a struct composed of this route's assets
  let route: Route(
    method:  method,
    path:    path,
    handler: handler
  )

  // adding it to current set of routes
  route[hashKey] = route
}

/*
** @function get
** @param {String} method
** @param {String} path
**
** shortcut to add a handler for a specific path when using 'get' method
**
*/
public func get(path: String, handler: HTTPHandler) {
  addRoute("get", path, handler)
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
public func resolve(method: String, path: String) {
  if !(let route: Route = routes["\(method):\(path)"]) {
    // route does not exist
    return -1
  }

  route.handler()

  return 0
}
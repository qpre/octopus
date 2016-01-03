import Foundation

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
  var regex:   Regex
  var handler: HTTPHandler
  var params:  [String]
}

func extractRouteComponents(path: String) -> (Regex, [String]) {
  var splitPath: [String] = path.characters.split {$0 == "/"}.map(String.init)
  var params: [String] = []
  var regex: Regex

  for (index, fragment) in splitPath.enumerate() {
    // is it a parameter ?
    if fragment[fragment.startIndex] != ":" {
      continue
    }

    // extract param name
    let param = fragment.replace(":", template: "")

    // replace current index with regex param
    splitPath[index] = "\\d"

    // save param name at the right index
    params.append(param)
  }

  var joinPath: String = ""

  for fragment in splitPath {
    joinPath += "/" + fragment
  }

  print(joinPath)

  regex = Regex(pattern: joinPath)

  return (regex, params)
}

/*
** @class Router
**
** A wrapping structure for routing elements
*/
public class Router {
  /*
  ** @dictionary
  ** Where all the currently available routes are stored
  */
  var routes = [Route]()

  /*
  ** @function addRoute
  ** @param {String} method
  ** @param {String} path
  ** @param {Closure} handler
  **
  ** creates and stores a new Route to be used when resolving requests.
  **
  */
  public func add(method: String, path: String, handler: HTTPHandler) {
    let (regex, params) = extractRouteComponents(path)

    // instantiate a struct composed of this route's assets
    let route = Route(
      method:  method,
      regex:   regex,
      handler: handler,
      params:  params
    )

    // adding it to current set of routes
    routes.append(route)
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
  public func resolve(req: HTTPRequest, res: HTTPResponse) throws -> HTTPResponse {
    var route: Route?
    var response = res

    // first match files from public directory
    let location = String("./public/\(req.uri)")
    let fileContent = NSData(contentsOfFile: location)

    if fileContent != nil {
      response.payload = String(data: fileContent!, encoding: NSUTF8StringEncoding)!
      return response
    }

    for r in routes {
      if req.uri.matchRegex(r.regex) {
        route = r
      }
    }

    if route == nil {
      // route does not exist
      throw HTTPError.NotFound
    }

    response = route!.handler(req: req, res: res)

    return response
  }
}

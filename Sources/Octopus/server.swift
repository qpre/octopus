/*
** server.swift
*/

// System specific imports
import Foundation

#if os(Linux)
  import Glibc
  import NSLinux
#endif

/*
** @function sync
** @param {NSLock}
** @param {Function} closure to be called in a thread-safe environnement
**
** performs a specific closed function in a thread-safe context
*/
func sync(handle: NSLock, closure: () -> ()) {
  handle.lock()
  closure()
  handle.unlock();
}

/*
** @class Server
** A wrapper-class for Octopus's HTTP server layer
*/
public class Server {
  // The set of handlers to be used when resolving request
  public var router:  Router

  // The socket that will be used by the server for incoming connections
  var socket:  Socket

  // All current clients will be stored in here
  var clients: Set<Socket>

  // A lock to be used for thread-safe actions.
  var lock: NSLock

  /*
  ** @constructor
  ** @param {Int} port to bind the socket to.
  */
  public init(port: Int = 8080) {
    self.socket  = try! createSocket(in_port_t(port))

    self.clients = Set<Socket>()
    self.router  = Router()
    self.lock    = NSLock()
  }

  /*
  ** @method start
  ** launches the server loop (accept/dispatch clients)
  */
  public func start() throws {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
      while let client = try? acceptClientSocket(self.socket) {
        sync (self.lock) {
          self.clients.insert(client)
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
          let address       = try! getPeerName(client)
          let requestString = try? readSocket(client)

          print(requestString)

          do {
            let response = try self.handle(requestString!)
            try respond(client, response: response)
          } catch _ {
            print("error while handling request from \(address)")
          }

          release(client.fileDescriptor)

          sync (self.lock) { self.clients.remove(client) }
        }
      }
    }
  }

  /*
  ** @function handle
  ** @param {String} requestString
  **
  ** parses request, applies consequent routes and responds
  */
  private func handle(requestString: String) throws -> HTTPResponse {
    var response = HTTPResponse()

    do {
      response = try self.router.resolve(requestString, res: response)
    } catch let e {
      let error = e as? HTTPError
      let (code, message) = getHTTPErrorParams(error!)

      response.statusCode    = code
      response.statusMessage = message
      response.payload = "HTTP/1.1 \(code) \(message)\r\n\r\n"
    }

    return response
  }

  /*
  ** @method
  ** kills the server loop
  */
  public func stop() {
    release(self.socket.fileDescriptor)

    sync (self.lock) {
      for client in self.clients {
        shutdownSocket(client.fileDescriptor)
      }

      self.clients.removeAll(keepCapacity: true)
    }
  }
}

/*
** @function respond
** @param {Socket} socket to write to
** @param {HTTPResponse} response to be sent back to the client
*/
func respond(socket: Socket, response: HTTPResponse) throws {
  print("respond with \(response.statusCode)")
  try writeSocket(socket, string: getResponseAsString(response))
}

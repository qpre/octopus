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
** @class OctopusServer
** A wrapper-class for Octopus's HTTP server layer
*/
public class OctopusServer {
  // The socket that will be used by the server for incoming connections
  var socket:  OctopusSocket

  // All current clients will be stored in here
  var clients: Set<OctopusSocket>

  // A lock to be used for thread-safe actions.
  var lock: NSLock

  /*
  ** @constructor
  ** @param {Int} port to bind the socket to.
  */
  public init(port: Int = 8080) {
    print("Starting server...")

    self.socket  = try! createSocket(in_port_t(port))

    print("Listening on port \(port)...")

    self.clients = Set<OctopusSocket>()
    self.lock = NSLock()
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
          let address = try! getPeerName(client)

          print("got a client from \(address)")

          let requestString = try? readSocket(client)

          do {
            print(requestString)
            let request = try parseRequest(requestString!)
            print(" \(request.method) \(request.uri)")
            try! respond(client, payload: "Welcome on Octopus, Please setup a new Router")
          } catch let e {
            let error = e as? HTTPRequestError
            let (code, message) = getHTTPRequestErrorParams(error!)
            print("error is: HTTP/1.1 \(code) \(message)")
            try! respond(client, payload: "HTTP/1.1 \(code) \(message)")
          }

          release(client.fileDescriptor)

          sync (self.lock) {
            self.clients.remove(client)
          }
        }
      }
    }
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
** @param {OctopusSocket} socket to write to
** @param {String} payload to be written on the socket
*/
func respond(socket: OctopusSocket, payload: String = "") throws {
  try writeSocket(socket, string: "HTTP/1.1 200 OK\r\n")
  try writeSocket(socket, string: "Server: Octopus\n")
  try writeSocket(socket, string: "Content-Length: \(payload.characters.count)\r\n")
  try writeSocket(socket, string: "Content-type: text-plain\n")
  try writeSocket(socket, string: "\r\n")
  try writeSocket(socket, string: payload)
}

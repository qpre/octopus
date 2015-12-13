/*
** server.swift
*/

import Foundation

// System specific imports
#if os(Linux)
  import Glibc
  import NSLinux
#endif

func sync(handle: NSLock, closure: () -> ()) {
  handle.lock()
  closure()
  handle.unlock();
}

public class OctopusServer {
  var socket:  OctopusSocket
  var clients: Set<OctopusSocket>
  var lock: NSLock

  public init(port: in_port_t = 8080) {
    print("Starting on port \(port)...")

    self.socket  = try! createSocket(port)

    print("Listening on port \(port)...")

    self.clients = Set<OctopusSocket>()
    self.lock = NSLock()
  }

  public func start() throws {
    print("Launch server loop")

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
      print("Accepting clients")

      while let client = try? acceptClientSocket(self.socket) {
        sync (self.lock) {
          self.clients.insert(client)
        }

        print("got a client")

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
          let address = try! getPeerName(client)

          print("got a client from \(address)")

          let requestString = try? readSocket(client)
          var request: HTTPRequest?

          do {
            request = try parseRequest(requestString!)
          } catch let e {
            let error = e as? HTTPRequestError
            let (code, message) = getHTTPRequestErrorParams(error!)
            try! respond(client, payload: "HTTP/1.1 \(code) \(message)")
          }

          print("\(request?.uri) \(request?.method)")

          try! respond(client, payload: "Welcome on Octopus, Please setup a new Router")

          release(client.fileDescriptor)

          sync (self.lock) {
            self.clients.remove(client)
          }
        }
      }
    }
  }

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

func respond(socket: OctopusSocket, payload: String = "") throws {
  print("responding to client")

  let payloadAsBytes: [UInt8] = Array(payload.utf8)

  try writeSocket(socket, string: "HTTP/1.1 200 OK\r\n")
  try writeSocket(socket, string: "Server: Octopus\n")
  try writeSocket(socket, string: "Content-Length: \(payloadAsBytes.count ?? 0)\r\n")
  try writeSocket(socket, string: "Content-type: text-plain\n")
  try writeSocket(socket, string: "\r\n")
  try writeSocket(socket, string: payload)
}

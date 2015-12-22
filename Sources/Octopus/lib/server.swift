/*
** server.swift
*/

// System specific imports
import Foundation

#if os(Linux)
  import Glibc
  import NSLinux
#else
  import Darwin.C
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

  public init(port: Int = 8080) {
    print("Starting on port \(port)...")

    self.socket  = try! createSocket(in_port_t(port))

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

  try writeSocket(socket, string: "HTTP/1.1 200 OK\r\n")
  try writeSocket(socket, string: "Server: Octopus\n")
  try writeSocket(socket, string: "Content-Length: \(payload.characters.count)\r\n")
  try writeSocket(socket, string: "Content-type: text-plain\n")
  try writeSocket(socket, string: "\r\n")
  try writeSocket(socket, string: payload)

  print("response sent to client")
}

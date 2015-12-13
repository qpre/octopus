/*
** server.swift
*/

// System specific imports
#if os(Linux)
  import Glibc
#else
  import Foundation
#endif

func sync(lock: AnyObject, closure: () -> Void) {
  objc_sync_enter(lock)
  closure()
  objc_sync_exit(lock)
}

public class OctopusServer {
  var socket:  OctopusSocket
  var clients: Set<OctopusSocket>

  public init(port: in_port_t = 8080) {
    self.socket  = try! createSocket(port)
    self.clients = Set<OctopusSocket>()
  }

  public func start() throws {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
      while let client = try? acceptClientSocket(self.socket) {
        sync (self) {
          self.clients.insert(client)
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
          // let address = try! getPeerName(client)

          let request = try? readSocket(client)
          print(request)

          try! respond(client, payload: "Welcome on Octopus, Please setup a new Router")

          release(client.fileDescriptor)

          sync (self) {
            self.clients.remove(client)
          }
        }
      }
    }
  }

  public func stop() {
    release(self.socket.fileDescriptor)

    sync (self) {
      for client in self.clients {
        shutdownSocket(client.fileDescriptor)
      }

      self.clients.removeAll(keepCapacity: true)
    }
  }
}

func respond(socket: OctopusSocket, payload: String = "") throws {
  try writeSocket(socket, string: "HTTP/1.1 200 OK\r\n")
  try writeSocket(socket, string: "Server: Octopus\n")
  try writeSocket(socket, string: "Content-Length: \(payload.characters.count)\r\n")
  try writeSocket(socket, string: "Content-type: text-plain\n")
  try writeSocket(socket, string: "\r\n")
  try writeSocket(socket, string: payload)
}

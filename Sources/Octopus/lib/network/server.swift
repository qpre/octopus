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

        print("client connected !")
      }
    }
  }
}

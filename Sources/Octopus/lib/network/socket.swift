/*
** socket.swift
*/

// System specific imports
#if os(Linux)
  import Glibc
#else
  import Darwin.C
#endif

// System specific values
#if os(Linux)
  let sockStream = Int32(SOCK_STREAM.rawValue)
  let sinZero = (UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0))
  let msgNoSignal: Int32 = Int32(MSG_NOSIGNAL)

  func shutdownSocket(socket: Int32) { shutdown(socket, Int32(SHUT_RDWR)) }
  func setNoSigPipe(socket: Int32) {} // do nothing, SO_NOSIGPIPE does not exist on Linux
  func htons(value: in_port_t) -> CUnsignedShort {
    return (value << 8) + (value >> 8)
  }
#else
  let sockStream = SOCK_STREAM
  let sinZero = (Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0))
  let msgNoSignal: Int32 = 0

  func shutdownSocket(socket: Int32) { Darwin.shutdown(socket, SHUT_RDWR) }
  func setNoSigPipe(socket: Int32) {
    var noSigPipe: Int32 = 1
    setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(sizeof(Int32)))
  }
  func htons(port: in_port_t) -> CUnsignedShort {
    let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
    return isLittleEndian ? _OSSwapInt16(port) : port
  }
#endif

// Errors
// TODO: rewrite this
enum SocketError: ErrorType {
  case SocketCreationFailed(String)
  case SocketSettingReUseAddrFailed(String)
  case BindFailed(String)
  case ListenFailed(String)
  case WriteFailed(String)
  case GetPeerNameFailed(String)
  case ConvertingPeerNameFailed
  case GetNameInfoFailed(String)
  case AcceptFailed(String)
  case RecvFailed(String)
}

// OctopusSocket
public struct OctopusSocket {
  var fileDescriptor: Int32 = -1
}

// Returns the last error encountered as a string
func lastErrorAsString() -> String {
  return String.fromCString(UnsafePointer(strerror(errno))) ?? "Error: \(errno)"
}

func sockaddr_cast(p: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<sockaddr> {
    return UnsafeMutablePointer<sockaddr>(p)
}

/*
** @function createSocket
**
** @param {in_port_t} port to bind to
** @param {Int32} connectionTimeout
*/
public func createSocket(port: in_port_t = 8080, connectionTimeout: Int32 = SOMAXCONN) throws -> OctopusSocket {
  var sockAddr: sockaddr_in
  var sockOpt: Int32
  var sockOptValue: Int32 = 1
  let sockLength = UInt8(sizeof(sockaddr_in))

  // preparing our magnificent wrapper
  var oSocket: OctopusSocket = OctopusSocket()

  // Create a new POSIX socket
  oSocket.fileDescriptor = socket(AF_INET, sockStream, 0);

  if oSocket.fileDescriptor == -1 {
    throw SocketError.SocketCreationFailed(lastErrorAsString())
  }

  // setting socket options
  sockOpt = setsockopt(oSocket.fileDescriptor, SOL_SOCKET, SO_REUSEADDR, &sockOptValue, socklen_t(sizeof(Int32)))

  if sockOpt == -1 {
    let error = lastErrorAsString()
    release(oSocket.fileDescriptor)
    throw SocketError.SocketSettingReUseAddrFailed(error)
  }

  // preventing from crashes when app is in Background (Useful for non-IOS apps ?)
  setNoSigPipe(oSocket.fileDescriptor)

  // setting up sockaddr_in, THIS IS THE INTERNET
  sockAddr = sockaddr_in()
  sockAddr.sin_family = sa_family_t(AF_INET)
  sockAddr.sin_port   = htons(port)
  sockAddr.sin_addr   = in_addr(s_addr: in_addr_t(0))
  sockAddr.sin_zero   = sinZero

  #if !os(Linux)
    sockAddr.sin_len = sockLength
  #endif

  // binding
  if bind(oSocket.fileDescriptor, sockaddr_cast(&sockAddr), socklen_t(sockLength)) == -1 {
    let error = lastErrorAsString()
    release(oSocket.fileDescriptor)
    SocketError.BindFailed(error)
  }

  // listening
  if listen(oSocket.fileDescriptor, connectionTimeout) == -1 {
    let error = lastErrorAsString()
    release(oSocket.fileDescriptor)
    SocketError.ListenFailed(error)
  }

  return oSocket
}

public func write(socket: OctopusSocket, string: String) throws {
  let data = [UInt8](string.utf8)

  try data.withUnsafeBufferPointer { pointer in
    var sent = 0

    while sent < data.count {
      let s = send(socket.fileDescriptor, pointer.baseAddress + sent, Int(data.count - sent), msgNoSignal)

      if s <= 0 {
        throw SocketError.WriteFailed(lastErrorAsString())
      }

      sent += s
    }
  }
}

public func readSocket(socket: OctopusSocket) throws -> String {
  var res: String = ""
  var bitsRead = 0;

  repeat {
    bitsRead = readBuffer(socket)

    if bitsRead > 13 { // CR
      res.append(Character(UnicodeScalar(bitsRead)))
    }
  } while bitsRead > 0 && bitsRead != 10

  if bitsRead == -1 {
    throw SocketError.RecvFailed(lastErrorAsString())
  }

  return res
}

func readBuffer(socket: OctopusSocket) -> Int {
  var buffer = [UInt8](count: 1, repeatedValue: 0)

  // get bits from the socket
  let next = recv(socket.fileDescriptor as Int32, &buffer, Int(buffer.count), 0)

  // are we done reading ?
  if next <= 0 {
    return next
  }

  return Int(buffer[0])
}

func release(socket: Int32) {
  shutdownSocket(socket)
  close(socket)
}
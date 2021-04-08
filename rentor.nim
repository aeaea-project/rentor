import strutils, sequtils, net, cgi, uri, std/sha1
import binarylang
import rentor/blbencode

proc hashToByteString(hash: SecureHash): string =
  for b in hash.Sha1Digest:
    result.add(b.char)

struct(header):
  s: key
  s: _ = ": "
  s: value
  s: _ = "\n"

proc `[]`(headers: seq[Header], key: string): string =
  for header in headers:
    if header.key == key:
      result = header.value

proc `[]=`(headers: var seq[Header]; key, value: string) =
  headers.add Header(key: key, value: value)

proc contains(headers: seq[Header], s: string): bool =
  for header in headers:
    if header.key == s:
      result = true
      break

proc getContentLen(headers: seq[Header]): int =
  if "Content-Length" in headers:
    headers["Content-Length"].parseInt
  else:
    0

template strGet(parse, parsed, output: untyped) =
  parse
  output = parsed.mapIt(it.char).join
template strPut(encode, encoded, output: untyped) =
  for i in 0 ..< encoded.len:
    output[i] = byte(encoded[i])
  encode

struct(httppost):
  s: _ = "HTTP/"
  s: version
  s: _ = " "
  s: code
  s: _ = " "
  s: msg
  s: _ = "\r\n"
  *header: {headers}
  s: _ = "\r\n"
  u8 {str[string]}: content[getContentLen(headers)]

struct(httpget):
  s: _ = "GET "
  s: url
  s: _ = " HTTP/"
  s: version
  s: _ = "\r\n"
  *header: {headers}
  s: _ = "\r\n"
  u8 {str[string]}: content[getContentLen(headers)]

block:
  var file = newFileBitStream("/some/path/_.torrent")
  defer: close(file)

  let metainfo = bencode.get(file, bekDict)
  var
    url = "/announce?"
    host, port: string
  for ben in metainfo.dict:
    if ben[0].disc == bekStr and ben[0].str.mapIt(it.char).join == "info":
      url &= "info_hash=" & ben[1].fromBencode(ben[1].disc).secureHash.hashToByteString.encodeUrl
  for ben in metainfo.dict[1][1].list:
    if ben.list[0].str.mapIt(it.char).join.startsWith("http"):
      let uri = ben.list[0].str.mapIt(it.char).join.parseUri
      host = uri.hostname
      port = uri.port
      echo host
      echo port
      break

  var request = HTTPGET(url: url, version: "1.1")
  request.headers["Host"] = host
  echo request.fromHTTPGET

  var socket = newSocket()
  socket.connect(host, Port(port.parseInt))
  socket.send(request.fromHTTPGET)
  let reply = socket.recv(4096)
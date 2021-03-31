import strutils
import binarylang, binarylang/plugins

createParser(header):
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

createParser(http):
  s: _ = "HTTP/"
  s: version
  s: _ = " "
  s: code
  s: _ = " "
  s: msg
  s: _ = "\n"
  *header: {headers}
  s: _ = "\n"
  s {
    cond: "Content-Length" in headers,
    @hook: (headers["Content-Length"] = $_.len)
  }: content(headers["Content-Length"].parseInt)
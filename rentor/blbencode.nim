import strutils
import bitstreams, binarylang

type BElemKind* = enum
  bekInt
  bekStr
  bekList
  bekDict

type Integer* = int

proc integerGet*(s: BitStream): Integer =
  var res: string
  var x = s.readU8.char
  if x in {'0' .. '9', '-'}:
    res.add x
  else:
    raise newException(Defect, "Not an integer")
  while true:
    x = s.readU8.char
    if x in {'0' .. '9'}:
      res.add x
    else:
      s.skip(-1)
      break
  parseInt(res)

proc integerPut*(s: BitStream, input: Integer) =
  s.writeStr($input)

let integer* = (get: integerGet, put: integerPut)

proc nextType(s: BitStream): BElemKind =
  let x = s.readU8.char
  s.skip(-1)
  case x
  of 'i': bekInt
  of 'l': bekList
  of 'd': bekDict
  else: bekStr

union(*bencode, *BElemKind):
  (bekInt):
    s: _ = "i"
    *integer: *num
    s: _ = "e"
  (bekStr):
    *integer: *size
    s: _ = ":"
    s: *str(size)
  (bekList):
    s: _ = "l"
    +bencode(nextType(s)): *{listElements}
    s: _ = "e"
  (bekDict):
    s: _ = "d"
    +bencode(nextType(s)): *{dictElements[2]}
    s: _ = "e"
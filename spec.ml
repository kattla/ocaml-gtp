
open Types

type ('a,'b) spec = compound_kind
type comm_cap = [`nothing|`simple|`pair|`list|`alt]
type ans_cap = [`nothing|`simple|`pair|`list|`alt|`mlist]
type 'a comm = ('a, comm_cap) spec
type 'a ans = ('a, ans_cap) spec

let structure a = a

let nothing = Nothing

let int = Entity Int
let float = Entity Float
let string = Entity String
let vertex = Entity Vertex
let color = Entity Color
let boolean = Entity Boolean

let pair a b = match a with Entity a -> Pair (a, b) | _ -> assert false
let list a = List a
let alt a b = match a,b with Entity a, Entity b -> Alt (a, b) | _ -> assert false
let mlist a = MList a

let string_line = String_line
let string_multiline = String_multiline

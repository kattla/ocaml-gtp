
type color = Black | White
type vertex = Pass | Coordinate of (int*int)

type ('a,'b) either = Left of 'a | Right of 'b

exception Error_message of string

type entity_kind =
  | Int
  | Float
  | String
  | Vertex
  | Color
  | Boolean

type compound_kind =
  | Nothing
  | Entity of entity_kind
  | Pair of (entity_kind * compound_kind)
  | List of compound_kind
  | Alt of (entity_kind * entity_kind)
  | MList of compound_kind
  | String_line
  | String_multiline

type opaque

type token =
  | E of (entity_kind * opaque)
  | NL
  | EOF


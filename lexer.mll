{
open Types
let ret kind any = E (kind, (Obj.magic any : opaque))
}

let ctrl_char = ['\000'-'\031' '\127'] # ['\t''\n']
let str = [^' ' '#' '\000'-'\031' '\127']+

rule token = parse
  | eof { EOF }
  | ctrl_char { token lexbuf }
  | '#' [^'\n']* { token lexbuf }
  | ' ' { token lexbuf } (* cheating *)
  | '\n' { NL }
  | ['0'-'9']+ as s { ret Int (int_of_string s) }
  | ['0'-'9']+ '.' ['0'-'9']+ { ret Float (float_of_string (Lexing.lexeme lexbuf)) }
  | (['a'-'z' 'A'-'Z'] as a) (['0'-'9']+ as b) {
      let a = Char.lowercase a in
      let x = int_of_char a - int_of_char 'a' in
      let x = if a > 'i' then x-1 else x in
      ret Vertex (Coordinate (x, int_of_string b - 1))
      }
  | str as s {
      match String.lowercase s with
      | "pass" -> ret Vertex Pass
      | "b" | "black" -> ret Color Black
      | "w" | "white" -> ret Color White
      | "false" -> ret Boolean false
      | "true" -> ret Boolean true
      | _ -> ret String s
      }

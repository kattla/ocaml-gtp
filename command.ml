
open Spec

type ('a,'b) t = {
  name : string;
  argument : 'a Spec.comm;
  output : 'b Spec.ans;
}

type string_no_newline = string
type string_no_space = string

let comm name ~arg ~ans =
  { name = name; argument = arg; output = ans }

let ( ** ) a b = pair a b


let protocol_version = comm "protocol_version"
  ~arg:nothing
  ~ans:int

let name = comm "name"
  ~arg:nothing
  ~ans:string_line

let version = comm "version"
  ~arg:nothing
  ~ans:string_line

let known_command = comm "known_command"
  ~arg:string
  ~ans:boolean

let list_commands = comm "list_commands"
  ~arg:nothing
  ~ans:(mlist string)

let quit = comm "quit"
  ~arg:nothing
  ~ans:nothing

let boardsize = comm "boardsize"
  ~arg:int
  ~ans:nothing

let clear_board = comm "clear_board"
  ~arg:nothing
  ~ans:nothing

let komi = comm "komi"
  ~arg:float
  ~ans:nothing

let fixed_handicap = comm "fixed_handicap"
  ~arg:int
  ~ans:(list vertex)

let place_free_handicap = comm "place_free_handicap"
  ~arg:int
  ~ans:(list vertex)

let set_free_handicap = comm "set_free_handicap"
  ~arg:(list vertex)
  ~ans:nothing

let play = comm "play"
  ~arg:(color ** vertex)
  ~ans:nothing

let genmove = comm "genmove"
  ~arg:color
  ~ans:(alt vertex string)

let undo = comm "undo"
  ~arg:nothing
  ~ans:nothing

let time_settings = comm "time_settings"
  ~arg:(int ** int ** int)
  ~ans:nothing

let time_left = comm "time_left"
  ~arg:(color ** int ** int)
  ~ans:nothing

let final_score = comm "final_score"
  ~arg:nothing
  ~ans:string

let final_status_list = comm "final_status_list"
  ~arg:string
  ~ans:(mlist (list vertex))

let loadsgf = comm "loadsgf"
  ~arg:(string ** int)
  ~ans:nothing

let reg_genmove = comm "reg_genmove"
  ~arg:color
  ~ans:(alt vertex string)

let showboard = comm "showboard"
  ~arg:nothing
  ~ans:string_multiline


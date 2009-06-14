
open Types
open Command

module type ENGINE_BASE = sig
  val name : string
  val version : string
  val boardsize : int -> unit
  val clear_board : unit -> unit
  val komi : float -> unit
  val play : (color * vertex) -> unit
  val genmove : color -> (vertex,string) either
end

module Make(E:ENGINE_BASE) = struct

  let cmds = Hashtbl.create 20

  exception Quit

  let run in_chan out_chan =
    let buf = IO.Read.from_channel in_chan in
    let chan = out_chan in
    try while true do
      match IO.Read.comm buf with
      | None -> raise Quit
      | Some cmd ->
      try
        let f = Hashtbl.find cmds cmd in
        f buf chan;
        if cmd = "quit" then raise Quit
      with Not_found ->
        IO.Read.recover_comm buf;
        IO.Write.error chan "unknown command"
    done with Quit -> ()

  let implement cmd f =
    Hashtbl.add cmds cmd.name (fun buf chan ->
      try 
        IO.Write.ans chan cmd.output
          (f (IO.Read.comm_args cmd.argument buf))
      with Error_message msg ->
        IO.Write.error chan msg
    )

  ;;implement protocol_version (fun () -> 2)
  ;;implement known_command (Hashtbl.mem cmds)
  ;;implement list_commands (fun () ->
    Hashtbl.fold (fun cmd _ tl -> cmd :: tl) cmds []
  )
  ;;implement quit (fun () -> ())
  ;;implement name (fun () -> E.name)
  ;;implement version (fun () -> E.version)
  ;;implement boardsize E.boardsize
  ;;implement clear_board E.clear_board
  ;;implement komi E.komi
  ;;implement play E.play
  ;;implement genmove  E.genmove

end

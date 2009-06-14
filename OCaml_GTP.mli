
(** An implementation of the Go Text Protocol (GTP). *)

(** This library implements the GTP protocol as described by {{:http://www.lysator.liu.se/~gunnar/gtp/gtp2-spec-draft2/gtp2-spec.html}this page}.

The protocol is asymmetric and involves two parties, which we call controller and engine. The controller is typically some kind of arbiter or relay and the engine is typically a go playing program. All communication is initiated by the controller in form of commands, to which the engine responds.
*)

(** Types used through-out the library. *)
module Types : sig
  type color = Black | White
  type vertex = Pass | Coordinate of (int * int)
  type ('a,'b) either = Left of 'a | Right of 'b
  exception Error_message of string
end

(** Predefined commands. *)
module Command : sig
  type ('a,'b) t
  (** Represents a command that takes an argument of type ['a] and outputs an answer of type ['b]. *)

  (** {2 Strings are special} *)

  type string_no_newline = string (** A string with no newlines. *)
  type string_no_space = string (** A string with no newlines or spaces (or tabs or CR). *)
  (** Other strings are allowed to contain spaces and newlines, {i but no empty lines}. *)
  
  (** {2 Commands} *)
  (** The semantic use of commands is described {{:http://www.lysator.liu.se/~gunnar/gtp/gtp2-spec-draft2/gtp2-spec.html#SECTION00073000000000000000}here}. *)

  val protocol_version : (unit, int) t
  val name : (unit, string_no_newline) t
  val version : (unit, string_no_newline) t
  val known_command : (string_no_space, bool) t
  val list_commands : (unit, string_no_space list) t
  val quit : (unit, unit) t
  val boardsize : (int, unit) t
  val clear_board : (unit, unit) t
  val komi : (float, unit) t
  val fixed_handicap : (int, Types.vertex list) t
  val place_free_handicap : (int, Types.vertex list) t
  val set_free_handicap : (Types.vertex list, unit) t
  val play : (Types.color * Types.vertex, unit) t
  val genmove : (Types.color, (Types.vertex, string_no_space) Types.either) t
  (** Output is either a {!Types.vertex} or the string ["resign"]. *)
  val undo : (unit, unit) t
  val time_settings : (int * (int * int), unit) t
  val time_left : (Types.color * (int * int), unit) t
  val final_score : (unit, string_no_space) t
  val final_status_list : (string_no_space, Types.vertex list list) t
  val loadsgf : (string_no_space * int, unit) t
  val reg_genmove : (Types.color, (Types.vertex, string_no_space) Types.either) t
  (** See {!genmove}. *)
  val showboard : (unit, string) t
end

(** Define your own commands. *)
module Private_extensions : sig
  type ('a,'b) spec

  val build_command : string ->
    argument:('a,[`nothing|`simple|`pair|`list|`alt]) spec ->
    output:('b,[`nothing|`simple|`pair|`list|`alt|`mlist]) spec ->
    ('a,'b) Command.t
  
  val nothing : (unit, [>`nothing]) spec
  (** Indicates the case where a command takes no arguments or return no output. *)

  (** {3 Simple entities} *)

  val int : (int, [>`simple]) spec (** Should not be negative. *)
  val float : (float, [>`simple]) spec
  val string : (Command.string_no_space, [>`simple]) spec (** Should not contain spaces or newlines! *)
  val vertex : (Types.vertex, [>`simple]) spec
  val color : (Types.color, [>`simple]) spec
  val boolean : (bool, [>`simple]) spec

  (** {3 Compound entities} *)

  val pair : ('a, [`simple]) spec -> ('b, [`simple|`pair]) spec -> ('a*'b, [>`pair]) spec
  (** A fixed sequence of simple entities. *)
  val list : ('a, [`simple|`pair]) spec -> ('a list, [>`list]) spec
  (** Space separated list. *)
  val alt : ('a, [`simple]) spec -> ('b, [`simple]) spec -> (('a,'b) Types.either, [>`alt]) spec
  (** Alternatives. *)
  val mlist : ('a, [`simple|`pair|`list|`alt]) spec -> ('a list, [>`mlist]) spec
  (** Newline separated list. *)

  (** {3 Convenience definitions for strings} *)

  val string_line : (Command.string_no_newline, [>`list]) spec (** String with spaces allowed. *)
  val string_multiline : (string, [>`mlist]) spec (** String with spaces and newlines allowed. But empty lines are not allowed. *)

end

(** For use by controllers. *)
module Controller : sig

  type connection
  (** A [connection] is a bi-directional communication channel with an engine. *)

  val open_connection : in_channel -> out_channel -> connection

  val command : connection -> ('a,'b) Command.t -> 'a -> 'b
  (** @raise OCaml_GTP.Types.Error_message if command fails. The error message is produced by the engine and can be any string. *)
end

(** For use by engines. *)
module Engine : sig
  module type ENGINE_BASE = sig
    val name : string
    val version : string
    val boardsize : int -> unit
    val clear_board : unit -> unit
    val komi : float -> unit
    val play : (Types.color * Types.vertex) -> unit
    val genmove : Types.color -> (Types.vertex,string) Types.either
  end

  module Make : functor (E:ENGINE_BASE) -> sig
    
    val run : in_channel -> out_channel -> unit
    (** [run in_ch out_ch] will listen for commands on [in_ch] and answer them on [out_ch] until {!val:OCaml_GTP.Command.quit} is recieved. *)

    val implement : ('a,'b) Command.t -> ('a -> 'b) -> unit
    (** [implement cmd f] implements [cmd] using [f]. If a previous implementation exists it is replaced.
        [f] should raise {!exception:OCaml_GTP.Types.Error_message} to indicate a failure to comply with the command.
     *)
    
    (** Default implementatins of {!val:OCaml_GTP.Command.protocol_version}, {!val:OCaml_GTP.Command.known_command}, {!val:OCaml_GTP.Command.list_commands} and {!val:OCaml_GTP.Command.quit} are provided.
        The functor argument is used to implement the remaining requiered commands.
        Use {!implement} if you need additional commands.
     *)

  end
end

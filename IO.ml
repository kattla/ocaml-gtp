
open Types

let get x = Obj.magic (x : opaque)
let put x = (Obj.magic x : opaque)

let to_string x = function
  | Int -> string_of_int (get x)
  | Float -> string_of_float (get x)
  | String -> get x
  | Boolean -> string_of_bool (get x)
  | Color ->
      ( match get x with
      | Black -> "black" | White -> "white"
      )
  | Vertex ->
      ( match get x with
      | Pass -> "pass"
      | Coordinate (x,y) ->
          let x = x + int_of_char 'a' in
          let x =
            if x < int_of_char 'i' then x else x + 1
          in
          String.make 1 (char_of_int x) ^
          string_of_int (y+1)
      )

module Read : sig
  
  exception Syntax_error

  type buf

  val from_channel : in_channel -> buf

  val comm : buf -> string option
  val comm_args : 'a Spec.comm -> buf -> 'a
  val ans : 'a Spec.ans -> buf -> 'a
  val recover_comm : buf -> unit
  val recover_ans : buf -> unit

end = struct

  exception Syntax_error

  type buf = (token Queue.t * Lexing.lexbuf)

  let from_channel chan =
    (Queue.create (), Lexing.from_channel chan)

  let read (q,lb) =
    try Queue.pop q with Queue.Empty ->
    Lexer.token lb

  let peek (q,lb) =
    try Queue.peek q with Queue.Empty ->
    let t = Lexer.token lb in
    Queue.push t q; t

  let pushback t (q,_) =
    let q' = Queue.copy q in
    Queue.clear q;
    Queue.push t q;
    Queue.transfer q' q

  let read_entity buf = match read buf with
    | E e -> e
    | NL -> raise Syntax_error
    | EOF -> raise End_of_file

  let read_nl buf = match read buf with
    | NL -> ()
    | E _ -> raise Syntax_error
    | EOF -> raise End_of_file

  let entity kind (kind', x) = match kind, kind' with
    | a,b when a = b -> x
    | a, String -> put (to_string x a)
    | _ -> raise Syntax_error

  let rec compound buf = function
    | Nothing -> put ()
    | Entity a -> entity a (read_entity buf)
    | Pair (a,b) ->
        let a = entity a (read_entity buf) in
        let b = compound buf b in
        put (a,b)
    | List a ->
        let rec f () = match peek buf with
          | E _ -> compound buf a :: f ()
          | NL -> []
          | EOF -> raise End_of_file
        in
        put (f ())
    | Alt (a,b) ->
        let x = read_entity buf in
        ( try put (Left (entity a x))
          with Syntax_error ->
          put (Right (entity b x))
        )
    | MList a ->
        let rec f () =
          let x = compound buf a in
          read_nl buf;
          match peek buf with
          | E _ -> x :: f ()
          | NL -> pushback NL buf; [x]
          | EOF -> raise End_of_file
        in
        put (f ())
    | String_line ->
        let l = compound buf (List (Entity String)) in
        put (String.concat " " (get l))
    | String_multiline ->
        let spec = MList (List (Entity String)) in
        let l = compound buf spec in
        let l = List.map (String.concat " ") (get l) in
        put (String.concat "\n" l)
  
  let rec ignore_newlines buf =
    match peek buf with
    | NL -> ignore (read buf); ignore_newlines buf
    | _ -> ()

  let comm buf =
    ignore_newlines buf;
    ( match peek buf with
    | E (Int,_) -> ignore (read buf)
    | _ -> ()
    );
    match read buf with
    | E (String, s) -> Some (get s : string)
    | EOF -> None
    | _ -> raise Syntax_error

  let comm_args spec buf =
    let spec = Spec.structure spec in
    let args = get (compound buf spec) in
    read_nl buf;
    args
  
  let ans spec buf =
    ignore_newlines buf;
    let spec = Spec.structure spec in
    let ans = match read_entity buf with
    | String, s ->
        ( match (get s).[0] with
        | '=' -> get (compound buf spec)
        | '?' ->
            let spec = MList (List (Entity String)) in
            let msg = List.map (String.concat " ") 
              (get (compound buf spec))
            in
            let msg = String.concat "\n" msg in
            raise (Error_message msg)
        | _ -> raise Syntax_error
        )
    | _ -> raise Syntax_error
    in
    read_nl buf;
    read_nl buf;
    ans

  let rec recover_comm buf =
    match read buf with
    | NL -> ()
    | EOF -> ()
    | E _ -> recover_comm buf

  let rec recover_ans buf =
    match read buf with
    | E _ -> recover_ans buf
    | EOF -> ()
    | NL ->
    match read buf with
    | NL -> ()
    | EOF -> ()
    | E _ -> recover_ans buf

end


module Write : sig

  val comm : out_channel -> string -> 'a Spec.comm -> 'a -> unit
  val ans : out_channel -> 'a Spec.ans -> 'a -> unit
  val error : out_channel -> string -> unit

end = struct

  let write chan s = output_string chan s; flush chan

  let entity chan x kind =
    write chan (to_string x kind)

  let rec compound chan x = function
    | Nothing -> ()
    | Entity a -> entity chan x a
    | Pair (a,b) ->
        let x,y = get x in
        entity chan x a;
        write chan " ";
        compound chan y b
    | List a ->
        let rec f = function
          | [] -> ()
          | [x] -> compound chan x a
          | x::xs ->
              compound chan x a; write chan " "; f xs
        in
        f (get x)
    | Alt (a,b) ->
        ( match get x with
        | Left x -> entity chan x a
        | Right x -> entity chan x b
        )
    | MList a ->
        let rec f = function
          | [] -> ()
          | [x] -> compound chan x a
          | x::xs ->
              compound chan x a; write chan "\n"; f xs
        in
        f (get x)
    | String_line -> write chan (get x)
    | String_multiline -> write chan (get x)

  let comm chan name spec x =
    let spec = Spec.structure spec in
    write chan name;
    write chan " "; (* is this ok? *)
    compound chan (put x) spec;
    write chan "\n"

  let ans chan spec x =
    let spec = Spec.structure spec in
    write chan "= ";
    compound chan (put x) spec;
    write chan "\n\n"

  let error chan msg =
    write chan "? ";
    write chan msg;
    write chan "\n\n"

end



type ('a,'b) spec
type comm_cap = [`nothing|`simple|`pair|`list|`alt]
type ans_cap = [`nothing|`simple|`pair|`list|`alt|`mlist]
type 'a comm = ('a, comm_cap) spec
type 'a ans = ('a, ans_cap) spec

val structure : ('a,'b) spec -> Types.compound_kind

val nothing : (unit, [>`nothing]) spec

val int : (int, [>`simple]) spec
val float : (float, [>`simple]) spec
val string : (string, [>`simple]) spec
val vertex : (Types.vertex, [>`simple]) spec
val color : (Types.color, [>`simple]) spec
val boolean : (bool, [>`simple]) spec

val pair : ('a, [`simple]) spec -> ('b, [`simple|`pair]) spec -> ('a*'b, [>`pair]) spec
val list : ('a, [`simple|`pair]) spec -> ('a list, [>`list]) spec
(* Spec Draft is not clear on alternatives *)
val alt : ('a, [`simple]) spec -> ('b, [`simple]) spec -> (('a,'b) Types.either, [>`alt]) spec
val mlist : ('a, [`simple|`pair|`list|`alt]) spec -> ('a list, [>`mlist]) spec

val string_line : (string, [>`list]) spec
val string_multiline : (string, [>`mlist]) spec

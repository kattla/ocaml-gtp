
to_install = META OCaml_GTP.mli _build/OCaml_GTP.cmi _build/ocaml-gtp.cma _build/ocaml-gtp.cmxa

.PHONY: all byte opt doc install uninstall

all: byte opt

byte:
	ocamlbuild ocaml-gtp.cma

opt:
	ocamlbuild ocaml-gtp.cmxa

doc:
	ocamlbuild ocaml-gtp.docdir/index.html

install: byte opt
	ocamlfind install ocaml-gtp $(to_install)

uninstall:
	ocamlfind remove ocaml-gtp

clean:
	ocamlbuild -clean

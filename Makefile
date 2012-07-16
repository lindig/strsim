
OCB = ocamlbuild

all:		strsim.native

strsim.native:
		$(OCB) $@

clean:
		$(OCB) -clean

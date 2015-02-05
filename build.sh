#!/bin/bash -xe

#build the target library
gcc -g -ansi -c -fPIC api/api.c -o api.o
gcc -g -shared -o libapi_c.so api.o

# compile the bindings and the code generator
ocamlfind opt -g -c  -package ctypes.stubs,ctypes.foreign api.ml api_rev.ml api_rev_generator.ml

# link and run the code generator
ocamlfind opt -linkpkg -package ctypes.stubs,ctypes.foreign api.cmx api_rev.cmx api_rev_generator.cmx -o gen
./gen

# compile the generated code
ocamlfind opt -g -c  -thread -package ctypes.stubs,ctypes.foreign \
          -I $(ocamlfind query ctypes)/.. ocaml_api.ml ocaml_api_stubs.c

# compile the pure ocaml backend
ocamlfind opt -g -c  -thread -package ctypes.stubs,ctypes.foreign \
          -I $(ocamlfind query ctypes)/.. pure.ml

# compile the ffi ocaml backend
ocamlfind opt -g -c  -thread -package ctypes.stubs,ctypes.foreign \
          -I $(ocamlfind query ctypes)/.. sniffer.ml

# build a shared library, with the pure ocaml backend
ocamlfind opt -thread -g -o libapi_pure_ml.so -linkpkg -output-obj \
   -package ctypes.stubs,ctypes.foreign \
   ocaml_api.cmx api.cmx api_rev.cmx ocaml_api_stubs.o pure.cmx

# build a shared library, with the sniffer ocaml backend
ocamlfind opt -thread -g -o libapi_ffi_ml.so -linkpkg -output-obj \
   -package ctypes.stubs,ctypes.foreign \
   ocaml_api.cmx api.cmx api_rev.cmx ocaml_api_stubs.o sniffer.cmx

OCAML=`opam config var prefix`
INCLUDE=$OCAML/lib/ocaml

# build the client
gcc -g -o main -I$INCLUDE -ldl -lpthread client/main.c -lm

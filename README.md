# Requires

```
opam switch 4.02.1+PIC
opam pin add  -k git ctypes.dev https://github.com/braibant/ocaml-ctypes.git#custom-inverted-stubs
```

# How to test

```
chmod u+x build.sh
build.sh
LD_LIBRARY_PATH=. ./main libapi_c.so #should work
LD_LIBRARY_PATH=. ./main libapi_ffi_ml.so #segfault
```

# Files

- `api/api.h` describes a very simple api that is illustrative of the
  kind of things we do with the PKCS#11 API.
- `api.ml` implements the ctypes bindings
- `api_rev_generator.ml` generates the reverse bindings code
- `api_rev.ml` the inverted bindings
- `build.sh`, the build script
- `client/main.c`, the client (main) library, which tests the library..

We use two flavor of the backend api:
- `api/api.c` implemented in C
- `pure.ml`, which implements the api, in - OCaml, and exposes it
using the reverse bindings .
- `sniffer.ml`, which is a man in the middle implementation, which
  routes the calls to the C implementation (using Foreign)

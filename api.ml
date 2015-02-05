open Ctypes

type _function_list
type function_list =  _function_list structure
let function_list : function_list typ = structure "FUNCTION_LIST"
module C =
struct

  (* contains the type declaration for all the functions *)
  module T = struct
    let c_arith = int @-> int @-> returning int
    let c_print = string @-> returning int
    let c_function_list = ptr (ptr function_list) @-> returning int

  end

  module FunctionList =
  struct

    let (-:) ty label = field function_list label (Foreign.funptr ~runtime_lock:true ty)
    let c_arith = T.c_arith -: "c_arith"
    let c_print = T.c_print -: "c_print"
    let c_function_list = T.c_function_list -: "c_function_list"
    let () = seal function_list
  end
end

module type RAW =
sig
  val c_arith : int -> int -> int
  val c_print : string -> int
  val c_function_list: function_list ptr ptr -> int
end

(* Bindings Maker: declare all the functions except [c_function_list] *)
module Raw(D: sig
             val declare: string ->
               ('a -> 'b, function_list) Ctypes.field ->
               ('a -> 'b) Ctypes.fn ->
               'a -> 'b
             val c_function_list : function_list ptr ptr -> int
           end
          ) : RAW
= struct
  module S = C.FunctionList
  let c_function_list = D.c_function_list
  let c_arith = D.declare "c_arith" S.c_arith C.T.c_arith
  let c_print = D.declare "c_print" S.c_print C.T.c_print
end

(* Configuration *)
module type CONFIG =
sig
  val library : Dl.library
end

(******************************************************************************)
(*                                Direct style                                *)
(******************************************************************************)

module Direct (X: CONFIG) : RAW =
struct


  let declare : 'a 'b . string -> ('a -> 'b) Ctypes.fn -> ('a -> 'b) = fun name typ ->
    Foreign.foreign ~release_runtime_lock:false ~from:X.library ~stub:true name typ

  let c_function_list = declare "c_function_list" C.T.c_function_list

  include Raw(struct
      let declare name _field typ = declare name typ
      let c_function_list = c_function_list
    end)
end

(******************************************************************************)
(*                            Local style bindings                           *)
(******************************************************************************)

module Local (X : sig  end) : RAW =
struct


  let declare : 'a 'b . string -> ('a -> 'b) Ctypes.fn -> ('a -> 'b) = fun name typ callback ->
    let () = Callback.register name callback in
    Foreign.foreign ~release_runtime_lock:false name typ callback

  let c_function_list = declare "c_function_list" C.T.c_function_list

  include Raw(struct
      let declare name _field typ = declare name typ
      let c_function_list = c_function_list
    end)
end

(******************************************************************************)
(*                                    Pure                                    *)
(******************************************************************************)

module Pure = struct
  let c_arith a b = a + b
  let c_print s = Printf.printf "in ml: %s\n%!" s; 0
  let c_function_list pp_fl = assert false
end

(******************************************************************************)
(*                                   Wrapper                                  *)
(******************************************************************************)

let load ~dll =
  let module C =
  struct
    let library = Dl.dlopen ~filename: dll ~flags: [ Dl.RTLD_LAZY; Dl.RTLD_DEEPBIND]
  end
  in
  (module (Direct(C)) : RAW)

module Static = Api.Local()

open Ctypes

exception Null_pointer

let safe_deref p =
  if Ctypes.ptr_compare (to_voidp p) null = 0
  then raise Null_pointer
  else Ctypes.(!@) p

let (!@) = safe_deref

module Make (Impl: Api.RAW) = struct

  include Impl

  let allocate_function_list () = Ctypes.allocate_n (Api.function_list) ~count:1

  let cache = ref None

  let update_function_list fl =
    Ctypes.setf fl Api.C.FunctionList.c_arith Impl.c_arith;
    Ctypes.setf fl Api.C.FunctionList.c_print Impl.c_print;
    Ctypes.setf fl Api.C.FunctionList.c_function_list Impl.c_function_list;
    ()

  let c_function_list pp_fl =
    Printf.printf "ffi: get_function_list\n%!";
    ignore (Impl.c_function_list pp_fl);
    let real_ptr = !@ pp_fl in
    let real_struct = !@ real_ptr in
    (* we must allocate our own memory *)
    begin match !cache with
    | None ->
      let ptr = allocate_function_list () in
      update_function_list (!@ ptr);
      cache := Some ptr;
      pp_fl <-@ ptr
    | Some ptr ->
      pp_fl <-@ ptr
    end;
    0
end

(* build the implem *)
module I = (val (Api.load ~dll:"libapi_c.so"))
(* wrap the sniffer around the imple *)
module W = Make(I)
(* register callbacks *)
module M = Api_rev.RevBindings(W)(Ocaml_api)
(* ensure thread is linked *)
let (_: Thread.t) = Thread.self ()
let _ = Printf.printf "ffi initialized\n%!"

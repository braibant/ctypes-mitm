(* toplevel ref to store value that should not be garbages collected *)
let roots = ref []
module RevBindings(Callback : Api.RAW)(I: Cstubs_inverted.INTERNAL) = struct

  let declare name signature cb =
    (* Format.eprintf "registering function %S@." name; *)
    roots := Obj.repr cb :: !roots;
    I.internal name signature cb

  let c_arith = declare "c_arith"  Api.C.T.c_arith Callback.c_arith
  let c_print = declare "c_print"  Api.C.T.c_print Callback.c_print
  let c_function_list = declare "c_function_list"  Api.C.T.c_function_list Callback.c_function_list
end

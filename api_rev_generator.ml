open Format

let with_formatter filename f =
  let fd = open_out filename in
  let fmt = formatter_of_out_channel fd in
  f fmt;
  close_out fd

let () =
  let module Bindings = Api_rev.RevBindings(Api.Local()) in
  let filename_prefix = "ocaml_api" in
  let file ext = filename_prefix ^ ext in
  let prefix = "ocaml_api" in

  let stubs_h = file "_stubs.h" in
  let stubs_c = file "_stubs.c" in
  let ml = file ".ml" in
  let outl fmt l = List.iter (Format.fprintf fmt "%s\n") l in

  let options = Cstubs_inverted.configure_options
      ~use_runtime_system_lock:true
      ~use_register_thread:true
  in
  begin
    with_formatter stubs_c (fun fmt ->

        let empty _ = ""
        and ident s = s in
        let lin = if Sys.unix then ident else empty in
        let win = if (Sys.win32 || Sys.cygwin) then ident else empty in
        let all s = s in

        (* generated c code *)

        outl fmt
          [all "#include \"api/api.h\""];

        Cstubs_inverted.write_c ~options fmt ~prefix (module Bindings);

        (* initialization of the dll *)
        (* We must initialize the caml runtime *)
        outl fmt [
          win "#include <windows.h>";
          lin "#define _GNU_SOURCE";
          (* Setting _GNU_SOURCE doesn't seems to work.
             So we need to set __USE_GNU *)
          lin "#define __USE_GNU";
          lin "#include <dlfcn.h>";
          lin "#include <string.h>";
          all "#include <stdio.h>";
          all "#include <caml/fail.h>";


          (* initialization function *)
          all "static void initialize_ocaml_runtime(){";
          all "  printf(\"init\\n\");";
          all "  fflush(stdout);";
          all "  char *caml_argv[1] = { NULL };";
          all "  caml_startup(caml_argv);";
          all "  caml_release_runtime_system();";
          all "  fflush(stdout);";
          all "}";

          (* unload function *)
          all "static void finalize_ocaml_runtime(){";
          all "  value * at_exit = caml_named_value(\"Pervasives.do_at_exit\");";
          all "  if (at_exit != NULL) caml_callback_exn(*at_exit, Val_unit);";
          all "}";

          (* dll_path *)
          all "char * caml_dll_path = NULL;";
          all "CAMLprim value caml_get_dll_path(value unit){";
          all "  CAMLparam0 ();   /* unit is unused */";
          all "  if(caml_dll_path == NULL) caml_raise_not_found();";
          all "  CAMLreturn(caml_copy_string(caml_dll_path));";
          all "}";

          (* inialization for linux *)
          lin "__attribute__((constructor))";
          lin "static void initialize_dll(){";
          lin "  Dl_info dl_info;";
          lin "  dladdr((void *)initialize_ocaml_runtime, &dl_info);";
          lin "  char* name = malloc(strlen(dl_info.dli_fname)+1);";
          lin "  if(name) {";
          lin "    strcpy(name,dl_info.dli_fname);";
          lin "    caml_dll_path = name;";
          lin "  }";
          lin "  initialize_ocaml_runtime();";
          lin "}";

          lin "__attribute__((destructor))";
          lin "static void finalize_dll(){";
          lin "  finalize_ocaml_runtime();";
          lin "}";

          (* inialization for windows *)
          win "BOOL WINAPI DllMain(";
          win "_In_ HINSTANCE hinstDLL,";
          win "_In_ DWORD fdwReason,";
          win "_In_ LPVOID lpvReserved";
          win ")";
          win "{";
          win "  TCHAR buffer[MAX_PATH];";
          win "  switch (fdwReason)";
          win "  {";
          win "    case DLL_PROCESS_ATTACH:";
          win "      GetModuleFileName(hinstDLL, buffer, MAX_PATH);";
          win "      caml_dll_path = buffer; ";
          win "      initialize_ocaml_runtime();";
          win "      break;";
          win "    case DLL_THREAD_ATTACH:";
          win "      break;";
          win "    case DLL_PROCESS_DETACH:";
          win "      finalize_ocaml_runtime();";
          win "      break;";
          win "    case DLL_THREAD_DETACH:";
          win "      break;";
          win "  }";
          win "  return TRUE;";
          win "}";
        ]
      );

    (* output ml file *)
    with_formatter ml
      (fun fmt ->
         Cstubs_inverted.write_ml fmt ~prefix (module Bindings)
      );
  end

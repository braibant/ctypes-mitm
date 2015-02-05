let (_: Thread.t) = Thread.self ()

module M = Api_rev.RevBindings(Api.Pure)(Ocaml_api)

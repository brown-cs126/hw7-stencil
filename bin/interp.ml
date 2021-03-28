open Core
open Csci1260

let command =
  Command.basic ~summary:"Interpret the given file"
    Command.Let_syntax.(
      let%map_open filename = anon (maybe ("filename" %: Filename.arg_type))
      and expression =
        flag "-e" (optional string) ~doc:"lisp expression to evaluate"
      in
      fun () ->
        try
          match (filename, expression) with
          | Some f, _ ->
              let text = In_channel.read_all f in
              let ast =
                if Filename.check_suffix f ".mlb" then Mlb_syntax.parse text
                else Lisp_syntax.parse text
              in
              ast |> Interp.interp ; print_endline ""
          | _, Some e ->
              Lisp_syntax.parse e |> Interp.interp ;
              print_endline ""
          | _ ->
              Printf.eprintf
                "Error: must specify either an expression to evaluate or a file\n"
        with e -> Printf.eprintf "Error: %s\n" (Exn.to_string e))

let () = Command.run ~version:"1.0" command

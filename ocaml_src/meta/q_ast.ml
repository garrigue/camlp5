(* camlp5r pa_macro.cmo *)
(* This file has been generated by program: do not edit! *)
(* Copyright (c) INRIA 2007 *)

(* Experimental AST quotations while running the normal parser and
   its possible extensions and meta-ifying the nodes. Antiquotations
   work only in "strict" mode. *)

(* #load "pa_extend.cmo";; *)
(* #load "q_MLast.cmo";; *)

let not_impl f x =
  let desc =
    if Obj.is_block (Obj.repr x) then
      "tag = " ^ string_of_int (Obj.tag (Obj.repr x))
    else "int_val = " ^ string_of_int (Obj.magic x)
  in
  failwith ("q_ast.ml: " ^ f ^ ", not impl: " ^ desc)
;;

let call_with r v f a =
  let saved = !r in
  try r := v; let b = f a in r := saved; b with e -> r := saved; raise e
;;

let eval_anti entry loc typ str =
  let r =
    call_with Plexer.force_antiquot_loc false (Grammar.Entry.parse entry)
      (Stream.of_string str)
  in
  let loc =
    let sh =
      if typ = "" then String.length "$"
      else String.length "$" + String.length typ + String.length ":"
    in
    let len = String.length str in Ploc.sub loc sh len
  in
  loc, r
;;

let get_anti_loc s =
  try
    let i = String.index s ':' in
    let (j, len) =
      let rec loop j =
        if j = String.length s then i, 0
        else
          match s.[j] with
            ':' -> j, j - i - 1
          | 'a'..'z' | 'A'..'Z' | '0'..'9' | '_' -> loop (j + 1)
          | _ -> i, 0
      in
      loop (i + 1)
    in
    let kind = String.sub s (i + 1) len in
    let loc =
      let k = String.index s ',' in
      let bp = int_of_string (String.sub s 0 k) in
      let ep = int_of_string (String.sub s (k + 1) (i - k - 1)) in
      Ploc.make_unlined (bp, ep)
    in
    Some (loc, kind, String.sub s (j + 1) (String.length s - j - 1))
  with Not_found | Failure _ -> None
;;

let expr_eoi = Grammar.Entry.create Pcaml.gram "expr";;
let patt_eoi = Grammar.Entry.create Pcaml.gram "patt";;
let ctyp_eoi = Grammar.Entry.create Pcaml.gram "type";;
let str_item_eoi = Grammar.Entry.create Pcaml.gram "str_item";;
let sig_item_eoi = Grammar.Entry.create Pcaml.gram "sig_item";;
let module_expr_eoi = Grammar.Entry.create Pcaml.gram "module_expr";;

(*
(* upper bound of tags of all syntax tree nodes *)
value anti_tag = 100;

value make_anti loc t s = do {
  let r = Obj.new_block anti_tag 3 in
  Obj.set_field r 0 (Obj.repr (loc : Ploc.t));
  Obj.set_field r 1 (Obj.repr (t : string));
  Obj.set_field r 2 (Obj.repr (s : string));
  Obj.magic r
};

value get_anti v =
  if Obj.tag (Obj.repr v) = anti_tag && Obj.size (Obj.repr v) = 3 then
    let loc : Ploc.t = Obj.magic (Obj.field (Obj.repr v) 0) in
    let t : string = Obj.magic (Obj.field (Obj.repr v) 1) in
    let s : string = Obj.magic (Obj.field (Obj.repr v) 2) in
    Some (loc, t, s)
  else None
;
*)

let make_anti loc t s = failwith "not impl: make_anti";;
let get_anti v = None;;

module Meta =
  struct
    open MLast;;
    let loc = Ploc.dummy;;
    let ln () = MLast.ExLid (loc, !(Ploc.name));;
    let e_vala elem e = elem e;;
    let p_vala elem p = elem p;;
    let e_list elem el =
      let rec loop el =
        match el with
          [] -> MLast.ExUid (loc, "[]")
        | e :: el ->
            MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExUid (loc, "::"), elem e),
               loop el)
      in
      loop el
    ;;
    let p_list elem el =
      let rec loop el =
        match el with
          [] -> MLast.PaUid (loc, "[]")
        | e :: el ->
            MLast.PaApp
              (loc, MLast.PaApp (loc, MLast.PaUid (loc, "::"), elem e),
               loop el)
      in
      loop el
    ;;
    let e_option elem oe =
      match oe with
        None -> MLast.ExUid (loc, "None")
      | Some e -> MLast.ExApp (loc, MLast.ExUid (loc, "Some"), elem e)
    ;;
    let p_option elem oe =
      match get_anti oe with
        Some (loc, typ, str) ->
          let (loc, r) = eval_anti patt_eoi loc typ str in
          MLast.PaAnt (loc, r)
      | None ->
          match oe with
            None -> MLast.PaUid (loc, "None")
          | Some e -> MLast.PaApp (loc, MLast.PaUid (loc, "Some"), elem e)
    ;;
    let e_bool b =
      match get_anti b with
        Some (loc, typ, str) ->
          let (loc, r) = eval_anti expr_eoi loc typ str in
          MLast.ExAnt (loc, r)
      | None ->
          if b then MLast.ExUid (loc, "True") else MLast.ExUid (loc, "False")
    ;;
    let p_bool b =
      match get_anti b with
        Some (loc, typ, str) ->
          let (loc, r) = eval_anti patt_eoi loc typ str in
          MLast.PaAnt (loc, r)
      | None ->
          if b then MLast.PaUid (loc, "True") else MLast.PaUid (loc, "False")
    ;;
    let e_string s = MLast.ExStr (loc, s);;
    let p_string s =
      match get_anti s with
        Some (loc, typ, str) ->
          let (loc, r) = eval_anti patt_eoi loc typ str in
          MLast.PaAnt (loc, r)
      | None -> MLast.PaStr (loc, s)
    ;;
    let e_ctyp t =
      let ln = ln () in
      let rec loop t =
        match get_anti t with
          Some (loc, typ, str) ->
            let r =
              let (loc, r) = eval_anti expr_eoi loc typ str in
              MLast.ExAnt (loc, r)
            in
            begin match typ with
              "" -> r
            | x -> not_impl ("e_ctyp anti " ^ x) 0
            end
        | None ->
            match t with
              TyAcc (_, t1, t2) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExApp
                        (loc,
                         MLast.ExAcc
                           (loc, MLast.ExUid (loc, "MLast"),
                            MLast.ExUid (loc, "TyAcc")),
                         ln),
                      loop t1),
                   loop t2)
            | TyAny _ ->
                MLast.ExApp
                  (loc,
                   MLast.ExAcc
                     (loc, MLast.ExUid (loc, "MLast"),
                      MLast.ExUid (loc, "TyAny")),
                   ln)
            | TyApp (_, t1, t2) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExApp
                        (loc,
                         MLast.ExAcc
                           (loc, MLast.ExUid (loc, "MLast"),
                            MLast.ExUid (loc, "TyApp")),
                         ln),
                      loop t1),
                   loop t2)
            | TyLid (_, s) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExAcc
                        (loc, MLast.ExUid (loc, "MLast"),
                         MLast.ExUid (loc, "TyLid")),
                      ln),
                   e_string s)
            | TyQuo (_, s) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExAcc
                        (loc, MLast.ExUid (loc, "MLast"),
                         MLast.ExUid (loc, "TyQuo")),
                      ln),
                   e_string s)
            | TyUid (_, s) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExAcc
                        (loc, MLast.ExUid (loc, "MLast"),
                         MLast.ExUid (loc, "TyUid")),
                      ln),
                   e_string s)
            | x -> not_impl "e_ctyp" x
      in
      loop t
    ;;
    let p_ctyp x = not_impl "p_ctyp" x;;
    let e_patt p =
      let ln = ln () in
      let rec loop p =
        match get_anti p with
          Some (loc, typ, str) ->
            let r =
              let (loc, r) = eval_anti expr_eoi loc typ str in
              MLast.ExAnt (loc, r)
            in
            begin match typ with
              "" -> r
            | "anti" ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExAcc
                        (loc, MLast.ExUid (loc, "MLast"),
                         MLast.ExUid (loc, "PaAnt")),
                      ln),
                   r)
            | x -> not_impl ("e_patt anti " ^ x) 0
            end
        | None ->
            match p with
              PaAcc (_, p1, p2) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExApp
                        (loc,
                         MLast.ExAcc
                           (loc, MLast.ExUid (loc, "MLast"),
                            MLast.ExUid (loc, "PaAcc")),
                         ln),
                      loop p1),
                   loop p2)
            | PaAli (_, p1, p2) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExApp
                        (loc,
                         MLast.ExAcc
                           (loc, MLast.ExUid (loc, "MLast"),
                            MLast.ExUid (loc, "PaAli")),
                         ln),
                      loop p1),
                   loop p2)
            | PaAny _ ->
                MLast.ExApp
                  (loc,
                   MLast.ExAcc
                     (loc, MLast.ExUid (loc, "MLast"),
                      MLast.ExUid (loc, "PaAny")),
                   ln)
            | PaApp (_, p1, p2) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExApp
                        (loc,
                         MLast.ExAcc
                           (loc, MLast.ExUid (loc, "MLast"),
                            MLast.ExUid (loc, "PaApp")),
                         ln),
                      loop p1),
                   loop p2)
            | PaChr (_, s) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExAcc
                        (loc, MLast.ExUid (loc, "MLast"),
                         MLast.ExUid (loc, "PaChr")),
                      ln),
                   e_string s)
            | PaInt (_, s, k) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExApp
                        (loc,
                         MLast.ExAcc
                           (loc, MLast.ExUid (loc, "MLast"),
                            MLast.ExUid (loc, "PaInt")),
                         ln),
                      e_string s),
                   MLast.ExStr (loc, k))
            | PaLid (_, s) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExAcc
                        (loc, MLast.ExUid (loc, "MLast"),
                         MLast.ExUid (loc, "PaLid")),
                      ln),
                   e_string s)
            | PaOrp (_, p1, p2) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExApp
                        (loc,
                         MLast.ExAcc
                           (loc, MLast.ExUid (loc, "MLast"),
                            MLast.ExUid (loc, "PaOrp")),
                         ln),
                      loop p1),
                   loop p2)
            | PaRng (_, p1, p2) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExApp
                        (loc,
                         MLast.ExAcc
                           (loc, MLast.ExUid (loc, "MLast"),
                            MLast.ExUid (loc, "PaRng")),
                         ln),
                      loop p1),
                   loop p2)
            | PaStr (_, s) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExAcc
                        (loc, MLast.ExUid (loc, "MLast"),
                         MLast.ExUid (loc, "PaStr")),
                      ln),
                   e_string s)
            | PaTup (_, pl) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExAcc
                        (loc, MLast.ExUid (loc, "MLast"),
                         MLast.ExUid (loc, "PaTup")),
                      ln),
                   e_list loop pl)
            | PaTyc (_, p, t) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExApp
                        (loc,
                         MLast.ExAcc
                           (loc, MLast.ExUid (loc, "MLast"),
                            MLast.ExUid (loc, "PaTyc")),
                         ln),
                      loop p),
                   e_ctyp t)
            | PaUid (_, s) ->
                MLast.ExApp
                  (loc,
                   MLast.ExApp
                     (loc,
                      MLast.ExAcc
                        (loc, MLast.ExUid (loc, "MLast"),
                         MLast.ExUid (loc, "PaUid")),
                      ln),
                   e_string s)
            | x -> not_impl "e_patt" x
      in
      loop p
    ;;
    let p_patt =
      let rec loop p =
        match get_anti p with
          Some (loc, typ, str) ->
            let r =
              let (loc, r) = eval_anti patt_eoi loc typ str in
              MLast.PaAnt (loc, r)
            in
            begin match typ with
              "" -> r
            | x -> not_impl ("p_patt anti " ^ x) 0
            end
        | None ->
            match p with
              PaAcc (_, p1, p2) ->
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaApp
                        (loc,
                         MLast.PaAcc
                           (loc, MLast.PaUid (loc, "MLast"),
                            MLast.PaUid (loc, "PaAcc")),
                         MLast.PaAny loc),
                      loop p1),
                   loop p2)
            | PaAli (_, p1, p2) ->
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaApp
                        (loc,
                         MLast.PaAcc
                           (loc, MLast.PaUid (loc, "MLast"),
                            MLast.PaUid (loc, "PaAli")),
                         MLast.PaAny loc),
                      loop p1),
                   loop p2)
            | PaChr (_, s) ->
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaAcc
                        (loc, MLast.PaUid (loc, "MLast"),
                         MLast.PaUid (loc, "PaChr")),
                      MLast.PaAny loc),
                   p_string s)
            | PaLid (_, s) ->
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaAcc
                        (loc, MLast.PaUid (loc, "MLast"),
                         MLast.PaUid (loc, "PaLid")),
                      MLast.PaAny loc),
                   p_string s)
            | PaTup (_, pl) ->
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaAcc
                        (loc, MLast.PaUid (loc, "MLast"),
                         MLast.PaUid (loc, "PaTup")),
                      MLast.PaAny loc),
                   p_list loop pl)
            | x -> not_impl "p_patt" x
      in
      loop
    ;;
    let rec e_expr e =
      let ln = ln () in
      let rec loop =
        function
          ExAcc (_, e1, e2) ->
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExApp
                    (loc,
                     MLast.ExAcc
                       (loc, MLast.ExUid (loc, "MLast"),
                        MLast.ExUid (loc, "ExAcc")),
                     ln),
                  loop e1),
               loop e2)
        | ExApp (_, e1, e2) ->
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExApp
                    (loc,
                     MLast.ExAcc
                       (loc, MLast.ExUid (loc, "MLast"),
                        MLast.ExUid (loc, "ExApp")),
                     ln),
                  loop e1),
               loop e2)
        | ExChr (_, s) ->
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExAcc
                    (loc, MLast.ExUid (loc, "MLast"),
                     MLast.ExUid (loc, "ExChr")),
                  ln),
               e_string s)
        | ExInt (_, s, k) ->
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExApp
                    (loc,
                     MLast.ExAcc
                       (loc, MLast.ExUid (loc, "MLast"),
                        MLast.ExUid (loc, "ExInt")),
                     ln),
                  e_string s),
               MLast.ExStr (loc, k))
        | ExFun (_, pwel) ->
            let pwel =
              e_list
                (fun (p, oe, e) ->
                   MLast.ExTup (loc, [e_patt p; e_option loop oe; loop e]))
                pwel
            in
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExAcc
                    (loc, MLast.ExUid (loc, "MLast"),
                     MLast.ExUid (loc, "ExFun")),
                  ln),
               pwel)
        | ExLet (_, rf, lpe, e) ->
            let rf = e_bool rf in
            let lpe =
              e_list (fun (p, e) -> MLast.ExTup (loc, [e_patt p; loop e])) lpe
            in
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExApp
                    (loc,
                     MLast.ExApp
                       (loc,
                        MLast.ExAcc
                          (loc, MLast.ExUid (loc, "MLast"),
                           MLast.ExUid (loc, "ExLet")),
                        ln),
                     rf),
                  lpe),
               loop e)
        | ExLid (_, s) ->
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExAcc
                    (loc, MLast.ExUid (loc, "MLast"),
                     MLast.ExUid (loc, "ExLid")),
                  ln),
               e_vala e_string s)
        | ExMat (_, e, pwel) ->
            let pwel =
              e_list
                (fun (p, oe, e) ->
                   MLast.ExTup (loc, [e_patt p; e_option loop oe; loop e]))
                pwel
            in
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExApp
                    (loc,
                     MLast.ExAcc
                       (loc, MLast.ExUid (loc, "MLast"),
                        MLast.ExUid (loc, "ExMat")),
                     ln),
                  loop e),
               pwel)
        | ExStr (_, s) ->
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExAcc
                    (loc, MLast.ExUid (loc, "MLast"),
                     MLast.ExUid (loc, "ExStr")),
                  ln),
               e_string s)
        | ExTup (_, el) ->
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExAcc
                    (loc, MLast.ExUid (loc, "MLast"),
                     MLast.ExUid (loc, "ExTup")),
                  ln),
               e_list loop el)
        | ExTyc (_, e, t) ->
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExApp
                    (loc,
                     MLast.ExAcc
                       (loc, MLast.ExUid (loc, "MLast"),
                        MLast.ExUid (loc, "ExTyc")),
                     ln),
                  loop e),
               e_ctyp t)
        | ExUid (_, s) ->
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExAcc
                    (loc, MLast.ExUid (loc, "MLast"),
                     MLast.ExUid (loc, "ExUid")),
                  ln),
               e_string s)
        | x -> not_impl "e_expr" x
      in
      loop e
    ;;
    let p_expr e =
      let rec loop e =
        match get_anti e with
          Some (loc, typ, str) ->
            let r =
              let (loc, r) = eval_anti patt_eoi loc typ str in
              MLast.PaAnt (loc, r)
            in
            begin match typ with
              "" -> r
            | x -> not_impl ("p_expr anti " ^ x) 0
            end
        | None ->
            match e with
              ExAcc (_, e1, e2) ->
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaApp
                        (loc,
                         MLast.PaAcc
                           (loc, MLast.PaUid (loc, "MLast"),
                            MLast.PaUid (loc, "ExAcc")),
                         MLast.PaAny loc),
                      loop e1),
                   loop e2)
            | ExApp (_, e1, e2) ->
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaApp
                        (loc,
                         MLast.PaAcc
                           (loc, MLast.PaUid (loc, "MLast"),
                            MLast.PaUid (loc, "ExApp")),
                         MLast.PaAny loc),
                      loop e1),
                   loop e2)
            | ExLet (_, rf, lpe, e) ->
                let rf = p_bool rf in
                let lpe =
                  p_list (fun (p, e) -> MLast.PaTup (loc, [p_patt p; loop e]))
                    lpe
                in
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaApp
                        (loc,
                         MLast.PaApp
                           (loc,
                            MLast.PaAcc
                              (loc, MLast.PaUid (loc, "MLast"),
                               MLast.PaUid (loc, "ExLet")),
                            MLast.PaAny loc),
                         rf),
                      lpe),
                   loop e)
            | ExRec (_, lpe, oe) ->
                let lpe =
                  p_list (fun (p, e) -> MLast.PaTup (loc, [p_patt p; loop e]))
                    lpe
                in
                let oe = p_option loop oe in
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaApp
                        (loc,
                         MLast.PaAcc
                           (loc, MLast.PaUid (loc, "MLast"),
                            MLast.PaUid (loc, "ExRec")),
                         MLast.PaAny loc),
                      lpe),
                   oe)
            | ExLid (_, s) ->
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaAcc
                        (loc, MLast.PaUid (loc, "MLast"),
                         MLast.PaUid (loc, "ExLid")),
                      MLast.PaAny loc),
                   p_vala p_string s)
            | ExStr (_, s) ->
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaAcc
                        (loc, MLast.PaUid (loc, "MLast"),
                         MLast.PaUid (loc, "ExStr")),
                      MLast.PaAny loc),
                   p_string s)
            | ExTup (_, el) ->
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaAcc
                        (loc, MLast.PaUid (loc, "MLast"),
                         MLast.PaUid (loc, "ExTup")),
                      MLast.PaAny loc),
                   p_list loop el)
            | ExUid (_, s) ->
                MLast.PaApp
                  (loc,
                   MLast.PaApp
                     (loc,
                      MLast.PaAcc
                        (loc, MLast.PaUid (loc, "MLast"),
                         MLast.PaUid (loc, "ExUid")),
                      MLast.PaAny loc),
                   p_string s)
            | x -> not_impl "p_expr" x
      in
      loop e
    ;;
    let e_sig_item x = not_impl "e_sig_item" x;;
    let rec e_str_item si =
      let ln = ln () in
      let rec loop =
        function
          StVal (_, rf, lpe) ->
            let lpe =
              e_list (fun (p, e) -> MLast.ExTup (loc, [e_patt p; e_expr e]))
                lpe
            in
            MLast.ExApp
              (loc,
               MLast.ExApp
                 (loc,
                  MLast.ExApp
                    (loc,
                     MLast.ExAcc
                       (loc, MLast.ExUid (loc, "MLast"),
                        MLast.ExUid (loc, "StVal")),
                     ln),
                  e_vala e_bool rf),
               lpe)
        | x -> not_impl "e_str_item" x
      in
      loop si
    and p_str_item x = not_impl "p_str_item" x
    and e_module_expr me =
      (*
            let ln = ln () in
      *)
      let rec loop x = not_impl "e_module_expr" x in loop me
    and p_module_expr x = not_impl "p_module_expr" x;;
    let p_sig_item x = not_impl "p_sig_item" x;;
  end
;;

Grammar.extend
  [Grammar.Entry.obj (expr_eoi : 'expr_eoi Grammar.Entry.e), None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj (Pcaml.expr : 'Pcaml__expr Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__expr) (loc : Ploc.t) -> (x : 'expr_eoi))]];
   Grammar.Entry.obj (patt_eoi : 'patt_eoi Grammar.Entry.e), None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj (Pcaml.patt : 'Pcaml__patt Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__patt) (loc : Ploc.t) -> (x : 'patt_eoi))]];
   Grammar.Entry.obj (ctyp_eoi : 'ctyp_eoi Grammar.Entry.e), None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj (Pcaml.ctyp : 'Pcaml__ctyp Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__ctyp) (loc : Ploc.t) -> (x : 'ctyp_eoi))]];
   Grammar.Entry.obj (sig_item_eoi : 'sig_item_eoi Grammar.Entry.e), None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj
           (Pcaml.sig_item : 'Pcaml__sig_item Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__sig_item) (loc : Ploc.t) -> (x : 'sig_item_eoi))]];
   Grammar.Entry.obj (str_item_eoi : 'str_item_eoi Grammar.Entry.e), None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj
           (Pcaml.str_item : 'Pcaml__str_item Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__str_item) (loc : Ploc.t) -> (x : 'str_item_eoi))]];
   Grammar.Entry.obj (module_expr_eoi : 'module_expr_eoi Grammar.Entry.e),
   None,
   [None, None,
    [[Gramext.Snterm
        (Grammar.Entry.obj
           (Pcaml.module_expr : 'Pcaml__module_expr Grammar.Entry.e));
      Gramext.Stoken ("EOI", "")],
     Gramext.action
       (fun _ (x : 'Pcaml__module_expr) (loc : Ploc.t) ->
          (x : 'module_expr_eoi))]]];;

(* *)

(*
let mod_ident = Grammar.Entry.find Pcaml.str_item "mod_ident" in
EXTEND
  mod_ident: FIRST
    [ [ s = ANTIQUOT_LOC "" -> Obj.repr s ] ]
  ;
END;

value check_anti s kind =
  if String.length s > String.length kind then
    if String.sub s 0 (String.length kind + 1) = kind ^ ":" then s
    else raise Stream.Failure
  else raise Stream.Failure
;
*)

let check_anti_loc s kind =
  try
    let i = String.index s ':' in
    let (j, len) =
      let rec loop j =
        if j = String.length s then i, 0
        else
          match s.[j] with
            ':' -> j, j - i - 1
          | 'a'..'z' | 'A'..'Z' | '0'..'9' | '_' -> loop (j + 1)
          | _ -> i, 0
      in
      loop (i + 1)
    in
    if String.sub s (i + 1) len = kind then
      let loc =
        let k = String.index s ',' in
        let bp = int_of_string (String.sub s 0 k) in
        let ep = int_of_string (String.sub s (k + 1) (i - k - 1)) in
        Ploc.make_unlined (bp, ep)
      in
      loc, String.sub s (j + 1) (String.length s - j - 1)
    else raise Stream.Failure
  with Not_found | Failure _ -> raise Stream.Failure
;;

let check_anti_loc2 s =
  try
    let i = String.index s ':' in
    let (j, len) =
      let rec loop j =
        if j = String.length s then i, 0
        else
          match s.[j] with
            ':' -> j, j - i - 1
          | 'a'..'z' | 'A'..'Z' | '0'..'9' | '_' -> loop (j + 1)
          | _ -> i, 0
      in
      loop (i + 1)
    in
    String.sub s (i + 1) len
  with Not_found | Failure _ -> raise Stream.Failure
;;

let check_and_make_anti prm typ =
  let (loc, str) = check_anti_loc prm typ in make_anti loc typ str
;;

(* Need adding in grammar.ml in Slist* cases:
      let pa = parser_of_token entry ("LIST", "") in
   and
      [: a = pa :] -> a
   in their parsers. Same for OPT and FLAG. *)

let lex = Grammar.glexer Pcaml.gram in
let tok_match = lex.Plexing.tok_match in
lex.Plexing.tok_match <-
  function
    "ANTIQUOT_LOC", p_prm ->
      (function
         "ANTIQUOT_LOC", prm -> snd (check_anti_loc prm p_prm)
       | _ -> raise Stream.Failure)
  | "V LIDENT", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "alid" then "a" ^ prm
           else if kind = "lid" then "b" ^ prm
           else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | "V FLAG", "" ->
      (function
         "ANTIQUOT_LOC", prm ->
           let kind = check_anti_loc2 prm in
           if kind = "aflag" then "a" ^ prm
           else if kind = "flag" then "b" ^ prm
           else raise Stream.Failure
       | _ -> raise Stream.Failure)
  | tok -> tok_match tok;;

(* reinit the entry functions to take the new tok_match into account *)
Grammar.iter_entry Grammar.reinit_entry_functions
  (Grammar.Entry.obj Pcaml.expr);;

let apply_entry e me mp =
  let f s =
    call_with Plexer.force_antiquot_loc true (Grammar.Entry.parse e)
      (Stream.of_string s)
  in
  let expr s = me (f s) in
  let patt s = mp (f s) in Quotation.ExAst (expr, patt)
;;

List.iter (fun (q, f) -> Quotation.add q f)
  ["expr", apply_entry expr_eoi Meta.e_expr Meta.p_expr;
   "patt", apply_entry patt_eoi Meta.e_patt Meta.p_patt;
   "ctyp", apply_entry ctyp_eoi Meta.e_ctyp Meta.p_ctyp;
   "str_item", apply_entry str_item_eoi Meta.e_str_item Meta.p_str_item;
   "sig_item", apply_entry sig_item_eoi Meta.e_sig_item Meta.p_sig_item;
   "module_expr",
   apply_entry module_expr_eoi Meta.e_module_expr Meta.p_module_expr];;

open Types
open Tast
open Report.Error

module Ast = Parse.Ast

module ID = struct
  let current = ref 0

  let next () =
    let id = !current in
    current := id + 1;
    id

  let reset () =
    current := 0

end

let error e span = raise_error (Type_error e) span []

let new_var level = TVar (ref (Unbound (ID.next (), level)))
let new_gen_var () = TVar (ref (Generic (ID.next ())))

let mk s t i = {span=s; item=i; typ=t}

(* helper functions *)

(** asserts that the type isn't recursive
    and solves constraints like {'a = 'b}
    if 'b comes from a higher level than 'a *)
let occurs_check_adjust_levels id level =
  let rec go = function
    | TName _ -> ()
    | TVar {contents = Link ty} -> go ty
    | TVar {contents = Generic _} -> assert false
    | TVar ({contents = Unbound (other_id, other_level)} as other) ->
      if other_id = id then error Recursive_type None;
      if other_level > level
        then other := Unbound (other_id, other_level)
        else ()
    | TEff t -> go t
    | TApp (a, t) -> go a; go t
    | TFun (p, r) -> go p; go r
    | TTup ts -> List.iter go ts
  in go

let rec unify ty1 ty2 =
  if ty1 == ty2 then ()
  else match (ty1, ty2) with
    | TName n1, TName n2 when n1 = n2 -> ()

    | TFun (p1, r1), TFun (p2, r2) ->
      unify p1 p2;
      unify r1 r2

    | TApp (a1, t1), TApp (a2, t2) ->
      unify a1 a2;
      unify t1 t2

    | TVar {contents = Link ty1}, ty2
    | ty1, TVar {contents = Link ty2} ->
      unify ty1 ty2

    | TVar ({contents = Unbound (id, level)} as tvar), ty
    | ty, TVar ({contents = Unbound (id, level)} as tvar) ->
      occurs_check_adjust_levels id level ty;
      tvar := Link ty

    | _ ->
      let ty1_str = show_type ty1 in
      let ty2_str = show_type ty2 in
      error (Expected (ty1_str, ty2_str)) None

(** generalizes type [ty] replacing 
    unbound type variables with Generic ones *)
let rec generalize level = function
  | TVar {contents = Unbound (id, other_level)}
  when other_level > level -> TVar (ref (Generic id))
  | TVar {contents = Link ty} -> generalize level ty

  | TEff t -> TEff (generalize level t)
  | TFun (p, r) -> TFun (generalize level p, generalize level r)
  | TApp (a, t) -> TApp (generalize level a, generalize level t)
  | TTup ts -> TTup (List.map (generalize level) ts)
  
  | TVar {contents = Generic _}
  | TVar {contents = Unbound _}
  | TName _ as ty -> ty

(** instantiates type [ty] replacing Generic
    type variables with fresh ones *)
let instantiate level ty =
  let id_var_map = Hashtbl.create 20 in
  let rec go ty = match ty with
    | TName _ -> ty
    | TVar {contents = Link ty} -> go ty
    | TVar {contents = Generic id} -> begin
        try Hashtbl.find id_var_map id
        with Not_found ->
          let var = new_var level in
          Hashtbl.add id_var_map id var;
          var
      end
    | TVar {contents = Unbound _} -> ty
    | TEff t -> TEff (go t)
    | TApp (a, t) -> TApp (go a, go t)
    | TFun (p, r) -> TFun (go p, go r)
    | TTup ts -> TTup (List.map go ts)
  in go ty

(** asserts that the given type is a function type *)
let rec match_fun_ty = function
  | TFun (p, r) -> p, r
  | TVar {contents = Link ty} -> match_fun_ty ty
  | TVar ({contents = Unbound (_, level)} as tvar) ->
    let param_ty = new_var level in
    let return_ty = new_var level in
    tvar := Link (TFun (param_ty, return_ty));
    param_ty, return_ty
  | t -> error (Expected_funtion (show_type t)) None

(* inference functions *)

let infer_patt ?(level=0) _ patt =
  let {span=s; item=patt} : Ast.pattern Ast.node = patt in
  match patt with
    | PA_Variable v -> mk s (new_var level) (PA_Variable v)
    | PA_Wildcard -> mk s (new_var level) PA_Wildcard

(** infer an expression *)
let rec infer_expr ?(level=0) env exp =
  let {span=s; item=exp} : Ast.expr Ast.node = exp in
  match exp with
    | EX_Grouping e ->
      let t = infer_expr ~level env e in
      mk s t.typ (EX_Grouping t) 
    
    (*| EX_Binding (bindings, body) ->
      per binding:
        var_ty = infer_expr env (level + 1) value
        gen_ty = generalize level var_ty
        extend_with_name env name gen_ty
      infer_expr env level body *)
    
    | EX_Lambda {patt; expr} ->
      let patt' = infer_patt ~level env patt in
      let env' = env (* TODO: extend env *) in
      let expr' = infer_expr ~level env' expr in
      mk s (TFun (patt'.typ, expr'.typ))
        (EX_Lambda {patt=patt'; expr=expr'})
    
    | EX_Sequence (e1, e2) ->
      let e1' = infer_expr ~level env e1 in
      let e2' = infer_expr ~level env e2 in
      mk s e2'.typ (EX_Sequence (e1', e2'))
  
    | EX_Tuple es ->
      let es' = List.map (infer_expr ~level env) es in
      let ts = List.map (fun e -> e.typ) es' in
      mk s (TTup ts) (EX_Tuple es')
    
    | EX_Literal l ->
      let name n = TName (Path.Ident n) in
      let l', t = match l with
        | LI_Char c   -> LI_Char c,   name "Chr"
        | LI_Float f  -> LI_Float f,  name "Flt"
        | LI_Int i    -> LI_Int i,    name "Int"
        | LI_Nil      -> LI_Nil,      name "Nil"
        | LI_String s -> LI_String s, name "Str"
      in mk s t (EX_Literal l')
    
    | EX_Identifier {span; item} ->
      let path = Path.from_ident item in
      let t = TName (Path.Ident "var") in (* TODO: lookup item in env *)
      mk s t (EX_Identifier (mk span t path)) 

    | _ -> error (Expected ("idk", "idc")) (Some s)

(* helper functions *)

let infer_expr e =
  try infer_expr ~level:0 () e
  with Error (err, s, n) ->
    Report.report err s n;
    (* return some empty expression? *)
    mk e.span (new_var 0) (EX_Literal LI_Nil)
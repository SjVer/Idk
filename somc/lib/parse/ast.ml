type 'a node =
  {
    span: Span.span;
    item: 'a
  }

(* ====================== Toplevel ===================== *)

and toplevel =
  | TL_Declaration of string * typ node (** `string: typ` *)
  | TL_Definition of value_binding (** `patt = expr;;` *)
  | TL_Type_Definition of type_definition (** `string := type;;` *)
  | TL_Import of import (** `#import` *)

and value_binding =
  {
    patt: pattern node;
    expr: expr node;
  }

and type_definition =
  {
    name: string node;
    params: string node list;
    typ: typ node;
  }
  
(* ======================= Import ======================= *)

and import =
  {
    path: string node list;
    kind: import_kind node;
  } 
    
and import_kind =
  | IK_Simple (** `path` *)
  | IK_Glob (** `path::*` *)  
  | IK_Rename of string (** `path => string` *)
  | IK_Nested of import node list (** `path::{import, list}` *)
  
(* ====================== Pattern ====================== *)

(** TODO: add pattern matching like as in
    github.com/ocaml/ocaml/blob/trunk/parsing/parsetree.mli#L219 *)
and pattern =
  | PA_Variable of string
  | PA_Wildcard

(* ===================== Expression ===================== *)

and expr =
  | EX_Grouping of expr node (** `(expr)` *)
  | EX_Binding of value_binding list * expr node (** `patt = expr, ... => expr` *)
  | EX_Lambda of value_binding (** `\patt => expr` *)
  | EX_Sequence of expr node * expr node (** `expr, expr` *)
  | EX_Application of applicant node * expr node list (** `appl expr ...` *)
  | EX_Tuple of expr node list (** `expr; expr; ...` *)
  | EX_Construct of Ident.t node * expr node option (** `String expr` *)
  | EX_Literal of literal (** `literal` *)
  | EX_Identifier of Ident.t node (** `variable` *)

and applicant =
  | AP_Expr of expr node
  | AP_BinaryOp of bin_op
  | AP_UnaryOp of un_op
  
and bin_op =
  | BI_Add
  | BI_Subtract
  | BI_Multiply
  | BI_Divide
  | BI_Power

and un_op =
  | UN_Negate
  | UN_Not

and literal =
  | LI_Bool of bool
  | LI_Int of int
  | LI_Float of float
  | LI_Char of char
  | LI_String of string
  | LI_Nil

(* ======================== Type ======================== *)

and typ =
  (* typedef-only *)
  | TY_Variant of (string node * typ node option) list
  (* generic *)
  | TY_Grouping of typ node (** `(typ)` *)
  | TY_Any (** `_` *)
  | TY_Variable of string (** `'string` *)
  | TY_Effect of typ node option (** `!typ` *)
  | TY_Function of typ node list * typ node (** `typ, ... -> typ` *)
  | TY_Tuple of typ node list (** `typ; ...` *)
  | TY_List of typ node (** `[typ]` *)
  | TY_Construct of typ node option * string (** `string` | `typ string`*)
  | TY_Builtin of builtin_typ (** `$llvm_typ` *)

and builtin_typ =
  | BT_Int of bool * int (* `$i.bool.int` *)
  | BT_Float of int (* `$f.int` *)
  | BT_Void (* `$v` *)

(* ===================== Directive ===================== *)

(* and directive =
  {
    (* TODO: enum instead of string *)
    id: string node;
    arg: directive_arg node option;
  }

and directive_arg =
  | DA_Bool of bool
  | DA_Integer of int
  | DA_Float of float
  | DA_String of string
  | DA_Identifier of string
*)
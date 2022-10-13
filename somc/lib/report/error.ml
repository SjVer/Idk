let f = Util.f

(* comments after variants for gen_codes_ml.py *)

(* Lexing errors *)

type lexing_error =
  | Unexpected_character of string
  | Illegal_escape of char (*+sequence*)
  | Unterminated_string
  | Invalid_literal of string
  | Invalid_builtin_type of string

let get_lexing_error_msg = function
  | Unexpected_character w  -> f "unexpected character '%s'" w
  | Illegal_escape w        -> f "illegal escape sequence '\\%c'" w
  | Unterminated_string     -> f "unterminated string"
  | Invalid_literal w       -> f "invalid literal '%s'" w
  | Invalid_builtin_type w  -> f "invalid builtin type '%s'" w

(* Syntax errors *)

type syntax_error =
  | Expected of string (*+token*)
  | Unexpected (*+token*)
  | Unclosed of string (*+token*)
  | Other of string (*+syntax error*)
  
let get_syntax_error_msg = function
  | Expected w            -> f "expected %s" w
  | Unexpected            -> f "unexpected token"
  | Unclosed w            -> f "unclosed '%s'" w
  | Other w               -> w
  
(* Type errors *)

type type_error =
  | Expected of string * string (*+a different type*)
  | Expected_funtion of string (*+type*)
  | Recursive_type
  | Use_of_unbound of string * string (*+symbol*)
  | Failed_to_resolve of string (*+symbol*)
  | Cannot_import_from of string (*+non-module symbol*)
  | Could_not_infer (*+type*)
  
let get_type_error_msg = function
  | Expected (e, g)       -> f "expected type `%s` but found type `%s`" e g
  | Expected_funtion g    -> f "expected a function type but found type `%s`" g
  | Recursive_type        -> f "recursive type"
  | Use_of_unbound (t, w) -> f "use of unbound %s `%s`" t w
  | Failed_to_resolve w   -> f "failed to resolve `%s`" w
  | Cannot_import_from w  -> f "cannot import from non-module symbol `%s`" w
  | Could_not_infer       -> f "could not infer type"

(* Other errors *)

type other_error =
  | Could_not_open of string (*+file*)
  | Cannot_import_dir of string (*+\bectory*)
  | Could_not_compile of string (*+file*)
  | Failed_to_import of string (*+symbol*)
  | Cannot_explain of int (*+error code*)
  | Nonexistent_pass of string

let get_other_error_msg = function
  | Could_not_open w    -> f "could not open file '%s'" w
  | Cannot_import_dir w -> f "cannot import directory '%s'" w
  | Could_not_compile w -> f "could not compile '%s' due to previous error" w
  | Failed_to_import w  -> f "failed to import `%s`" w
  | Cannot_explain w    -> f "cannot explain invalid error code E%03d" w
  | Nonexistent_pass w  -> f "cannot run nonexistend LLVM pass '%s'" w

(* Types *)

type error =
  | Lexing_error of lexing_error
  | Syntax_error of syntax_error
  | Type_error of type_error
  | Other_error of other_error

let get_error_header_and_msg = function
  | Lexing_error e -> "lexing error", get_lexing_error_msg e
  | Syntax_error e -> "syntax error", get_syntax_error_msg e
  | Type_error e   -> "type error",   get_type_error_msg e
  | Other_error e  -> "error",        get_other_error_msg e

exception Error of error * Span.t option * string list

let raise_error err span notes = raise (Error (err, span, notes))

let add_note e note =
  let (err, span, notes) = e in
  Error (err, span, notes @ [note])
(* File generated by gen_codes_ml.py on Mon Oct 31 14:35:00 2022. *)

open Error

let int_from_lexing_error : lexing_error -> int = function
  | Unexpected_character _ -> 101
  | Illegal_escape _ -> 102
  | Unterminated_string -> 103
  | Invalid_literal _ -> 104
  | Invalid_builtin_type _ -> 105

let int_from_syntax_error : syntax_error -> int = function
  | Expected _ -> 201
  | Unexpected -> 202
  | Unclosed _ -> 203
  | Other _ -> 204

let int_from_type_error : type_error -> int = function
  | Expected _ -> 301
  | Expected_function _ -> 302
  | Recursive_type -> 303
  | Use_of_unbound _ -> 304
  | Failed_to_resolve _ -> 305
  | Cannot_private _ -> 306
  | Cannot_import_from _ -> 307
  | Could_not_infer -> 308

let int_from_other_error : other_error -> int = function
  | Could_not_open _ -> 401
  | Cannot_import_dir _ -> 402
  | Could_not_compile _ -> 403
  | Failed_to_import _ -> 404
  | Cannot_explain _ -> 405
  | Nonexistent_pass _ -> 406

let int_from_error = function
  | Lexing_error e -> int_from_lexing_error e
  | Syntax_error e -> int_from_syntax_error e
  | Type_error e -> int_from_type_error e
  | Other_error e -> int_from_other_error e

let error_name_from_int = function
  | 101 -> Some ("lexing", "unexpected character")
  | 102 -> Some ("lexing", "illegal escape sequence")
  | 103 -> Some ("lexing", "unterminated string")
  | 104 -> Some ("lexing", "invalid literal")
  | 105 -> Some ("lexing", "invalid builtin type")
  | 201 -> Some ("syntax", "expected token")
  | 202 -> Some ("syntax", "unexpected token")
  | 203 -> Some ("syntax", "unclosed token")
  | 204 -> Some ("syntax", "other syntax error")
  | 301 -> Some ("type", "expected a different type")
  | 302 -> Some ("type", "expected function type")
  | 303 -> Some ("type", "recursive type")
  | 304 -> Some ("type", "use of unbound symbol")
  | 305 -> Some ("type", "failed to resolve symbol")
  | 306 -> Some ("type", "cannot use private symbol")
  | 307 -> Some ("type", "cannot import from non-module symbol")
  | 308 -> Some ("type", "could not infer type")
  | 401 -> Some ("other", "could not open file")
  | 402 -> Some ("other", "cannot import directory")
  | 403 -> Some ("other", "could not compile file")
  | 404 -> Some ("other", "failed to import symbol")
  | 405 -> Some ("other", "cannot explain error code")
  | 406 -> Some ("other", "nonexistent pass")
  | _ -> None
let get_code_opt = function
  | Other_error _ -> None
  | e -> Some (int_from_error e)
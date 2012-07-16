(** This file implements a small command-line utility to find strings
    that are almost equal. It reads from stdin lines whith two strings
    that are separated by a single tab and emits those lines, whose
    strings are very smilar. Command line flag -d controls the minimum
    similarity above which lines are emitted.  *)

exception Error of string

(** [options] represents command line options *)

type options =
    { mutable delimiter:   char
    ; mutable similarity:  float
    ; mutable arg_string:  string option 
    }

(** [defaults] holds default values for command line options *)

let defaults =
    { delimiter  = '\t'
    ; similarity = 0.9
    ; arg_string = None
    }

let error   fmt = Printf.kprintf (fun msg -> raise (Error msg)) fmt
let (@@) f x    = f x
let i2f         = float_of_int
let a2f s       = try float_of_string s 
                  with Failure _ -> error "not a float: %s" s
let some = function
    | Some x -> x
    | None   -> error "this can't happen: some called with None"


(** [IntSet] implements a set of integers *)
module Int = struct
    type t = int
    let compare (x:int) (y:int) = compare x y
end
module IntSet = Set.Make(Int)

(** [split] splits a string in two parts.
    @param delimiter holds the character at which the string is split.
    @param string is the argument to be split.
    @return pair of two strings [x],[y]. 
    Invariant: [string] = [x] ^ [delimiter] ^ [y].
*)
let split delimiter string =
    try 
        let d   = String.index string delimiter in
        let len = String.length string in
            ( String.sub string 0 d
            , String.sub string (d+1) (len-d-1)
            )
    with Not_found -> (string,"")

(** [pair] computes an integer from two characters, representing the 
    pair of the two characters. We only count such pairs and hence don't
    provide the inverse operation that produces two characters from an
    integer. *)

let pair x y = 256 * Char.code x + Char.code y

(** [[adjacent]] computes from a string the set of all adjacent characters. 
    @return a set of integers since pairs are encoded as integers for
    performance. *)

let adjacent_pairs string =
    let len = String.length string in
    let rec loop i set =
        if i >= len-1 
        then set
        else loop (i+1) (IntSet.add  (pair string.[i] string.[i+1]) set)
    in
        loop 0 IntSet.empty

(** [[similarity]] compares two strings for similarity.
    @return a float in range [0 .. 1.0], where 0 denotes no similarity
    and 1.0 perfect similarity *)

let similarity x y =
    let xs = adjacent_pairs x in
    let ys = adjacent_pairs y in
           (i2f @@ ( * ) 2 @@ IntSet.cardinal @@ IntSet.inter xs ys)
        /. (i2f @@ IntSet.cardinal xs + IntSet.cardinal ys)

let exec_split options = 
    let rec loop () =
        let line = read_line () in
        let left,right = split options.delimiter line in
        let s = similarity left right in
            ( if s >= options.similarity then print_endline line else ()
            ; loop ()
            )
    in
        try loop () with End_of_file -> ()

let exec_nosplit options =
    let sim y = similarity (some options.arg_string) y in
    let rec loop () =
        let line = read_line () in
        let s = sim line in
            ( if s >= options.similarity then print_endline line else ()
            ; loop ()
            )
    in
        try loop () with End_of_file -> ()

let exec options = match options.arg_string with
    | None   -> exec_split options
    | Some x -> exec_nosplit options
    



(** [delimiter] expects a string of length one and returns the first
    character. It is used to extract the delimiter character from a
    command line argument 
    @return delimiter character
    *)

let delimiter str = match String.length str with
    | 1 -> String.get str 0
    | 0 -> error "delimiter must be one character"
    | _ -> error "delimiter '%s' too long - must be one character" str

(** [help] offers some help on stdout. 
    @param this the name of this tool (argv[0]) *)


let help this = 
    let s = Printf.sprintf in
    List.iter prerr_endline
    [ s "usage: %s options" this
    ; s "%s reads lines from stdin, splits them in two halfs and emits all" this
    ; "lines whose half exceed a given similarity threshold in range 0.0..1.0"
    ; ""
    ; "options:"
    ; "-t c     split input lines at character c; default is tab"
    ; "-d 0.8   emit lines with similarity of 0.8 or greater; default 0.9"
    ; "-h       emit this help to stderr"
    ]

(** [main] evaluates the command line and gets everything started. *)

let main () =
    let argv    = Array.to_list Sys.argv in
    let this    = Filename.basename (List.hd argv) in 
    let args    = List.tl argv in
    let cat xs  = String.concat " " xs in 
    let rec parse opts = function
        | "-t" :: x :: args -> opts.delimiter  <- delimiter x ; parse opts args
        | "-d" :: x :: args -> opts.similarity <- a2f x       ; parse opts args
        | "-h" :: _         -> help this
        | [x]               -> opts.arg_string <- Some x      ; exec opts
        | []                -> exec opts
        | xs                -> error "too many arguments %s" (cat xs)
    in
        parse defaults args

let () = if !Sys.interactive then () else main () 

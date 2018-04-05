theory FourL
  imports Main ElleSyntax ElleCompiler
begin

(* deal with literals:
- strings (truncate to 32 bytes, left align)
- integers
- expressions
*)

datatype llllarith =
   LAPlus
  | LAMinus

datatype llll =
   L4L_Str "string"
  | L4L_Int "int"
  | L4I "inst"
  | L4Seq "llll list"
  | L4Arith "llllarith" "llll list"
  | L4When "llll" "llll"
  | L4If "llll" "llll" "llll"
  | L4While "llll" "llll"

(* Read in a string as a word list (truncate to 32 bytes)*)
(* TODO: need to explicitly pad with zeros? *)
(* i think we might not need to, let's see *)
fun truncate_string_sub :: "string \<Rightarrow> nat \<Rightarrow> 8 word list"
  where
"truncate_string_sub _ 0 = []"
| "truncate_string_sub [] (Suc n) = byteFromNat 0 # truncate_string_sub [] n"
| "truncate_string_sub (h#t) (Suc n) =
   byteFromNat (String.char.nat_of_char h) #
   truncate_string_sub t n"

definition truncate_string :: "string \<Rightarrow> 8 word list"
  where "truncate_string s = truncate_string_sub s 32"

(* ints need to be right aligned (lowest sig bit) *)
(* output_address, from ElleCompiler, should work *)
(* note that this effectively means that
PUSHes are little-endian?
but no, numbers _are_ big endian in EVM
*)
definition intToBytes :: "int \<Rightarrow> 8 word list" where
"intToBytes i = bytes_of_nat (Int.nat i)"

value "intToBytes 2049"

(* TODO: do we need raw?
If so, how do we get it?
Raw means we need to basically save the first non-void result *)

(* TODO: is this the right ("jnz") semantics? *)
(* Idea: literals translate into pushes *)
fun llll_compile :: "llll \<Rightarrow> ll1" where
"llll_compile (L4L_Str s) = ll1.L (Evm.inst.Stack (PUSH_N (truncate_string s)))"
| "llll_compile (L4L_Int i) = ll1.L (Evm.inst.Stack (PUSH_N (intToBytes i)))"
| "llll_compile (L4I i) = ll1.L i"
| "llll_compile (L4Seq l) = ll1.LSeq (map llll_compile l)"
| "llll_compile (L4When c l) =
   ll1.LSeq [llll_compile c, ll1.LJmpI 0, llll_compile l, ll1.LLab 0]"
| "llll_compile (L4If c l1 l2) = 
   ll1.LSeq [llll_compile c, ll1.LJmpI 0, llll_compile l2, ll1.LLab 0]"
(* TODO: we can have a more efficient loop *)
| "llll_compile (L4While c l) = 
   ll1.LSeq [
   ll1.LSeq [
   ll1.LSeq [ll1.LLab 0,
             llll_compile c, ll1.LJmpI 1,
             ll1.LJmp 2,
             ll1.LLab 1,
             llll_compile l,
             ll1.LJmp 0,
             ll1.LLab 2]]]"

(* Q: best way to deal with the fact that
conditionals might not result in a value? *)
(*
| "llll_compile (L4Until c l) =
   ll1.LSeq [
   ll1.LSeq [ ll1.LLab 0,
              llll_compile c, ll1.LJmpI 1,
              llll_compile l,
              ll1.LJmp 0,
              ll1.LLab 1]]
*)

(* Q: will returning strings make termination proving harder? *)

(*definition charParse :: "char \<Rightarrow> string \<Rightarrow> (string * llll option)" where
"charParse _ [] = "[], *)

(* next: need to be able to parse fourL *)
(* do we want continuations here somehow? *)
(* Val's idea: continuations for:
- same level of precedence
- next level of precedence
- top 

the problem is that this seems to break termination. *)
(*
fun fourLParse :: "string \<Rightarrow> string * llll option" where
"fourParse
*)
value "LemExtraDefs.char_to_digit (CHR ''B'')"
(* TODO: we need to bring back the extra continuation (of type 'a \<Rightarrow> string \<Rightarrow> llll option)
for the recursive cases we will hit soon
*)
(* should we be parametric in both input and output? *)
type_synonym 'a parser =
  "string \<Rightarrow>
    ('a \<Rightarrow> string \<Rightarrow> llll option) \<Rightarrow> (* success continuation *)
    (string \<Rightarrow> llll option) \<Rightarrow> (* failure continuation, doesn't consume *)
    (string \<Rightarrow> llll option) \<Rightarrow> (* captures recursive call to entire grammar parser (e.g. for parens) *)
    llll option"

(* capturing the self-recursive nature of the grammar (parentheses) *)


fun parseNumeral :: "nat parser" where
"parseNumeral [] s f r = f []" (* at this point we have no string to operate on *)
| "parseNumeral (h#t) s f r =
   (if LemExtraDefs.is_digit_char h
    then s (LemExtraDefs.char_to_digit h) t
    else f (h#t))"

(* idea: now we need to parse an arbitrary series of numerals
(as in TRX, we are including tokenization)
our failure case will not consume the next item yet
*)
(*
I still wonder if we need explicit peeking
*)
(* *)
function(sequential) parseIntSub :: "int \<Rightarrow> int parser" where
"parseIntSub i [] su fa r  = su i []"
| "parseIntSub i (h#t) su fa r  =
   parseNumeral (h#t) 
                (\<lambda> n l . parseIntSub (10*i + Int.int n) l su fa r)
                (\<lambda> l . su i l) r
   "
  by pat_completeness auto
termination sorry

fun parseInt :: "int parser" where
"parseInt [] su fa r = fa []"
| "parseInt (h#t) su fa r =
   parseNumeral (h#t) 
    (\<lambda> n l . parseIntSub n l su fa r)
    fa r"

(* more helpers: matching a keyword (literal string) *)
(* matching an empty keyword is technically valid *)
fun parseKeyword :: "string \<Rightarrow> unit parser" where
"parseKeyword [] l su fa r = su () l"
| "parseKeyword (h#t) [] su fa r = fa []"
| "parseKeyword (h#t) (h'#t') su fa r =
   (if h = h' then
       parseKeyword t t' su fa r
    else fa (h'#t'))"

(* next: parsing expressions
(for now, for demonstration, just add and sub) *)

(* TODO: be more consistent in calling the parser input parameter l*)
function run_parse :: "llll option parser \<Rightarrow> string \<Rightarrow> (llll option)" where
"run_parse p s =
  p s (\<lambda> x s . x) (\<lambda> s . None)
    (run_parse p)"
  by pat_completeness auto
termination sorry


definition hello :: string where "hello = ''hello''"

fun silly_parse :: "llll option parser" where
"silly_parse l su fa r =
 parseKeyword hello l
  (\<lambda> x l . su (Some (L4L_Int 0)) l)
 (\<lambda> l . parseKeyword ''kitty'' l
  (\<lambda> x l . su (Some (L4L_Int 1)) l) fa r) r"

value "run_parse silly_parse ''kitty''"
value "run_parse silly_parse ''hello''"
value "run_parse silly_parse ''other''"

fun fourLParse_int :: "llll option parser" where
"fourLParse_int l su fa =
 parseInt l (\<lambda> x s . su (Some (L4L_Int x)) s) fa"

value "run_parse fourLParse_int ''100''"

(* idea: no parentheses yet.
"+ 1 2" or "- 1 2" should parse correctly means
*)

(* one or more of something, separated by a delimiter string *)
(* idea: first we parse one of the thing
   then we attempt to parse a delimiter and repeat the process on the tail
   if that all succeeds, succeed
   otherwise, fail
*)
(* Q: make this more general? have arbitrary parsers for the delimiters? *)
function(sequential) delimitParse_sub :: "string \<Rightarrow> 'a parser \<Rightarrow> 'a list \<Rightarrow> 'a list parser" where
"delimitParse_sub s parse acc l su fa r =
  parseKeyword s l
  (\<lambda> x l . parse l 
    (\<lambda> x1 l . delimitParse_sub s parse (acc@[x1]) l
             (\<lambda> x2 l . su x2 l)
             (\<lambda> l . su (acc@[x1]) l) r)
  fa r)
  fa r"
  by pat_completeness auto
termination sorry

fun endInputParse :: "unit parser" where
"endInputParse [] su fa r =
  su () []"
| "endInputParse l su fa r =
  fa l"

(* useful primitives:
 - chaining successes
 - chaining failures
 - choices of alternatives
 - greedy recursive matching (?)
 - one or more *)

(*
more concretely:
- chaining successes (done)
- choose between 2 alternatives, i.e. chaining in the first one's failure case
- optionally run a parser (can be seen as choice between parser and empty, or its own thing)
*)

definition chainParse :: "'a parser \<Rightarrow> ('a \<Rightarrow> 'b parser) \<Rightarrow> 'b parser" where
"chainParse parse after l su fa r =
  parse l
   (\<lambda> x l . after x l su fa r)
   fa r
"

definition choiceParse :: "'a parser \<Rightarrow> 'a parser \<Rightarrow> 'a parser" where
"choiceParse parse1 parse2 l su fa r =
  parse1 l su
   (\<lambda> l . parse2 l su fa r) r"

(* takes a default value, if parsing fails
nil, in the case of delimitParse *)
(* ordering of inputs to this guy? *)
definition optionalParse :: "'a parser \<Rightarrow> 'a \<Rightarrow> 'a parser" where
"optionalParse parse dfl l su fa r =
  parse l su (su dfl) r"

function(sequential) starParse_sub :: "'a parser \<Rightarrow> 'a list \<Rightarrow> 'a list parser" where
"starParse_sub parse acc l su fa r =
  parse l (\<lambda> x l . starParse_sub parse (acc@[x]) l su fa r)
    (su acc) r"
  by pat_completeness auto
termination sorry
  

definition starParse :: "'a parser \<Rightarrow> 'a list parser" where
"starParse parse l su fa r = starParse_sub parse [] l su fa r"

definition examine_unit_result :: "unit list \<Rightarrow> llll option parser" where
"examine_unit_result ls l su fa r = 
  su (Some (L4Seq (map (\<lambda> _ . L4L_Int 0) ls))) l"

(* it would be nice to be parametric in output type... *)
value "run_parse (chainParse (starParse (parseKeyword ''hi'')) examine_unit_result) []"

value "run_parse (chainParse (starParse (parseKeyword ''hi'')) examine_unit_result) ''hi''"

value "run_parse (chainParse (starParse (parseKeyword ''hi'')) examine_unit_result) ''hihi''"

definition plusParse :: "'a parser \<Rightarrow> 'a list parser" where
"plusParse parse l su fa r =
  parse l (\<lambda> x l . starParse_sub parse [x] l su fa r) 
  fa r"

value "run_parse (chainParse (plusParse (parseKeyword ''hi'')) examine_unit_result) ''''"

value "run_parse (chainParse (plusParse (parseKeyword ''hi'')) examine_unit_result) ''hi''"

value "run_parse (chainParse (plusParse (parseKeyword ''hi'')) examine_unit_result) ''hihi''"


(* should we have some kind of repeatParse combinator? *)

(* Q: have leading whitespace, or no? *)
definition delimitParse' :: "string \<Rightarrow> 'a parser \<Rightarrow> 'a list parser" where
"delimitParse' s parse l su fa r = 
  parse l 
    (\<lambda> x1 l . delimitParse_sub s parse [x1] l
             (\<lambda> x2 l . su x2 l)
             (\<lambda> l . su [x1] l) r)
  fa r"

(* idea: chainParse parse (optionalParse (delimitParse_sub s parse) *)
definition delimitParse :: "string \<Rightarrow> 'a parser \<Rightarrow> 'a list parser" where
"delimitParse s parse = 
  chainParse parse 
    (\<lambda> x . optionalParse (delimitParse_sub s parse [x]) [x])"

(*
    (\<lambda> x1 l . delimitParse_sub s parse [x1] l
             (\<lambda> x2 l . su x2 l)
             (\<lambda> l . su [x1] l) r)
  fa r"
*)


fun nums_parse :: "llll option parser" where
"nums_parse l su fa = (delimitParse '' '' parseInt) l
  (\<lambda> x l . su (Some (L4Seq (map L4L_Int x))) l)
  (\<lambda> l . None)"
  
value "run_parse nums_parse ''10 11''"

(* arith parser, with choice parsing, shows off + and - *)
fun arith_parse1 :: "llll option parser" where
"arith_parse1 =
  chainParse
  (parseKeyword ''('')
  ()
 "

(* require ''+'', then '' '' (for now) *)
(*
fun arith_parse1 :: "llll option parser" where
"arith_parse1 l su fa =
  (parseKeyword ''+'' l
   (\<lambda> x l . parseKeyword '' '' l
      (\<lambda> x l .  (delimitParse '' '' parseInt) l
        (\<lambda> x l . su (Some (L4Arith LAPlus (map L4L_Int x))) l)
        fa)
      fa)
   fa)"

value "run_parse arith_parse1 ''+ 1 0 2''"
*)

(*

need to start by parsing "("
end by parsing ")"

choice:
( - parse +
    - then parse one or more whitespaces
      - then 

fun arith_parse1 :: "llll option parser" where
"arith_parse1 l su fa =
  (parseChoice 
    (pa)
    ())
*)
(*

fun fourLParse_arith_test :: "llll option parser" where
"fourLParse_arith_test l su fa =
 parseKeyword ''+'' l
  

fun fourLParse_add :: "llll option parser" where
"fourLParse_sub l su fa =
 (* addition *)
 parseKeyword ''+'' l
  (\<lambda> x s . su (fourLParse_sub

*)
(*
fun fourLParse :: "string \<Rightarrow> (string \<Rightarrow> llll option) \<Rightarrow> (string \<Rightarrow> llll option) \<Rightarrow> llll option" where
"fourParse"
*)

end
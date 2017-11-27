theory LLLL
  
  imports Main Nat "../ContractSem" "../RelationalSem" "../ProgramInAvl" "../Hoare/Hoare" "../lem/Evm" 
begin

value "CHR''0'' :: char"
(* convenience routines for reading/printing hex as string *)
value "List.hd (''abcd'' :: char list)"

definition hexread1_dom :: "char \<Rightarrow> bool" where
"hexread1_dom c = (c = CHR ''0'' \<or> c = CHR ''1'' \<or> c = CHR ''2'' \<or>
                   c = CHR ''3'' \<or> c = CHR ''4'' \<or> c = CHR ''5'' \<or>
                   c = CHR ''6'' \<or> c = CHR ''7'' \<or> c = CHR ''8'' \<or>
                   c = CHR ''9'' \<or> c = CHR ''A'' \<or> c = CHR 'pr'B'' \<or>
                   c = CHR ''D'' \<or> c = CHR ''E'' \<or> c = CHR ''F'')"

definition hexread1 :: "char \<Rightarrow> nat" where
"hexread1 c = (if c = (CHR ''0'') then 0 else
               if c = (CHR ''1'') then 1 else
               if c = (CHR ''2'') then 2 else
               if c = (CHR ''3'') then 3 else
               if c = (CHR ''4'') then 4 else
               if c = (CHR ''5'') then 5 else
               if c = (CHR ''6'') then 6 else
               if c = (CHR ''7'') then 7 else
               if c = (CHR ''8'') then 8 else
               if c = (CHR ''9'') then 9 else
               if c = (CHR ''A'') then 10 else
               if c = (CHR ''B'') then 11 else
               if c = (CHR ''C'') then 12 else
               if c = (CHR ''D'') then 13 else
               if c = (CHR ''E'') then 14 else
               if c = (CHR ''F'') then 15 else
               undefined)"

definition hexwrite1_dom :: "nat \<Rightarrow> bool" where
"hexwrite1_dom n = (n < 16)"

definition hexwrite1 :: "nat \<Rightarrow> char" where
"hexwrite1 c = (if c = 0 then CHR ''0'' else
                if c = 1 then CHR ''1'' else
                if c = 2 then CHR ''2'' else
                if c = 3 then CHR ''3'' else
                if c = 4 then CHR ''4'' else
                if c = 5 then CHR ''5'' else
                if c = 6 then CHR ''6'' else
                if c = 7 then CHR ''7'' else
                if c = 8 then CHR ''8'' else
                if c = 9 then CHR ''9'' else
                if c = 10 then CHR ''A'' else
                if c = 11 then CHR ''B'' else
                if c = 12 then CHR ''C'' else
                if c = 13 then CHR ''D'' else
                if c = 14 then CHR ''E'' else
                if c = 15 then CHR ''F'' else undefined)"

value "(1 < (0::nat))"

lemma hexread1_hexwrite1 : "hexread1_dom c \<Longrightarrow> hexwrite1 (hexread1 c) = c"
  apply (auto simp add:hexread1_dom_def hexread1_def hexwrite1_def)
  done

lemma hexwrite1_help :
"n < 16 \<Longrightarrow>
    n \<noteq> 15 \<Longrightarrow>
    n \<noteq> 14 \<Longrightarrow>
    n \<noteq> 13 \<Longrightarrow>
    n \<noteq> 12 \<Longrightarrow>
    n \<noteq> 11 \<Longrightarrow>
    n \<noteq> 10 \<Longrightarrow>
    n \<noteq> 9 \<Longrightarrow>
    n \<noteq> 8 \<Longrightarrow>
    n \<noteq> 7 \<Longrightarrow>
    n \<noteq> 6 \<Longrightarrow>
    n \<noteq> 5 \<Longrightarrow>
    n \<noteq> 4 \<Longrightarrow>
    n \<noteq> 3 \<Longrightarrow>
    n \<noteq> 2 \<Longrightarrow>
    n \<noteq> Suc 0 \<Longrightarrow>
    0 < n \<Longrightarrow> False"
proof(induction n, auto)
qed 

lemma hexwrite1_hexread1 : "hexwrite1_dom n \<Longrightarrow> hexread1 (hexwrite1 n) = n"
  apply(auto simp add:hexwrite1_dom_def hexwrite1_def)
                  apply(auto simp add:hexread1_def)
                  apply(insert hexwrite1_help, auto)
  done


definition hexread2 :: "char \<Rightarrow> char \<Rightarrow> nat" where
"hexread2 c1 c2 = (16 * (hexread1 c1) + hexread1 c2)"

(* we need to reverse the input list? *)
(* TODO: later handle zero padding for odd numbers of bytes *)
fun hexread' :: "char list \<Rightarrow> nat \<Rightarrow> nat" where
"hexread' [] n = n"
| "hexread' [_] _ = undefined"
| "hexread' (n1#n2#t) a = hexread' t (hexread2 n1 n2 + 256 * a)"

definition hexread :: "char list \<Rightarrow> nat" where
"hexread ls = hexread' ls 0"

fun hexwrite2 :: "8 word \<Rightarrow> (char * char)" where
"hexwrite2 w = 
  (case Divides.divmod_nat (Word.unat w) 16 of
       (d,m) \<Rightarrow> (hexwrite1 d, hexwrite1 m))"

(* TODO: make sure we aren't supposed to do the reverse of this *)
fun hexwrite :: "8 word list \<Rightarrow> char list" where
"hexwrite [] = []"
| "hexwrite (h#t) = (case hexwrite2 h of
                     (c1, c2) \<Rightarrow> c1#c2#(hexwrite t))"

value "(hexwrite [1,2])"

(* *)

(* we need to rule out invalid, PC, and misc instrs *)
(* stack manipulation should be OK *)
fun inst_valid :: "inst => bool" where
  "inst_valid (Unknown _) = False"
| "inst_valid (Pc _) = False"
| "inst_valid (Misc _) = False"
| "inst_valid _ = True"

(* don't mix up de Bruijn indices with sizes *)  
type_synonym idx = nat
  
datatype ll1 =
  L "inst"
  (* de-Bruijn style approach to local binders *)
  | LLab "idx"
  | LJmp "idx"
  | LJmpI "idx"
  (* sequencing nodes also serve as local binders *)
  | LSeq "ll1 list"

lemma my_ll1_induct:
  assumes Ln: "(\<And> i. P1 (L i))"
  and La: "(\<And> idx . P1 (LLab idx))"
  and Lj: "(\<And>idx . P1 (LJmp idx))"
  and Lji : "(\<And>idx . P1 (LJmpI idx))"
  and Lls : "(\<And>l . P2 l \<Longrightarrow> P1 (LSeq l))"
  and Lln : "P2 []"
  and Llc : "\<And>t l . P1 t \<Longrightarrow> P2 l \<Longrightarrow> P2 (t # l)"
  shows "P1 t \<and> P2 l"
proof-
  {fix t
    have "P1 t \<and> (\<forall> l . t = LSeq l \<longrightarrow> P2 l)"
    proof (induction)
      case (L) thus ?case using Ln by auto next
      case (LLab) thus ?case using La by auto next
      case (LJmp) thus ?case using Lj by auto next
      case (LJmpI) thus ?case using Lji by auto next
      case (LSeq l) thus ?case
        apply (induct l) using Lls Lln Llc by auto blast+
    qed}
  
  thus ?thesis by auto
qed
          
fun ll1_valid :: "ll1 \<Rightarrow> bool" where
  "ll1_valid (L i) = inst_valid i"
  | "ll1_valid (LSeq is) = list_all ll1_valid is"
  | "ll1_valid _ = True"
  
    
(* "quantitative annotations" *)
type_synonym qan = "nat * nat"
  
datatype ('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) punit =
  PU

(* let's try the uniform version with pairs first *)
(* Q: can we fix the cases for valid_q by adding a 'dummy' optional argument of each data type? - doesn't seem to work *)
datatype ('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) llt =
  L "'lix" "inst"
  (* de-Bruijn style approach to local binders *)
  | LLab "'llx" "idx"
  (* idx stores which label it is
     nat stores how many bytes *)
  | LJmp "'ljx" "idx" "nat"
  | LJmpI "'ljix" "idx" "nat"
  (* sequencing nodes also serve as local binders *)
  (* do we put an "'ix" in here? *)
  | LSeq "'lsx" "(qan * ('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx )llt )list"
    
type_synonym ('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll =
  "(qan * ('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) llt)"

(* Q: should P2 also take a qan expressing entire list? *)
lemma my_ll_induct:
  assumes Ln: "(\<And> q e i. P1 (q, L e i))"
  and La: "(\<And> q e idx . P1 (q, LLab e idx))"
  and Lj: "(\<And> q e idx n . P1 (q, LJmp e idx n))"
  and Lji : "(\<And> q e idx n . P1 (q, LJmpI e idx n))"
  and Lls : "(\<And> q e l . P2 l \<Longrightarrow> P1 (q, LSeq e l))"
  and Lln : "P2 []" (* should this only be identical q? *)
  and Llc : "\<And> h l. P1 h \<Longrightarrow> P2 l \<Longrightarrow> P2 (h # l)"
  shows "P1 t \<and> P2 l"
proof-
  {fix t 
    have "(\<forall> q . P1 (q, t)) \<and> (\<forall> l e . t = LSeq e l \<longrightarrow> P2 l)"
    proof (induction)
      case (L) thus ?case using Ln by auto next
      case (LLab) thus ?case using La by auto next
      case (LJmp) thus ?case using Lj by auto next
      case (LJmpI) thus ?case using Lji by auto next
      case (LSeq e l) thus ?case 
      proof(induct l)
        case Nil thus ?case using Lln Lls by auto next
        case (Cons a l)
        thus ?case using Llc Lls
          apply(clarsimp) 
          apply(case_tac a)
          apply(subgoal_tac "P1 a") apply(clarsimp)
           apply(subgoal_tac "P2 l") apply(clarsimp)
           apply(auto, blast)
          apply(metis)
          done
      qed
    qed} 
  thus ?thesis
    apply(case_tac t)
    apply(auto, blast )
  done qed

(*Q: do we need more qan's in the path *)
datatype ('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) llpath =
  Top "'ptx" 
  | Node "'pnx" "'lsx" "('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll list"
               "('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) llpath"
               "('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll list" 

(* undecorated syntax with qan *)  
(* TODO: change these from units to any type *)
type_synonym ll2 =
  "(unit, unit, unit, unit, unit, unit, unit) ll"

type_synonym ll2p = 
  "(unit, unit, unit, unit, unit, unit, unit) llpath"

(* location = path + node *)  
type_synonym ll2l = "(ll2 * ll2p)"  

(* decorate Seq nodes with label resolution *)  
(* Q: just store which number child? list of nats representing path?*)
type_synonym ll3t =
  "(unit, bool, unit, unit, nat list, unit, unit) llt"  

type_synonym ('lix, 'ljx, 'ljix, 'ptx, 'pnx) ll3t' =
  "('lix, bool, 'ljx, 'ljix, nat list, 'ptx, 'pnx) llt"
  
type_synonym ll3 =
  "(unit, bool, unit, unit, nat list, unit, unit) ll"  


type_synonym ('lix, 'ljx, 'ljix, 'ptx, 'pnx) ll3' =
  "('lix, bool, 'ljx, 'ljix, nat list, 'ptx, 'pnx) ll"
  
type_synonym ll3p = 
  "(unit, bool, unit, unit, nat list, unit, unit) llpath"
  
type_synonym ll3l = "ll3 * ll3p"
  
type_synonym ll4t =
  "(unit, bool, nat, nat, nat list, unit, unit) llt"  
  
type_synonym ll4 =
  "(unit, bool, nat, nat, nat list, unit, unit) ll"  
  
type_synonym ll4p = 
  "(unit, bool, nat, nat, nat list, unit, unit) llpath"
  
type_synonym ll4l = "ll4 * ll4p"


  
    
definition jump_size :: "nat" where
  "jump_size = nat (inst_size (Pc JUMP))"
  
declare jump_size_def [simp]

definition jumpi_size :: "nat" where
  "jumpi_size = nat (inst_size (Pc JUMPI))"  

declare jumpi_size_def [simp]
  
(* validity of ll2 terms that have just been translated from ll1 *)
(* TODO: we need to break this up into separate pieces for each constructor,
   this way we can reuse them later without type variable ambiguities *)

definition ll_valid_qi :: "(qan * inst) set" where
  "ll_valid_qi = {((n,n'),i) . inst_valid i \<and> n' = n + nat (inst_size i)}"

declare ll_valid_qi_def [simp]  
  
definition ll_valid_ql :: "(qan * idx) set" where
  "ll_valid_ql = {((n,n'),i) . n' = n+1}"
  
declare ll_valid_ql_def [simp]  
  
definition ll_valid_qj :: "(qan * idx * nat) set" where
  "ll_valid_qj = {((n,n'),d,s) . n' = n + 1 + s}"

declare ll_valid_qj_def [simp]  
  
definition ll_valid_qji :: "(qan * idx * nat) set" where
  "ll_valid_qji = {((n,n'),d,s) . n' = n + 1 + s}"

declare ll_valid_qji_def [simp]
  
inductive_set
  ll_valid_q :: "('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll set" and
  ll_validl_q :: "(qan * (('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll list)) set " 
  where
    "\<And> i x e . (x, i) \<in> ll_valid_qi \<Longrightarrow> (x, L e i) \<in> ll_valid_q"
  | "\<And> x d e . (x, d) \<in> ll_valid_ql \<Longrightarrow> (x, LLab e d) \<in> ll_valid_q"
  | "\<And> x d e s . (x, d, s) \<in> ll_valid_qj \<Longrightarrow> (x, LJmp e d s) \<in> ll_valid_q"
  | "\<And> x d e s . (x, d, s) \<in> ll_valid_qji \<Longrightarrow> (x, LJmpI e d s) \<in> ll_valid_q"
  | "\<And> n l n' e . ((n, n'), l) \<in> ll_validl_q \<Longrightarrow> ((n, n'), (LSeq e l)) \<in> ll_valid_q"
  | "\<And> n . ((n,n), []) \<in> ll_validl_q"  
  | "\<And> n h n' t n'' .
     ((n,n'), h) \<in> ll_valid_q \<Longrightarrow>
     ((n',n''), t) \<in> ll_validl_q \<Longrightarrow>
     ((n,n''), ((n,n'), h) # t) \<in> ll_validl_q"

(* TODO: define "bump" to move the given ll to the "right" in the buffer by X bytes
   in order for this to be useful, we will need to make our annotations
   parametric in the size (? - maybe we don't use this until the
   very end so it will work out)
*)
(* this should operate on a (qan * (ll list))?
   otherwise there is and repacking we have to do... *)    
fun ll_bump :: "nat \<Rightarrow> ('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll \<Rightarrow>
                       ('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll" where
    "ll_bump b ((n,n'), l) = ((n+b,n'+b), (case l of
                                           LSeq e ls \<Rightarrow> LSeq e (map (ll_bump b) ls)
                                           | _ \<Rightarrow>  l))"
    
(* this is also suffering from the same problem as the validity predicate itself had.
   we need a case for each constructor. *)
(* to fix this we should have a better induction rule for validity that breaks out cases,
   maybe defining all of them as a mutually inductive set will work... *)
(* I am unsure if this is actually necessary though as both rules work individually *)
    
lemma ll_bump_valid [rule_format]:
  "((x, (t :: ('lix, 'llx, 'ljx, 'ljix, 'llx, 'ptx, 'pnx) llt)) \<in> ll_valid_q \<longrightarrow> (! b . ((ll_bump b (x,t))) \<in> ll_valid_q)) \<and>
   (((m,m'), (l :: ('lix, 'llx, 'ljx, 'ljix, 'llx, 'ptx, 'pnx) ll list)) \<in> ll_validl_q \<longrightarrow> (! b' .((m+b', m'+b'), map (ll_bump b') l) \<in> ll_validl_q))"
proof(induction rule: ll_valid_q_ll_validl_q.induct) 
  case 1 thus ?case by (auto simp add: ll_valid_q_ll_validl_q.intros) next
  case 2 thus ?case by (auto simp add: ll_valid_q_ll_validl_q.intros) next
  case 3 thus ?case by (auto simp add: ll_valid_q_ll_validl_q.intros) next
  case 4 thus ?case by (auto simp add: ll_valid_q_ll_validl_q.intros) next
  case (5 n l n' e) thus ?case by (auto simp add:ll_valid_q_ll_validl_q.intros) next
  case 6 thus ?case by (auto simp add:ll_valid_q_ll_validl_q.intros) next
  case (7 n h n' t n'') thus ?case
    apply(clarsimp)
    apply(drule_tac x = "b'" in spec)
    apply(drule_tac x = "b'" in spec)
    apply(rule ll_valid_q_ll_validl_q.intros(7), auto)
    done qed

  
fun ll1_size :: "ll1 \<Rightarrow> nat" and
    ll1_size_seq :: "ll1 list \<Rightarrow> nat" where
    "ll1_size (ll1.L inst) = nat (inst_size inst)"
  | "ll1_size (ll1.LLab idx) = 1"
  | "ll1_size (ll1.LJmp idx) = 1"
  | "ll1_size (ll1.LJmpI idx) = 1"
  | "ll1_size (ll1.LSeq ls) = ll1_size_seq ls"
  | "ll1_size_seq [] = 0"
  | "ll1_size_seq (h # t) = ll1_size h + ll1_size_seq t"
  
(* first pass, storing sizes *)
fun ll_phase1 :: "ll1 \<Rightarrow> nat \<Rightarrow> (ll2 * nat)" and
    ll_phase1_seq :: "ll1 list \<Rightarrow> nat \<Rightarrow> (ll2 list * nat)"
  where
  "ll_phase1 (ll1.L inst) i = (((i, i + nat (inst_size inst)), L () inst ), i + nat (inst_size inst))"
| "ll_phase1 (ll1.LLab idx) i = (((i, i+1), LLab () idx ), 1+i)" (* labels take 1 byte *)
| "ll_phase1 (ll1.LJmp idx) i = (((i, 1 + i), LJmp () idx 0), 1 + i)" (* jumps take at least 1 bytes *)
| "ll_phase1 (ll1.LJmpI idx) i = (((i, 1 + i), LJmpI () idx 0), 1 + i)"
| "ll_phase1 (ll1.LSeq ls) i =
   (let (ls', i') = ll_phase1_seq ls i in
   (((i, i'), LSeq () ls'), i'))"
| "ll_phase1_seq [] i = ([], i)"
| "ll_phase1_seq (h # t) i =
   (let (h', i') = ll_phase1 h i in
    (let (t', i'') = ll_phase1_seq t i' in
      (h' # t', i'')))"
  
definition ll_pass1 :: "ll1 \<Rightarrow> ll2" where
  "ll_pass1 l = fst (ll_phase1 l 0)"

lemma ll_phase1_correct :
  "(ll1_valid x \<longrightarrow> (! i . ? x2 . ? i' . ll_phase1 x i = (((i, i'), x2), i') \<and> ((i, i'), x2) \<in> ll_valid_q)) \<and>
   (list_all ll1_valid xs \<longrightarrow>
    (! j . ? xs2 . ? j' . ll_phase1_seq xs j = (xs2, j') \<and> ((j,j'),xs2) \<in> ll_validl_q))"
proof(induction rule:my_ll1_induct)
  case (1 i) thus ?case by (auto simp add:ll_valid_q.simps) next
  case (2 idx) thus ?case by (auto simp add:ll_valid_q.simps) next
  case (3 idx) thus ?case by (auto simp add:ll_valid_q.simps) next
  case (4 idx) thus ?case by (auto simp add:ll_valid_q.simps) next
  case (5 l) thus ?case
    apply(clarsimp)
    apply(case_tac "ll_phase1_seq l i", clarsimp)
    apply(drule_tac x = "i" in spec)
    apply (auto simp add:ll_valid_q.simps)
    done  next
  case (6) thus ?case using ll_valid_q_ll_validl_q.intros(6) by auto next
  case(7 t l) thus ?case 
    apply(clarsimp)
    apply(case_tac "ll_phase1 t j", clarsimp)
    apply(rename_tac "b'")
    apply(case_tac "ll_phase1_seq l b'", clarsimp)
    apply(drule_tac x = "j" in spec)
    apply(clarsimp)
    apply(drule_tac x = "b" in spec)
    apply(clarsimp)
    apply(rule ll_valid_q_ll_validl_q.intros(7), auto)
    done
qed
  
value "ll_pass1 (ll1.LSeq [ll1.LLab 0, ll1.L (Arith ADD)])"
  
value "(inst_size (Arith ADD))"


inductive_set ll_descend :: "(('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll * ('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll * nat) set"
  where
    "\<And> n n' e ls t .
       ((n, n'), LSeq e ls) \<in> ll_valid_q \<Longrightarrow>
       t \<in> set ls \<Longrightarrow>
       (((n,n'), LSeq e ls), t, 1) \<in> ll_descend"    
  | "\<And> t t' n t'' n' .
       (t, t', n) \<in> ll_descend \<Longrightarrow>
       (t', t'', n') \<in> ll_descend \<Longrightarrow>
       (t, t'', n + n') \<in> ll_descend"

type_synonym childpath = "nat list"

(* TODO: need a validity premise? for step case? *)
inductive_set ll3'_descend :: "(('lix, 'ljx, 'ljix, 'ptx, 'pnx) ll3' * ('lix, 'ljx, 'ljix, 'ptx, 'pnx) ll3' * childpath) set"
  where
    "\<And> q e ls t .
       List.nth ls c = t \<Longrightarrow>
       ((q, LSeq e ls), t, [c]) \<in> ll3'_descend"    
  | "\<And> t t' n t'' n' .
       (t, t', n) \<in> ll3'_descend \<Longrightarrow>
       (t', t'', n') \<in> ll3'_descend \<Longrightarrow>
       (t, t'', n @ n') \<in> ll3'_descend"
    
definition ll_valid_q3 :: "ll3 set" where
  "ll_valid_q3 = ll_valid_q"
  
definition ll_validl_q3 :: "(qan * ll3 list) set" where
  "ll_validl_q3 = ll_validl_q"
  
(*definition ll_valid_q3' :: "('lix, 'llx, 'ljx, 'ljix, nat list, 'ptx, 'pnx) ll set" where
  "ll_valid_q3' = ll_valid_q"*)
definition ll_valid_q3' :: "('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll set" where
  "ll_valid_q3' = {}"
  
definition ll_validl_q3' :: "(qan * (('lix, 'llx, 'ljx, 'ljix, nat list, 'ptx, 'pnx) ll list)) set" where
  "ll_validl_q3' = ll_validl_q"

definition ll_descend3' :: "(('lix, 'llx, 'ljx, 'ljix, nat list, 'ptx, 'pnx) ll * ('lix, 'llx, 'ljx, 'ljix, nat list, 'ptx, 'pnx) ll * nat) set" where
  "ll_descend3' = ll_descend"

(* Q: do we need to winnow this down to an ll3' set?
   might make this easier to work with, since then we can rely on additional data
   from the other annotations
 *)


inductive_set ll_valid3' :: "('lix, 'ljx, 'ljix, 'ptx, 'pnx) ll3' set" where
"\<And> i e x. (x, i) \<in> ll_valid_qi \<Longrightarrow>
               (x, L e i) \<in> ll_valid3'"
 | "\<And> x d. (x, d) \<in> ll_valid_ql \<Longrightarrow>
             (x, LLab True d) \<in> ll_valid3'"
  | "\<And> e x d s. (x, d, s) \<in> ll_valid_qj \<Longrightarrow>
                (x, (LJmp e d s)) \<in> ll_valid3'"
  | "\<And> e x d s. (x, d, s) \<in> ll_valid_qji \<Longrightarrow>
               (x, (LJmpI e d s)) \<in> ll_valid3'"

(* Our descend predicate doesn't seem to be quite what we want here.
   What we really want is a predicate for searching by childpath *)
(* replace n with length of child path *)
  | "\<And> x l e  . (x, l) \<in> ll_validl_q \<Longrightarrow>
                 (z \<in> set l \<Longrightarrow> z \<in> ll_valid3') \<Longrightarrow>
                 (\<not> (\<exists> k y e' . ((x, LSeq e l), (y, LLab e' (List.length k)), k) \<in> ll3'_descend)) \<Longrightarrow>
                 (x, (LSeq [] l)) \<in> ll_valid3'"
  | "\<And> x l e  z k y. (x, l) \<in> ll_validl_q \<Longrightarrow>
                (z \<in> set l \<Longrightarrow> z \<in> ll_valid3') \<Longrightarrow>
                (((x, LSeq e l), (y, LLab True (List.length k)), k) \<in> ll3'_descend) \<Longrightarrow>
                (\<And> k' y' . (((x, LSeq e l), (y, LLab True (List.length k')), k') \<in> ll3'_descend) \<Longrightarrow> k = k' \<and> y = y') \<Longrightarrow>
                (x, LSeq k l) \<in> ll_valid3'"

(* old version of ll3 validity, may have bugs *)
(*
inductive_set ll_valid3 :: "('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll set"
  where
    "\<And> i e x. (x, i) \<in> ll_valid_qi \<Longrightarrow>
               (x, L e i) \<in> ll_valid3"
  | "\<And> e x d. (x, d) \<in> ll_valid_ql \<Longrightarrow>
             (x, LLab e d) \<in> ll_valid3" 
  | "\<And> e x d s. (x, d, s) \<in> ll_valid_qj \<Longrightarrow>
                (x, (LJmp e d s)) \<in> ll_valid3"
  | "\<And> e x d s. (x, d, s) \<in> ll_valid_qji \<Longrightarrow>
               (x, (LJmpI e d s)) \<in> ll_valid3"
  | "\<And> x l e e' . (x, l) \<in> ll_validl_q \<Longrightarrow>
                 (z \<in> set l \<Longrightarrow> z \<in> ll_valid3) \<Longrightarrow>
                 (\<not> (\<exists> k y . ((x, LSeq e l), (y, LLab e' k), k) \<in> ll_descend)) \<Longrightarrow>
                 (x, (LSeq e l)) \<in> ll_valid3"
  | "\<And> x l e e' z. (x, l) \<in> ll_validl_q \<Longrightarrow>
                (z \<in> set l \<Longrightarrow> z \<in> ll_valid3) \<Longrightarrow>
                (\<exists>! k . \<exists>! y . (((x, LSeq e l), (y, LLab e' k), k) \<in> ll_descend)) \<Longrightarrow>
                (x, LSeq e l) \<in> ll_valid3"
    *)


(* dump an l2 to l3, marking all labels as unconsumed *)
fun ll3_init :: "ll2 \<Rightarrow> ll3" where
  "ll3_init (x, L e i) = (x, L e i)"
| "ll3_init (x, LLab e idx) = (x, LLab False idx)"
| "ll3_init (x, LJmp e idx s) = (x, LJmp e idx s)"
| "ll3_init (x, LJmpI e idx s) = (x, LJmpI e idx s)"
| "ll3_init (x, LSeq e ls) = 
   (x, LSeq [] (map ll3_init ls))"
(*
\<and>
 
*)


lemma ll3_init_noquant :
"(fst (ll3_init l) = fst l) \<and>
 (List.map (\<lambda> t . fst (ll3_init t)) ls = List.map fst ls)"
  apply(induction rule:my_ll_induct, auto)
  done

(* step one: prove that ll3_init does not touch qan's
   maaybe this could be done using parametricity? *)

lemma ll3_init_pres :
"((q, l2) \<in> ll_valid_q \<longrightarrow> (ll3_init (q, l2)) \<in> ll_valid_q)\<and>
 (((x,y), ls) \<in> ll_validl_q \<longrightarrow> ((x,y), (map ll3_init ls)) \<in> ll_validl_q)"
proof(induction rule: ll_valid_q_ll_validl_q.induct)
  case 1 thus ?case by (auto simp add:ll_valid_q_ll_validl_q.intros) next
  case 2 thus ?case by (auto simp add:ll_valid_q_ll_validl_q.intros) next
  case 3 thus ?case by (auto simp add:ll_valid_q_ll_validl_q.intros) next
  case 4 thus ?case by (auto simp add:ll_valid_q_ll_validl_q.intros) next
  case 5 thus ?case by (auto simp add:ll_valid_q_ll_validl_q.intros) next
  case 6 thus ?case by (auto simp add:ll_valid_q_ll_validl_q.intros) next
  case (7 n h n' t n'') thus ?case using ll3_init_noquant[of "((n,n'),h)" "[]"]
    apply(auto)
    apply(case_tac "ll3_init ((n,n'),h)", clarsimp)
    apply(rule ll_valid_q_ll_validl_q.intros(7), auto)
    done
qed

value "ll3_init (ll_pass1 (ll1.LSeq [ll1.LLab 0])) :: ll3"

(*
datatype consume_label_result =
  CFound "ll3 list" "childpath"
  | CNone "ll3 list"
  | CFail
*)

inductive cp_less :: "childpath \<Rightarrow> childpath \<Rightarrow> bool" where
"\<And> n t . cp_less [] (n#t)"
| "\<And> n n' t t' . n < n' \<Longrightarrow> cp_less (n#t) (n'#t')"
| "\<And> n t t' . cp_less t t' \<Longrightarrow> cp_less (n#t) (n#t')"

inductive cp_rev_less' :: "childpath \<Rightarrow> childpath \<Rightarrow> bool" where
"\<And> n t . cp_rev_less' [] (n#t)"
| "\<And> n n' t . n < n' \<Longrightarrow> cp_rev_less' (n#t) (n'#t)"
| "\<And> t t' n n' . cp_rev_less t t' \<Longrightarrow> cp_rev_less' (n#t) (n'#t')"

(* we need to capture incrementing a childpath *)
fun cp_next :: "childpath \<Rightarrow> childpath" where
"cp_next [] = []"
| "cp_next (h#t) = (Suc h)#t"



(* this should be "plus anything"? *)
lemma cp_rev_less'_suc1 :
"cp_rev_less' (Suc n # t) p \<Longrightarrow> cp_rev_less' (n#t) p"
  apply(induction rule:cp_rev_less'.induct)
    apply(auto simp add:cp_rev_less'.intros)
  done

(* i should not do it this way *)
inductive cp_rev_less :: "childpath \<Rightarrow> childpath \<Rightarrow> bool" where
"\<And> n t . cp_rev_less [] (n#t)"
| "\<And> n n' t t' . n < n' \<Longrightarrow> cp_rev_less (t@[n]) (t'@[n'])"
| "\<And> n t t' . cp_rev_less t t' \<Longrightarrow> cp_rev_less (t@[n]) (t'@[n])"


type_synonym consume_label_result = "(ll3 list * childpath) option"


(* TODO - proof plan
   first, we need to prove that the outputs of consume_label and then assign_label are qan-valid
   then, we need to have a "strong induction" theorem describing the results of consume_label
   under the conditions where we actually run it (if we haven't found a descendent yet for
   lesser paths  
   then we should have the additional facts we need to prove full ll3 validity for assign_labels
*)

(* this prevents multiple locations for the same label name
   because it will only "consume" one label per name
   and then it will fail later on the other one *)
(* modify this to pass around root?
   modify this to take a node instead of a node list? *)
(* subroutine for assign_label, marks label as consumed *)
fun ll3_consume_label :: "childpath \<Rightarrow> nat  \<Rightarrow> ll3 list \<Rightarrow> consume_label_result" where
 "ll3_consume_label p n [] = Some ([], [])"
(* Actually consume the label, but it must not be consumed yet *)
| "ll3_consume_label p n ((x, LLab b idx) # ls) = 
   (if idx = length p then (if b = False then Some ((x, LLab True idx)#ls, n#p) else None)
   else case (ll3_consume_label p (n+1) ls) of
    Some (ls', p') \<Rightarrow> Some ((x, LLab b idx)#ls', p')
   | None \<Rightarrow> None)"

| "ll3_consume_label p n ((x, LSeq e lsdec) # ls) =
   (case ll3_consume_label (n#p) 0 lsdec of
    Some (lsdec', []) \<Rightarrow> (case ll3_consume_label p (n+1) ls of
      Some (ls', p') \<Rightarrow> Some (((x, LSeq e lsdec') # ls'), p')
      | None \<Rightarrow> None)
    | Some (lsdec', p') \<Rightarrow> Some (((x, LSeq e lsdec') # ls), p')
    | None \<Rightarrow> None)"
  
| "ll3_consume_label p n (T#ls) =
   (case ll3_consume_label p (n+1) ls of
    Some (ls', p') \<Rightarrow> Some ((T#ls'), p')
    | None \<Rightarrow> None)"

(* we need to make this work with ll_induct, though *)
(*lemma ll3_consume_label_correct :
""*)

fun numnodes :: "('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll \<Rightarrow> nat" and
    numnodes_l :: "('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll list \<Rightarrow> nat" where
"numnodes (_, LSeq _ xs) = 1 + numnodes_l xs"
| "numnodes _ = 1"
| "numnodes_l [] = 1"
| "numnodes_l (h#t) = numnodes h + numnodes_l t"


(* should we shove the quantifiers into the Some case? *)
(* Another option, return a bool representing failure ? *)
(* no, i think we can just add a thing to the first case about
   how the numnodes of the result is less than original *)
(* we need another side for l, regarding what happens if l's head is an lseq *)
lemma ll3_consume_label_numnodes [rule_format] :
"
  (! e l l' p p' n q . t = (q, LSeq e l) \<longrightarrow> ll3_consume_label p n l = Some (l',p') \<longrightarrow> numnodes t \<ge> numnodes_l l' + 1) \<and>
  (! l' p p' n . ll3_consume_label p n l = Some (l', p') \<longrightarrow> numnodes_l l \<ge> numnodes_l l')"

proof(induction rule:my_ll_induct)
  case 1 thus ?case by auto next
  case 2 thus ?case by auto next
  case 3 thus ?case by auto next
  case 4 thus ?case by auto next
  case (5 q e l) thus ?case by auto next
  case 6 thus ?case by auto next
  case (7 h l) thus ?case
    apply(case_tac h)
    apply(clarsimp)
    apply(case_tac ba, clarsimp)
         apply(case_tac[1] "ll3_consume_label p (Suc n) l", clarsimp, auto)
         apply(blast)
        apply(case_tac[1] "x22 = length p", clarsimp)
         apply(case_tac[1] "x21", clarsimp, auto)
    apply(case_tac[1] "ll3_consume_label p (Suc n) l", clarsimp, auto, blast)
    apply(case_tac[1] "ll3_consume_label p (Suc n) l", clarsimp, auto, blast)
      apply(case_tac[1] "ll3_consume_label p (Suc n) l", clarsimp, auto, blast)
     apply(case_tac[1] "ll3_consume_label (n#p) 0 x52", clarsimp, auto)
     apply(case_tac[1] "ba", clarsimp, auto)
      apply(case_tac[1] "ll3_consume_label p (Suc n) l", clarsimp, auto)
    apply(drule_tac [1] x = aa in spec) 
    apply(drule_tac [1] x = ab in spec)
    
    apply(auto)
    done
qed

lemma ll3_consume_label_numnodes1 : "ll3_consume_label p n l = Some (l', p') \<Longrightarrow> numnodes_l l \<ge> numnodes_l l'"
  apply(insert ll3_consume_label_numnodes)
  apply(blast)
  done

(* finish this lemma statement, we may need a "strong" hypothesis
   about failing to run on previous steps, and re-stitching results *)


lemma ll3_consume_label_qvalid' :
"((q, t) \<in> ll_valid_q \<longrightarrow> (! ls e . t = (LSeq e ls) \<longrightarrow> (! p p' n ls' . ll3_consume_label p n ls = Some (ls', p') \<longrightarrow> (q, LSeq e ls') \<in> ll_valid_q)))
\<and> (((x,x'), ls) \<in> ll_validl_q \<longrightarrow> (! p p' n ls' . ll3_consume_label p n ls = Some (ls', p') \<longrightarrow> ((x,x'), ls') \<in> ll_validl_q ))"
  apply(induction rule:ll_valid_q_ll_validl_q.induct, auto simp add:ll_valid_q_ll_validl_q.intros)
  apply(case_tac h, auto)
      apply(case_tac[1] "ll3_consume_label p (Suc na) t", auto simp add:ll_valid_q_ll_validl_q.intros)
     apply(case_tac [1] "x22 = length p", clarsimp)
      apply(case_tac [1] "\<not>x21", clarsimp, auto)
      apply(rule_tac [1] "ll_valid_q_ll_validl_q.intros", auto)
      apply(erule_tac [1] "ll_valid_q.cases", auto simp add:ll_valid_q_ll_validl_q.intros)
     apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
     apply(rule_tac [1] "ll_valid_q_ll_validl_q.intros", auto)
    apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto simp add:ll_valid_q_ll_validl_q.intros)
   apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto simp add:ll_valid_q_ll_validl_q.intros)
  apply(case_tac "ll3_consume_label (na # p) 0 x52", auto)
  apply(case_tac b, auto)
   apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto simp add:ll_valid_q_ll_validl_q.intros)
  done

lemma ll3_consume_label_qvalid :
"(q,ls) \<in> ll_validl_q \<Longrightarrow> ll3_consume_label p n ls = Some (ls', p') \<Longrightarrow> (q, ls') \<in> ll_validl_q"
  apply(insert ll3_consume_label_qvalid')
  apply(case_tac q)
  apply(auto)
  done

lemma ll3_consume_label_hdq' :
  "(! e q qh h ts. t = (q, LSeq e ((qh,h)#ts)) \<longrightarrow>
      (! p n l' p'. ll3_consume_label p n ((qh,h)#ts) = Some (l',p') \<longrightarrow> 
     (? qh' h' ts' . l' = ((qh',h' )#ts') \<and> qh = qh'))) 
\<and>
  (! qh h ts . l = ((qh,h)#ts) \<longrightarrow>
    (! p n l' p' . ll3_consume_label p n l = Some (l', p') \<longrightarrow> 
    (? qh' h' ts' . l' = ((qh',h' )#ts') \<and> qh = qh')))"

  apply(induction rule:my_ll_induct)
        apply(auto)
  apply(case_tac[1] h, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
         apply(case_tac [1] "x22 = length p", auto)
          apply(case_tac [1] "\<not>x21", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
         apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
       apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
    apply(rename_tac [1] boo)
      apply(case_tac [1] boo, auto)
       apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)

  apply(case_tac[1] h, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
         apply(case_tac [1] "x22 = length p", auto)
          apply(case_tac [1] "\<not>x21", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
         apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
       apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
    apply(rename_tac [1] boo)
      apply(case_tac [1] boo, auto)
      apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)

  apply(case_tac[1] h, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
         apply(case_tac [1] "x22 = length p", auto)
          apply(case_tac [1] "\<not>x21", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
         apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
       apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
    apply(rename_tac [1] boo)
      apply(case_tac [1] boo, auto)
     apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)

  apply(case_tac[1] h, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
         apply(case_tac [1] "x22 = length p", auto)
          apply(case_tac [1] "\<not>x21", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
         apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
       apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
    apply(rename_tac [1] boo)
      apply(case_tac [1] boo, auto)
    apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)

  apply(case_tac[1] h, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
         apply(case_tac [1] "x22 = length p", auto)
          apply(case_tac [1] "\<not>x21", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
         apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)
       apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
    apply(rename_tac [1] boo)
      apply(case_tac [1] boo, auto)
   apply(case_tac[1] "ll3_consume_label p (Suc n) ts", auto)

    apply(case_tac[1] h, auto)
      apply(case_tac[1] "ll3_consume_label p (Suc n) l", auto)
         apply(case_tac [1] "x22 = length p", auto)
          apply(case_tac [1] "\<not>x21", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) l", auto)
         apply(case_tac[1] "ll3_consume_label p (Suc n) l", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) l", auto)
  apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
  apply(case_tac [1] b, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) l", auto)
  done

lemma ll3_consume_label_hdq :
  "ll3_consume_label p n ((qh,h)#ts') = Some (l', p') \<Longrightarrow>
    (? qh' h' ts' . l' = ((qh',h' )#ts') \<and> qh = qh')"
  apply(insert ll3_consume_label_hdq'[of bunk "((qh, h) # ts')"])
  apply(auto)
  apply(drule_tac x = p in spec)
  apply(drule_tac x = p in spec)
  apply(drule_tac x = n in spec)
  apply(drule_tac x = n in spec)
  apply(auto)
  done

(* new idea: we need to take into account arbitrary number of consumes (?) *)
(* idea: we need to take into account the other premises *)
(* crucially we need to properly track where in the list the change happened as a childpath *)
(* this means we need to track only the suffix.
*)
inductive_set ll3_consumes :: "(ll3 list * childpath set * ll3 list) set" where
"\<And> l . (l,{},l) \<in> ll3_consumes"
| "\<And> p n l l' . ll3_consume_label p n l = Some (l', []) \<Longrightarrow> (l,{},l') \<in> ll3_consumes"
| "\<And> p n l l' ph pt . ll3_consume_label p n l = Some (l', ph#pt) \<Longrightarrow> (l,{(ph#pt)}, l') \<in> ll3_consumes"
| "\<And> l s l' s' l'' . (l,s,l') \<in> ll3_consumes \<Longrightarrow> (l',s', l'') \<in> ll3_consumes \<Longrightarrow> (s \<inter> s' = {})  
     \<Longrightarrow> (l,s \<union> s',l'') \<in> ll3_consumes"

(*
New idea: either p' is nil, or
the path we return has p plus a prefix
this prefix will be greater than or equal
to [n] (that is, p is not less than [n]))
*)
lemma ll3_consume_label_char [rule_format] :
"
  (! e l . (t :: ll3) = (q, LSeq e l) \<longrightarrow> 
  (! p n p' . ll3_consume_label p n l = Some (l',p') \<longrightarrow> 
  (p' = [] \<or>
   p' = n#p \<or>
   (? pp . p' = pp@p \<and>
    cp_rev_less' [n] pp))))
\<and>
  (! p n l' p' . ll3_consume_label p n (l :: ll3 list) = Some (l', p') \<longrightarrow>
  (p' = [] \<or>
   p' = n#p \<or>
   (? pp . p' = pp@p \<and>
    cp_rev_less' [n] pp)))
"

proof(induction rule:my_ll_induct)
  case 1 thus ?case by auto next
  case 2 thus ?case by auto next
  case 3 thus ?case by auto next
  case 4 thus ?case by auto next
  case (5 q e l) thus ?case 
    apply(auto) done next
  case 6 thus ?case by auto next
  case (7 h l) thus ?case
    apply(case_tac h)
    apply(auto)
     apply(case_tac [1] ba, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) l", auto)
          apply(drule_tac[1] x = p in spec)
          apply(drule_tac[1] x = "Suc n" in spec)
         apply(auto)
    apply(subgoal_tac "cp_rev_less' [n] [Suc n]") apply(auto simp add:cp_rev_less'.intros)
          apply(drule_tac [1] cp_rev_less'_suc1) apply(auto)
          apply(drule_tac [1] cp_rev_less'_suc1) apply(auto)

     apply(case_tac [1] "x22 = length p", auto)
      apply(case_tac [1] "\<not>x21", auto)
        apply(case_tac [1] "ll3_consume_label p (Suc n) l", auto)
          apply(drule_tac[1] x = p in spec)
        apply(drule_tac[1] x = "Suc n" in spec) apply(auto)
    apply(subgoal_tac[1] "cp_rev_less' [n] [Suc n]") apply(auto simp add:cp_rev_less'.intros)
         apply(drule_tac [1] cp_rev_less'_suc1) apply(auto)
    apply(drule_tac [1] cp_rev_less'_suc1) apply(auto)

       apply(case_tac [1] "ll3_consume_label p (Suc n) l", auto)
          apply(drule_tac[1] x = p in spec)
       apply(drule_tac[1] x = "Suc n" in spec) apply(auto)
    apply(subgoal_tac[1] "cp_rev_less' [n] [Suc n]") apply(auto simp add:cp_rev_less'.intros)
         apply(drule_tac [1] cp_rev_less'_suc1) apply(auto)
         apply(drule_tac [1] cp_rev_less'_suc1) apply(auto)

      apply(case_tac [1] "ll3_consume_label p (Suc n) l", auto)
          apply(drule_tac[1] x = p in spec)
      apply(drule_tac[1] x = "Suc n" in spec) apply(auto)
    apply(subgoal_tac[1] "cp_rev_less' [n] [Suc n]") apply(auto simp add:cp_rev_less'.intros)
         apply(drule_tac [1] cp_rev_less'_suc1) apply(auto)
         apply(drule_tac [1] cp_rev_less'_suc1) apply(auto)

  apply(case_tac "ll3_consume_label (n#p) 0 x52", auto)
  apply(case_tac ba, auto)
       apply(case_tac "ll3_consume_label p (Suc n) l", auto)
          apply(drule_tac[1] x = p in spec)
       apply(drule_tac[1] x = "Suc n" in spec) apply(auto)
         apply(subgoal_tac[1] "cp_rev_less' [n] [Suc n]") apply(auto simp add:cp_rev_less'.intros)
         apply(drule_tac [1] cp_rev_less'_suc1) apply(auto)
       apply(drule_tac [1] cp_rev_less'_suc1) apply(auto) 
    (* i am unsure if this is provable. *)
    apply(case_tac [1] x52, auto)
      apply(case_tac[1] bb, auto)
    apply(case_tac [1] "ll3_consume_label (n # p)
              (Suc 0) lista", auto)
    apply(case_tac [1] list, auto)  

    apply(case_tac [1]
    apply(rotate_tac [1] 2)
                apply(drule_tac[1] x = "[]" in spec)
       apply(drule_tac[1] x = "Suc n" in spec) apply(auto)
         apply(drule_tac [1] cp_rev_less'_suc1) apply(auto)
    sorry

(* idea: have a neater characterization of ll3 correctness. 
   IF we return something for a particular n and path
   AND we didn't return anything for the prefix
   THEN we have returned the label with "smallest" path
*)

lemma ll3_consume_label_unch' :
"(! e l l' p n q. (t :: ll3) = (q, LSeq e l) \<longrightarrow> (ll3_consume_label p n l = Some(l', []) \<longrightarrow> l = l'))
\<and> (! p n ls' . ll3_consume_label p n ls = Some (ls', []) \<longrightarrow> ls = ls')"
  
  apply(induction rule:my_ll_induct)
        apply(auto)
  apply(case_tac ba, auto)
      apply(case_tac [1] "ll3_consume_label p (Suc n) l", auto)
     apply(case_tac [1] "x22 = length p", auto)
      apply(case_tac [1] "\<not>x21", auto)
     apply(case_tac [1] "ll3_consume_label p (Suc n) l", auto)
    apply(case_tac [1] "ll3_consume_label p (Suc n) l", auto)
   apply(case_tac [1] "ll3_consume_label p (Suc n) l", auto)
  apply(case_tac "ll3_consume_label (n#p) 0 x52", auto)
  apply(case_tac ba, auto)
  apply(case_tac "ll3_consume_label p (Suc n) l", auto)
  done

lemma ll3_consume_label_unch :
"\<And> p n ls ls' . ll3_consume_label p n ls = Some (ls', []) \<Longrightarrow> ls = ls'"
  apply(insert ll3_consume_label_unch')
  apply(blast)
  done

function (sequential) ll3_assign_label :: "ll3 \<Rightarrow> ll3 option" and
    ll3_assign_label_list :: "ll3 list \<Rightarrow> ll3 list option" where
  "ll3_assign_label (x, LSeq e ls) =
   (case (ll3_consume_label [] 0 ls) of
    Some (ls', p) \<Rightarrow> (case ll3_assign_label_list ls' of
      Some ls'' \<Rightarrow> Some (x, LSeq (rev p) ls'')
      | None \<Rightarrow> None)
   | None \<Rightarrow> None)"
(* unconsumed labels are an error *)
| "ll3_assign_label (x, LLab False idx) = None"
| "ll3_assign_label T = Some T"

| "ll3_assign_label_list [] = Some []"
| "ll3_assign_label_list (h#t) = 
   (case ll3_assign_label h of
    Some h' \<Rightarrow> (case ll3_assign_label_list t of
                Some t' \<Rightarrow> Some (h'#t')
                | None \<Rightarrow> None)
   | None \<Rightarrow> None)"
  by pat_completeness auto

termination 
  apply(relation "measure (\<lambda> x . case x of Inl t \<Rightarrow> numnodes t | Inr l \<Rightarrow> numnodes_l l)")
     apply(clarsimp)
    apply(auto)
    apply(induct_tac [2] "t", auto)
  apply(subgoal_tac "numnodes_l a \<le> numnodes_l ls", auto)
   apply(rule ll3_consume_label_numnodes1, auto)
  apply(case_tac ba, auto)
  done



(* lemma: "unch" for assign_label*)
lemma ll3_assign_label_unch' :
"(! q' t' . ll3_assign_label t = Some (q', t') \<longrightarrow> fst t = q') \<and>
 (! l' . ll3_assign_label_list l = Some l' \<longrightarrow> map fst l = map fst l')"
  apply(induction rule:my_ll_induct, auto)
      apply(case_tac [1] e, auto)
     apply(case_tac [1] e, auto)
    apply(case_tac[1] "ll3_consume_label [] 0 l", auto)
  apply(rename_tac abo) (* W  T F *)
    apply(case_tac[1] "ll3_assign_label_list ab", clarsimp)
  apply(auto)
   apply(case_tac [1] "ll3_consume_label [] 0 l", auto)
   apply(rename_tac abco)
   apply(case_tac "ll3_assign_label_list ab", auto)
  apply(case_tac "ll3_assign_label ((a,b), ba)", auto)
  apply(case_tac "ll3_assign_label_list l", auto)
  done

lemma ll3_assign_label_unch1 :
"ll3_assign_label (q,t) = Some (q', t') \<Longrightarrow> q = q'"
  apply(case_tac q, auto)
  apply(case_tac q', auto)
   apply(insert ll3_assign_label_unch')
   apply(auto)
   apply(blast)
  apply(blast)
  done

lemma ll3_assign_label_unch2 :
"ll3_assign_label_list ls = Some ls' \<Longrightarrow> map fst ls = map fst ls'"
  apply(insert ll3_assign_label_unch')
  apply(auto)
  done

(*
lemma ll3_consume_label_nofiddle :
"
("(! e l l' p n q. (t :: ll3) = (q, LSeq e l) \<longrightarrow> (ll3_consume_label p n l = Some(l', []) \<longrightarrow> l = l'))
\<and> (! p n ls' . ll3_consume_label p n ls = Some (ls', []) \<longrightarrow> ls = ls')")
\<and>
()
"
*)

(* my the inductive hypothesis is not right, maybe it needs to be strengthened
   in the list case. also I'm skeptical about this OR... *)
(* we need to revise the second clause along these lines *)
(* restate: if EITHER assigning the label immediately works yielding q''
   OR consuming the label and then assigning it works yielding q''
   THEN ll_valid_q holds on the result *)
(* I need to add in label consumption to the chain of the second case, it's not there now *)

(* We can state this more succinctly, because we are doing rule induction on premise. *)
(* Q: do we need to generalize over possible annotation changes? *)
(* TODO: this is still not quite right... we need to
   we need a "rest of ll3 assign label" as things stand we are basically trying to apply
   assign_label twice.
*)
(* our list case is subtly wrong,
   we need to be handling all recursive calls on sub cases.
   in practice what this means is that we need to 
   - handle the case where the head of the list is a Seq node?
*)

(* we need 2 lemmas here:
  1: if consuming and then assigning a label is q-valid, assigning the label must
     be valid under the same qan
  2: if assigning a label is valid, and consuming the label on the original list
     is also valid, then assigning the consumed label is valid under the same qan *)

(* Idea: doing consume_label can't make assign_labels at the root true
   and it can't make assign_labels at the root false *)
(*aeaeae
lemma ll3_assign_label_consume_label2' :
"((q, (t :: ll3t)) \<in> ll_valid_q \<longrightarrow>
  (! e l . t = LSeq e l \<longrightarrow> (! p n l' p' . ll3_consume_label p n l = Some (l', p') \<longrightarrow>
  
)
\<and>
()
"
*)



inductive_set ll3_consumes :: "(ll3 list * childpath set * ll3 list) set" where
"\<And> l . (l,{},l) \<in> ll3_consumes"
| "\<And> p n l l' . ll3_consume_label p n l = Some (l', []) \<Longrightarrow> (l,{},l') \<in> ll3_consumes"
| "\<And> p n l l' ph pt . ll3_consume_label p n l = Some (l', ph#pt) \<Longrightarrow> (l,{(ph#pt)}, l') \<in> ll3_consumes"
| "\<And> l s l' s' l'' . (l,s,l') \<in> ll3_consumes \<Longrightarrow> (l',s', l'') \<in> ll3_consumes \<Longrightarrow> (s \<inter> s' = {})  
     \<Longrightarrow> (l,s \<union> s',l'') \<in> ll3_consumes"

lemma ll3_consume_label_prefix :
"(! q e l . (t::ll3) = (q, LSeq e l) \<longrightarrow> 
   (! p n l' p'. (ll3_consume_label p n l = Some (l', p')) \<longrightarrow> 
    (p' = [] \<or> (? pp . p' = pp @ p))))
\<and>
((! p n l' p'. (ll3_consume_label p n (l :: ll3 list) = Some (l', p')) \<longrightarrow>
    (p' = [] \<or> (? pp . p' = pp @ p))))
"
  apply(induction rule:my_ll_induct, auto)
  apply(case_tac ba, auto)
      apply(case_tac " ll3_consume_label p (Suc n) l", auto) apply(blast)
     apply(case_tac "x22 = length p", auto)
      apply(case_tac "\<not> x21", auto)  apply(drule_tac[1] x = 
      apply(case_tac " ll3_consume_label p (Suc n) l", auto) apply(blast)
      apply(case_tac " ll3_consume_label p (Suc n) l", auto) apply(blast)
      apply(case_tac " ll3_consume_label p (Suc n) l", auto) apply(blast)
  apply(case_tac "ll3_consume_label (n # p) 0 x52", auto)
  apply(case_tac ba, auto)
      apply(case_tac " ll3_consume_label p (Suc n) l", auto) apply(blast)
  apply(case_tac x52, auto)
  apply(case_tac ba, auto)
      apply(case_tac " ll3_consume_label (n # p) (Suc 0) lista", auto) 
(*
lemma ll3_consume_label_diff :

"
(! e l . (t :: ll3) = (q, LSeq e l) \<longrightarrow> 
   ( ! p n l' ph pt. ll3_consume_label p n l = Some(l', (ph#pt)) \<longrightarrow> 
    (! p' n' l'' . ll3_consume_label p' n' l' = Some (l'', (ph'#pt')) \<longrightarrow>
        
     l'))
\<and> (! p n ls' . ll3_consume_label p n ls = Some (ls', (ph#pt)) \<longrightarrow> ls = ls')
"
*)
lemma ll3_consumes_extend :
"(l, s, l') \<in> ll3_consumes \<Longrightarrow> ll3_consume_label p n l' = Some (l'', ph#pt) \<Longrightarrow> (l,s\<union>{ph#pt},l'')\<in>ll3_consumes"
  apply(induction rule:ll3_consumes.induct)
     apply(auto simp add:ll3_consumes.intros)
  apply(drule_tac ll3_consume_label_unch, auto)
    apply(auto simp add:ll3_consumes.intros)
   apply(frule_tac ll3_consumes.intros(3))
   apply(rotate_tac [1] 1)
   apply(frule_tac ll3_consumes.intros(3))

   apply(subgoal_tac "(l,{pha # pta} \<union> {ph # pt}, l'') \<in> ll3_consumes") 
    apply(rule_tac[2] ll3_consumes.intros(4), auto)
     apply(auto simp add:ll3_consumes.intros)
  sorry (* this lemma fails because we aren't properly tracking paths *)

lemma ll3_consume_label_length :
"(! q e l . (t::ll3) = (q, LSeq e l) \<longrightarrow> 
   (! p n l' p'. (ll3_consume_label p n l = Some (l', p')) \<longrightarrow> length l = length l'))
\<and>
((! p n l' p'. (ll3_consume_label p n (l :: ll3 list) = Some (l', p')) \<longrightarrow> length l = length l'))
"
proof(induction rule:my_ll_induct)
  case 1 thus ?case by auto next
  case 2 thus ?case by auto next
  case 3 thus ?case by auto next
  case 4 thus ?case by auto next
  case (5 q e l) thus ?case by auto next
  case 6 thus ?case 
    apply(auto)
    done
  case (7 h l) thus ?case 
    apply(auto)
     apply(case_tac h, auto)
    apply(case_tac [1] ba, auto)
         apply(case_tac [1] "ll3_consume_label p (Suc n) l", auto) apply(blast)
       apply(case_tac [1] "x22 = length p", auto)

        apply(case_tac [1] "\<not>x21", auto)

       apply(case_tac [1] "ll3_consume_label p (Suc n) l", auto) apply(blast)
    apply(case_tac [1] "ll3_consume_label p (Suc n) l", auto) apply(blast)
    apply(case_tac [1] "ll3_consume_label p (Suc n) l", auto) apply(blast)

     apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
    apply(case_tac [1] ba, auto)
    apply(case_tac [1] "ll3_consume_label p (Suc n) l", auto) apply(blast)
    done
qed

lemma ll3_consumes_length :
"(l1, s, l2) \<in> ll3_consumes \<Longrightarrow> length l1 = length l2"
  apply(induction rule:ll3_consumes.induct, auto)
   apply(insert  ll3_consume_label_length, blast+)
  done

lemma set_diff_fact :
"s \<inter> s' = {} \<Longrightarrow> (s \<union> s') - (s \<union> t) = s' - t"
  apply(blast+)
  done

lemma set_diff_fact2 :
"s \<inter> s' = {} \<Longrightarrow> (s \<union> s') - (t \<union> s') = s - t"
  apply(blast+)
  done

lemma set_diff_fact3 :
"s \<inter> s' = {} \<Longrightarrow> sa \<subseteq> s \<Longrightarrow> s'a \<subseteq> s' ==> (s \<union> s') - (sa \<union> s'a) = (s - sa) \<union> (s' - s'a)"
  apply(auto)
  done

lemma set_diff_dist1 :
"(s1 - ss1) \<union> (s2 - ss2) \<subseteq>
(s1 \<union> s2) "
  apply(blast)
  done

lemma set_diff_dist2:
"? sk . (s1 - ss1) \<union> (s2 - ss2) = ((s1 \<union> s2) - sk)"
  apply(insert set_diff_dist1)
  apply(blast)
  done

lemma quick_opt_split :
"\<And> opt r f r'. (case opt of
  None \<Rightarrow> None
  | Some r \<Rightarrow> Some (f r)) = Some r' \<Longrightarrow> (? r . opt = Some r \<and> r' = f r)"
  apply(case_tac opt, auto)
  done

lemma ll3_consumes_split :
"(l1, s, l2) \<in> ll3_consumes \<Longrightarrow> 
(! q1 h1 t1 q2 h2 t2 . l1 = (q1, h1) # t1 \<longrightarrow> l2 = (q2, h2) # t2 \<longrightarrow> 
  (q1 = q2 \<and> (? s' . s' \<subseteq> s \<and> (t1, s', t2) \<in> ll3_consumes \<and>
           ((h1 = h2 \<and> s = s') \<or> 
              (? n . h1 = LLab False n \<and> h2 = LLab True n \<and> (? s'' . s'' \<subseteq> s \<and> s' = s - s'')) \<or> 
              (? e ls1 ls2 . h1 = LSeq e ls1 \<and> h2 = LSeq e ls2 \<and> 
               (? s''.  s'' = s - s' \<and> s = s'' \<union> s' \<and> (ls1, s'', ls2) \<in> ll3_consumes))))))"
proof(induction rule:ll3_consumes.induct)
  case (1 l) thus ?case
    apply(auto simp add:ll3_consumes.intros) 
    done next
  case (2 p n l l')
  then show ?case
    apply(auto)
      apply(case_tac h1, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
         apply(case_tac [1] "x22 = length p", auto)
          apply(case_tac [1] "\<not>x21", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
         apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
       apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
    apply(rename_tac [1] boo)
      apply(case_tac [1] boo, auto)
       apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)

      apply(case_tac h1, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
         apply(case_tac [1] "x22 = length p", auto)
          apply(case_tac [1] "\<not>x21", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
         apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
       apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
    apply(rename_tac [1] boo)
      apply(case_tac [1] boo, auto)
      apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)

     apply(frule_tac[1] ll3_consume_label_unch, auto)
      apply(insert ll3_consumes.intros(1)) apply(blast)

    apply(frule_tac[1] ll3_consume_label_unch, auto)
    done next

  case (3 p n l l' ph pt) thus ?case
    apply(clarify)
    apply(simp)

    apply(rule conjI)
     apply(drule_tac ll3_consume_label_hdq) apply(simp)

    apply(rule conjI)
     apply(drule_tac ll3_consume_label_hdq) apply(simp)

    apply(case_tac h1, simp)
        apply(case_tac[1] "ll3_consume_label p (Suc n) t1") apply(simp)
        apply(auto 2 1)
        apply(drule_tac [1] "ll3_consumes.intros")
        apply(auto 2 1)

               apply(case_tac [1] "x22 = length p", auto 2 1)
          apply(case_tac [1] "\<not>x21", auto 2 1)
          apply(rule_tac [1] x = "{}" in exI)
    apply(auto 2 1)
        apply(rule_tac [1] "ll3_consumes.intros")

        apply(case_tac[1] "ll3_consume_label p (Suc n) t1") apply(simp)
        apply(auto 2 1)
       apply(drule_tac [1] "ll3_consumes.intros") apply(auto 2 1)
      
        apply(case_tac[1] "ll3_consume_label p (Suc n) t1") apply(simp)
        apply(auto 2 1)
       apply(drule_tac [1] "ll3_consumes.intros") apply(auto 2 1)

        apply(case_tac[1] "ll3_consume_label p (Suc n) t1") apply(simp)
       apply(auto 2 1)

      apply(case_tac[1] "ll3_consume_label p (Suc n) t1") apply(simp)
        apply(auto 2 1)
      apply(drule_tac [1] "ll3_consumes.intros") apply(auto 2 1)

      apply(case_tac[1] "ll3_consume_label p (Suc n) t1") apply(auto 2 1)

    apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto 2 1)
    apply(rename_tac [1] "boo")
apply(case_tac [1] "boo", auto 2 1)

     apply(case_tac[1] "ll3_consume_label p (Suc n) t1") apply(auto 2 0)
     apply(drule_tac [1] "ll3_consume_label_unch", auto 2 0)
     apply(drule_tac [1] "ll3_consumes.intros") 
     apply(auto 2 1)

    apply(rule_tac [1] x = "{}" in exI, auto 2 0)
     apply(rule_tac [1] "ll3_consumes.intros")
    apply(drule_tac [1] "ll3_consumes.intros", auto 2 0 )
    done next

  case (4 l s l' s' l'') thus ?case
    apply(clarify)
    apply(simp)
    apply(case_tac l', auto 2 0)
            apply(drule_tac[1] ll3_consumes_length, simp)
           apply(drule_tac[1] ll3_consumes_length, simp)
          apply(drule_tac[1] ll3_consumes_length, simp)
               apply(rule_tac [1] x = "s \<union> s'" in exI)
    apply(auto 2 1)
         apply(rule_tac [1] ll3_consumes.intros(4), simp) apply(auto 2 1)
        apply(rule_tac [1] x = "s \<union> (s' - s'')" in exI) apply(auto 2 1)
         apply(rule_tac [1] ll3_consumes.intros(4), simp) apply(auto 2 1)
        apply(rule_tac [1] x = "s''" in exI) apply(auto 2 1)
    apply(blast)
      
       apply(rule_tac [1] x = "s \<union> s'a" in exI) apply(auto 2 1)
         apply(rule_tac [1] ll3_consumes.intros(4), simp) apply(auto 2 1)
        apply(subgoal_tac [1] "(s \<union> s') - (s \<union> s'a) = s' - s'a")
          apply(rule_tac [2] set_diff_fact)
    apply(subgoal_tac [1] "(ls1, s - s'a, ls2) \<in> ll3_consumes")
         apply(simp)  apply(simp)
        apply(auto 2 1) 

       apply(subgoal_tac [1] "(s \<union> s') - (s \<union> s'a) = s' - s'a")
        apply(rule_tac [2] set_diff_fact) apply(simp) apply(simp)

    apply(rule_tac [1] x = "(s - s'') \<union> s'" in exI)
      apply(auto 2 1)
         apply(rule_tac [1] ll3_consumes.intros(4), simp) apply(auto 2 1)
    apply(rule_tac [1] x = s'' in exI)
      apply(auto 2 1)
    apply(blast)     

    apply(rule_tac [1] x = "(s'a \<union> s')" in exI)
      apply(auto 2 1)
       apply(rule_tac [1] ll3_consumes.intros(4), simp) apply(auto 2 1)
      apply(subgoal_tac [1] "(s \<union> s') - (s'a \<union> s') = s - s'a") 
       apply(rule_tac [2] set_diff_fact2) apply(simp) apply(simp)
      apply(subgoal_tac [1] "(s \<union> s') - (s'a \<union> s') = s - s'a") 
       apply(rule_tac [2] set_diff_fact2) apply(simp) apply(simp)

    apply(rule_tac [1] x = "(s'a \<union> s'aa)" in exI)
      apply(auto 2 1)
       apply(rule_tac [1] ll3_consumes.intros(4), simp) apply(auto 2 1)
       apply(blast)

apply(subgoal_tac [1] "(ls1, (s - s'a) \<union> (s' - s'aa), ls2a) \<in> ll3_consumes")
    apply(rule_tac [2] ll3_consumes.intros(4)) apply(auto 1 2)
       apply(subgoal_tac [1] " s \<union> s' - (s'a \<union> s'aa) = (s - s'a) \<union> (s' - s'aa)")
    
        apply(rule_tac [2] set_diff_fact3) apply(simp) apply(simp)
        apply(auto 2 1)

      apply(subgoal_tac [1] " s \<union> s' - (s'a \<union> s'aa) = (s - s'a) \<union> (s' - s'aa)")
      apply(rule_tac [2] set_diff_fact3) apply(simp)
    apply(auto 2 1)
apply(subgoal_tac [1] "(ls1, (s - s'a) \<union> (s' - s'aa), ls2a) \<in> ll3_consumes")
    apply(rule_tac [2] ll3_consumes.intros(4)) apply(auto 1 2)

   apply(subgoal_tac [1] "(ls1, (s - s'a) \<union> (s' - s'aa), ls2a) \<in> ll3_consumes")
    apply(rule_tac [2] ll3_consumes.intros(4)) apply(auto 1 2)
      apply(subgoal_tac [1] " s \<union> s' - (s'a \<union> s'aa) = (s - s'a) \<union> (s' - s'aa)")

     apply(rule_tac [2] set_diff_fact3) apply(simp) apply(auto 2 1)
    done qed

(*
lemma ll3_consumes_split :
"(l1, s, l2) \<in> ll3_consumes \<Longrightarrow> 
(! q1 h1 t1 q2 h2 t2 . l1 = (q1, h1) # t1 \<longrightarrow> l2 = (q2, h2) # t2 \<longrightarrow> 
  (q1 = q2 \<and> (h1 = h2 \<or> 
              (? n . h1 = LLab False n \<and> h2 = LLab True n) \<or> 
              (? e ls1 ls2 . h1 = LSeq e ls1 \<and> h2 = LSeq e ls2 \<and> 
               (? s' . (ls1, (s - s'), ls2) \<in> ll3_consumes))
\<and> (? s' . (t1, (s - s'), t2) \<in> ll3_consumes))))"
proof(induction rule:ll3_consumes.induct)
  case (1 l) thus ?case
    apply(auto simp add:ll3_consumes.intros) done next
  case (2 p n l l')
  then show ?case
    apply(auto)
      apply(case_tac h1, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
         apply(case_tac [1] "x22 = length p", auto)
          apply(case_tac [1] "\<not>x21", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
         apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
       apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
    apply(rename_tac [1] boo)
      apply(case_tac [1] boo, auto)
       apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)

      apply(case_tac h1, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
         apply(case_tac [1] "x22 = length p", auto)
          apply(case_tac [1] "\<not>x21", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
         apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
       apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
    apply(rename_tac [1] boo)
      apply(case_tac [1] boo, auto)
      apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)

     apply(case_tac h1, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
         apply(case_tac [1] "x22 = length p", auto)
         apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
         apply(case_tac [1] "x22 = length p", auto)
    apply(case_tac [1] "\<not> x21", auto)
         apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
       apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)

       apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
    apply(rename_tac [1] boo)
      apply(case_tac [1] boo, auto)
      apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
     apply(drule_tac [1] ll3_consume_label_unch, auto)
    apply(drule_tac [1] ll3_consume_label_unch, auto)
    done next
  case (3 p n l l' ph pt) thus ?case
    apply(clarify)
       apply(case_tac h1, auto)
                    apply(case_tac "ll3_consume_label p (Suc n) t1", auto)
                    apply(case_tac "ll3_consume_label p (Suc n) t1", auto)
                    apply(case_tac "ll3_consume_label p (Suc n) t1", auto)

               apply(case_tac [1] "x22 = length p", auto)
                  apply(case_tac [1] "\<not>x21", auto)
                    apply(case_tac "ll3_consume_label p (Suc n) t1", auto)
  
               apply(case_tac [1] "x22 = length p", auto)
                  apply(case_tac [1] "\<not>x21", auto)
                    apply(case_tac "ll3_consume_label p (Suc n) t1", auto)

               apply(case_tac [1] "x22 = length p", auto)
                  apply(case_tac [1] "\<not>x21", auto)
               apply(case_tac "ll3_consume_label p (Suc n) t1", auto)

               apply(case_tac [1] "x22 = length p", auto)
                  apply(case_tac [1] "\<not>x21", auto)
              apply(case_tac "ll3_consume_label p (Suc n) t1", auto)

             apply(case_tac "ll3_consume_label p (Suc n) t1", auto)

              apply(case_tac "ll3_consume_label p (Suc n) t1", auto)

           apply(case_tac "ll3_consume_label p (Suc n) t1", auto)

              apply(case_tac "ll3_consume_label p (Suc n) t1", auto)

              apply(case_tac "ll3_consume_label p (Suc n) t1", auto)

              apply(case_tac "ll3_consume_label p (Suc n) t1", auto)

         apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
       apply(rename_tac[1] boo)
    apply(case_tac boo, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)

         apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
       apply(rename_tac[1] boo)
    apply(case_tac boo, auto)
      apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)

         apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
       apply(rename_tac[1] boo)
    apply(case_tac boo, auto)
      apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
      apply(drule_tac [1] ll3_consume_label_unch, auto)
     apply(drule_tac [1] ll3_consumes.intros(3)) 
    apply(drule_tac [1] x = "{}" in spec, auto)

    apply(case_tac "ll3_consume_label (n # p) 0 x52", auto)
       apply(rename_tac[1] boo)
    apply(case_tac boo, auto)
     apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
      apply(drule_tac [1] ll3_consume_label_unch, auto)

    apply(drule_tac [1] x = "{ph#pt}" in spec, auto)
    apply(subgoal_tac [1] "(t2, {}, t2) \<in> ll3_consumes")
     apply(rule_tac [2] ll3_consumes.intros)
    apply(auto)
    done next
  case (4 l s l' s' l'') thus ?case
    apply(clarify)
    apply(simp)
    apply(case_tac l', auto)
    apply(drule_tac[1] ll3_consumes_length, auto)
            apply(drule_tac[1] ll3_consumes_length, auto)
           apply(drule_tac[1] ll3_consumes_length, auto)
          apply(drule_tac[1] ll3_consumes_length, auto)
         apply(drule_tac[1] x = "s \<union> s'aa" in spec)
         apply(subgoal_tac[1] "(ls1, s \<union> s' - (s \<union> s'aa), ls2) \<in> ll3_consumes") apply(auto)
         apply(subgoal_tac[1] "s \<union> s' - (s \<union> s'aa) = s' - s'aa", auto)

         apply(drule_tac[1] x = "s' \<union> s'aa" in spec)
               apply(subgoal_tac[1] "(ls1, s \<union> s' - (s' \<union> s'aa), ls2) \<in> ll3_consumes") apply(auto)
        apply(subgoal_tac[1] "s \<union> s' - (s' \<union> s'aa) = s - s'aa", auto)

    
    apply(subgoal_tac [1] "(ls1, (s - s'aa) \<union> (s' - s'c), ls2a) \<in> ll3_consumes")
        apply(rule_tac[2] ll3_consumes.intros) apply(auto)

       apply(subgoal_tac [1] "? sk . s - s'aa \<union> (s' - s'c) = ((s \<union> s') - sk)")
        apply(clarsimp)
       apply(rule_tac[1] set_diff_dist2) 

      (* i think i'm stuck here *)
      apply(subgoal_tac [1] "(t1, (s - s'aa) \<union> (s' - s'aa), ls2) \<in> ll3_consumes")
         apply(rule_tac[2] ll3_consumes.intros) apply(auto)

       apply(subgoal_tac [1] "? z . s - s'aa \<union> (s' - s'aa) =  ")

       apply(rule_tac[2] ll3_consumes.intros) apply(auto)


       apply(clarsimp)

       apply(rule_tac[2] ll3_consumes.intros) apply(auto)

    apply(

         apply(drule_tac x = "s' \<union> s'aa" in spec)

       apply(subgoal_tac[1] "(\<exists> sl . (ls1, s \<union> s' - sl, ls2a) \<in> ll3_consumes)") apply(simp)
       apply(drule_tac [1] "ll3_consumes.intros")
         apply(auto)
       apply(drule_tac [1] x = "s \<union> (s'aa \<union> s'c)" in spec)

       apply(frule_tac[1]set_diff_fact[of s s'])
    apply(simp)
       apply(clarify)
    apply(rule_tac [1] set_diff_dist2)

     (* we need to figure out if s'aa and s'c have an intersection *)
     (* dealing with the set theory here is annoying and may end up being unnecessary
        hopefully this proof technique works. *)
       apply(subgoal_tac[1] "(ls1, (s - s'aa) \<union> (s' - s'c), ls2a) \<in> ll3_consumes") 
    (* this case should be true because we can "distribute" the subtraction"
       actually i don't think so *)
    apply(rule_tac [1] ll3_consumes.intros(4))
        
        apply(auto)
    apply(drule_tac [1] ll3_consumes.intros(4))

    apply(drule_tac [1] 
    apply(drule_tac x = "s' \<union> h")


    apply(subgoal_tac[1] "(ls1, s \<union> s' - (s \<union> {s'a}), ls2) \<in> ll3_consumes"
, simp)    
    apply(rule_tac [2] set_diff_fact, simp)
    apply(drule_tac[1] set_diff_fact[of "{s'a}"])

      
  
    apply(auto)
  

    apply(auto)
    
    

*)
(*
lemma ll3_consumes_split :
"(l1, l2) \<in> ll3_consumes \<Longrightarrow> (! h1 t1 h2 t2 . l1 = h1 # t1 \<longrightarrow> l2 = h2 # t2 \<longrightarrow> (fst h1 = fst h2 \<and> (t1, t2) \<in> ll3_consumes))"
proof(induction rule:ll3_consumes.induct)
  case (1 l) thus ?case
    apply(auto simp add:ll3_consumes.intros) done next
  case (2 p n l l' p')
  then show ?case
    apply(auto)
      apply(case_tac ba, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
         apply(case_tac [1] "x22 = length p", auto)
          apply(case_tac [1] "\<not>x21", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
      apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
      apply(case_tac [1] ba, auto)
      apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)

      apply(case_tac ba, auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
         apply(case_tac [1] "x22 = length p", auto)
          apply(case_tac [1] "\<not>x21", auto)
        apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
          apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
      apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
      apply(case_tac ba, auto)
        apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)

      apply(case_tac ba, auto)
        apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
        apply(subgoal_tac[1] "ll3_consume_label p n (((aa, bb), llt.L () x12) # t1) = Some ((((aa, bb), llt.L () x12) # t2), p')")
    apply(drule_tac [1] ll3_consumes.intros(2)[of p "(Suc n)"], auto)

         apply(case_tac [1] "x22 = length p", auto)
        apply(case_tac [1] "\<not>x21", auto)
       apply(subgoal_tac[1] "ll3_consume_label p n (((aa, bb), llt.LLab False (length p)) # t2) = Some ((((aa, bb), llt.LLab True (length p)) # t2), p')")
         apply(rule_tac [1] ll3_consumes.intros(1), auto)

       apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
     apply(subgoal_tac[1] "ll3_consume_label p n (((aa, bb), llt.LLab x21 x22) # t1) = Some ((((aa, bb), llt.LLab x21 x22) # t2), p')")
    apply(rule_tac [1] ll3_consumes.intros(2)[of p "(Suc n)"], auto)

      apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
      apply(subgoal_tac[1] "ll3_consume_label p n (((aa, bb), LJmp () x32 x33) # t1) = Some ((((aa, bb), LJmp () x32 x33) # t2), p')")
         apply(rule_tac [1] ll3_consumes.intros(2)[of p "(Suc n)"], auto)
 
     apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
      apply(subgoal_tac[1] "ll3_consume_label p n (((aa, bb), LJmpI () x42 x43) # t1) = Some ((((aa, bb), LJmpI () x42 x43) # t2), p')")
         apply(rule_tac [1] ll3_consumes.intros(2)[of p "(Suc n)"], auto)

    apply(case_tac [1] "ll3_consume_label (n # p) 0 x52", auto)
    apply(case_tac [1] ba, auto)
     apply(case_tac[1] "ll3_consume_label p (Suc n) t1", auto)
    apply(subgoal_tac[1] "ll3_consume_label p n (((aa, bb), LSeq x51 x52) # t1) = Some ((((aa, bb), LSeq x51 x52) # t2), p')")
      apply(rule_tac [1] ll3_consumes.intros(2)[of p "(Suc n)"], auto)
     apply(drule_tac [1] ll3_consume_label_unch, auto)

    apply(rule_tac [1] ll3_consumes.intros(1))
    done next

  case (3 l l' l'') thus ?case
    apply(clarify)
    apply(case_tac [1] l', auto)
       apply(drule_tac ll3_consumes_length, auto)
      apply(drule_tac ll3_consumes_length, auto)
     apply(drule_tac ll3_consumes_length, auto)
    apply(rule_tac [1] ll3_consumes.intros(3), auto)
    done qed

  *)

(*
lemma ll3_consumes_char' :
"(! q e h l . (t::ll3) = (q, LSeq e (h#l)) \<longrightarrow> 
   (! p n h' l' p'. (ll3_consume_label p n (h#l) = Some (h'#l', p')) \<longrightarrow> (fst h = fst h')length l = length l'))
\<and>
((! p n l' p'. (ll3_consume_label p n (l :: ll3 list) = Some (l', p')) \<longrightarrow> length l = length l'))
"
*)
lemma ll3_assign_label_qvalid' :
"((q,t) \<in> ll_valid_q \<longrightarrow> ((! q' t' . ll3_assign_label (q,t) = Some (q',t') \<longrightarrow> q = q' \<and> (q',t') \<in> ll_valid_q) \<and>
    ((! e l . t = LSeq e l \<longrightarrow> (!p n  s l' . (l,s,l') \<in> ll3_consumes \<longrightarrow>
                     (! l'' . ll3_assign_label_list l' = Some l'' \<longrightarrow> (q,l'') \<in> ll_validl_q))))))
\<and> (((x,x'), ls) \<in> ll_validl_q \<longrightarrow> 
    ((! ls' . ll3_assign_label_list ls = Some ls' \<longrightarrow> ((x,x'), ls') \<in> ll_validl_q ))
     \<and> (!p n  s ls' . (ls,s,ls') \<in> ll3_consumes \<longrightarrow>
                     (! ls'' . ll3_assign_label_list ls' = Some ls'' \<longrightarrow> ((x,x'),ls'') \<in> ll_validl_q)))"
  apply(induction rule:ll_valid_q_ll_validl_q.induct, auto simp add:ll_valid_q_ll_validl_q.intros)
    apply(case_tac e, auto simp add:ll_valid_q_ll_validl_q.intros)
    apply(case_tac e, auto simp add:ll_valid_q_ll_validl_q.intros)
    apply(case_tac e, auto simp add:ll_valid_q_ll_validl_q.intros)

  apply(case_tac "ll3_consume_label [] 0 l", auto)
   apply(case_tac "ll3_assign_label_list aa", auto)
  
  apply(case_tac "ll3_consume_label [] 0 l", auto)
    apply(case_tac "ll3_assign_label_list aa", auto)

  apply(case_tac "ll3_consume_label [] 0 l", auto)
     apply(case_tac "ll3_assign_label_list aa", auto)
     apply(rule_tac [1] ll_valid_q_ll_validl_q.intros)
     apply(case_tac ba, auto)
      apply(drule_tac "ll3_consume_label_unch", auto)
      
     apply(subgoal_tac [1] "(l,{ac#list}, aa) \<in> ll3_consumes")
      apply(blast)

     apply(rule_tac [1] ll3_consumes.intros, auto)

    apply(drule_tac [1] ll3_consumes_length, auto simp add:ll_valid_q_ll_validl_q.intros)

   apply(case_tac [1] "ll3_assign_label ((n, n'), h)", auto)
 apply(case_tac [1] "ll3_assign_label_list t", auto)
   apply(auto simp add:ll_valid_q_ll_validl_q.intros)

  apply(case_tac[1] ls', auto)
   apply(drule_tac[1] ll3_consumes_length, auto)
  apply(case_tac[1] "ll3_assign_label ((a, b), ba)", auto)
  apply(case_tac [1] "ll3_assign_label_list list", auto)

  apply(frule_tac "ll3_assign_label_unch1", auto)

  apply(drule_tac ll3_consumes_split)
  apply(auto simp add:ll_valid_q_ll_validl_q.intros)
  apply(drule_tac [1] ll_valid_q.cases, auto)
   apply(auto simp add:ll_valid_q_ll_validl_q.intros)

  apply(case_tac "ll3_consume_label [] 0 ls2", auto)
  apply(case_tac "ll3_assign_label_list a", auto)
  apply(rule_tac [1] ll_valid_q_ll_validl_q.intros)
    apply(auto simp add:ll_valid_q_ll_validl_q.intros)

  apply(rule_tac [1] ll_valid_q_ll_validl_q.intros)
  (* we now need a consumes fact about ls1, ?, ls2 *)
  (* I'm like 90% sure this is provable from here *)
  apply(case_tac b, auto)
  apply(drule_tac ll3_consume_label_unch, auto)
  apply(subgoal_tac [1] "(ls2, {ad#lista}, a) \<in> ll3_consumes")
  apply(drule_tac [1] ll3_consumes.intros(3))
    apply(auto simp add:ll_valid_q_ll_validl_q.intros)
  (* this will be a lemma, consumes_split *)
  apply(subgoal_tac "aa = n \<and> bb = n' \<and>
      (? s' .( t,s',list) \<in> ll3_consumes) \<and>
      (! e1 l1 e2 l2 . h = LSeq e1 l1 \<longrightarrow> ba = LSeq e2 l2 \<longrightarrow> (? s' . (l1, s', l2) \<in> ll3_consumes))"
, auto)
      apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)
      apply(case_tac h, auto)
       

      apply(drule_tac [1] ll3_consumes.cases, auto)
        apply(drule_tac [1] ll3_consume_label_unch, auto)
    

  apply(case_tac [1] "ba", auto)
  apply(drule_tac [1] ll3_consumes.cases, auto)

  apply(blast)

(* very likely we need an inner induction here *)
  apply(drule_tac ll3_consumes.cases, auto)
     apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
    apply(drule_tac [1] ll3_consume_label_unch, auto)
         apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)

  apply(case_tac[1] h, auto)
       apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
  apply(drule_tac [1] ll_valid_q.cases, auto)
       apply(rule_tac[1] ll_valid_q_ll_validl_q.intros)
        apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
       apply(subgoal_tac [1] "(t,{ph#pt},list) \<in> ll3_consumes") apply(blast)
       apply(rule_tac [1] ll3_consumes.intros, auto)

      apply(case_tac [1] "x22 = length p", auto)
       apply(case_tac [1] "\<not>x21", auto)
       apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
  apply(drule_tac [1] ll_valid_q.cases, auto)
       apply(auto simp add:ll_valid_q_ll_validl_q.intros)
  apply(case_tac "ll3_consume_label p (Suc na) t", auto)
       apply(rule_tac[1] ll_valid_q_ll_validl_q.intros)
     apply(auto simp add:ll_valid_q_ll_validl_q.intros)

  apply(subgoal_tac [1] "(t, {ph#pt}, list) \<in> ll3_consumes") apply(blast)
       apply(rule_tac [1] ll3_consumes.intros, auto)

  apply(case_tac "ll3_consume_label p (Suc na) t", auto)
       apply(rule_tac[1] ll_valid_q_ll_validl_q.intros)
      apply(auto simp add:ll_valid_q_ll_validl_q.intros)
  apply(drule_tac [1] ll_valid_q.cases, auto)
  apply(subgoal_tac [1] "(t, {ph#pt}, list) \<in> ll3_consumes") apply(blast)
     apply(rule_tac [1] ll3_consumes.intros, auto)

  apply(case_tac "ll3_consume_label p (Suc na) t", auto)
       apply(rule_tac[1] ll_valid_q_ll_validl_q.intros)
      apply(auto simp add:ll_valid_q_ll_validl_q.intros)
  apply(drule_tac [1] ll_valid_q.cases, auto)
  apply(subgoal_tac [1] "(t, {ph#pt}, list) \<in> ll3_consumes") apply(blast)
    apply(rule_tac [1] ll3_consumes.intros, auto)

   apply(case_tac [1] "ll3_consume_label (na # p) 0 x52", auto)
   apply(rename_tac [1] boo)
   apply(case_tac [1] boo, auto)
  apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
    apply(case_tac [1] "ll3_consume_label [] 0 ac", auto)
   apply(rename_tac [1] boo2)
    apply(case_tac [1] "ll3_assign_label_list ad", auto)
    apply(drule_tac [1] ll3_consume_label_unch, auto)
    apply(drule_tac [1] ll_valid_q.cases, auto)
    apply(drule_tac [1] ll_valid_q.cases, auto)

    apply(rule_tac[1] ll_valid_q_ll_validl_q.intros)
     apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
  apply(subgoal_tac [1] "(t, {ph#pt}, list) \<in> ll3_consumes") apply(blast)
    apply(rule_tac [1] ll3_consumes.intros, auto)

    apply(case_tac [1] "ll3_consume_label [] 0 ac", auto)
   apply(rename_tac [1] boo3)
   apply(case_tac [1] "ll3_assign_label_list ad", auto)
    apply(drule_tac [1] ll_valid_q.cases, auto)
  
    apply(rule_tac[1] ll_valid_q_ll_validl_q.intros)
    apply(rule_tac[1] ll_valid_q_ll_validl_q.intros)
    apply(case_tac[1] boo3, auto)
    apply(drule_tac [1] ll3_consume_label_unch, auto)
  apply(subgoal_tac [1] "(l, {ph#pt}, ad) \<in> ll3_consumes") apply(blast)
    apply(rule_tac [1] ll3_consumes.intros, auto)

  apply(frule_tac [2] ll3_assign_label_unch1, auto)
  apply(rule_tac [2] ll_valid_q_ll_validl_q.intros)

   apply(subgoal_tac [1] "(l, {ph#pt} \<union> {a#lista}, ad) \<in> ll3_consumes") apply(blast)
  
    apply(rule_tac [1] ll3_consumes.intros(4), auto)

  apply(subgoal_tac [1]

  apply(auto)

  apply(case_tac [1] "ll3_assign_label ((n, n'), h)", auto)
     apply(case_tac [1] "ll3_assign_label_list t", auto)
     apply(auto simp add:ll_valid_q_ll_validl_q.intros)

    apply(case_tac [1] "ll3_assign_label ((a, b), ba)", auto)
    apply(case_tac [1] "ll3_assign_label_list list", auto)
  apply(drule_tac [1] "ll3_consume_label_unch", auto)
    apply(auto simp add:ll_valid_q_ll_validl_q.intros)

    apply(case_tac [1] "ll3_assign_label ((a, b), ba)", auto)
    apply(case_tac [1] "ll3_assign_label_list list", auto)

   apply(case_tac [1] h, auto)
  apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
       apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
       apply(subgoal_tac[1] "(t, {ph#pt}, list) \<in> ll3_consumes") apply(blast)
       apply(rule_tac [1] ll3_consumes.intros(3), auto)

      apply(case_tac [1] "x22 = length p", auto)
       apply(case_tac [1] "\<not>x21", auto)
       apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
  apply(drule_tac [1] ll_valid_q.cases, auto)
       apply(auto simp add:ll_valid_q_ll_validl_q.intros)
  apply(case_tac "ll3_consume_label p (Suc na) t", auto)
       apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
  apply(drule_tac [1] ll_valid_q.cases, auto)
         apply(subgoal_tac[1] "(t, {ph#pt}, list) \<in> ll3_consumes") apply(blast)
       apply(rule_tac [1] ll3_consumes.intros(3), auto)

  apply(case_tac "ll3_consume_label p (Suc na) t", auto)
       apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
         apply(subgoal_tac[1] "(t, {ph#pt}, list) \<in> ll3_consumes") apply(blast)
     apply(rule_tac [1] ll3_consumes.intros(3), auto)

  apply(case_tac "ll3_consume_label p (Suc na) t", auto)
    apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
  apply(drule_tac [1] ll_valid_q.cases, auto)
         apply(subgoal_tac[1] "(t, {ph#pt}, list) \<in> ll3_consumes") apply(blast)
     apply(rule_tac [1] ll3_consumes.intros(3), auto)

   apply(case_tac [1] "ll3_consume_label (na # p) 0 x52", auto)
   apply(rename_tac [1] boo)
   apply(case_tac boo, auto)
    apply(case_tac "ll3_consume_label p (Suc na) t", auto)
    apply(case_tac "ll3_consume_label [] 0 ac", auto)
  apply(rename_tac [1] boo)
    apply(case_tac [1] "ll3_assign_label_list ad", auto)
    apply(drule_tac [1] ll_valid_q.cases, auto)
  apply(frule_tac [1] ll3_consume_label_unch, auto)
    apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
    apply(drule_tac [1] ll_valid_q.cases, auto)
  

  apply(case_tac [3] "ll3_assign_label ((a, b), ba)", auto)
    apply(case_tac [3] "ll3_assign_label_list list", auto)
    apply(drule_tac [1] ll3_consumes_length, auto simp add:ll_valid_q_ll_validl_q.intros)
   apply(drule_tac [1] ll3_consumes_length, auto simp add:ll_valid_q_ll_validl_q.intros)

  apply(frule_tac [1] ll3_assign_label_unch1, auto)
  apply(drule_tac [1] ll3_consumes_split, auto)
    apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)
   apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)
   apply(rule_tac [1] ll_valid_q.cases, auto)
   apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)

   apply(case_tac "ll3_consume_label [] 0 ls2", auto)
   apply(case_tac "ll3_assign_label_list a", auto)
  apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)
  apply(rule_tac [1] ll_valid_q_ll_validl_q.intros)
  apply(drule_tac [1] ll_valid_q.cases, auto)
  
  (* new idea: track which things were consumed in the "consumes" predicate? *)
   

  apply(case_tac "ll3_consume_label [] 0 l", auto)

   apply(case_tac [2] "ll3_assign_label_list aa", auto)
  apply(drule_tac [3] "ll_valid_q.cases", auto)
   apply(rule_tac [2] ll_valid_q_ll_validl_q.intros, auto)
   apply(rule_tac [2] ll_valid_q_ll_validl_q.intros)

   apply(frule_tac [2] ll3_consumes_split, auto)
  apply(case_tac [2] "ll3_assign_label_list a", auto)


   apply(drule_tac [1] ll3_consumes.cases)
   

  apply(case_tac ba, auto)
  apply(frule_tac [1] ll3_consumes_split, auto)


  apply(rotate_tac [1] 4)
  apply(drule_tac [1] x = list in spec, auto)
  apply(case_tac [1] "ll3_assign_label_list t", auto)
  
  apply(frule_tac [1] ll3_consume_label_unch)
  apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)

  apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)
  apply(rotate_tac [1] 4)
  apply(drule_tac [1] x = list in spec, auto)
  
  apply(drule_tac [1] x = ab in spec, auto)
  apply(case_tac "ll3_assign_label ((aa, bb), h)", auto)
  
  apply(

    apply(auto simp add:ll_valid_q_ll_validl_q.intros)
    


    apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, blast)

   apply(case_tac [1] "ll3_assign_label ((n, n'), h)", auto)
   apply(case_tac [1] "ll3_assign_label_list t", auto simp add:ll_valid_q_ll_validl_q.intros)

  apply(case_tac h, auto)
  
      apply(case_tac [1] " ll3_consume_label p (Suc na) t", auto)
      apply(case_tac [1] "ll3_assign_label_list a", auto)
      apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)
      apply(blast)

     apply(case_tac [1] "x22 = length p", auto)
      apply(case_tac [1] "\<not> x21", auto)
      apply(case_tac [1] "ll3_assign_label_list t", auto)
      apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)
      apply(drule_tac[1] ll_valid_q.cases, auto simp add:ll_valid_q_ll_validl_q.intros)

        apply(case_tac [1] " ll3_consume_label p (Suc na) t", auto)
  apply(case_tac [1] "ll3_assign_label ((n, n'), llt.LLab x21 x22)", auto)
      apply(case_tac [1] "ll3_assign_label_list a", auto)
        apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)
     apply(blast)

        apply(case_tac [1] " ll3_consume_label p (Suc na) t", auto)
      apply(case_tac [1] "ll3_assign_label_list a", auto)
        apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)
    apply(blast)

        apply(case_tac [1] " ll3_consume_label p (Suc na) t", auto)
      apply(case_tac [1] "ll3_assign_label_list a", auto)
        apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)
   apply(blast)

  apply(case_tac [1] "ll3_consume_label (na # p) 0 x52", auto)
  apply(drule_tac [1] "ll_valid_q.cases", auto)


   apply(case_tac [1] b, auto)

    apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
  apply(drule_tac [1] "ll_valid_q.cases", auto)
    apply(case_tac [1] "(case ll3_consume_label [] 0 a of None \<Rightarrow> None
             | Some (ls', p) \<Rightarrow>
                 (case ll3_assign_label_list ls' of None \<Rightarrow> None
                 | Some ls'' \<Rightarrow> Some ((nb, n'a), llt.LSeq (rev p) ls'')))", auto)
    apply(case_tac [1] "ll3_consume_label [] 0 a", auto)
  apply(rename_tac [1] boo)
    apply(case_tac [1] "ll3_assign_label_list ac", auto)
    apply(case_tac [1] "ll3_assign_label_list aa", auto)

    apply(rule_tac[1] "ll_valid_q_ll_validl_q.intros")
     apply(rule_tac[1] "ll_valid_q_ll_validl_q.intros")

   apply(frule_tac [1] "ll_valid_q_ll_validl_q.intros", auto)
   apply(drule_tac [1] "ll3_consume_label_unch", auto)
   apply(drule_tac [1] "ll_valid_q.cases", auto)
  
  

lemma ll3_assign_label_qvalid' :
"((q,t) \<in> ll_valid_q \<longrightarrow> 
   ((! q' t' . ll3_assign_label (q,t) = Some (q',t') \<longrightarrow> (q = q' \<and> (q',t') \<in> ll_valid_q))
    \<and> (! q' t' . ll3_assign_label (q', t') = Some (q,t) \<longrightarrow> (q=q' \<and> (q', t') \<in> ll_valid_q))))
\<and>  
(((x,x'), ls) \<in> ll_validl_q \<longrightarrow> 
   ((! ls' . ll3_assign_label_list ls = Some ls' \<longrightarrow> (((x,x'), ls') \<in> ll_validl_q ))
   \<and> (! ls' . ll3_assign_label_list ls' = Some ls \<longrightarrow> (((x,x'),ls') \<in> ll_validl_q))))"
proof(induction rule: ll_valid_q_ll_validl_q.induct)

  case (5 n l n' e) thus ?case
    apply(auto)
    apply(case_tac [1] "ll3_consume_label [] 0 l", auto)
         apply(case_tac [1] "ll3_assign_label_list aa", auto)

        apply(case_tac [1] "ll3_consume_label [] 0 l", auto)
         apply(case_tac [1] "ll3_assign_label_list aa", auto)
  
        apply(case_tac [1] "ll3_consume_label [] 0 l", auto)
       apply(case_tac [1] "ll3_assign_label_list aa", auto)

       apply(rule_tac[1] ll_valid_q_ll_validl_q.intros)
    apply(drule_tac x = 

  case (6 n) thus ?case
    apply(auto simp add:ll_valid_q_ll_validl_q.intros)
    apply(case_tac ls', auto simp add:ll_valid_q_ll_validl_q.intros)
    apply(case_tac "ll3_assign_label ((a, b), ba)", auto)
    apply(case_tac "ll3_assign_label_list list", auto)
    done

  case (7 n h n' t n'') thus ?case
    apply(auto)
     apply(case_tac [1] "ll3_assign_label ((n, n'), h)", auto)
     apply(case_tac [1] "ll3_assign_label_list t", auto)
     apply(auto simp add:ll_valid_q_ll_validl_q.intros)
    apply(case_tac [1] ls', auto)
    apply(case_tac [1] "ll3_assign_label ((a, b), ba)", auto)
    apply(case_tac [1] "ll3_assign_label_list list", auto)
    apply(drule_tac [1] x = list in spec) (* bogus *)
    apply(drule_tac [1] x = list in spec, auto)
    apply(drule_tac [1] x = a in spec)
    apply(drule_tac [1] x = a in spec)
    apply(drule_tac [1] x = b in spec)
    apply(drule_tac [1] x = b in spec)
    apply(drule_tac [1] x = ba in spec)
    apply(drule_tac [1] x = ba in spec, auto)
    
    apply(rule ll_valid_q_ll_validl_q.intros(7), auto)
    done

    case (1 i x e) thus ?case
    apply(auto simp add:ll_valid_q_ll_validl_q.intros)
    apply(case_tac t', auto)
                      apply(case_tac t', auto)
                      apply(case_tac x21, auto)
   
  apply(case_tac [1] "ll3_consume_label [] 0 x52", auto)
  apply(rename_tac boo)
                      apply(case_tac [1] "ll3_assign_label_list ab", auto )

                      apply(case_tac t', auto) apply(case_tac x21, auto)

                      apply(case_tac [1] "ll3_consume_label [] 0 x52", auto)
  apply(rename_tac boo)
                      apply(case_tac [1] "ll3_assign_label_list ab", auto )

                      apply(case_tac t', auto simp add:ll_valid_q_ll_validl_q.intros) 
                      apply(case_tac [1] x21, auto)

  apply(case_tac [1] "ll3_consume_label [] 0 x52", auto)
  apply(rename_tac boo)
                      apply(case_tac [1] "ll3_assign_label_list ab", auto )
  

  apply(case_tac [1] x21, auto)
  apply(auto simp add:ll_valid_q_ll_validl_q.intros)
       apply(case_tac[1] e, auto simp add:ll_valid_q_ll_validl_q.intros)
  apply(case_tac[1] e, auto simp add:ll_valid_q_ll_validl_q.intros)

  apply(case_tac [1] "ll3_consume_label [] 0 l", auto)
     apply(case_tac [1] "ll3_assign_label_list aa", auto)

  apply(case_tac [1] "ll3_consume_label [] 0 l", auto)
    apply(case_tac [1] "ll3_assign_label_list aa", auto)

  apply(case_tac [1] "ll3_consume_label [] 0 l", auto)
    apply(case_tac [1] "ll3_assign_label_list aa", auto)

   apply(case_tac [1] "ll3_assign_label_list l", auto)

  sorry
*)
(* do we also need to talk about consume_label? *)
lemma ll3_assign_label_qvalid' :
"
((q, (t :: ll3t)) \<in> ll_valid_q \<longrightarrow> 
  (((! q' t' . ll3_assign_label (q,t) = Some (q', t') \<longrightarrow> (q=q' \<and> (q', t') \<in> ll_valid_q)))
   \<and> (! e l . t = LSeq e l \<longrightarrow> 
                        (!  p n l' p'. ll3_consume_label p n l = Some (l', p') \<longrightarrow>
                        ((q,l') \<in> ll_validl_q) \<and> 
                         (! l'' . ll3_assign_label_list l' = Some l'' \<longrightarrow>
                           (! e' . (q, LSeq e' l'') \<in> ll_valid_q))))))
\<and>
(((x,x'), (ls :: ll3 list)) \<in> ll_validl_q \<longrightarrow> 
   ((! ls' . ll3_assign_label_list ls = Some ls' \<longrightarrow> ((x,x'), ls') \<in> ll_validl_q) 
    \<and> (! p n p' ls' . ll3_consume_label p n ls = Some (ls', p') \<longrightarrow>
                          (((x,x'), ls') \<in> ll_validl_q \<and>
                           (! ls'' . ll3_assign_label_list ls' = Some ls'' \<longrightarrow>
                            ((x,x'), ls'') \<in> ll_validl_q)))))

(* old last case, other part *)
(* need an assumption about consume_label here, but which one?
   this one isn't right, we need to talk about running consume_label on the head? *)
(* Q:  *)
(*
  \<and> (! e qh lsdec tl . ls = ((qh, LSeq e lsdec)#tl) \<longrightarrow>
     ( ! h' p n p' tl' . ll3_consume_label p n ls = Some (h'#tl', p') \<longrightarrow>
     (! h'' . ll3_assign_label h' = Some h'' \<longrightarrow>
        (! tl'' . ll3_assign_label_list tl' = Some tl'' \<longrightarrow>
        (((x,x'), (h''#tl'')) \<in> ll_validl_q))) *)

"
(*
"
((q, (t :: ll3t)) \<in> ll_valid_q \<longrightarrow> 
  (((! q' t' . ll3_assign_label (q,t) = Some (q', t') \<longrightarrow> (q=q' \<and> (q', t') \<in> ll_valid_q)))
   \<and> (! e l . t = LSeq e l \<longrightarrow> 
                        (! p n l' p' . ll3_consume_label p n l = Some (l', p') \<longrightarrow>
                        (! l'' . ll3_assign_label_list l' = l'' \<longrightarrow>
                           (! e' . (q, LSeq e' l') \<in> ll_valid_q))))))
\<and>
(((x,x'), (ls :: ll3 list)) \<in> ll_validl_q \<longrightarrow> 
   ((! ls' . ll3_assign_label_list ls = Some ls' \<longrightarrow> ((x,x'), ls') \<in> ll_validl_q)
    \<and> (! p n p' ls' . ll3_consume_label p n ls = Some (ls', p') \<longrightarrow>
                          (! ls'' . ll3_assign_label_list ls' = Some ls'' \<longrightarrow>
                            ((x,x'), ls'') \<in> ll_validl_q
 ))                       
))
"
*)
(*
lemma ll3_assign_label_qvalid' :
"((q,t) \<in> ll_valid_q \<longrightarrow> (! q' t' . ll3_assign_label (q,t) = Some (q',t') \<longrightarrow> (q',t') \<in> ll_valid_q))
\<and> (((x,x'), ls) \<in> ll_validl_q \<longrightarrow> (! ls' . ll3_assign_label_list ls = Some ls' \<longrightarrow> ((x,x'), ls') \<in> ll_validl_q ))"
*)
  apply(induction rule:ll_valid_q_ll_validl_q.induct)
        apply(auto simp add:ll_valid_q_ll_validl_q.intros)
             apply(case_tac [1] e, auto simp add:ll_valid_q_ll_validl_q.intros)
            apply(case_tac e, auto simp add:ll_valid_q_ll_validl_q.intros)
           apply(case_tac e, auto simp add:ll_valid_q_ll_validl_q.intros) 
   apply(case_tac [1] "ll3_consume_label [] 0 l", auto)
          apply(case_tac [1] "ll3_assign_label_list aa", auto)
     apply(case_tac [1] "ll3_consume_label [] 0 l", auto)
     apply(case_tac [1] "ll3_assign_label_list aa", auto)

apply(case_tac [1] "ll3_consume_label [] 0 l", auto)
       apply(case_tac [1] "ll3_assign_label_list aa", auto)
     apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)

   apply(case_tac [1] "ll3_assign_label ((n,n'), h)", auto)
   apply(case_tac [1] "ll3_assign_label_list t", auto simp add:ll_valid_q_ll_validl_q.intros)

  apply(case_tac h, clarsimp)
      apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
      apply(case_tac[1] "ll3_assign_label_list a", auto simp add:ll_valid_q_ll_validl_q.intros)
     apply(case_tac[1] "x22 = length p", auto)
      apply(case_tac[1] "\<not>x21", auto)
      apply(case_tac [1] "ll3_assign_label_list t", auto)
      apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
      apply(rule_tac[1] ll_valid_q_ll_validl_q.intros)
        apply(drule_tac [1] ll_valid_q.cases, auto)
       apply(drule_tac [1] ll_valid_q.cases, auto)
         apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)
apply(rule_tac [1] ll_valid_q_ll_validl_q.intros, auto)
      apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
      apply(auto simp add:ll_valid_q_ll_validl_q.intros)
  
      apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
      apply(auto simp add:ll_valid_q_ll_validl_q.intros)
  
    apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
    apply(auto simp add:ll_valid_q_ll_validl_q.intros)

   apply(case_tac [1] "ll3_consume_label (na # p) 0 x52", auto)
   apply(case_tac [1] b, auto)
    apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
    apply(rule_tac ll_valid_q_ll_validl_q.intros, auto)
    apply(drule_tac [1] ll_valid_q.cases, auto)
    apply(drule_tac [1] x = "(na # p)" in spec)
  apply(rotate_tac [1] 3)
    
    apply(drule_tac [1] x = "0" in spec)
  apply(drule_tac [1] x = a in spec)
    apply(rule_tac ll_valid_q_ll_validl_q.intros, auto)
   apply(drule_tac [1] x = "(na # p)" in spec)
  apply(rotate_tac[1] 3)
   apply(drule_tac [1] x = 0 in spec)
   apply(drule_tac [1] x = "a" in spec)
   apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto simp add:ll_valid_q_ll_validl_q.intros)

  apply(case_tac "h", auto)
      apply(drule_tac [1] ll_valid_q.cases, auto)
      apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
  apply(case_tac [1] "ll3_assign_label_list aa", auto simp add:ll_valid_q_ll_validl_q.intros)


     apply(case_tac[1] "x22 = length p", auto)
      apply(case_tac [1] "\<not>x21", auto)
      apply(case_tac[1] "ll3_assign_label_list t", auto)

  apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
      apply(rule_tac[1] ll_valid_q_ll_validl_q.intros, auto)
      apply(drule_tac [1] ll_valid_q.cases, auto)
     apply(case_tac[1] "ll3_consume_label p (Suc na) t", auto)
     apply(case_tac [1] "ll3_assign_label ((n, n'), llt.LLab x21 x22)", auto)
        apply(drule_tac [1] ll_valid_q.cases, auto)

     apply(case_tac [1] " ll3_assign_label_list a", auto)
     apply(drule_tac [1] ll_valid_q_ll_validl_q.intros, auto)

    apply(case_tac[1] "ll3_consume_label p (Suc na) t", auto)
    apply(case_tac[1] "ll3_assign_label_list a", auto)
    apply(rule_tac [1] "ll_valid_q_ll_validl_q.intros", auto)

     apply(case_tac[1] "ll3_consume_label p (Suc na) t", auto)
    apply(case_tac[1] "ll3_assign_label_list a", auto)
    apply(rule_tac [1] "ll_valid_q_ll_validl_q.intros", auto)

  apply(case_tac "ll3_consume_label (na # p) 0 x52", auto)
  apply(case_tac b, auto)
   apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
  apply(case_tac [1] "(case ll3_consume_label [] 0 a of None \<Rightarrow> None
             | Some (ls', p) \<Rightarrow>
                 (case ll3_assign_label_list ls' of None \<Rightarrow> None
                 | Some ls'' \<Rightarrow> Some ((n, n'), llt.LSeq (rev p) ls'')))", auto)
   apply(case_tac [1] "ll3_consume_label [] 0 a", auto)
  apply(case_tac [1] "ll3_assign_label_list aa", auto)
   apply(case_tac [1] "ll3_assign_label_list ac", auto)
   apply(rule_tac[1] "ll_valid_q_ll_validl_q.intros", auto)
   apply(frule_tac [1] "ll_valid_q_ll_validl_q.intros", auto)
   apply(drule_tac [1] "ll3_consume_label_unch", auto)
   apply(drule_tac [1] "ll_valid_q.cases", auto)

    apply(case_tac [1] "(case ll3_consume_label [] 0 a of None \<Rightarrow> None
             | Some (ls', p) \<Rightarrow>
                 (case ll3_assign_label_list ls' of None \<Rightarrow> None
                 | Some ls'' \<Rightarrow> Some ((nb, n'a), llt.LSeq (rev p) ls'')))", auto)

  apply(case_tac [1] "ll3_assign_label_list t", auto)
   apply(case_tac [1] "ll3_consume_label [] 0 a", auto)
  apply(rename_tac [1] boo)
  apply(case_tac [1] "ll3_assign_label_list ad", auto)
  apply(rule_tac [1] "ll_valid_q_ll_validl_q.intros", auto)
  apply(rule_tac [1] "ll_valid_q_ll_validl_q.intros")
  apply(frule_tac [1] x = "na#p" in spec)
  apply(rotate_tac [1] 3)
  apply(drule_tac [1] x = 0 in spec)
  apply(drule_tac [1] x = a in spec, auto)
 apply(case_tac [1] "ll3_assign_label_list a", auto)

   apply(subgoal_tac [2] "((ab, b), llt.LSeq [] af)  \<in> ll_valid_q")
  apply(drule_tac [2] "ll_valid_q.cases", auto)

  apply(rotate_tac [2] 3)
   apply(drule_tac [2] x = "[]" in spec)

   apply(subgoal_tac [2] "((ab, b), llt.LSeq [] af)  \<in> ll_valid_q")

  apply(rotate_tac [2] 3)
 apply(clarsimp add:ll_valid_q_ll_validl_q.intros)


  apply(case_tac [1] "ll3_consume_label [] 0 l", auto)

  

  apply(rename_tac [2] boo2)
  apply(case_tac [2] "ll3_assign_label_list af", auto)

  (* we need some lemmas about interaction of assiging different labels
     of different lengths. case 3 is the interesting one *)

  apply(rotate_tac [1] 5)
  apply(drule_tac [1] x = "p" in spec)
  apply(rotate_tac [1] 5)
  apply(drule_tac [1] x = na in spec)
   

    apply(auto simp add:ll_valid_q_ll_validl_q.intros)

  apply(case_tac [1] "(ll3_assign_label
              ((n, n'), llt.LLab x21 x22))", auto)
     apply(case_tac[1] "ll3_assign_label_list a", auto simp add:ll_valid_q_ll_validl_q.intros)

    apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
    apply(case_tac[1] "ll3_assign_label_list a", auto simp add:ll_valid_q_ll_validl_q.intros)
  
    apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)
    apply(case_tac[1] "ll3_assign_label_list a", auto simp add:ll_valid_q_ll_validl_q.intros) 
  apply(drule_tac[1] "ll_valid_q.cases", auto)

  apply(case_tac [1] "ll3_consume_label (na # p) 0 l", auto)
  apply(case_tac [1] "b", auto)
  apply(case_tac [1] "ll3_consume_label p (Suc na) t", auto)


  apply(case_tac [1] "case ll3_consume_label [] 0 a of
             None \<Rightarrow> None
             | Some (ls', p) \<Rightarrow>
                 (case ll3_assign_label_list ls' of
                 None \<Rightarrow> None
                 | Some ls'' \<Rightarrow>
                     Some
                      ((nb, n'a),
                       llt.LSeq (rev p) ls''))", auto)
      apply(case_tac [1] "ll3_consume_label [] 0 a", auto)

   apply(case_tac [1] "ll3_assign_label_list aa", auto)
   apply(case_tac [1] "ll3_assign_label_list ac", auto)
    apply(rule_tac [1] "ll_valid_q_ll_validl_q.intros", auto)

   apply(drule_tac[1] "ll3_consume_label_unch", auto)

  apply(case_tac [1] "case ll3_consume_label [] 0 a of
             None \<Rightarrow> None
             | Some (ls', p) \<Rightarrow>
                 (case ll3_assign_label_list ls' of
                 None \<Rightarrow> None
                 | Some ls'' \<Rightarrow>
                     Some
                      ((nb, n'a),
                       llt.LSeq (rev p) ls''))", auto)

  apply(case_tac "ll3_consume_label [] 0 a", auto)
   apply(rename_tac[1] boo)
  apply(case_tac [1] "ll3_assign_label_list ac", auto)
  apply(case_tac [1] "ll3_assign_label_list t" , auto)
    apply(rule_tac [1] "ll_valid_q_ll_validl_q.intros", auto)

  apply(case_tac [1] "ll3_consume_label [] 0 l", auto)
   apply(rename_tac [2] boo)
   apply(case_tac [2] "ll3_assign_label_list af", auto)

  apply(rule_tac[3] "ll_valid_q_ll_validl_q.intros")
  apply(drule_tac [3] "ll_valid_q.cases", auto)

  (* Q: need to split up list ? *)

   apply(drule_tac [1] x = "na#p" in spec)
   apply(drule_tac [1] x = 0 in spec)
   apply(drule_tac x = a in spec, auto)
  apply(drule_tac [1] "ll3_consume_label_unch")
  apply(rule_tac[1] "ll_valid_q_ll_validl_q.intros")

     apply(rule_tac[1] "ll_valid_q_ll_validl_q.intros", auto)
    apply(drule_tac[1] "ll3_consume_label_unch", auto)
  apply(case_tac [1] "case ll3_consume_label [] 0 a of None \<Rightarrow> None
             | Some (ls', p) \<Rightarrow>
                 (case ll3_assign_label_list ls' of None \<Rightarrow> None
                 | Some ls'' \<Rightarrow> Some ((nb, n'a), llt.LSeq (rev p) ls''))", auto)
  apply(case_tac[1] " ll3_consume_label [] 0 a", auto)
   apply(rename_tac[1] boo)
  apply(case_tac [1] "ll3_assign_label_list ac", auto)
  apply(case_tac [1] "ll3_assign_label_list t", auto)

   apply(rule_tac "ll_valid_q_ll_validl_q.intros", auto)
   apply(drule_tac "ll3_consume_label_qvalid", auto)
   apply(drule_tac "ll3_consume_label_qvalid", auto)
  apply(drule_tac "ll3_assign_label_unch2")

  apply(case_tac [2] "ll3_consume_label (na # p) 0 l", auto)
  

  apply(drule_tac "ll_valid_q.cases", auto)
  apply(rotate_tac 3)
   apply(frule_tac [1] x = "(na#p)" in spec)
  apply(rotate_tac[1] 3)
   apply(drule_tac [1] x = "0" in spec)
   apply( drule_tac [1] x = "a" in spec)
  apply(auto)
  apply(case_tac "ll3_consume_label [] 0 l", auto)
   (* we need to use unch here, I think this miiiight be provable*)

   
   apply(subgoal_tac [1] "((n, n'), llt.LSeq (rev boo) ae) \<in> ll_valid_q")
    apply(drule_tac [1] "ll_valid_q.cases", auto)

  apply(case_tac[1] "(case ll3_consume_label [] 0 a of
             None \<Rightarrow> None
             | Some (ls', p) \<Rightarrow>
                 (case ll3_assign_label_list ls' of
                 None \<Rightarrow> None
                 | Some ls'' \<Rightarrow>
                     Some
                      ((n, n'),
                       llt.LSeq (rev p) ls'')))", auto) 

   apply(case_tac [1] "ll3_assign_label_list t", auto)
   apply(case_tac [1] "ll3_consume_label [] 0 a", auto)  
  apply(rename_tac boo)
   apply(case_tac [1] "ll3_assign_label_list ad", auto)
   apply(rule_tac [1] "ll_valid_q_ll_validl_q.intros", auto)

   apply(drule_tac [1] x = "(na#p)" in spec)
  apply(rotate_tac[1] 3)
   apply(drule_tac [1] x = "0" in spec)
   apply( drule_tac [1] x = "a" in spec)
   apply(clarsimp)
   apply(drule_tac [1] "ll_valid_q.cases", auto)
  apply(case_tac [1] "ll3_consume_label [] 0 l", auto)
  apply(rule_tac [1] "ll_valid_q_ll_validl_q.intros")
   apply(rotate_tac[1] 3)
  apply(subgoal_tac "(\<forall>e'. ((n, n'), llt.LSeq e' ad) \<in> ll_valid_q)", auto)
  apply(drule_tac [1] x = "rev boo" in spec)
   

  apply(thin_tac [1] 0)
    apply(auto simp add:ll_valid_q.cases)
  apply(rotate_tac [1] 2)
  apply(drule_tac[1] ll3_consume_label_qvalid, auto)
    (* we need to use our quant unch lemma here. *)
    

    apply(drule_tac[1] x = "ab" in spec) (* bogus *)
    apply(drule_tac[1] x = "p" in spec)
    apply(drule_tac[1] x = "na" in spec)
    apply(drule_tac[1] x = "p'" in spec)    
    apply(clarsimp)
    apply(subgoal_tac[1] "aa = l'", auto)
  apply(rule_tac[1] ll3_consume_label_unch, auto)
  apply(cut_tac [1] )
  
 
  apply(drule_tac [1] x = "[]" in spec)

    
    apply(case_tac [1] "ab", auto simp add:ll_valid_q_ll_validl_q.intros)
   (* Q: do we need unch? *)
   apply(case_tac [2] "ll3_assign_label ((n,n'), h)", auto)
    apply(case_tac [2] "ll3_assign_label_list t", auto simp add:ll_valid_q_ll_validl_q.intros)
   apply(drule_tac [2] "ll3_assign_label_unch1")
   apply(auto simp add:ll_valid_q_ll_validl_q.intros)
  (* idea: we want to show that *)
  (* do we want to talk about ALL predicates not mentioning the annotation? *)

  apply(drule_tac [1] "ll3_consume_label_unch")
  
  
   (* i think we need to strengthen our theorem statement.
      include the fact that we can also attempt to assign labels for any value and still get validity *)
   apply(case_tac [1] ba, auto simp add:ll_valid_q_ll_validl_q.intros)
    apply(frule_tac [1] ll3_consume_label_unch, auto simp add:ll_valid_q_ll_validl_q.intros)
  
   (* we seem to need a lemma about how we don't change the tree if we don't find anything *)

(* informal statement:
   IF we find a label with consume_label
   AND we run assign_labels successfully on the rest
   THEN we are ll3 *)
(* it would be better to not refer to assign_labels, now we are back to the problem
   of describing correctness of consume_label when run with a nonempty path *)
(*lemma ll3_consume_label_desc :*)

lemma ll3_assign_label_valid :
  fixes t :: "ll3t"
  fixes l :: "ll3 list"
  shows
"((q,t) \<in> ll_valid_q \<longrightarrow> (\<forall> q' t' . ll3_assign_label (q, t) = Some (q', t') \<longrightarrow> (q',t') \<in> ll_valid3'))\<and>
 (((n,n'),l) \<in> ll_validl_q \<longrightarrow> (\<forall> l' . ll3_assign_label_list l = Some l' \<longrightarrow> (\<forall> t . t \<in> set l' \<longrightarrow> t \<in> ll_valid3')))"
  apply(induction rule:ll_valid_q_ll_validl_q.induct)
        apply(auto simp add:ll_valid3'.intros)
    apply(case_tac [1] e, auto simp add:ll_valid3'.intros)
   apply(case_tac [1]" ll3_consume_label [] 0 l", auto)
   apply(case_tac [1] "ll3_assign_label_list aa", auto)
   apply(rule_tac [1] ll3_consume_label.elims, auto)
 
   apply(case_tac [1] ba, clarsimp)
    apply(rule_tac[1] ll_valid3'.intros(5), clarsimp)
      apply(insert ll3_consume_label_qvalid)
  apply(auto)
  
  apply(clarsimp)
  apply
   
   (* we need to strengthen this *)

fun ll3_unwrap :: "(ll3 list \<Rightarrow> 'a option) \<Rightarrow> ll3  \<Rightarrow> 'a option" where
  "ll3_unwrap f (_, LSeq _ ls) = f ls"
  | "ll3_unwrap _ (_, _) = None"
 
value "(ll3_init (ll_pass1 (ll1.LSeq [ll1.LLab 0])))"
value "ll3_assign_label (ll3_init (ll_pass1 (ll1.LSeq [ll1.LLab 0])))"
value "ll3_assign_label (ll3_init (ll_pass1 (ll1.LSeq [ll1.LSeq [ll1.LLab 0], ll1.LSeq [], ll1.LSeq [ll1.LLab 1]])))"

(* get the label at the provided childpath, if it exists *)
(* TODO: should we check to make sure this label is the right one? *)
(* TODO: we can generalize this, not just make ll3 specific *)
(* TODO apply this to a node, not a list (?) *)
(*
fun ll3_get_label :: "ll3 list \<Rightarrow> childpath \<Rightarrow> nat option" where
    "ll3_get_label (((x,_),LLab _ _)#_) (0#_) = Some x"
  | "ll3_get_label ((_, LSeq _ lsdec)#ls) (0#p) = 
     ll3_get_label lsdec p"
  | "ll3_get_label (_#ls) (0#_) = None"
  | "ll3_get_label (_#ls) (n#p) = 
     ll3_get_label (ls) ((n-1)#p)"
  | "ll3_get_label _ _ = None"
*)

fun ll_get_label :: "('lix, 'llx, 'ljx, 'ljix, 'lsx, 'ptx, 'pnx) ll list \<Rightarrow> childpath \<Rightarrow> nat option" where
    "ll_get_label (((x,_),LLab _ _)#_) (0#_) = Some x"
  | "ll_get_label ((_, LSeq _ lsdec)#ls) (0#p) = 
     ll_get_label lsdec p"
  | "ll_get_label (_#ls) (0#_) = None"
  | "ll_get_label (_#ls) (n#p) = 
     ll_get_label (ls) ((n-1)#p)"
  | "ll_get_label _ _ = None"

definition prog1 where
  "prog1 = ll3_assign_label (ll3_init (ll_pass1 (ll1.LSeq [ll1.LLab 0])))"

value prog1
  
definition prog2 where
  "prog2 = ll3_assign_label (ll3_init (ll_pass1 (ll1.LSeq [ll1.L (Arith ADD), ll1.LLab 0])))"  
  
value "(case prog2 of
        Some (_, LSeq _ lsdec) \<Rightarrow> ll3_get_label lsdec [1]
        | _ \<Rightarrow> None)"

definition src3 where
"src3 = ll1.LSeq [ll1.LSeq [ll1.LLab 0], ll1.LSeq [ll1.LJmp 1], ll1.LSeq [ll1.LLab 1]]"

definition prog3 where
"prog3 = ll3_assign_label (ll3_init (ll_pass1 (ll1.LSeq [ll1.LSeq [ll1.LLab 0], ll1.LSeq [ll1.LJmp 1], ll1.LSeq [ll1.LLab 1]])))"
 
value prog3

(* now we go to ll4, we are getting ready to put in jump targets *)
fun ll4_init :: "ll3 \<Rightarrow> ll4" where
 "ll4_init (x, L e i) = (x, L e i)"
| "ll4_init (x, LLab e idx) = (x, LLab e idx)"
| "ll4_init (x, LJmp e idx s) = (x, LJmp 0 idx s)"
| "ll4_init (x, LJmpI e idx s) = (x, LJmpI 0 idx s)"
| "ll4_init (x, LSeq e ls) = (x, LSeq e (map ll4_init ls))"

(* resolve_jump routine, for once we know the label location *)
(* Idea: for any jump we find, we check if it is big enough to store what we want
   If it is not, then we need to rebuild the entire tree and try again *)
(* idea: we once again build a childpath as we go, so that if we must bail out,
   we know where to enlarge the node *)
(* the nat this takes as input will be read out of the label node.
   label resolution should have already taken place for this to work. *)

datatype jump_resolve_result =
  JSuccess
  | JFail "childpath"
  | JBump "childpath"
  
(* need a function to get number of bytes needed to encode a
   location *)
value "(Evm.log256floor 2048) + 1"

definition encode_size :: "nat \<Rightarrow> nat" where
  "encode_size n = (nat (Evm.log256floor (Int.int n)) + 1)"

(* declaring this makes the termination prover blow up *)  
(*declare encode_size_def [simp]  *)

(* this should take an ll4 *)
(*  TODO everything from here onward should take ll4 *)
(* make this mutually recursive with a "consume" function?  *)
(* the first nat argument is a location in buffer,
   the second is the current child index 
   the first nat should be optional, that is, None if there is
   no label at that node
*)
(* NB the childpath output by this function ought to be reversed *)
(* NB LJmpI also needs to be handled *)
(* TODO: add another argument that is the "previously resolved" childpath? *)
(* should we do a "jump"/"jumps" split again? seems like a good idea *)
fun ll3_resolve_jump :: "ll3 list \<Rightarrow> nat option \<Rightarrow> nat \<Rightarrow> childpath \<Rightarrow> childpath \<Rightarrow> jump_resolve_result" where
  (* TODO: does this handle returning the childpath correctly? should it be n#c?*)
  "ll3_resolve_jump ((_, LJmp e idx s)#ls) None n rel absol = 
   (if idx + 1 = length rel then JFail (n#absol)
    else ll3_resolve_jump ls None (n+1) rel absol)"

| "ll3_resolve_jump ((_, LJmp e idx s)#ls) (Some addr) n rel absol =
     (if idx (*+ 1*) = length rel then
        (if s < encode_size addr then JBump (n#absol) else
         if s = encode_size addr then ll3_resolve_jump ls (Some addr) (n + 1) rel absol
        else JFail (n#absol))
        else ll3_resolve_jump ls (Some addr) (n+1) rel absol)"

 | "ll3_resolve_jump ((_, LSeq [] lsdec)#ls') oaddr n rel absol =
     (* first we resolve the descendents' labels relative to where we were *)
     (case ll3_resolve_jump lsdec oaddr 0 (n#rel) (n#absol) of
     JSuccess \<Rightarrow> (* now we resolve the descendents' relative labels *)
                 (* for this we need to obtain label target, but there may not be one
                    if there isn't one we still need to check for failing jumps, but i think this does that*)
      (case ll3_resolve_jump lsdec None 0 [] (n#absol) of
       JSuccess \<Rightarrow> (* now we resolve neighbors *) ll3_resolve_jump ls' oaddr (n+1) rel absol
       | JFail c \<Rightarrow> JFail c
       | JBump c \<Rightarrow> JBump c)
     | JFail c \<Rightarrow> JFail c
     | JBump c \<Rightarrow> JBump c)"

| "ll3_resolve_jump ((_, LSeq e lsdec)#ls') oaddr n rel absol =
   (case ll3_resolve_jump lsdec oaddr 0 (n#rel) (n#absol) of
    JSuccess \<Rightarrow> 
    (case ll_get_label lsdec e of
        Some newaddr \<Rightarrow> (case ll3_resolve_jump lsdec (Some newaddr) 0 [] (n#absol) of
                      JSuccess \<Rightarrow> ll3_resolve_jump ls' oaddr (n+1) rel absol
                      | JFail c \<Rightarrow> JFail c
                      | JBump c \<Rightarrow> JBump c)
       | None \<Rightarrow> JFail absol)
    | JFail c \<Rightarrow> JFail c
    | JBump c \<Rightarrow> JBump c)"

  | "ll3_resolve_jump (h#ls) oaddr n rel absol =
     ll3_resolve_jump ls oaddr (n + 1) rel absol"
  | "ll3_resolve_jump [] _ _ _ _ = JSuccess"
(*
fun ll3_resolve_jump :: "ll3 list \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> childpath \<Rightarrow> jump_resolve_result" where
  (* TODO: does this handle returning the childpath correctly? should it be n#c?*)
  "ll3_resolve_jump ((_, LJmp e idx s)#ls) addr n c =
     (if idx + 1 = length c then
        (if s < encode_size addr then JBump c else
         if s = encode_size addr then ll3_resolve_jump ls addr (n + 1) c
        else JFail c)
        else ll3_resolve_jump ls addr (n+1) c)"
   
| "ll3_resolve_jump ((_, LSeq e lsdec)#ls') addr n c =
     (case ll3_resolve_jump lsdec addr 0 (n#c) of
     JSuccess \<Rightarrow> ll3_resolve_jump ls' addr (n+1) c
     | JFail c \<Rightarrow> JFail c
     | JBump c \<Rightarrow> JBump c)"

  | "ll3_resolve_jump (h#ls) addr n c =
     ll3_resolve_jump ls addr (n + 1) c"
  | "ll3_resolve_jump [] _ _ _ = JSuccess"
*)
(* TODO: later replace this bump routine with a general bump *)    

(* this will call get label target *)
fun ll3_resolve_jump_wrap :: "ll3 \<Rightarrow> jump_resolve_result" where
"ll3_resolve_jump_wrap (x, LSeq e lsdec) =
   (case e of [] \<Rightarrow> ll3_resolve_jump lsdec None 0 [] []
    | e \<Rightarrow> (case ll_get_label lsdec e of
             Some a \<Rightarrow> ll3_resolve_jump lsdec (Some a) 0 [] []
           | None \<Rightarrow> JFail []))"
| "ll3_resolve_jump_wrap _ = JFail []"

value prog3

value "(case prog3 of
        Some l \<Rightarrow> ll3_resolve_jump_wrap l
        | _ \<Rightarrow> JFail [666])"

fun ll3_bump :: "nat \<Rightarrow> ll3 list \<Rightarrow> ll3 list" where
    "ll3_bump n (((x,x'), LSeq e lsdec)#ls') = ((x+n,x'+n),LSeq e (ll3_bump n lsdec))#(ll3_bump n ls')"
  | "ll3_bump n (((x,x'), t)#ls') = ((x+n, x'+n),t)#(ll3_bump n ls')"
  | "ll3_bump n [] = []"
    
(* once we find the offending jump, increment it *)
(* we need to return a qan defining new size things for the overall list *)
(* do we take a qan? or at least a bool showing whether we grew in that sublist *)    
fun ll3_inc_jump :: "ll3 list \<Rightarrow> nat \<Rightarrow> childpath \<Rightarrow> ll3 list * bool" where 
    (* TODO: select jump based on childpath *)
    "ll3_inc_jump (((x,x'), LJmp e idx s)#ls) n [c] = 
     (if n = c then
     (((x,x'+1), LJmp e idx (s+1))#(ll3_bump 1 ls), True)
       else (case ll3_inc_jump ls (n+1) [c] of
                  (ls', b) \<Rightarrow> (((x,x'), LJmp e idx s)#(ls'), b)))"
  (* TODO: should we use computed lsdec' or old lsdec in failure to find case *)
  | "ll3_inc_jump (((x,x'), LSeq e lsdec)#ls) n (c#cs) =
     (if n = c then case ll3_inc_jump lsdec 0 cs of
       (lsdec', True) \<Rightarrow> (((x,x'+1), LSeq e lsdec')#(ll3_bump 1 ls), True)
       | (lsdec', False) \<Rightarrow> (case ll3_inc_jump ls n (c#cs) of
                             (ls', b) \<Rightarrow> ((((x,x'), LSeq e lsdec')#ls'), b))
      else case ll3_inc_jump ls (n+1) (c#cs) of
       (ls', b) \<Rightarrow> (((x,x'), LSeq e lsdec)#ls', b))"
  | "ll3_inc_jump (h#ls) n c = (case (ll3_inc_jump ls (n + 1) c) of
                                  (ls', b) \<Rightarrow> (h#ls', b))"
  | "ll3_inc_jump [] _ _ = ([], False)"

fun ll3_inc_jump_wrap :: "ll3 \<Rightarrow> childpath \<Rightarrow> ll3" where
 "ll3_inc_jump_wrap ((x,x'), LSeq e lsdec) c =
  (case ll3_inc_jump lsdec 0 c of
   (lsdec', True) \<Rightarrow> ((x,x'+1), LSeq e lsdec')
  |(lsdec', False) \<Rightarrow> ((x,x'), LSeq e lsdec))
  "
|"ll3_inc_jump_wrap T _ = T"
    
value "(case prog3 of
        Some (_, LSeq e lsdec) \<Rightarrow> ll3_get_label lsdec e
        | _ \<Rightarrow> None)"
  
value "(case prog3 of
        Some (_, LSeq _ lsdec) \<Rightarrow> Some (ll3_inc_jump lsdec 0 [1,0])
        | _ \<Rightarrow> None)"

value "Word.word_rsplit ((Word256.word256FromNat 0) :: 256 word) :: 8 word list" 

fun process_jumps_loop :: "nat \<Rightarrow> ll3 \<Rightarrow> ll3 option" where
  "process_jumps_loop 0 _ = None"
| "process_jumps_loop n ls = 
   (case ll3_resolve_jump_wrap ls of
    JSuccess \<Rightarrow> Some ls
  | JFail _ \<Rightarrow> None
  | JBump c \<Rightarrow> process_jumps_loop (n - 1) (ll3_inc_jump_wrap ls (rev c)))"

value "(case prog3 of
        Some l \<Rightarrow> process_jumps_loop 40 l
        | _ \<Rightarrow> None)"

value "(case prog3 of
        Some l \<Rightarrow> (case (process_jumps_loop 40 l) of
                       Some l \<Rightarrow> Some (ll4_init l)
                       | _ \<Rightarrow> None)
        | _ \<Rightarrow> None)"


(* have a ll3_resolve_jumps_list *)
(* combine ll3_resolve_jump with ll3_inc_jump *)
(* we also need to use get_label to get the label location *)
(* take a nat and a childpath? we need to track where we
   are among descendents in the tree so we can reconstruct
   the "bump" command *)
(* first nat is fuel *)
(*
fun ll3_resolve_jumps :: "nat \<Rightarrow> ll3 \<Rightarrow> ll3 option" and
    ll3_resolve_jumps_list :: "nat \<Rightarrow> ll3 list \<Rightarrow> ll3 list option" where
  "ll3_resolve_jumps 0 _ = None"
| "ll3_resolve_jumps n (x, LSeq p []) = Some (x, LSeq p [])"
| "ll3_resolve_jumps n (x, LSeq p (h#ls)) =
   ((case ll3_get_label (h#ls) p of
     Some n \<Rightarrow> case ll3_resolve_jump (h#ls) n 0 [] of
      JSuccess \<Rightarrow> Some (n, LSeq) (* jsuccess means we need to add to childpath and process sublist, resolving sub jumps
                                    if any of them bump, we need to restart *)
      (* jbump means bump and restart *)
    | None \<Rightarrow> None))"  

| "ll3_resolve_jumps n ("
*)
(* finally, we resolve all jumps. for now, this will be fuelled, later we'll prove
   termination *)
(* do we need an ll4 init?
   maybe we don't, we can just use a childpath-stack to track which label is which address *)
(* should this return an ll4? yes *)
(* idea: putting the parts together.
   we require that labels have been assigned
   steps (should be separate functions?)
   1: call resolve_jump
      - bump if we need to, try to resolve again (fuelled)
      - pass result onto next stage
   1a: ll4 init?
   2: call write_jump_targets
      - if success, we get the thing

*)

fun mynth :: "'a option list \<Rightarrow> nat \<Rightarrow> 'a option" where
    "mynth [] _ = None"
  | "mynth (h#t) 0 = h"
  | "mynth (h#t) n = mynth t (n-1)"

fun mypeel :: "'a option list \<Rightarrow> 'a list option" where
"mypeel [] = Some []"
| "mypeel (None#_) = None"
| "mypeel ((Some h)#t) = (case mypeel t of
                          Some t' \<Rightarrow> Some (h#t')
                         | None \<Rightarrow> None)"

(* here we have a list of addresses, accumulated by labels as we go *)
fun write_jump_targets :: "nat option list \<Rightarrow> ll4 \<Rightarrow> ll4 option" where
"write_jump_targets ns ((x, x'), LSeq [] lsdec) = 
  (case (mypeel (map (write_jump_targets (None#ns)) lsdec)) of
   Some lsdec' \<Rightarrow> Some ((x,x'), LSeq [] lsdec')
  | None \<Rightarrow> None)"
| "write_jump_targets ns ((x,x'), LSeq loc lsdec) =
  (case ll_get_label lsdec loc of
    Some addr \<Rightarrow> (case (mypeel (map (write_jump_targets ((Some addr)#ns)) lsdec)) of
                  Some lsdec' \<Rightarrow> Some ((x,x'), LSeq loc lsdec')
                 | None \<Rightarrow> None)
    | None \<Rightarrow> None)"
| "write_jump_targets ns ((x,x'), LJmp _ idx sz) = 
  (case mynth ns idx of
   Some a \<Rightarrow> Some ((x,x'), LJmp a idx sz)
  | None \<Rightarrow> None)"
| "write_jump_targets _ T = Some T"

value "(case prog3 of
        Some l \<Rightarrow> (case (process_jumps_loop 40 l) of
                       Some l \<Rightarrow> write_jump_targets [] (ll4_init l)
                       | _ \<Rightarrow> None)
        | _ \<Rightarrow> None)"
(* ll3_resolve_jumps :: "ll3 list \<Rightarrow> ll4 list"*)

value "Word.word_of_int 1 :: 1 word"
value "Evm.byteFromNat 255"

value "Divides.divmod_nat 255 256"

(* TODO ensure these are coming out in the right order *)
(* TODO this terminates because divmod decreases number *)
function output_address :: "nat \<Rightarrow> 8 word list" where
    "output_address n = (case Divides.divmod_nat n 256 of
                         (0, mo) \<Rightarrow> [Evm.byteFromNat mo]
                        |(Suc n, mo) \<Rightarrow> (Evm.byteFromNat mo)#(output_address (Suc n)))"
  by auto
termination sorry

(* use word256FromNat to get w256
   then use word_rsplit245 *)
definition bytes_of_nat :: "nat \<Rightarrow> 8 word list" where
  "bytes_of_nat n = Word.word_rsplit (Word256.word256FromNat n)"

fun codegen' :: "ll4 \<Rightarrow> inst list" where
    "codegen' (_, (L _ i)) = [i]"
  | "codegen' (_, (LLab _ _)) = [Pc JUMPDEST]"
  | "codegen' (_, (LJmp a _ s)) =
     (Evm.inst.Stack (PUSH_N (output_address a))) #[Pc JUMP]"
  | "codegen' (_, (LJmpI a _ _)) =
     (Evm.inst.Stack (PUSH_N (output_address a))) #[Pc JUMPI]"
  | "codegen' (_, (LSeq _ ls)) = List.concat (map codegen' ls)"
     
definition codegen :: "ll4 \<Rightarrow> 8 word list" where
"codegen ls = List.concat (map Evm.inst_code (codegen' ls))"

definition pipeline' :: "ll1 \<Rightarrow> nat \<Rightarrow> ll4 option" where
"pipeline' l n = 
 (case (ll3_assign_label (ll3_init (ll_pass1 l))) of
  Some l' \<Rightarrow> (case process_jumps_loop n l' of
              Some l'' \<Rightarrow> (case write_jump_targets [] (ll4_init l'') of
                           Some l''' \<Rightarrow> Some (l''')
                          | None \<Rightarrow> None)
             | None \<Rightarrow> None)
  | None \<Rightarrow> None)"

(* nat argument is fuel to give to jump resolver *)
definition pipeline :: "ll1 \<Rightarrow> nat \<Rightarrow> 8 word list option" where
"pipeline l n = 
 (case pipeline' l n of
  Some l' \<Rightarrow> Some (codegen l')
  | None \<Rightarrow> None)"

value "pipeline' src3 20"

(* this showcases an interesting bug. our jump needs to point to the beginning of the "jump block" not the end *)
(* actually no this is behaving properly i think  *)
value "pipeline src3 20"
(* idea: *)
(* for final codegen pass, use stack_inst.PUSH_N
   *)
(* before going further with paths, we need some path utilities
   (inspired by Huet's Zippers paper)
 *)
  
(* assumes our first notion of validity *)
(* TODO make this parametric w/r/t our syntax ? *)

inductive_set ll2_validl_rev :: "(nat * ((nat * ll2 * nat) list) * nat) set" where
    "\<And> n . (n, [], n) \<in> ll2_validl_rev"
  | "\<And> n l n' h n''.
    (n', h, n'') \<in> ll2_valid \<Longrightarrow>
    (n, l, n') \<in> ll2_validl_rev \<Longrightarrow>
    (n, (n',h,n'')#l, n'') \<in> ll2_validl_rev"
 
(* need an induction lemma for valid_rev *)    

lemma ll2_validl_rev_correct' [rule_format] : 
    "(k, l1, k') \<in> ll2_validl_rev \<Longrightarrow> (\<forall> l2 . (k', l2, k'') \<in> ll2_validl \<longrightarrow> (k, rev l1 @ l2, k'') \<in> ll2_validl)"
proof(induction "k" "l1" "k'"  rule: ll2_validl_rev.induct)
  case (1 n)
  thus ?case by auto 
  case (2 n l n' h n'')
  thus ?case
    apply(auto)
    apply(subgoal_tac "(n', (n', h, n'')#l2, k'') \<in> ll2_validl")
     apply(auto)
    apply(rule ll2_valid_ll2_validl.intros(7))
     apply(auto)
    done
qed

lemma ll2_validl_rev_correct :
  "(k, r, k') \<in> ll2_validl_rev \<Longrightarrow> (k, rev r, k') \<in> ll2_validl"
proof-
  assume H1: "(k, r, k') \<in> ll2_validl_rev"
  have H2: "(k', [], k') \<in> ll2_validl"
    apply(rule ll2_valid_ll2_validl.intros)
  done
  from ll2_validl_rev_correct'[OF H1 H2] have ?thesis
    apply(auto)
    done
  thus ?thesis by auto
qed

lemma ll2_validl_induct' [rule_format]:
  assumes Ll: "(n, t, n') \<in> ll2_validl"
  and Ln: "\<And> n . P n [] n"
  and Lind: "\<And> n h n' l n'' . (n, h, n') \<in> ll2_valid \<Longrightarrow> (n', l, n'') \<in> ll2_validl \<Longrightarrow> P n' l n'' \<Longrightarrow> P n ((n, h, n')#l) n''"
shows "P n t n'"
proof-
  {fix h l n n' m m'
    have "((n, h, n') \<in> ll2_valid \<longrightarrow> (n, h, n') \<in> ll2_valid) \<and>
          ((n, l, n') \<in> ll2_validl \<longrightarrow> P n l n')"
    proof (induction  rule:ll2_valid_ll2_validl.induct)
      case(1 i n) thus ?case by (rule ll2_valid_ll2_validl.intros) next
      case(2 n d) thus ?case by (rule ll2_valid_ll2_validl.intros) next
      case(3 n d) thus ?case by (rule ll2_valid_ll2_validl.intros) next
      case(4 n d) thus ?case by (rule ll2_valid_ll2_validl.intros) next
      case(5 n l n') 
        assume Hlv: "(n, l, n') \<in> ll2_validl"
        thus ?case using ll2_valid_ll2_validl.intros(5)[OF Hlv] 
          apply(auto)
            done next
      case(6 n) thus ?case using Ln by auto next
      case(7 n h n' l n'') 
        assume Hlv: "(n, h, n') \<in> ll2_valid"
         and Hllv : "(n', l, n'') \<in> ll2_validl"
         and Hp : "P n' l n''"
        thus ?case using Lind[OF Hlv]
          apply(auto)
          done
      qed}
    thus ?thesis using Ll by auto
qed

lemma ll2_validl_rev_correct_conv' [rule_format]:
  assumes H1: "(k', l1, k'') \<in> ll2_validl" 
  shows "(\<forall> l2 . (k, l2, k') \<in> ll2_validl_rev \<longrightarrow> (k, (rev l1) @ l2, k'') \<in> ll2_validl_rev)"
proof(induction "k'" "l1" "k''" rule: ll2_validl_induct')
  case (1) thus ?case using H1 by auto
  case (2 n) thus ?case by auto
  case (3 n h n' l n'') thus ?case
    apply(auto)
    apply(subgoal_tac "(k, (n, h, n') # l2, n') \<in> ll2_validl_rev")
     apply(auto)
    apply(rule ll2_validl_rev.intros)
     apply(auto)
    done
qed

lemma ll2_validl_rev_correct_conv :
  "(k, r, k') \<in> ll2_validl \<Longrightarrow> (k, rev r, k') \<in> ll2_validl_rev"
proof-
  assume H1 : "(k, r, k') \<in> ll2_validl"
  have H2 : "(k, [], k) \<in> ll2_validl_rev"
    apply(rule ll2_validl_rev.intros)
    done
  from ll2_validl_rev_correct_conv'[OF H1 H2] have ?thesis by auto
  thus ?thesis by auto
qed
    
    
  (* NOT DONE *)
  (* Q: should path correctness just be indexed to where root is in buffer? *)
  (* Q: better to have a few mut.ind. sets? *)
  (* we are using the first notion of validity *)
  (* Q: make this inductive def better? Can't prove go_left correct *)
inductive_set path2_valid :: "(nat * loc2 * nat) set" where
  "\<And> n n'.
   (n, t, n') \<in> ll2_valid \<Longrightarrow>
   (n, (t, Top (n, n')), n') \<in> path2_valid"
(*|"\<And> .
  (n, t, n') \<in> ll2_valid \<Longrightarrow>
  (n, (t, up), n') \<in> path2_valid \<Longrightarrow>
  ()
"*)
(* Q: move rev into premise to free up form of conclusion? *)
|"\<And> n l n' t n'' r n''' k up k'.
   (n', t, n'') \<in> ll2_valid \<Longrightarrow>
   (n, l, n') \<in> ll2_validl_rev  \<Longrightarrow>
   (n'', r, n''') \<in> ll2_validl \<Longrightarrow>
   (k, (LSeq (n, rev l @ ((n', t, n'')#r), n'''), up), k') \<in> path2_valid \<Longrightarrow> 
   (k, (t, Node(n, l, n', up, n'', r, n''')), k') \<in> path2_valid"


  
fun go_left :: "loc2 \<Rightarrow> loc2" where
  "go_left (t, path2.Node(n, (m,l,m')#ls, n', up, n'', rs, n''')) = 
           (l, path2.Node(n, ls, m, up, m', (n', t, n'')#rs, n'''))"
| "go_left loc = loc" (* bogus *)

(* Q: should these nav functions signal error *)
  
lemma go_left_correct :
  shows "(n, (t, l), n') \<in> path2_valid \<Longrightarrow> (n, go_left (t, l), n') \<in> path2_valid"
proof(induction rule: path2_valid.induct)
  case(1 t n n') thus ?case
    apply(simp)
    apply(rule path2_valid.intros, auto)
    done next
  case(2 n l n' t n'' r n''' k up k')
    thus ?case using ll2_valid_ll2_validl.intros(7)[OF `(n', t, n'')
       \<in> ll2_valid` `(n'', r, n''') \<in> ll2_validl`]
      apply(case_tac l)
       apply(auto)
       apply(erule path2_valid.intros, auto)
        apply(frule ll2_validl_rev.cases, auto)
      apply(rule path2_valid.intros, auto)
      done
qed

  (* go_right *)
fun go_right :: "loc2 \<Rightarrow> loc2" where
  "go_right (t, path2.Node(n, ls, n', up, n'', (m,r,m')#rs, n''')) = 
            (r, path2.Node(n, (n', t, n'')#ls, m, up, m', rs, n'''))"
| "go_right loc = loc" (*bogus*)
  
  (* go_up *)
fun go_up :: "loc2 \<Rightarrow> loc2" where
  "go_up (t, path2.Node(n, ls, n', up, n'', rs, n''')) =
         (LSeq (n, (rev ls)@((n',t,n'')#rs), n'''), up)"
| "go_up loc = loc" (*bogus*)
  
  (* go_down *)
fun go_down :: "loc2 \<Rightarrow> loc2" where
  "go_down (LSeq (n, (m,t,m')#ts, n'), p) =
           (t, path2.Node(n, [], m, p, m', ts, n'))"  
| "go_down loc = loc"
  
  (* then we can start talking about recursion *)
  
function sweep :: "loc2 \<Rightarrow> loc2" where
   "sweep (t, path2.Node(n, ls, n', up, n'', (m,r,m')#rs, n''')) =
    sweep (go_right (t, path2.Node(n, ls, n', up, n'', (m,r,m')#rs, n''')))" 
 | "sweep loc = loc"
  
     apply(auto)
     apply(auto)
      
    apply(simp)
   


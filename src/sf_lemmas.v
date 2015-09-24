Require sf_spec.
Require Import sf_tactic.
Require Import RelDec.
Require Import List.
Require Import Sorted.
Require Import Permutation.
Require Import FunctionalExtensionality.
Require Import Classical.
Import ListNotations.

Section cand.

Variable candidate : Set.
Variable reldec_candidate : RelDec (@eq candidate).
Variable reldec_correct_candidate : RelDec_Correct reldec_candidate.

Ltac solve_rcv := sf_tactic.solve_rcv reldec_correct_candidate.
Ltac intuition_nosplit := sf_tactic.intuition_nosplit reldec_correct_candidate.


Lemma next_ranking_cons_or :
forall b1 bal e x,
sf_spec.next_ranking candidate e (b1 :: bal) x ->
sf_spec.next_ranking candidate e [b1] x \/ 
sf_spec.next_ranking candidate e bal x.
intros. inv H; solve_rcv. left.
destruct H4; solve_rcv. eapply sf_spec.next_ranking_valid; solve_rcv.
left. eauto. eapply sf_spec.next_ranking_valid; solve_rcv.
Qed.

Lemma next_ranking_in :
forall e bal x,
  sf_spec.next_ranking candidate e bal x ->
  In x bal.
Proof.
induction bal; solve_rcv.
inv H; solve_rcv. 
Qed.

Lemma no_viable_candidates_cons :
forall a b e,
sf_spec.no_viable_candidates candidate (e) (a ::  b) <->
(sf_spec.no_viable_candidates candidate e [a] /\
sf_spec.no_viable_candidates candidate e b).
split.
intros.
unfold sf_spec.no_viable_candidates in *.
split.
intros. eapply H; eauto. inv H0; simpl in *; intuition.
intros. eapply H; eauto. simpl. intuition.
intros. intuition.
unfold sf_spec.no_viable_candidates in *. simpl in *.
intuition. eapply H0; eauto. 
eapply H1; eauto.
Qed.

Lemma first_choices_app : 
forall c l1 l2 x1 x2  r cnd, 
sf_spec.first_choices c r cnd l1 x1 ->
sf_spec.first_choices c r cnd l2 x2 ->
sf_spec.first_choices c r cnd (l1 ++ l2) (x1 + x2).
Proof.
induction l1; intros.
- simpl in *. inv H. simpl. auto.
- simpl in *. Print sf_spec.first_choices.
  inv H.
  + apply sf_spec.first_choices_selected. auto. fold plus.
    apply IHl1; auto.
  + apply sf_spec.first_choices_not_selected; auto.
Qed.

Lemma first_choices_app_gt :
forall c l1 l2 x1 x2 r cnd,
sf_spec.first_choices c r cnd l1 x1 ->
sf_spec.first_choices c r cnd (l1 ++ l2) (x2) ->
x2 >= x1.
Proof.
induction l1; intros.
- simpl in *. inv H. omega.
- simpl in *. inv H; inv H0; try congruence; try omega.
  eapply IHl1 in H5; eauto. omega.
  eapply IHl1; eauto.
Qed.

Lemma first_choices_perm : 
forall c l1 l2 x r cnd,
Permutation l1 l2 ->
sf_spec.first_choices c r cnd l1 x ->
sf_spec.first_choices c r cnd l2 x.
Proof.
induction l1; intros.
- apply Permutation_nil in H. subst. auto. 
- assert (exists l2s l23, l2 = l2s ++ (a :: l23)). 
  { eapply Permutation_in in H. instantiate (1 := a) in H.
    apply List.in_split in H. auto.
    constructor; auto. }
  destruct H1. destruct H1.
  subst.
  apply Permutation_cons_app_inv in H.
  inv H0.
  + eapply (IHl1 _ n' r cnd) in H; auto.
    clear - H H3.
    { generalize dependent x1. generalize dependent n'.
      induction x0; intros.
      - simpl in *. constructor; auto.
      - simpl in *. inv H. 
        + constructor; auto.
        + apply sf_spec.first_choices_not_selected; auto.
    }
  + eapply IHl1 in H; eauto.
    { clear - H H3.
      generalize dependent x1. generalize dependent x.
      induction x0; intros.
      - simpl in *. apply sf_spec.first_choices_not_selected; auto.
      - simpl in *. inv H.
        + constructor; auto.
        + apply sf_spec.first_choices_not_selected; auto.
    }
Qed.

Lemma selected_participates : forall election (c : candidate) bal  r,
sf_spec.selected_candidate _ r bal c ->
In bal election ->
sf_spec.participates _ c election.
Proof.
induction election; intros.
inv H0.
destruct H0. subst.
unfold sf_spec.participates.
unfold sf_spec.selected_candidate in H.
destruct H. destruct H0.
exists bal. split; eauto.
simpl. auto.
exists x. intuition.
apply next_ranking_in in H1. auto.
eapply IHelection in H0.
unfold sf_spec.participates in H0.
unfold sf_spec.participates.
simpl in *.
destruct H0.
exists x. split; auto. intuition.
destruct H0.
apply H1.
eauto.
Qed.

Lemma participates_cons : forall e a (c : candidate) ,
        sf_spec.participates _ c [a] \/ sf_spec.participates _ c e <->
        sf_spec.participates _ c (a :: e).
Proof.
split.
- intros.
  destruct H.
  + unfold sf_spec.participates in *.
    destruct H. destruct H. destruct H0. destruct H0.
    exists a. simpl in *. intuition.
    subst. exists x0. auto.
  + unfold sf_spec.participates in *. 
    destruct  H. intuition. destruct H1. exists x; intuition.
    exists x0; intuition.
- intros. destruct H.
  destruct H. destruct H0.
  destruct H.
  +  unfold sf_spec.participates.
     subst. left. exists x. intuition.
     exists x0; auto.
  +  right. unfold sf_spec.participates.
     exists x. intuition.
     exists x0; auto.
Qed.

Lemma total_selected_unique : forall r e v v',
sf_spec.total_selected candidate r e v ->
sf_spec.total_selected candidate r e v' ->
v= v'.
Admitted.

Lemma majority_not_0 :
forall r e x ,
sf_spec.majority candidate r e x ->
exists v, sf_spec.first_choices _ r x e v /\ v <> 0.
Proof.
intros.
unfold sf_spec.majority in *.
edestruct (sf_spec.sf_first_choices_total _ r e x).
edestruct (sf_spec.total_selected_total _ r e).
exists x0. intuition.
subst.
eapply H in H0; eauto.
omega.
Qed.

Lemma update_eliminated_in_rec : forall rec loser c,
sf_spec.update_eliminated candidate (in_record rec) loser c <->
in_record ([loser] :: rec) c.
Proof.
split; intros.
{ induction rec.
  - unfold sf_spec.update_eliminated in H.
    intuition. inv H0. destruct H. inv H.
    subst. unfold in_record. exists [c]. intuition; auto.
  - unfold sf_spec.update_eliminated in  *. intuition.
    unfold in_record in H0. destruct H0. intuition.
    simpl in H2. destruct H2.
    + subst. unfold in_record. exists x. 
      intuition.
    + unfold in_record. exists x. intuition.
    + unfold in_record in H2. destruct H2.
      intuition. simpl in H2. destruct H2.
      * subst. unfold in_record. exists [c].
        intuition.
      * exists x. intuition. }
{ unfold in_record in H. destruct H. intuition. simpl in H0.
  destruct H0. subst. unfold sf_spec.update_eliminated.
  right. inv H1; auto. inv H.
  left. unfold in_record. eauto. }
Qed.

Axiom prop_ext : forall (P Q : Prop), 
  (P <-> Q) -> P = Q.


Lemma update_eliminated_in_rec_eq : forall rec loser c,
sf_spec.update_eliminated candidate (in_record rec) loser c =
in_record ([loser] :: rec) c.
Proof. intros.
apply prop_ext. apply update_eliminated_in_rec.
Qed.


Lemma update_eliminated_in_rec_eq_noc : forall rec loser,
sf_spec.update_eliminated candidate (in_record rec) loser =
in_record ([loser] :: rec).
intros. extensionality c. apply update_eliminated_in_rec_eq.
Qed.

Definition continuing2 b rec:=
exists r, sf_spec.next_ranking candidate rec b r /\ ~sf_spec.overvote candidate r.


Lemma continuing2_continuing : 
forall b rec,
continuing2 b rec <-> sf_spec.continuing_ballot candidate rec b.
Proof.
intros.
split.
intros.
unfold continuing2 in *.
solve_rcv.
destruct H1. apply H1. exists x. auto.
destruct H1. solve_rcv.
eapply sf_spec.next_ranking_unique in H; eauto. subst.
apply H0; eauto.
intros.
unfold continuing2.
solve_rcv.

apply Classical_Prop.not_or_and in H.
destruct H. apply Classical_Prop.NNPP in H.
destruct H. exists x.
split. auto.
intro. apply H0. exists x. auto.
Qed.

Lemma continuing_ballot_cons :
forall r h t,
sf_spec.continuing_ballot candidate r (h :: t) ->
sf_spec.continuing_ballot candidate r [h] \/ ((~sf_spec.overvote candidate h) /\ sf_spec.continuing_ballot candidate r t).
Proof.
intros. repeat rewrite <- continuing2_continuing in *.
induction t. 
- auto.
- unfold continuing2 in *.
  destruct H. destruct H.
  inv H.
  + right. intuition. exists x. auto.
  + destruct H5. 
    *  intuition. 
    * left. exists x.
      intuition. eapply sf_spec.next_ranking_valid.
      apply H3. auto.
Qed.

Lemma continuing_ballot_cons2 :
forall r a b,
sf_spec.continuing_ballot candidate r [a] ->
sf_spec.continuing_ballot candidate r (a :: b).
Proof.
intros. rewrite <- continuing2_continuing in *.
unfold continuing2 in *. destruct H.
exists x.
destruct H. intuition.
clear H0.
inv H. inv H5. eapply sf_spec.next_ranking_valid; eauto.
Qed.

Lemma continuing_ballot_cons3 :
forall t h r
(OV : ~sf_spec.overvote candidate h), 
sf_spec.continuing_ballot candidate r t ->
sf_spec.continuing_ballot candidate r (h :: t).
Proof.
intros. rewrite <- continuing2_continuing in *.
unfold continuing2 in *.
destruct H. destruct H.
destruct (classic (Forall r h)).
exists x. intuition. 
constructor; eauto.
destruct h. exfalso. solve_rcv. apply H1. solve_rcv.
exists (c::h). intuition.
eapply sf_spec.next_ranking_valid. simpl. eauto. 
right. solve_rcv. apply H1. intros. destruct H3. subst. auto.
destruct (rel_dec_p c x0).
subst. auto.
exfalso. apply OV. exists c. exists x0.
simpl. auto.
Qed.

Lemma continuing_ballot_rec_cons : 
forall l r b,
  sf_spec.continuing_ballot candidate (in_record ([l] :: r)) (b) ->
   sf_spec.continuing_ballot candidate (in_record r) (b).
Proof.
  intros. induction b.
  - unfold sf_spec.continuing_ballot in *.  
    intro. apply H. clear H.
    unfold sf_spec.exhausted_ballot. left. intro.
    inv H. inv H1.
  - apply continuing_ballot_cons in H.  
    destruct H.
    apply continuing_ballot_cons2. 
    rewrite <- continuing2_continuing in *.
    unfold continuing2. 
    unfold continuing2 in H.
    destruct H. exists x.
    destruct H. intuition.
    inv H. constructor; solve_rcv.
    destruct H5. intuition.
    eapply sf_spec.next_ranking_valid; eauto.
    right. intro. apply H; clear H.
    unfold in_record in *. solve_rcv.
    intuition.
    apply continuing_ballot_cons3; auto.
Qed.

Lemma next_ranking_cons_or2 :
forall b1 bal e x,
sf_spec.next_ranking candidate e (b1 :: bal) x ->
sf_spec.next_ranking candidate e [b1] x \/ 
(Forall e b1 /\ sf_spec.next_ranking candidate e bal x).
intros. inv H; solve_rcv. left.
destruct H4; solve_rcv. eapply sf_spec.next_ranking_valid; solve_rcv.
left. eauto. eapply sf_spec.next_ranking_valid; solve_rcv.
Qed.

Lemma continuing_ballot_cons4 : (*should be main lemma, don't want to rework proofs :( *)
forall r h t,
sf_spec.continuing_ballot candidate r (h :: t) ->
sf_spec.continuing_ballot candidate r [h] \/ ((~sf_spec.overvote candidate h) /\ sf_spec.continuing_ballot candidate r t /\ Forall r h).
Proof.
intros. repeat rewrite <- continuing2_continuing in *.
induction t. 
- auto.
- unfold continuing2 in *.
  destruct H. destruct H.
  inv H.
  + right. intuition. exists x. auto.
  + destruct H5. 
    *  intuition. 
    * left. exists x.
      intuition. eapply sf_spec.next_ranking_valid.
      apply H3. auto.
Qed.

Lemma selected_cons :
forall r a b c,
sf_spec.selected_candidate candidate  r (a :: b) c ->
sf_spec.selected_candidate candidate r [a] c \/
(Forall r a /\ ~sf_spec.overvote candidate a /\sf_spec.selected_candidate candidate r b c).
Proof.
intros.
unfold sf_spec.selected_candidate in H.
intuition_nosplit. apply continuing_ballot_cons4 in H.
apply next_ranking_cons_or2 in H0.
destruct H, H0.
left. unfold sf_spec.selected_candidate. intuition.
eauto.
rewrite <- continuing2_continuing in H.
unfold continuing2 in H. destruct H. destruct H.
inv H. inv H8. rewrite Forall_forall in H0. intuition.
destruct H. destruct H2. inv H0. inv H9. rewrite Forall_forall in *.
intuition.
right. unfold sf_spec.selected_candidate. intuition.
eauto.
Qed.

Lemma first_choices_0_cons :
forall r c h t,
sf_spec.first_choices candidate r c (h :: t) 0 <->
sf_spec.first_choices candidate r c [h] 0 /\
sf_spec.first_choices candidate r c t 0.
Proof.
split.
- intros.
  induction t. intuition. constructor.
  inv H. intuition.
  inv H4.
  apply IHt.
  constructor. auto. auto.
- intros. destruct H.
  inv H. constructor; auto.
Qed.

Lemma next_ranking_record_same :
forall b x c l r,
  In c x ->
  c <> l ->
  sf_spec.next_ranking candidate (in_record r) b x ->
  ~ sf_spec.overvote candidate x ->
  sf_spec.next_ranking candidate (in_record ([l] :: r)) b x.
Proof.
induction b; intros.
inv H1.
inv H1.
- constructor. solve_rcv. specialize (H5 x0); solve_rcv.
  auto.
  eapply IHb; eauto.
- intuition.
  eapply sf_spec.next_ranking_valid.
  apply H5. right. intro.
  apply H1. solve_rcv. simpl in H3. destruct H3; solve_rcv.
  assert (c0 = l). inv H4. subst; intuition. inv H3. subst. clear H4.
  exfalso. apply H2. exists c. exists l. eauto.
Qed.

Lemma ne_still_continuing :
forall b c l  x r,
sf_spec.next_ranking candidate (in_record r) b x ->
sf_spec.continuing_ballot candidate (in_record r) b ->
In c x ->
c <> l ->
sf_spec.continuing_ballot candidate (in_record ([l] :: r)) b.
Proof.
intros. repeat rewrite <- continuing2_continuing in *.
unfold continuing2 in *. intuition_nosplit.
exists x0. split; eauto. 
eapply sf_spec.next_ranking_unique in H; eauto. subst.
eapply next_ranking_record_same; eauto.
Qed.

Lemma selected_rec_cons :
forall r b c l,
c <> l ->
sf_spec.selected_candidate candidate (in_record r) b c ->
sf_spec.selected_candidate candidate (in_record ([l]::r)) b c.
intros.
induction b. solve_rcv.
apply selected_cons in H0. 
destruct H0. 
- clear IHb. 
  unfold sf_spec.selected_candidate in *.
  intuition_nosplit.
  split. 
  + apply continuing_ballot_cons2. 
  eapply ne_still_continuing; eauto.
  + inv H1. inv H8.
    destruct H7. exists x. intuition.
    eapply sf_spec.next_ranking_valid; eauto.
    exists x. intuition. eapply sf_spec.next_ranking_valid; eauto.
    right. intro. apply H1. rewrite <- continuing2_continuing in *. 
    unfold continuing2 in *. unfold in_record in *. intuition_nosplit. 
    simpl in *. destruct H3; subst; try solve [solve_rcv].
    inv H4; intuition_nosplit. inv H0. inv H10. intuition.
    exfalso. apply H6. solve_rcv.
- intuition. clear H3. 
  unfold sf_spec.selected_candidate in *.
  intuition_nosplit. split. 
  rewrite <- continuing2_continuing. unfold continuing2. exists x.
  intuition. constructor; auto. rewrite Forall_forall in *.
  intro. specialize (H1 x0). intro. intuition. 
  solve_rcv.  rewrite <-  continuing2_continuing in *.
  unfold continuing2 in *. intuition_nosplit.
  eapply sf_spec.next_ranking_unique in H2; eauto. subst.
  auto.
  exists x. intuition.
  constructor; auto.
  rewrite Forall_forall in *. intros. specialize (H1 x0). 
  solve_rcv.
Qed.

Lemma first_choices_rec_0 :
forall c l r e,
  sf_spec.first_choices candidate (in_record ([l] :: r)) c e 0 ->
  c <> l ->
  sf_spec.first_choices candidate (in_record r) c e 0.
Proof.
intros.
induction e.
- constructor.
- apply first_choices_0_cons in H. destruct H. intuition.
  apply first_choices_0_cons. intuition.
  inv H.
  constructor. intro. apply H5. clear H5. 
  apply selected_rec_cons; auto. constructor.
Qed.



Lemma first_choices_0_loser :
forall c election l,
~in_record l c ->
sf_spec.participates _ c election ->
sf_spec.first_choices candidate (in_record l) c election 0 ->
sf_spec.is_loser _ (in_record l) election c.
Proof.
intros. unfold sf_spec.is_loser in *.
split.
- unfold sf_spec.viable_candidate. 
  split.
  + unfold in_record. intuition_nosplit. apply H. unfold in_record. eauto.
  + auto.
- intros. eapply sf_spec.sf_first_choices_unique in H1; eauto. subst. omega.
Qed.

Lemma in_record_nil_nil (c: candidate) :
forall l, in_record l c <-> in_record ([] :: l) c.
split; intros; unfold in_record in *;
intuition_nosplit. exists x. simpl. intuition.
inv H. inv H0. exists x; simpl; auto.
Qed.

Lemma in_record_nil_nil_eq :
forall (l : list (list candidate)), in_record l = in_record ([] :: l).
intros. extensionality c. apply prop_ext.
apply in_record_nil_nil.
Qed.

Fixpoint flatten {A} (l : list (list A)) : list A :=
match l with
| h :: t => h ++ flatten t
| nil => nil
end.


Lemma in_flatten :
forall A (x: list A) l (c : A),
(exists x, In x l /\ In c x) <-> In c (flatten l).
split; intros.
- induction l.
  +  intuition_nosplit.
  + intuition_nosplit. simpl in *. destruct H.
    * subst. apply in_app_iff. auto.
    * apply in_app_iff. right. apply IHl. eauto.
- induction l.
  inv H.
  simpl in *. apply in_app_or in H. destruct H.
  eauto.
  edestruct IHl; eauto.
  exists x0. intuition.
Qed.

Lemma in_record_flatten (c : candidate): 
forall l, in_record l c <-> in_record ([flatten l]) c.
Proof.
split; intros;
unfold in_record in *; intuition_nosplit.
exists (flatten l). intuition. apply in_flatten; eauto.
inv H. apply in_flatten in H0. auto. apply nil.
inv H1.
Qed.


Lemma winner_eliminate_0s :
forall election r winner l
(NODUP : NoDup l),
(forall c, in_record (r::l) c -> sf_spec.first_choices _ (in_record l) c election 0) ->
sf_spec.winner candidate election (in_record (r ::l) ) winner ->
sf_spec.winner candidate election (in_record l) winner.
Proof.
intros. 
induction r; auto; intros. rewrite in_record_nil_nil_eq. auto.  
destruct (classic (sf_spec.participates _ a election)).
- destruct (classic (sf_spec.no_majority candidate (in_record l) election)).
  + eapply sf_spec.winner_elimination.
    auto. specialize (H a). eapply first_choices_0_loser in H. apply H.
    
    auto. unfold in_record. 
Admitted. 
(*exists (a::r). simpl; auto.
    rewrite update_eliminated_in_rec_eq_noc. inv H0. admit. (* no majority conflicts with majority *)
*)

End cand.
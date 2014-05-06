/*************************************************************************
*									 *
*	 YAP Prolog 							 *
*									 *
*	Yap Prolog was developed at NCCUP - Universidade do Porto	 *
*       BEAM extends the YAP Prolog system to support the EAM            *
*									 *
*    Copyright Ricardo Lopes and Universidade do Porto 2000-2006	 *
*									 *
**************************************************************************
*									 *
* File:		eam.yap						         *
* Last rev:	6/4/2006						 *
* mods:									 *
* comments:	Some utility predicates needed by BEAM		         *
*									 *
*************************************************************************/

eamtrans(A,A):- var(A),!.
eamtrans((A,B),(C,D)):- !, eamtrans(A,C),eamtrans(B,D).
eamtrans((X is Y) ,(skip_while_var(Vars), X is Y  )):- !, '$variables_in_term'(Y,[],Vars).
eamtrans((X =\= Y),(skip_while_var(Vars), X =\= Y )):- !, '$variables_in_term'(X + Y,[],Vars).
eamtrans((X =:= Y),(skip_while_var(Vars), X =:= Y )):- !, '$variables_in_term'(X + Y,[],Vars).
eamtrans((X >= Y) ,(skip_while_var(Vars), X >= Y  )):- !, '$variables_in_term'(X + Y,[],Vars).
eamtrans((X > Y)  ,(skip_while_var(Vars), X > Y   )):- !, '$variables_in_term'(X + Y,[],Vars).
eamtrans((X < Y)  ,(skip_while_var(Vars), X < Y   )):- !, '$variables_in_term'(X + Y,[],Vars).
eamtrans((X =< Y) ,(skip_while_var(Vars), X =< Y  )):- !, '$variables_in_term'(X + Y,[],Vars).
eamtrans((X @>= Y) ,(skip_while_var(Vars), X @>= Y  )):- !, '$variables_in_term'(X + Y,[],Vars).
eamtrans((X @> Y)  ,(skip_while_var(Vars), X @> Y   )):- !, '$variables_in_term'(X + Y,[],Vars).
eamtrans((X @< Y)  ,(skip_while_var(Vars), X @< Y   )):- !, '$variables_in_term'(X + Y,[],Vars).
eamtrans((X @=< Y) ,(skip_while_var(Vars), X @=< Y  )):- !, '$variables_in_term'(X + Y,[],Vars).

eamtrans((X \= Y) ,(skip_while_var(Vars), X \= Y  )):- !, '$variables_in_term'(X + Y,[],Vars).
eamtrans((X \== Y),(skip_while_var(Vars), X \== Y )):- !, '$variables_in_term'(X + Y,[],Vars).

eamtrans(B,B).

eamconsult(File):- eam, eam,                    %fails if eam is disable
                assert((user:term_expansion((A :- B),(A :- C)):- eamtrans(B,C))),
                eam, ( consult(File) ; true), eam,
		abolish(user:term_expansion,2).

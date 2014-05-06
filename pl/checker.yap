/*************************************************************************
*									 *
*	 YAP Prolog 							 *
*									 *
*	Yap Prolog was developed at NCCUP - Universidade do Porto	 *
*									 *
* Copyright L.Damas, V.S.Costa and Universidade do Porto 1985-1997	 *
*									 *
**************************************************************************
*									 *
* File:		checker.yap						 *
* comments:	style checker for Prolog				 *
*									 *
* Last rev:     $Date: 2008-03-31 22:56:22 $,$Author: vsc $						 *
* $Log: not supported by cvs2svn $
* Revision 1.23  2007/11/26 23:43:09  vsc
* fixes to support threads and assert correctly, even if inefficiently.
*
* Revision 1.22  2006/11/17 12:10:46  vsc
* style_checker was failing on DCGs
*
* Revision 1.21  2006/03/24 16:26:31  vsc
* code review
*
* Revision 1.20  2005/11/05 23:56:10  vsc
* should have meta-predicate definitions for calls,
*   multifile and discontiguous.
* have discontiguous as a builtin, not just as a
*   declaration.
*
* Revision 1.19  2005/10/28 17:38:50  vsc
* sveral updates
*
* Revision 1.18  2005/04/20 20:06:11  vsc
* try to improve error handling and warnings from within consults.
*
* Revision 1.17  2005/04/20 04:08:20  vsc
* fix warnings
*
* Revision 1.16  2005/01/13 05:47:27  vsc
* lgamma broke arithmetic optimisation
* integer_y has type y
* pass original source to checker (and maybe even use option in parser)
* use warning mechanism for checker messages.
*
* Revision 1.15  2004/06/29 19:12:01  vsc
* fix checker messages
*
* Revision 1.14  2004/06/29 19:04:46  vsc
* fix multithreaded version
* include new version of Ricardo's profiler
* new predicat atomic_concat
* allow multithreaded-debugging
* small fixes
*
* Revision 1.13  2004/03/19 11:35:42  vsc
* trim_trail for default machine
* be more aggressive about try-retry-trust chains.
*    - handle cases where block starts with a wait
*    - don't use _killed instructions, just let the thing rot by itself.
*                                                                  *
*									 *
*************************************************************************/

%
% A Small style checker for YAP

:- op(1150, fx, multifile).

style_check(V) :- var(V), !, fail.
style_check(all) :-
	'$syntax_check_single_var'(_,on),
	'$syntax_check_discontiguous'(_,on),
	'$syntax_check_multiple'(_,on).
style_check(single_var) :-
	'$syntax_check_single_var'(_,on).
style_check(singleton) :-
	style_check(single_var).
style_check(-single_var) :-
	no_style_check(single_var).
style_check(-singleton) :-
	no_style_check(single_var).
style_check(discontiguous) :-
	'$syntax_check_discontiguous'(_,on).
style_check(-discontiguous) :-
	no_style_check(discontiguous).
style_check(multiple) :-
	'$syntax_check_multiple'(_,on).
style_check(-multiple) :-
	no_style_check(multiple).
style_check([]).
style_check([H|T]) :- style_check(H), style_check(T).

no_style_check(V) :- var(V), !, fail.
no_style_check(all) :-
	'$syntax_check_single_var'(_,off),
	'$syntax_check_discontiguous'(_,off),
	'$syntax_check_multiple'(_,off).
no_style_check(single_var) :-
	'$syntax_check_single_var'(_,off).
no_style_check(discontiguous) :-
	'$syntax_check_discontiguous'(_,off).
no_style_check(multiple) :-
	'$syntax_check_multiple'(_,off).
no_style_check([]).
no_style_check([H|T]) :- no_style_check(H), no_style_check(T).


'$syntax_check_single_var'(O,N) :- 
	'$values'('$syntaxchecksinglevar',O,N),
	'$checking_on'.

'$syntax_check_discontiguous'(O,N) :- 
	'$values'('$syntaxcheckdiscontiguous',O,N),
	'$checking_on'.

'$syntax_check_multiple'(O,N) :- 
	'$values'('$syntaxcheckmultiple',O,N),
	'$checking_on'.

%
% cases where you need to check a clause
%
'$checking_on' :-
	( 
	  get_value('$syntaxchecksinglevar',on)
	;
	  get_value('$syntaxcheckdiscontiguous',on)
	;
	  get_value('$syntaxcheckmultiple',on)
	), !,
	set_value('$syntaxcheckflag',on).
'$checking_on' :-
	set_value('$syntaxcheckflag',off).

% reset current state of style checker.
'$init_style_check'(File) :-
	recorded('$predicate_defs','$predicate_defs'(_,_,_,File),R),
	erase(R),
	fail.
'$init_style_check'(_).

% style checker proper..
'$check_term'(_, T, _,P,M) :-
	get_value('$syntaxcheckdiscontiguous',on),
	strip_module(T, M, T1),
	'$pred_arity'( T1, Name, Arity ),
	% should always fail
	'$handle_discontiguous'(Name, Arity, M),
	fail.
'$check_term'(_, T,_,P,M) :-
	get_value('$syntaxcheckmultiple',on),
	strip_module(T, M, T1),
	'$pred_arity'( T1, Name, Arity ),
	'$handle_multiple'( Name , Arity, M), 
	fail.
'$check_term'(_, T,_,_,M) :-
	( 
	    get_value('$syntaxcheckdiscontiguous',on)
	->
	       true
	;
	    get_value('$syntaxcheckmultiple',on)
	),
	source_location( File, _ ),
	strip_module(T, M, T1),
	'$pred_arity'( T1, Name, Arity ),
	\+ (
	    % allow duplicates if we are not the last predicate to have
	    % been asserted.
	    once(recorded('$predicate_defs','$predicate_defs'(F0,A0,M0,File),_)),
	    F0 = F, A0 = A, M0 = NM
	),
	recorda('$predicate_defs','$predicate_defs'(F,A,NM,File),_),
	fail.
'$check_term'(_,_,_,_,_).

'$sv_warning'([], _) :- !.
'$sv_warning'(SVs,  T) :-
	strip_module(T, M, T1),
	'$pred_arity'( T1, Name, Arity ),
	print_message(warning,singletons(SVs,(M:Name/Arity))).

'$pred_arity'(V,M,M,V,call,1) :- var(V), !.
'$pred_arity'((H:-_),Name,Arity) :- !,
	functor(H,Name,Arity).
'$pred_arity'((H-->_),Name,Arity) :- !,
	functor(HL,Name,1),
	Arity is A1+2.
'$pred_arity'(H,Name,Arity) :-
	functor(H,Name,Arity).

% check if a predicate is discontiguous.
'$handle_discontiguous'(F,A,M) :-
	recorded('$discontiguous_defs','$df'(F,A,M),_), !,
	fail.
'$handle_discontiguous'(F,A,M) :-
	functor(Head, F, A),
	'$is_multifile'(Head, M), !,
	fail.
'$handle_discontiguous'((:-),1,_) :- !,
	fail.
'$handle_discontiguous'(F,A,M) :-
	source_location( FileName, _ ),
	% we have been there before
	once(recorded('$predicate_defs','$predicate_defs'(F, A, M, FileName),_)),
	% and we are not 
	\+ (
	    % the last predicate to have been asserted
	    once(recorded('$predicate_defs','$predicate_defs'(F0,A0,M0,FileName),_)),
	    F0 = F, A0 = A, M0 = M
	),
	print_message(warning,clauses_not_together((M:F/A))),
        fail.

% never complain the second time
'$handle_multiple'(F,A,M) :-
	source_location(FileName, _),
	recorded('$predicate_defs','$predicate_defs'(F,A,M,FileName),_), !.
% first time we have a definition
'$handle_multiple'(F,A,M) :-
	source_location(FileName0, _),
	recorded('$predicate_defs','$predicate_defs'(F,A,M,FileName),_),
	FileName \= FileName0,
	'$multiple_has_been_defined'(FileName, F/A, M), !.

% be careful about these cases.
% consult does not count
'$multiple_has_been_defined'(_, _, _) :-
	'$nb_getval'('$consulting_file', _, fail), !.	
% multifile does not count
'$multiple_has_been_defined'(_, F/A, M) :-
	functor(S, F, A),
	'$is_multifile'(S, M), !.
'$multiple_has_been_defined'(Fil,F/A,M) :-
	% first, clean up all definitions in other files
	% don't forget, we just removed everything.
	recorded('$predicate_defs','$predicate_defs'(F,A,M,FileName),R),
	erase(R),
	fail.
'$multiple_has_been_defined'(Fil,P,M) :-
	print_message(warning,defined_elsewhere(M:P,Fil)).

multifile(P) :-
	'$current_module'(OM),
	'$multifile'(P, M).

'$multifile'(V, _) :- var(V), !,
	'$do_error'(instantiation_error,multifile(V)).
'$multifile'((X,Y), M) :- !, '$multifile'(X, M), '$multifile'(Y, M).
'$multifile'(Mod:PredSpec, _) :- !,
	'$multifile'(PredSpec, Mod).
'$multifile'(N//A, M) :- !,
	integer(A),
	A1 is A+2,
	'$multifile'(N/A1, M).
'$multifile'(N/A, M) :-
	'$add_multifile'(N,A,M),
	fail.
'$multifile'(N/A, M) :-
         functor(S,N,A),
	'$is_multifile'(S, M), !.
'$multifile'(N/A, M) :- !,
	'$new_multifile'(N,A,M).
'$multifile'([H|T], M) :- !,
	'$multifile'(H,M),
	'$multifile'(T,M).
'$multifile'(P, M) :-
	'$do_error'(type_error(predicate_indicator,P),multifile(M:P)).

discontiguous(V) :-
	var(V), !,
	'$do_error'(instantiation_error,discontiguous(V)).
discontiguous(M:F) :- !,
	'$discontiguous'(F,M).
discontiguous(F) :-
	'$current_module'(M),
	'$discontiguous'(F,M).

'$discontiguous'(V,M) :- var(V), !,
	'$do_error'(instantiation_error,M:discontiguous(V)).
'$discontiguous'((X,Y),M) :- !,
	'$discontiguous'(X,M),
	'$discontiguous'(Y,M).
'$discontiguous'(M:A,_) :- !,
	'$discontiguous'(A,M).
'$discontiguous'(N//A1, M) :- !,
	integer(A1), !,
	A is A1+2,
	'$discontiguous'(N/A, M).
'$discontiguous'(N/A, M) :- !,
	( recordzifnot('$discontiguous_defs','$df'(N,A,M),_) ->
	    true
	;
	    true
	).
'$discontiguous'(P,M) :-
	'$do_error'(type_error(predicate_indicator,P),M:discontiguous(P)).

%
% did we declare multifile properly?
%
'$check_multifile_pred'(Hd, M, _) :-
	functor(Hd,Na,Ar),
	source_location(F, _),
	recorded('$multifile_defs','$defined'(F,Na,Ar,M),_), !.
% oops, we did not.
'$check_multifile_pred'(Hd, M, Fl) :-
	% so this is not a multi-file predicate any longer.
	functor(Hd,Na,Ar),
	NFl is \(0x20000000) /\ Fl,
	'$flags'(Hd,M,Fl,NFl),
	'$warn_mfile'(Na,Ar).

'$warn_mfile'(F,A) :-
	write(user_error,'% Warning: predicate '),
	write(user_error,F/A), write(user_error,' was a multifile predicate '),
	write(user_error,' (line '),
	'$start_line'(LN), write(user_error,LN),
	write(user_error,')'),
	nl(user_error).	




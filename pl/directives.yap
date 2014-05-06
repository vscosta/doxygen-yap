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
* File:		directives.yap						 *
* Last rev:								 *
* mods:									 *
* comments:	directing system execution				 *
*									 *
*************************************************************************/

'$all_directives'(_:G1) :- !,
	'$all_directives'(G1).
'$all_directives'((G1,G2)) :- !,
	'$all_directives'(G1),
	'$all_directives'(G2).
'$all_directives'(G) :- !,
	'$directive'(G).

'$directive'(block(_)).
'$directive'(char_conversion(_,_)).
'$directive'(compile(_)).
'$directive'(consult(_)).
'$directive'(discontiguous(_)).
'$directive'(dynamic(_)).
'$directive'(elif(_)).
'$directive'(else).
'$directive'(encoding(_)).
'$directive'(endif).
'$directive'(ensure_loaded(_)).
'$directive'(expects_dialect(_)).
'$directive'(if(_)).
'$directive'(include(_)).
'$directive'(initialization(_)).
'$directive'(initialization(_,_)).
'$directive'(license(_)).
'$directive'(meta_predicate(_)).
'$directive'(module(_,_)).
'$directive'(module(_,_,_)).
'$directive'(module_transparent(_)).
'$directive'(multifile(_)).
'$directive'(noprofile(_)).
'$directive'(public(_)).
'$directive'(op(_,_,_)).
'$directive'(require(_)).
'$directive'(set_prolog_flag(_,_)).
'$directive'(reconsult(_)).
'$directive'(reexport(_)).
'$directive'(reexport(_,_)).
'$directive'(predicate_options(_,_,_)).
'$directive'(thread_initialization(_)).
'$directive'(thread_local(_)).
'$directive'(uncutable(_)).
'$directive'(use_module(_)).
'$directive'(use_module(_,_)).
'$directive'(use_module(_,_,_)).
'$directive'(wait(_)).

'$exec_directives'((G1,G2), Mode, M, VL, Pos) :- !,
	'$exec_directives'(G1, Mode, M, VL, Pos),
	'$exec_directives'(G2, Mode, M, VL, Pos).
'$exec_directives'(G, Mode, M, VL, Pos) :-
	'$exec_directive'(G, Mode, M, VL, Pos).

'$exec_directive'(multifile(D), _, M, _, _) :-
	'$system_catch'('$multifile'(D, M), M,
	      Error,
	      user:'$LoopError'(Error, top)).
'$exec_directive'(discontiguous(D), _, M, _, _) :-
	'$discontiguous'(D,M).
'$exec_directive'(initialization(D), _, M, _, _) :-
	'$initialization'(M:D).
'$exec_directive'(initialization(D,OPT), _, M, _, _) :-
	'$initialization'(M:D, OPT).
'$exec_directive'(thread_initialization(D), _, M, _, _) :-
	'$thread_initialization'(M:D).
'$exec_directive'(expects_dialect(D), _, _, _, _) :-
	'$expects_dialect'(D).
'$exec_directive'(encoding(Enc), _, _, _, _) :-
        '$set_encoding'(Enc).
'$exec_directive'(include(F), Status, _, _, _) :-
	'$include'(F, Status).
'$exec_directive'(module(N,P), Status, _, _, _) :-
	'$module'(Status,N,P).
'$exec_directive'(module(N,P,Op), Status, _, _, _) :-
	'$module'(Status,N,P,Op).
'$exec_directive'(meta_predicate(P), _, M, _, _) :-
	'$meta_predicate'(P, M).
'$exec_directive'(module_transparent(P), _, M, _, _) :-
	'$module_transparent'(P, M).
'$exec_directive'(noprofile(P), _, M, _, _) :-
	'$noprofile'(P, M).
'$exec_directive'(require(Ps), _, M, _, _) :-
	'$require'(Ps, M).
'$exec_directive'(dynamic(P), _, M, _, _) :-
	'$dynamic'(P, M).
'$exec_directive'(thread_local(P), _, M, _, _) :-
	'$thread_local'(P, M).
'$exec_directive'(op(P,OPSEC,OP), _, _, _, _) :-
	'$current_module'(M),
	op(P,OPSEC,M:OP).
'$exec_directive'(set_prolog_flag(F,V), _, _, _, _) :-
	set_prolog_flag(F,V).
'$exec_directive'(ensure_loaded(Fs), _, M, _, _) :-
	'$load_files'(M:Fs, [if(changed)], ensure_loaded(Fs)).
'$exec_directive'(char_conversion(IN,OUT), _, _, _, _) :-
	char_conversion(IN,OUT).
'$exec_directive'(public(P), _, M, _, _) :-
	'$public'(P, M).
'$exec_directive'(compile(Fs), _, M, _, _) :-
	'$load_files'(M:Fs, [], compile(Fs)).
'$exec_directive'(reconsult(Fs), _, M, _, _) :-
	'$load_files'(M:Fs, [], reconsult(Fs)).
'$exec_directive'(consult(Fs), _, M, _, _) :-
	'$load_files'(M:Fs, [consult(consult)], consult(Fs)).
'$exec_directive'(use_module(F), _, M, _, _) :-
	'$load_files'(M:F, [if(not_loaded),must_be_module(true)],use_module(F)).
'$exec_directive'(reexport(F), _, M, _, _) :-
	'$load_files'(M:F, [if(not_loaded), silent(true), reexport(true),must_be_module(true)], reexport(F)).
'$exec_directive'(reexport(F,Spec), _, M, _, _) :-
	'$load_files'(M:F, [if(changed), silent(true), imports(Spec), reexport(true),must_be_module(true)], reexport(F, Spec)).
'$exec_directive'(use_module(F,Is), _, M, _, _) :-
	'$load_files'(M:F, [if(not_loaded),imports(Is),must_be_module(true)],use_module(F,Is)).
'$exec_directive'(use_module(Mod,F,Is), _, _, _, _) :-
	'$use_module'(Mod,F,Is).
'$exec_directive'(block(BlockSpec), _, _, _, _) :-
	'$block'(BlockSpec).
'$exec_directive'(wait(BlockSpec), _, _, _, _) :-
	'$wait'(BlockSpec).
'$exec_directive'(table(PredSpec), _, M, _, _) :-
	'$table'(PredSpec, M).
'$exec_directive'(uncutable(PredSpec), _, M, _, _) :-
	'$uncutable'(PredSpec, M).
'$exec_directive'(if(Goal), Context, M, _, _) :-
	'$if'(M:Goal, Context).
'$exec_directive'(else, Context, _, _, _) :-
	'$else'(Context).
'$exec_directive'(elif(Goal), Context, M, _, _) :-
	'$elif'(M:Goal, Context).
'$exec_directive'(endif, Context, _, _, _) :-
	'$endif'(Context).
'$exec_directive'(license(_), Context, _, _, _) :-
	Context \= top.
'$exec_directive'(predicate_options(PI, Arg, Options), Context, Module, VL, Pos) :-
	Context \= top,
	'$predopts':expand_predicate_options(PI, Arg, Options, Clauses),
	'$assert_list'(Clauses, Context, Module, VL, Pos).

'$assert_list'([], _Context, _Module, _VL, _Pos).
'$assert_list'(Clause.Clauses, Context, Module, VL, Pos) :-
	'$command'(Clause, VL, Pos, Context),
	'$assert_list'(Clauses, Context, Module, VL, Pos).

%                                                                                  
% allow users to define their own directives.                                      
%                                                                                  
user_defined_directive(Dir,_) :-
        '$directive'(Dir), !.
user_defined_directive(Dir,Action) :-
        functor(Dir,Na,Ar),
        functor(NDir,Na,Ar),
        '$current_module'(M, prolog),
	assert_static('$directive'(NDir)),
	assert_static(('$exec_directive'(Dir, _, _, _, _) :- Action)),
        '$current_module'(_, M).

'$thread_initialization'(M:D) :-
	eraseall('$thread_initialization'),
	recorda('$thread_initialization',M:D,_),
	fail.
'$thread_initialization'(M:D) :-
	'$initialization'(M:D).



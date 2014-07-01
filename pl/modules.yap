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
* File:		modules.pl						 *
* Last rev:								 *
* mods:									 *
* comments:	module support						 *
*									 *
*************************************************************************/
% module handling

'$module'(_,N,P) :-
	'$module_dec'(N,P).

'$module'(O,N,P,Opts) :- !,
	'$module'(O,N,P),
	'$process_module_decls_options'(Opts,module(Opts,N,P)).

	
'$process_module_decls_options'(Var,Mod) :-
	var(Var), !,
	'$do_error'(instantiation_error,Mod).
'$process_module_decls_options'([],_) :- !.
'$process_module_decls_options'([H|L],M) :- !,
	'$process_module_decls_option'(H,M),
	'$process_module_decls_options'(L,M).
'$process_module_decls_options'(T,M) :-
	'$do_error'(type_error(list,T),M).

'$process_module_decls_option'(Var,M) :- 
	var(Var), 
	'$do_error'(instantiation_error,M).
'$process_module_decls_option'(At,_) :- 
	atom(At), !,
	'$use_module'(At).
'$process_module_decls_option'(library(L),_) :- !,
	'$use_module'(library(L)).
'$process_module_decls_option'(hidden(Bool),M) :- !,
	'$process_hidden_module'(Bool, M).
'$process_module_decls_option'(Opt,M) :- 
	'$do_error'(domain_error(module_decl_options,Opt),M).

'$process_hidden_module'(TNew,M) :-
        '$convert_true_off_mod3'(TNew, New, M),
	source_mode(Old, New),
	'$prepare_restore_hidden'(Old,New).

'$convert_true_off_mod3'(true, off, _) :- !.
'$convert_true_off_mod3'(false, on, _) :- !.
'$convert_true_off_mod3'(X, _, M) :-
	'$do_error'(domain_error(module_decl_options,hidden(X)),M).

'$prepare_restore_hidden'(Old,Old) :- !.
'$prepare_restore_hidden'(Old,New) :-
	recorda('$system_initialisation', source_mode(New,Old), _).

module(N) :-
	var(N), 
	'$do_error'(instantiation_error,module(N)).
module(N) :-
	atom(N), !,
	% set it as current module.
	'$current_module'(_,N).
module(N) :-
	'$do_error'(type_error(atom,N),module(N)).

'$module_dec'(N, Ps) :-
	'$current_module'(_,N),
	source_location(F, _),
	'$add_module_on_file'(N, F, Ps).

'$add_module_on_file'(Mod, F, Exports) :-
	recorded('$module','$module'(F0,Mod,_,_),R), !,
	'$add_preexisting_module_on_file'(F, F0, Mod, Exports, R).
'$add_module_on_file'(Module, F, Exports) :-
	'$convert_for_export'(all, Exports, Module, Module, TranslationTab, AllExports0, load_files),
	'$add_to_imports'(TranslationTab, Module, Module), % insert ops, at least for now
	sort( AllExports0, AllExports ),
	( source_location(_, Line) -> true ; Line = 0 ),
	recorda('$module','$module'(F,Module,AllExports, Line),_).

'$extend_exports'(F, Exps , NewF) :-
	recorded('$module','$module'(NewF,NMod, NewExports, _),_R),
	recorded('$module','$module'(F, Module,OriginalExports,Line),R),
	'$convert_for_export'(Exps, NewExports, NMod, NMod, _TranslationTab, NewExports1, load_files),
	'$add_exports'( NewExports1, OriginalExports, Exports ),
	sort( Exports, AllExports ),
	erase(R),
	recorda('$module','$module'(F,Module,AllExports,Line),_),
	fail.
'$extend_exports'(_F, _Module, _NewExports).

'$add_exports'( [], Exports, Exports ).
'$add_exports'( [PI|NewExports], OriginalExports, [PI|Exports] ) :-
	% do not check for redefinitions, at least for now.
	'$add_exports'( NewExports, OriginalExports, Exports ).


% redefining a previously-defined file, no problem.
'$add_preexisting_module_on_file'(F, F, Mod, Exports, R) :- !,
	erase(R),
	( recorded('$import','$import'(Mod,_,_,_,_,_),R), erase(R), fail; true),
	( source_location(_, Line) -> true ; Line = 0 ),
	recorda('$module','$module'(F,Mod,Exports, Line),_).
'$add_preexisting_module_on_file'(F,F0,Mod,Exports,R) :-
	repeat,
	format(user_error, "The module ~a is being redefined.~n    Old file:  ~a~n    New file:  ~a~nDo you really want to redefine it? (y or n)",[Mod,F0,F]),
	'$mod_scan'(C), !,
	( C is "y" ->
	    '$add_preexisting_module_on_file'(F, F, Mod, Exports, R)
	 ;
	    '$do_error'(permission_error(module,redefined,Mod),module(Mod,Exports))
	).

'$mod_scan'(C) :-
	stream_property(user_input,tty(true)),
	stream_property(user_error,tty(true)),
        !,
	repeat,
	get0(C),
	'$skipeol'(C),
	(C is "y" -> true ; C is "n" -> true ; C is "h" -> true  ; C is "e" -> halt(1) ; format(user_error,  ' Please answer with ''y'', ''n'', ''e'' or ''h'' ', []), fail), !.
'$mod_scan'(C) :- C is "n".

'$module_produced by'(M, M0, N, K) :-
	recorded('$import','$import'(M,M0,_,_,N,K),_), !.
'$module_produced by'(M, M0, N, K) :-
	recorded('$import','$import'(MI,M0,G1,_,N,K),_),
	functor(G1, N1, K1),
	'$module_produced by'(M,MI,N1,K1).	


% expand module names in a clause
% A1: Input Clause
% A2: Output Class to Compiler (lives in module HM) 
% A3: Output Class to clause/2 and listing (lives in module HM)
%
% modules:
% A4: module for body of clause (this is the one used in looking up predicates)
% A5: context module (this is the current context
% A6: head module (this is the one used in compiling and accessing).
%
%
'$module_expansion'(H,H,H,_M,_HM) :- var(H), !.
'$module_expansion'((H:-B),(H:-B1),(H:-BOO),M,HM) :- !,
	'$is_mt'(M, H, B, IB, MM),
	'$module_u_vars'(H,UVars,M),	 % collect head variables in
					 % expanded positions
	'$module_expansion'(IB,B1,BO,M,MM,HM,UVars),
	('$full_clause_optimisation'(H, M, BO, BOO) ->
	  true
	  ;
	  BO = BOO
	).
% do not expand bodyless clauses.
'$module_expansion'(H,H,H,_,_).


'$trace_module'(X) :-
	telling(F),
	tell('P0:debug'),
	write(X),nl,
	tell(F), fail.
'$trace_module'(_).

'$trace_module'(X,Y) :- X==Y, !.
'$trace_module'(X,Y) :-
	telling(F),
	tell('~/.dbg.modules'),
	write('***************'), nl,
	portray_clause(X),
	portray_clause(Y),
	tell(F),fail.
'$trace_module'(_,_).

	
% expand module names in a body
% args are:
%       goals to expand
%       code to pass to listing
%       code to pass to compiler
%       current module for looking up preds  M
%       default module  DM
%       head module   HM
%
% to understand the differences, you can consider:
%
%  a:(d:b(X) :- g:c(X), d(X), user:hello(X)).
%
% when we process meta-predicate c, HM=d, DM=a, BM=a, M=g and we should get:
%
%  d:b(X) :- g:c(g:X), a:d(X), user:hello(X).
%
% on the other hand,
%
%  a:(d:b(X) :- c(X), d(X), d:e(X)).
%
% will give
%
%  d:b(X) :- a:c(a:X), a:d(X), e(X).
%
%
%       head variables.
%       goals or arguments/sub-arguments?
% I cannot use call here because of format/3
'$module_expansion'(V,NG,NG,_,MM,_,HVars) :-
	var(V), !,
	( '$not_in_vars'(V,HVars)
	->
	  NG = call(MM:V)
	;
	  NG = call(V)
	).	
'$module_expansion'((A,B),(A1,B1),(AO,BO),M,MM,HM,HVars) :- !,
	'$module_expansion'(A,A1,AO,M,MM,HM,HVars),
	'$module_expansion'(B,B1,BO,M,MM,HM,HVars).
'$module_expansion'((A;B),(A1;B1),(AO;BO),M,MM,HM,HVars) :- var(A), !,
	'$module_expansion'(A,A1,AO,M,MM,HM,HVars),
	'$module_expansion'(B,B1,BO,M,MM,HM,HVars).
'$module_expansion'((A*->B;C),(A1*->B1;C1),(yap_hacks:current_choicepoint(DCP),AO,yap_hacks:cut_at(DCP),BO; CO),M,MM,HM,HVars) :- !,
	'$module_expansion'(A,A1,AOO,M,MM,HM,HVars),
	'$clean_cuts'(AOO, AO),
	'$module_expansion'(B,B1,BO,M,MM,HM,HVars),
	'$module_expansion'(C,C1,CO,M,MM,HM,HVars).
'$module_expansion'((A;B),(A1;B1),(AO;BO),M,MM,HM,HVars) :- !,
	'$module_expansion'(A,A1,AO,M,MM,HM,HVars),
	'$module_expansion'(B,B1,BO,M,MM,HM,HVars).
'$module_expansion'((A|B),(A1|B1),(AO|BO),M,MM,HM,HVars) :- !,
	'$module_expansion'(A,A1,AO,M,MM,HM,HVars),
	'$module_expansion'(B,B1,BO,M,MM,HM,HVars).
'$module_expansion'((A->B),(A1->B1),(AO->BO),M,MM,HM,HVars) :- !,
	'$module_expansion'(A,A1,AOO,M,MM,HM,HVars),
	'$clean_cuts'(AOO, AO),
	'$module_expansion'(B,B1,BO,M,MM,HM,HVars).
'$module_expansion'(\+A,\+A1,\+AO,M,MM,HM,HVars) :- !,
	'$module_expansion'(A,A1,AO,M,MM,HM,HVars).
'$module_expansion'(not(A),not(A1),not(AO),M,MM,HM,HVars) :- !,
	'$module_expansion'(A,A1,AO,M,MM,HM,HVars).
'$module_expansion'(true,true,true,_,_,_,_) :- !.
'$module_expansion'(fail,fail,fail,_,_,_,_) :- !.
'$module_expansion'(false,false,false,_,_,_,_) :- !.
% if I don't know what the module is, I cannot do anything to the goal,
% so I just put a call for later on.
'$module_expansion'(M:G,call(M:G),'$execute_wo_mod'(G,M),_,_,_,_) :- var(M), !.
'$module_expansion'(M:G,G1,GO,_,_CM,HM,HVars) :- !,
	'$module_expansion'(G,G1,GO,M,M,HM,HVars).
'$module_expansion'(G, G1, GO, CurMod, MM, HM,HVars) :-
	% is this imported from some other module M1?
	'$imported_pred'(G, CurMod, GG, M1),
	!,
	'$module_expansion'(GG, G1, GO, M1, MM, HM,HVars).
'$module_expansion'(G, G1, GO, CurMod, MM, HM,HVars) :-
	'$meta_expansion'(G, CurMod, MM, HM, GI, HVars), !,
	'$complete_goal_expansion'(GI, CurMod, MM, HM, G1, GO, HVars).
'$module_expansion'(G, G1, GO, CurMod, MM, HM, HVars) :-
	'$complete_goal_expansion'(G, CurMod, MM, HM, G1, GO, HVars).

expand_goal(G, G) :-
	var(G), !.
expand_goal(M:G, M:NG) :-
	'$do_expand'(G, M, NG), !.
expand_goal(G, NG) :- 
	'$current_module'(Mod),
	'$do_expand'(G, Mod, NG), !.
expand_goal(G, G).
	
'$do_expand'(G, _, G) :- var(G), !.
'$do_expand'(M:G, _CurMod, M:GI) :- !,
	'$do_expand'(G, M, GI).
'$do_expand'(G, CurMod, GI) :-
	(
	 '$pred_exists'(goal_expansion(G,GI), CurMod),
	 call(CurMod:goal_expansion(G, GI))
	->
	 true
	;
	 '$pred_exists'(goal_expansion(G,GI), system),
	 system:goal_expansion(G, GI)
	->
	  true
	;
	 user:goal_expansion(G, CurMod, GI)
	->
	  true
	;
	  user:goal_expansion(G, GI)
	), !.
'$do_expand'(G, CurMod, NG) :-
	'$is_metapredicate'(G,CurMod), !,
	functor(G, Name, Arity),
	prolog:'$meta_predicate'(Name,CurMod,Arity,PredDef),
	G =.. [Name|GArgs],
	PredDef =.. [Name|GDefs],
	'$expand_args'(GArgs, CurMod, GDefs, NGArgs),
	NG =.. [Name|NGArgs].

'$expand_args'([], _, [], []).
'$expand_args'([A|GArgs], CurMod, [0|GDefs], [NA|NGArgs]) :-
	'$do_expand'(A, CurMod, NA), !,
	'$expand_args'(GArgs, CurMod, GDefs, NGArgs).
'$expand_args'([A|GArgs], CurMod, [_|GDefs], [A|NGArgs]) :-
	'$expand_args'(GArgs, CurMod, GDefs, NGArgs).

% args are:
%       goal to expand
%       current module for looking up pred
%       current module for looking up pred
%       current module from top-level clause
%       goal to pass to listing
%       goal to pass to compiler
%       head variables.
'$complete_goal_expansion'(G, CurMod, MM, HM, G1, GO, HVars) :-
%	'$pred_goal_expansion_on',
	'$do_expand'(G, CurMod, GI),
	GI \== G, !,
	'$module_expansion'(GI, G1, GO, CurMod, MM, HM, HVars).
'$complete_goal_expansion'(G, M, _CM, HM, G1, G2, _HVars) :-
	'$all_system_predicate'(G,M,ORIG), !,
	% make built-in processing transparent.
	'$match_mod'(G, M, ORIG, HM, G1),
	'$c_built_in'(G1, M, Gi),
	Gi = G2.
'$complete_goal_expansion'(G, GMod, _, HM, NG, NG, _) :-
	'$match_mod'(G, GMod, GMod, HM, NG).

%'$match_mod'(G, GMod, GMod, NG) :- !,
%	NG = G.
'$match_mod'(G, _, SM, _, G) :- SM == prolog, nonvar(G), \+ '$is_multifile'(G,SM), !. % prolog: needs no module info.
% same module as head,  and body goal (I cannot get rid of qualifier before
% meta-call.
'$match_mod'(G, HMod, _, HM, G) :- HMod == HM, !.
'$match_mod'(G, GMod, _, _,  GMod:G).


% be careful here not to generate an undefined exception.
'$imported_pred'(G, ImportingMod, G0, ExportingMod) :-
	'$enter_undefp',
	'$undefined'(G, ImportingMod),
	'$get_undefined_pred'(G, ImportingMod, G0, ExportingMod),
	ExportingMod \= ImportingMod, !,
	'$exit_undefp'.
'$imported_pred'(_G, _ImportingMod, _, _) :-
	'$exit_undefp',
	fail.

'$get_undefined_pred'(G, ImportingMod, G0, ExportingMod) :-
	recorded('$import','$import'(ExportingModI,ImportingMod,G0I,G,_,_),_),
	'$continue_imported'(ExportingMod, ExportingModI, G0, G0I), !.
% SWI builtin
'$get_undefined_pred'(G, _ImportingMod, G0, ExportingMod) :-
	recorded('$dialect',Dialect,_),
	Dialect \= yap,
	functor(G, Name, Arity),
	call(Dialect:index(Name,Arity,ExportingModI,_)), !,
	'$continue_imported'(ExportingMod, ExportingModI, G0, G), !.
'$get_undefined_pred'(G, _ImportingMod, G0, ExportingMod) :-
	yap_flag(autoload, V),
	V = true,
	'$autoloader_find_predicate'(G,ExportingModI), !,
	'$continue_imported'(ExportingMod, ExportingModI, G0, G).
'$get_undefined_pred'(G, ImportingMod, G0, ExportingMod) :-
	prolog:'$parent_module'(ImportingMod,ExportingModI),
	'$continue_imported'(ExportingMod, ExportingModI, G0, G).


'$autoloader_find_predicate'(G,ExportingModI) :-
	'$nb_getval'('$autoloader_set', true, fail), !,
	autoloader:find_predicate(G,ExportingModI).
'$autoloader_find_predicate'(G,ExportingModI) :-
	'$exit_undefp',
	yap_flag(autoload, false), 
	load_files([library(autoloader),
		    autoloader:library('INDEX'),
		    swi:library('dialect/swi/INDEX')],
		   [autoload(true),if(not_loaded)]),
	nb_setval('$autoloader_set', true),
	yap_flag(autoload, true), 
	'$enter_undefp',
	autoloader:find_predicate(G,ExportingModI).


'$continue_imported'(Mod,Mod,Pred,Pred) :-
	\+ '$undefined'(Pred, Mod), !.
'$continue_imported'(FM,Mod,FPred,Pred) :-
	recorded('$import','$import'(IM,Mod,IPred,Pred,_,_),_), !,
	'$continue_imported'(FM, IM, FPred, IPred).
'$continue_imported'(FM,Mod,FPred,Pred) :-
	prolog:'$parent_module'(Mod,IM),
	'$continue_imported'(FM, IM, FPred, Pred).


% module_transparent declaration
% 

:- dynamic('$module_transparent'/4).

'$module_transparent'((P,Ps), M) :- !, 
	'$module_transparent'(P, M),
	'$module_transparent'(Ps, M).
'$module_transparent'(M:D, _) :- !,
	'$module_transparent'(D, M).
'$module_transparent'(F/N, M) :-
	'$module_transparent'(F,M,N,_), !.
'$module_transparent'(F/N, M) :-
	functor(P,F,N),
	asserta(prolog:'$module_transparent'(F,M,N,P)),
	'$flags'(P, M, Fl, Fl),
	NFlags is Fl \/ 0x200004,
	'$flags'(P, M, Fl, NFlags).

'$is_mt'(M, H, B, (context_module(CM),B), CM) :-
	'$module_transparent'(_, M, _, H), !.
'$is_mt'(M, _, B, B, M).

% meta_predicate declaration
% records $meta_predicate(SourceModule,Functor,Arity,Declaration)

% directive now meta_predicate Ps :- $meta_predicate(Ps).

:- dynamic('$meta_predicate'/4).

:- multifile '$meta_predicate'/4.

'$meta_predicate'(P, M) :-
	var(P),
	'$do_error'(instantiation_error,module(M)).
'$meta_predicate'((P,Ps), M) :- !, 
	'$meta_predicate'(P, M),
	'$meta_predicate'(Ps, M).
'$meta_predicate'(M:D, _) :- !,
	'$meta_predicate'(D, M).
'$meta_predicate'(P, M1) :-
	'$install_meta_predicate'(P, M1).


'$install_meta_predicate'(P, M1) :-
	functor(P,F,N),
	( M1 = prolog -> M = _ ; M1 = M),
	( retractall(prolog:'$meta_predicate'(F,M,N,_)), fail ; true),
	asserta(prolog:'$meta_predicate'(F,M,N,P)),
	'$flags'(P, M1, Fl, Fl),
	NFlags is Fl \/ 0x200000,
	'$flags'(P, M1, Fl, NFlags).

% return list of vars in expanded positions on the head of a clause.
%
% these variables should not be expanded by meta-calls in the body of the goal.
%
'$module_u_vars'(H,UVars,M) :-
	functor(H,F,N),
	'$meta_predicate'(F,M,N,D), !,
	'$module_u_vars'(N,D,H,UVars).
'$module_u_vars'(_,[],_).

'$module_u_vars'(0,_,_,[]) :- !.
'$module_u_vars'(I,D,H,LF) :-
	arg(I,D,X), ( X=':' ; integer(X)),
	arg(I,H,A), '$uvar'(A, LF, L), !,
	I1 is I-1,
	'$module_u_vars'(I1,D,H,L).
'$module_u_vars'(I,D,H,L) :-
	I1 is I-1,
	'$module_u_vars'(I1,D,H,L).

'$uvar'(Y, [Y|L], L)  :- var(Y), !.
% support all/3
'$uvar'(same( G, _), LF, L)  :-
    '$uvar'(G, LF, L).
'$uvar'('^'( _, G), LF, L)  :-
    '$uvar'(G, LF, L).

% expand arguments of a meta-predicate
% $meta_expansion(ModuleWhereDefined,CurrentModule,Goal,ExpandedGoal,MetaVariables)

'$meta_expansion0'(G,_Mod,MP,_HM, G1,_HVars) :-
    var(G), !,
    G1 = call(MP:G).
'$meta_expansion0'(M:G,_Mod,_MP,_HM,G1,_HVars) :-
    var(M), !,
    G1 = '$execute_wo_mod'(G,M).
% support for all/3
'$meta_expansion0'(same(G, P),Mod,MP,HM, same(G1, P),HVars) :- !,
    '$meta_expansion0'(G,Mod,MP,HM,G1,HVars).
'$meta_expansion0'(G,Mod,MP,HM,M2:G2,HVars) :-
    nonvar(G), G \= _:_,
    '$module_expansion'(G,_,G1,MP,MP,HM,HVars), !,
    strip_module(MP:G1, M2, G2).
'$meta_expansion0'(G,Mod,MP,HM,M1:G1,HVars) :-
    strip_module(MP:G,M1,G1).


'$meta_expansion'(G,Mod,MP,HM,G1,HVars) :-
	functor(G,F,N),
	'$meta_predicate'(F,Mod,N,D), !, % we're in an argument
%	format(user_error,'[ ~w ',[G]),
	functor(G1,F,N),
	'$meta_expansion_loop'(N, D, G, G1, HVars, Mod, MP, HM).
%	format(user_error,' gives ~w]`n',[G1]).

% expand argument
'$meta_expansion_loop'(0,_,_,_,_,_,_,_) :- !.
'$meta_expansion_loop'(I,D,G,NG,HVars,CurMod,M,HM) :- 
	arg(I,D,X), (X==':' -> true ; integer(X)),
	arg(I,G,A), 
	'$should_expand'(A,HVars),
	!,
	( X ==0 ->
	  '$values'('$c_arith',Old, false),
	  '$meta_expansion0'(A,CurMod,M,HM,NA,HVars),
	  '$values'('$c_arith', _False, Old)
	  ;
	      NA = M:A
	),
	arg(I,NG,NA),
	I1 is I-1,
	'$meta_expansion_loop'(I1, D, G, NG, HVars, CurMod, M, HM).
'$meta_expansion_loop'(I, D, G, NG, HVars, CurMod, M, HM) :- 
	arg(I,G,A),
	arg(I,NG,A),
	I1 is I-1,
	'$meta_expansion_loop'(I1, D, G, NG, HVars, CurMod, M, HM).

% check if an argument should be expanded
'$should_expand'(V,HVars) :- var(V), !, '$not_in_vars'(V,HVars).
'$should_expand'(_:_,_) :- !, fail.
'$should_expand'(_,_).

'$not_in_vars'(_,[]).
'$not_in_vars'(V,[X|L]) :- X\==V, '$not_in_vars'(V,L).

current_module(Mod) :-
	'$all_current_modules'(Mod),
	\+ '$system_module'(Mod).

current_module(Mod,TFN) :-
	'$all_current_modules'(Mod),
	( recorded('$module','$module'(TFN,Mod,_Publics, _),_) -> true ; TFN = user ).

source_module(Mod) :-
	'$current_module'(Mod).

% comma has its own problems.
:- '$install_meta_predicate'((0,0), prolog).

:- meta_predicate
	abolish(:),
	abolish(:,+),
	all(?,0,-),
	assert(:),
	assert(:,+),
	assert_static(:),
	asserta(:),
	asserta(:,+),
	asserta_static(:),
	assertz(:),
	assertz(:,+),
	assertz_static(:),
	at_halt(0),
	bagof(?,0,-),
	bb_get(:,-),
	bb_put(:,+),
	bb_delete(:,?),
	bb_update(:,?,?),
	call(0),
	call(1,?),
	call(2,?,?),
	call(3,?,?,?),
	call_with_args(0),
	call_with_args(1,?),
	call_with_args(2,?,?),
	call_with_args(3,?,?,?),
	call_with_args(4,?,?,?,?),
	call_with_args(5,?,?,?,?,?),
	call_with_args(6,?,?,?,?,?,?),
	call_with_args(7,?,?,?,?,?,?,?),
	call_with_args(8,?,?,?,?,?,?,?,?),
	call_with_args(9,?,?,?,?,?,?,?,?,?),
	call_cleanup(0,0),
	call_cleanup(0,?,0),
	call_residue(0,?),
	call_residue_vars(0,?),
	call_shared_object_function(:,+),
	catch(0,?,0),
	clause(:,?),
	clause(:,?,?),
	compile(:),
	consult(:),
	current_predicate(:),
	current_predicate(?,:),
	db_files(:),
	depth_bound_call(0,+),
	discontiguous(:),
	ensure_loaded(:),
	exo_files(:),
	findall(?,0,-),
	findall(?,0,-,?),
	forall(0,0),
	format(+,:),
	format(+,+,:),
	freeze(?,0),
	hide_predicate(:),
	if(0,0,0),
	ignore(0),
	incore(0),
	listing(:),
	multifile(:),
	nospy(:),
        not(0),
        notrace(0),
        once(0),
        phrase(2,?),
        phrase(2,?,+),
	predicate_property(:,?),
	predicate_statistics(:,-,-,-),
	on_exception(+,0,0),
	qsave_program(+,:),
	reconsult(:),
	retract(:),
	retract(:,?),
	retractall(:),
	reconsult(:),
	setof(?,0,-),
	setup_call_cleanup(0,0,0),
	setup_call_catcher_cleanup(0,0,?,0),
	spy(:),
	stash_predicate(:),
	unknown(+,:),
	use_module(:),
	use_module(:,?),
	use_module(?,:,?),
	when(+,0),
	with_mutex(+,0),
	with_output_to(?,0),
	(0 -> 0),
	(0 *-> 0),
	(0 ; 0),
	^(+,0),
	{}(0,?,?),
	','(2,2,?,?),
	;(2,2,?,?),
	'|'(2,2,?,?),
	->(2,2,?,?),
	\+(2,?,?),
	\+ 0 .

%
% get rid of a module and of all predicates included in the module.
%
abolish_module(Mod) :-
	recorded('$module','$module'(_,Mod,_,_),R), erase(R),
	fail.
abolish_module(Mod) :-
	recorded('$import','$import'(Mod,_,_,_,_,_),R), erase(R),
	fail.
abolish_module(Mod) :-
	'$current_predicate'(Mod,Na,Ar),
	abolish(Mod:Na/Ar),
	fail.
abolish_module(_).

export(Resource) :-
	var(Resource),
	'$do_error'(instantiation_error,export(Resource)).	
export([]) :- !.
export([Resource| Resources]) :- !,
	export_resource(Resource),
	export(Resources).
export(Resource) :-
	export_resource(Resource).

export_resource(Resource) :-
	var(Resource),
	'$do_error'(instantiation_error,export(Resource)).	
export_resource(P) :-
	P = F/N, atom(F), number(N), N >= 0, !,
	'$current_module'(Mod), 
	(	recorded('$module','$module'(File,Mod,ExportedPreds,Line),R) ->
		erase(R), 
		recorda('$module','$module'(File,Mod,[P|ExportedPreds],Line),_)
	;	prolog_load_context(file, File) ->
		recorda('$module','$module'(File,Mod,[P],Line),_)
	;	recorda('$module','$module'(user_input,Mod,[P],1),_)
	).
export_resource(P0) :-
	P0 = F//N, atom(F), number(N), N >= 0, !,
	N1 is N+2, P = F/N1,
	'$current_module'(Mod), 
	(	recorded('$module','$module'(File,Mod,ExportedPreds,Line),R) ->
		erase(R), 
		recorda('$module','$module'(File,Mod,[P|ExportedPreds],Line ),_)
	;	prolog_load_context(file, File) ->
		recorda('$module','$module'(File,Mod,[P],Line),_)
	;	recorda('$module','$module'(user_input,Mod,[P],1),_)
	).
export_resource(op(Prio,Assoc,Name)) :- !,
	op(Prio,Assoc,prolog:Name).
export_resource(Resource) :-
	'$do_error'(type_error(predicate_indicator,Resource),export(Resource)).
	
export_list(Module, List) :-
	recorded('$module','$module'(_,Module,List,_),_).

'$convert_for_export'(all, Exports, _Module, _ContextModule, Tab, MyExports, _) :-
	'$simple_conversion'(Exports, Tab, MyExports).
'$convert_for_export'([], Exports, Module, ContextModule, Tab, MyExports, Goal) :-
	'$clean_conversion'([], Exports, Module, ContextModule, Tab, MyExports, Goal).
'$convert_for_export'([P1|Ps], Exports, Module, ContextModule, Tab, MyExports, Goal) :-
	'$clean_conversion'([P1|Ps], Exports, Module, ContextModule, Tab, MyExports, Goal).
'$convert_for_export'(except(Excepts), Exports, Module, ContextModule, Tab, MyExports, Goal) :-
	'$neg_conversion'(Excepts, Exports, Module, ContextModule, MyExports, Goal),
	'$simple_conversion'(MyExports, Tab, _).

'$simple_conversion'([], [], []).
'$simple_conversion'([F/N|Exports], [F/N-F/N|Tab], [F/N|E]) :-
	'$simple_conversion'(Exports, Tab, E).
'$simple_conversion'([F//N|Exports], [F/N2-F/N2|Tab], [F/N2|E]) :-
	N2 is N+1,
	'$simple_conversion'(Exports, Tab, E).
'$simple_conversion'([F/N as NF|Exports], [F/N-NF/N|Tab], [NF/N|E]) :-
	'$simple_conversion'(Exports, Tab, E).
'$simple_conversion'([F//N as BF|Exports], [F/N2-NF/N2|Tab], [NF/N2|E]) :-
	N2 is N+1,
	'$simple_conversion'(Exports, Tab, E).
'$simple_conversion'([op(Prio,Assoc,Name)|Exports], [op(Prio,Assoc,Name)|Tab], [op(Prio,Assoc,Name)|E]) :-
	'$simple_conversion'(Exports, Tab, E).

'$clean_conversion'([], _, _, _, [], [], _).
'$clean_conversion'([(N1/A1 as N2)|Ps], List, Module, ContextModule, [N1/A1-N2/A1|Tab], [N2/A1|MyExports], Goal) :- !,
	( lists:memberchk(N1/A1, List)
	->
	  true
	;
	  '$bad_export'((N1/A1 as A2), Module, ContextModule)
	),
	'$clean_conversion'(Ps, List, Module, ContextModule, Tab, MyExports, Goal).	
'$clean_conversion'([N1/A1|Ps], List, Module, ContextModule, [N1/A1-N1/A1|Tab], [N1/A1|MyExports], Goal) :- !,
	(
	 lists:memberchk(N1/A1, List)
	->
	   true
	;
	  '$bad_export'(N1/A1, Module, ContextModule)
	),
	'$clean_conversion'(Ps, List, Module, ContextModule, Tab, MyExports, Goal).
'$clean_conversion'([N1//A1|Ps], List, Module, ContextModule, [N1/A2-N1/A2|Tab], [N1/A2|MyExports], Goal) :- !,
	A2 is A1+2,
	(
	  lists:memberchk(N1/A2, List)
	->
	  true
	;
	  '$bad_export'(N1//A1, Module, ContextModule)

	),
	'$clean_conversion'(Ps, List, Module, ContextModule, Tab, MyExports, Goal).
'$clean_conversion'([N1//A1 as N2|Ps], List, Module, ContextModule, [N2/A2-N1/A2|Tab], [N2/A2|MyExports], Goal) :- !,
	A2 is A1+2,
	(
	  lists:memberchk(N2/A2, List)
	->
	  true
	;
	  '$bad_export'((N1//A1 as A2), Module, ContextModule)
	),
	'$clean_conversion'(Ps, List, Module, ContextModule, Tab, MyExports, Goal).
'$clean_conversion'([op(Prio,Assoc,Name)|Ps], List, Module, ContextModule, [op(Prio,Assoc,Name)|Tab], [op(Prio,Assoc,Name)|MyExports], Goal) :- !,
	(
	 lists:memberchk(op(Prio,Assoc,Name), List)
	->
	 true
	;
	 '$bad_export'(op(Prio,Assoc,Name), Module, ContextModule)
	),
	'$clean_conversion'(Ps, List, Module, ContextModule, Tab, MyExports, Goal).
'$clean_conversion'([P|_], _List, _, _, _, _, Goal) :-
	'$do_error'(domain_error(module_export_predicates,P), Goal).

'$bad_export'(_, _Module, _ContextModule) :- !.
'$bad_export'(Name/Arity, Module, ContextModule) :-
	functor(P, Name, Arity),
	predicate_property(Module:P, _), !,
	print_message(warning, declaration(Name/Arity, Module, ContextModule, private)).
'$bad_export'(Name//Arity, Module, ContextModule) :-
	Arity2 is Arity+2,
	functor(P, Name, Arity2),
	predicate_property(Module:P, _), !,
	print_message(warning, declaration(Name/Arity, Module, ContextModule, private)).
'$bad_export'(Indicator, Module, ContextModule) :- !,
	print_message(warning, declaration( Indicator, Module, ContextModule, undefined)).

'$neg_conversion'([], Exports, _, _, Exports, _).
'$neg_conversion'([N1/A1|Ps], List, Module, ContextModule, MyExports, Goal) :- !,
	(
	 lists:delete(List, N1/A1, RList)
	->
	 '$neg_conversion'(Ps, RList, Module, ContextModule, MyExports, Goal)
	;
	 '$bad_export'(N1/A1, Module, ContextModule)
	).
'$neg_conversion'([N1//A1|Ps], List, Module, ContextModule, MyExports, Goal) :- !,
	A2 is A1+2,
	(
	 lists:delete(List, N1/A2, RList)
	->
	 '$neg_conversion'(Ps, RList, Module, ContextModule, MyExports, Goal)
	;
	 '$bad_export'(N1//A1, Module, ContextModule)
	).
'$neg_conversion'([op(Prio,Assoc,Name)|Ps], List, Module, ContextModule, MyExports, Goal) :- !,
	(
	 lists:delete(List, op(Prio,Assoc,Name), RList)
	->
	 '$neg_conversion'(Ps, RList, Module, ContextModule, MyExports, Goal)
	;
	 '$bad_export'(op(Prio,Assoc,Name), Module, ContextModule)
	).
'$clean_conversion'([P|_], _List, _, _, _, Goal) :-
	'$do_error'(domain_error(module_export_predicates,P), Goal).

	
'$add_to_imports'([], _, _).
% no need to import from the actual module
'$add_to_imports'([T|Tab], Module, ContextModule) :- 
	'$do_import'(T, Module, ContextModule),
	'$add_to_imports'(Tab, Module, ContextModule).

'$do_import'(op(Prio,Assoc,Name), _Mod, ContextMod) :-
	op(Prio,Assoc,ContextMod:Name).
'$do_import'(N0/K0-N0/K0, Mod, Mod) :- !.
'$do_import'(_N/K-N1/K, _Mod, ContextMod) :-
       recorded('$module','$module'(_F, ContextMod, MyExports,_),_),
       once(lists:member(N1/K, MyExports)),
       functor(S, N1, K),
       %  reexport predicates if they are undefined in the current module.
       \+ '$undefined'(S,ContextMod), !.
'$do_import'( N/K-N1/K, Mod, ContextMod) :-
	functor(G,N,K),
	'$follow_import_chain'(Mod,G,M0,G0),
	G0=..[N0|Args],
	G1=..[N1|Args],
	( '$check_import'(M0,ContextMod,N1,K) ->
	  ( ContextMod = user ->
	    ( recordzifnot('$import','$import'(M0,user,G0,G1,N1,K),_) -> true ; true)
	  ;
	    ( recordaifnot('$import','$import'(M0,ContextMod,G0,G1,N1,K),_) -> true ; true )
	  )
	;
	  true
	).

'$follow_import_chain'(M,G,M0,G0) :-
	recorded('$import','$import'(M1,M,G1,G,_,_),_), M \= M1, !,
	'$follow_import_chain'(M1,G1,M0,G0).
'$follow_import_chain'(M,G,M,G).

% trying to import Mod:N/K into ContextM
'$check_import'(Mod, ContextM, N, K) :-
	recorded('$import','$import'(MI, ContextM, _, _, N,K),_R),
	% dereference MI to M1, in order to find who 
	% is actually generating
	( '$module_produced by'(M1, MI,  N, K) -> true ; MI = M1 ),
	( '$module_produced by'(M2, Mod, N, K) -> true ;  M = M2 ),
	M2 \= M1,  !,
	b_getval('$lf_status', TOpts),
	'$lf_opt'(redefine_module, TOpts, Action),
	'$redefine_action'(Action, M1, M2, M, N/K).
'$check_import'(_,_,_,_).

'$redefine_action'(ask, M1, M2, M, N/K) :-
	stream_property(user_input,tty(true)), !,
	format(user_error,'NAME CLASH: ~w was already imported to module ~w;~n',[M1:N/K,M2]),
	format(user_error,'            Do you want to import it from ~w ? [y, n, e or h] ',M),
	'$mod_scan'(C),
	( C =:= 0'e -> halt(1) ;
	  C =:= 0'y ).  
'$redefine_action'(true, M1, _, _, _) :- !,
	recorded('$module','$module'(F, M1, _MyExports,_Line),_),
	unload_file(F).
'$redefine_action'(false, M1,M2, M, N/K) :-
	'$do_error'(permission_error(import,M1:N/K,redefined,M2),module(M)).

% I assume the clause has been processed, so the
% var case is long gone! Yes :)
'$clean_cuts'(G,(yap_hacks:current_choicepoint(DCP),NG)) :-
	'$conj_has_cuts'(G,DCP,NG,OK), OK == ok, !.
'$clean_cuts'(G,G).

'$conj_has_cuts'(V,_,V, _) :- var(V), !.
'$conj_has_cuts'(!,DCP,'$$cut_by'(DCP), ok) :- !. 
'$conj_has_cuts'((G1,G2),DCP,(NG1,NG2), OK) :- !,
	'$conj_has_cuts'(G1, DCP, NG1, OK),
	'$conj_has_cuts'(G2, DCP, NG2, OK).
'$conj_has_cuts'((G1;G2),DCP,(NG1;NG2), OK) :- !,
	'$conj_has_cuts'(G1, DCP, NG1, OK),
	'$conj_has_cuts'(G2, DCP, NG2, OK).
'$conj_has_cuts'((G1->G2),DCP,(G1;NG2), OK) :- !,
	% G1: the system must have done it already
	'$conj_has_cuts'(G2, DCP, NG2, OK).
'$conj_has_cuts'((G1*->G2),DCP,(G1;NG2), OK) :- !,
	% G1: the system must have done it already
	'$conj_has_cuts'(G2, DCP, NG2, OK).
'$conj_has_cuts'(if(G1,G2,G3),DCP,if(G1,NG2,NG3), OK) :- !,
	% G1: the system must have done it already
	'$conj_has_cuts'(G2, DCP, NG2, OK),
	'$conj_has_cuts'(G3, DCP, NG3, OK).
'$conj_has_cuts'(G,_,G, _).

set_base_module(ExportingModule) :-
	var(ExportingModule),
	'$do_error'(instantiation_error,set_base_module(ExportingModule)).
set_base_module(ExportingModule) :-
	atom(ExportingModule), !,
	'$current_module'(Mod),
	retractall(prolg:'$parent_module'(Mod,_)),
	asserta(prolog:'$parent_module'(Mod,ExportingModule)).
set_base_module(ExportingModule) :-
	'$do_error'(type_error(atom,ExportingModule),set_base_module(ExportingModule)).

import_module(Mod, ImportModule) :-
	var(Mod),
	'$do_error'(instantiation_error,import_module(Mod, ImportModule)).
import_module(Mod, ImportModule) :-
	atom(Mod), !,
	prolog:'$parent_module'(Mod,ImportModule).
import_module(Mod, EM) :-
	'$do_error'(type_error(atom,Mod),import_module(Mod, EM)).

add_import_module(Mod, ImportModule, Pos) :-
	var(Mod),
	'$do_error'(instantiation_error,add_import_module(Mod, ImportModule, Pos)).
add_import_module(Mod, ImportModule, Pos) :-
	var(Pos),
	'$do_error'(instantiation_error,add_import_module(Mod, ImportModule, Pos)).
add_import_module(Mod, ImportModule, start) :-
	atom(Mod), !,
	retractall(prolog:'$parent_module'(Mod,ImportModule)),
	asserta(prolog:'$parent_module'(Mod,ImportModule)).
add_import_module(Mod, ImportModule, end) :-
	atom(Mod), !,
	retractall(prolog:'$parent_module'(Mod,ImportModule)),
	assertz(prolog:'$parent_module'(Mod,ImportModule)).
add_import_module(Mod, ImportModule, Pos) :-
	\+ atom(Mod), !,
	'$do_error'(type_error(atom,Mod),add_import_module(Mod, ImportModule, Pos)).
add_import_module(Mod, ImportModule, Pos) :-
	'$do_error'(domain_error(start_end,Pos),add_import_module(Mod, ImportModule, Pos)).

delete_import_module(Mod, ImportModule) :-
	var(Mod),
	'$do_error'(instantiation_error,delete_import_module(Mod, ImportModule)).
delete_import_module(Mod, ImportModule) :-
	var(ImportModule),
	'$do_error'(instantiation_error,delete_import_module(Mod, ImportModule)).
delete_import_module(Mod, ImportModule) :-
	atom(Mod),
	atom(ImportModule), !,
	retractall(prolog:'$parent_module'(Mod,ImportModule)).
delete_import_module(Mod, ImportModule) :-
	\+ atom(Mod), !,
	'$do_error'(type_error(atom,Mod),delete_import_module(Mod, ImportModule)).
delete_import_module(Mod, ImportModule) :-
	'$do_error'(type_error(atom,ImportModule),delete_import_module(Mod, ImportModule)).

'$set_source_module'(Source0, SourceF) :-
	prolog_load_context(module, Source0), !,
	module(SourceF).
'$set_source_module'(Source0, SourceF) :-
	current_module(Source0, SourceF).

/** '$declare_module'(+Module, +Super, +File, +Line, +Redefine) is det.

Start a new (source-)module

@param	Module is the name of the module to declare
@param	File is the canonical name of the file from which the module
	is loaded
@param  Line is the line-number of the :- module/2 directive.
@param	Redefine If =true=, allow associating the module to a new file
*/
'$declare_module'(Name, _Test, Context, _File, _Line) :-
	add_import_module(Name, Context, start).

module_property(Mod, line_count(L)) :-
	recorded('$module','$module'(_F,Mod,_,L),_).
module_property(Mod, file(F)) :-
	recorded('$module','$module'(F,Mod,_,_),_).
module_property(Mod, exports(Es)) :-
	recorded('$module','$module'(_,Mod,Es,_),_).

ls_imports :-
	recorded('$import','$import'(M0,M,G0,G,_N,_K),_R),
	numbervars(G0+G, 0, _),
	format('~a:~w <- ~a:~w~n', [M, G, M0, G0]),
	fail.
ls_imports.



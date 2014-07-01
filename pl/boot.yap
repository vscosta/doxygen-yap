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
* File:		boot.yap						 *
* Last rev:	8/2/88							 *
* mods:									 *
* comments:	boot file for Prolog					 *
*									 *
*************************************************************************/

%
%
%
true :- true.

'$live' :-
	'$init_system',
        '$do_live'.

'$init_prolog' :-
    '$init_system'.

'$do_live' :-
    repeat,
    '$current_module'(Module),
    ( Module==user ->
      '$compile_mode'(_,0)
    ;
      format(user_error,'[~w]~n', [Module])
    ),
    '$system_catch'('$enter_top_level',Module,Error,user:'$Error'(Error)).


'$init_system' :-
    get_value('$yap_inited', true), !.
'$init_system' :-
    set_value('$yap_inited', true),
    % do catch as early as possible
    (
     '$access_yap_flags'(15, 0),
     '$access_yap_flags'(22, 0),
     \+ '$uncaught_throw'
    ->
     '$version'
    ;
     true
    ),
    (
     '$access_yap_flags'(22, 0) ->
	'$swi_set_prolog_flag'(verbose,  normal)
    ;
	'$swi_set_prolog_flag'(verbose,  silent)
    ),
%	'$init_preds', % needs to be done before library_directory
%	(
%	 retractall(user:library_directory(_)),
%	 '$system_library_directories'(D),
%	 assertz(user:library_directory(D)),
%	 fail
%	;
%	 true
%	),
    '$swi_current_prolog_flag'(file_name_variables, OldF),
    '$swi_set_prolog_flag'(file_name_variables, true),
    '$init_consult',
    '$swi_set_prolog_flag'(file_name_variables, OldF),
    '$init_win_graphics',
    '$init_globals',
    '$swi_set_prolog_flag'(fileerrors, true),
    set_value('$gc',on),
    ('$exit_undefp' -> true ; true),
    prompt1(' ?- '),
    '$swi_set_prolog_flag'(debug, false),
	% simple trick to find out if this is we are booting from Prolog.
	% boot from a saved state
	(
	  '$undefined'('$init_preds',prolog)
	 ->
	  true
	 ;
	 '$init_state'
        ),
	'$db_clean_queues'(0),
% this must be executed from C-code.
%	'$startup_saved_state',
	set_input(user_input),
	set_output(user_output),
	'$init_or_threads',
	'$run_at_thread_start'.

'$init_globals' :-
	% '$swi_set_prolog_flag'(break_level, 0),
	% '$set_read_error_handler'(error), let the user do that 
	nb_setval('$chr_toplevel_show_store',false).

'$init_consult' :-
	set_value('$open_expands_filename',true),
	nb_setval('$assert_all',off),
	nb_setval('$if_level',0),
	nb_setval('$endif',off),
 	nb_setval('$initialization_goals',off),
	nb_setval('$included_file',[]),
	\+ '$undefined'('$init_preds',prolog),
	'$init_preds',
	fail.
'$init_consult' :-
	retractall(user:library_directory(_)),
	'$system_library_directories'(library, D),
	assert(user:library_directory(D)),
	fail.
'$init_consult' :-
	retractall(user:commons_directory(_)),
	'$system_library_directories'(commons, D),
	assert(user:commons_directory(D)),
	fail.
'$init_consult'.

'$init_win_graphics' :-
    '$undefined'(window_title(_,_), system), !.
'$init_win_graphics' :-
    load_files([library(win_menu)], [silent(true),if(not_loaded)]),
    fail.
'$init_win_graphics'.

'$init_or_threads' :-
	'$c_yapor_workers'(W), !,
	'$start_orp_threads'(W).
'$init_or_threads'.

'$start_orp_threads'(1) :- !.
'$start_orp_threads'(W) :-
	thread_create('$c_worker',_,[detached(true)]),
	W1 is W-1,
	'$start_orp_threads'(W1).


% Start file for yap

/*		I/O predicates						*/

/* meaning of flags for '$write' is
	  1	quote illegal atoms
	  2	ignore operator declarations
	  4	output '$VAR'(N) terms as A, B, C, ...
	  8	use portray(_)
*/

/* main execution loop							*/
'$read_toplevel'(Goal, Bindings) :-
	'$pred_exists'(read_history(_,_,_,_,_,_), user),
	'$swi_current_prolog_flag'(readline, true), !,
	read_history(h, '!h',
                         [trace, end_of_file],
                         Prompt, Goal, Bindings), !,
	(nonvar(Err) ->
	 print_message(error,Err), fail
	;
	 true
	).
'$read_toplevel'(Goal, Bindings) :-
	prompt1('?- '),
	prompt(_,'|: '),
	'$system_catch'('$raw_read'(user_input, Line), prolog, E,
			(print_message(error, E),
	                 '$handle_toplevel_error'(Line, E))),
	(   
	    '$pred_exists'(rl_add_history(_), user)
	-> 
	    format(atom(CompleteLine), '~W~W',
		   [ Line, [partial(true)],
		     '.', [partial(true)]
		   ]),
	    user:rl_add_history(CompleteLine)
	;   
	    true
	),
	'$system_catch'(
			atom_to_term(Line, Goal, Bindings), prolog, E,
			(   print_message(error, E),
			    fail
			)
		       ), !.

'$handle_toplevel_error'(_, syntax_error(_)) :- !, fail.
'$handle_toplevel_error'(end_of_file, error(io_error(read,user_input),_)) :- !.
'$handle_toplevel_error'(_, E) :-
	throw(E).

% reset alarms when entering top-level.
'$enter_top_level' :-
	'$alarm'(0, 0, _, _),
	fail.
'$enter_top_level' :-
	'$clean_up_dead_clauses',
	fail.
'$enter_top_level' :-
	'$swi_current_prolog_flag'(break_level, BreakLevel),
        '$swi_current_prolog_flag'(debug, DBON),
	(
	 '$nb_getval'('$trace', on, fail)
	->
	 TraceDebug = trace
	;
	 DBON == true
	->
	 TraceDebug = debug
	;
	 true
	),
	print_message(informational,prompt(BreakLevel,TraceDebug)),
	fail.
'$enter_top_level' :-
	get_value('$top_level_goal',GA), GA \= [], !,
	set_value('$top_level_goal',[]),
	'$run_atom_goal'(GA),
	'$swi_current_prolog_flag'(break_level, BreakLevel),
	( Breaklevel \= 0 -> true ; '$pred_exists'(halt(_), user) -> halt(0) ; '$halt'(0) ).
'$enter_top_level' :-
        flush_output,
	'$run_toplevel_hooks',
	prompt1(' ?- '),
	'$read_toplevel'(Command,Varnames),
	nb_setval('$spy_gn',1),
	% stop at spy-points if debugging is on.
	nb_setval('$debug_run',off),
	nb_setval('$debug_jump',off),
	'$command'(Command,Varnames,_Pos,top),
	'$swi_current_prolog_flag'(break_level, BreakLevel),
	( BreakLevel \= 0 -> true ; '$pred_exists'(halt(_), user) -> halt(0) ; '$halt'(0) ).


 '$erase_sets' :- 
		 eraseall('$'),
		 eraseall('$$set'),
		 eraseall('$$one'), 
		 eraseall('$reconsulted'), fail.
 '$erase_sets' :- \+ recorded('$path',_,_), recorda('$path',"",_).
 '$erase_sets'.

 '$version' :- 
	 get_value('$version_name',VersionName),
	 print_message(help, version(VersionName)),
	 get_value('$myddas_version_name',MYDDASVersionName),
	 MYDDASVersionName \== [],
	 print_message(help, myddas_version(MYDDASVersionName)),
	 fail.
 '$version' :-
	 recorded('$version',VersionName,_),
	 print_message(help, VersionName),
	 fail.
 '$version'.

 repeat :- '$repeat'.

 '$repeat'.
 '$repeat'.
 '$repeat'.
 '$repeat'.
 '$repeat'.
 '$repeat'.
 '$repeat'.
 '$repeat'.
 '$repeat'.
 '$repeat' :- '$repeat'.

'$start_corouts' :-
	recorded('$corout','$corout'(Name,_,_),R),
	Name \= main,
	finish_corout(R),
	fail.
'$start_corouts' :- 
	eraseall('$corout'),
	eraseall('$result'),
	eraseall('$actual'),
	fail.
'$start_corouts' :- recorda('$actual',main,_),
	recordz('$corout','$corout'(main,main,'$corout'([],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[])),_Ref),
	recorda('$result',going,_).

'$command'(C,VL,Pos,Con) :-
	'$access_yap_flags'(9,1), !,
	 '$execute_command'(C,VL,Pos,Con,C).
'$command'(C,VL,Pos,Con) :-
	( (Con = top ; var(C) ; C = [_|_])  ->  
	  '$execute_command'(C,VL,Pos,Con,C), ! ;
	  % do term expansion
	  expand_term(C, EC),
	  % execute a list of commands
	  '$execute_commands'(EC,VL,Pos,Con,C),
	  % succeed only if the *original* was at end of file.
	  C == end_of_file
	).

 %
 % Hack in case expand_term has created a list of commands.
 %
 '$execute_commands'(V,_,_,_,Source) :- var(V), !,
	 '$do_error'(instantiation_error,meta_call(Source)).
 '$execute_commands'([],_,_,_,_) :- !.
 '$execute_commands'([C|Cs],VL,Pos,Con,Source) :- !,
	 (
	   '$system_catch'('$execute_command'(C,VL,Pos,Con,C),prolog,Error,user:'$LoopError'(Error, Con)),
	   fail	
	 ;
	   '$execute_commands'(Cs,VL,Pos,Con,Source)
	 ).
 '$execute_commands'(C,VL,Pos,Con,Source) :-
	 '$execute_command'(C,VL,Pos,Con,Source).

				%
 %
 %

 '$execute_command'(C,_,_,top,Source) :- var(C), !,
	 '$do_error'(instantiation_error,meta_call(Source)).
 '$execute_command'(C,_,_,top,Source) :- number(C), !,
	 '$do_error'(type_error(callable,C),meta_call(Source)).
 '$execute_command'(R,_,_,top,Source) :- db_reference(R), !,
	 '$do_error'(type_error(callable,R),meta_call(Source)).
 '$execute_command'(end_of_file,_,_,_,_) :- !.
 '$execute_command'(Command,_,_,_,_) :-
	 '$nb_getval'('$if_skip_mode', skip, fail),
	 \+ '$if_directive'(Command),
	 !.
 '$execute_command'((:-G),VL,Pos,Option,_) :-
%          !, 
	 Option \= top, !,
	 '$current_module'(M),
	 % allow user expansion
	 expand_term((:- G), O),
	 (
	     O = (:- G1)
	 ->
	   '$process_directive'(G1, Option, M, VL, Pos)
          ;
	    '$execute_commands'(O,VL,Pos,Option,O)
	 ).
 '$execute_command'((?-G), V, Pos, Option, Source) :-
	 Option \= top, !,
	 '$execute_command'(G, V, Pos, top, Source).
 '$execute_command'(G, V, Pos, Option, Source) :-
	 '$continue_with_command'(Option, V, Pos, G, Source).

 %
 % This command is very different depending on the language mode we are in.
 %
 % ISO only wants directives in files
 % SICStus accepts everything in files
 % YAP accepts everything everywhere
 % 
 '$process_directive'(G, top, M, VL, Pos) :-
	 '$access_yap_flags'(8, 0), !, % YAP mode, go in and do it,
	 '$process_directive'(G, consult, M, VL, Pos).
 '$process_directive'(G, top, _, _, _) :- !,
	 '$do_error'(context_error((:- G),clause),query).
 %
 % allow modules
 %
 '$process_directive'(M:G, Mode, _, VL, Pos) :- !,
	 '$process_directive'(G, Mode, M, VL, Pos).
 %
 % default case
 %
 '$process_directive'(Gs, Mode, M, VL, Pos) :-
	 '$all_directives'(Gs), !,
	 '$exec_directives'(Gs, Mode, M, VL, Pos).

 %
 % ISO does not allow goals (use initialization).
 %
 '$process_directive'(D, _, M, VL, Pos) :-
	 '$access_yap_flags'(8, 1), !, % ISO Prolog mode, go in and do it,
	 '$do_error'(context_error((:- M:D),query),directive).
 %
 % but YAP and SICStus does.
 %
 '$process_directive'(G, _, M, VL, Pos) :-
	 ( '$execute'(M:G) -> true ; format(user_error,':- ~w:~w failed.~n',[M,G]) ).

 '$continue_with_command'(Where,V,'$stream_position'(C,_P,A1,A2,A3),'$source_location'(_F,L):G,Source) :- !,
	  '$continue_with_command'(Where,V,'$stream_position'(C,L,A1,A2,A3),G,Source).
 '$continue_with_command'(reconsult,V,Pos,G,Source) :-
	 '$go_compile_clause'(G,V,Pos,5,Source),
	 fail.
 '$continue_with_command'(consult,V,Pos,G,Source) :-
	 '$go_compile_clause'(G,V,Pos,13,Source),
	 fail.
 '$continue_with_command'(top,V,_,G,_) :-
	 '$query'(G,V).

 %
 % not 100% compatible with SICStus Prolog, as SICStus Prolog would put
 % module prefixes all over the place, although unnecessarily so.
 %
 '$go_compile_clause'(G,V,Pos,N,Source) :-
	 '$current_module'(Mod),
	 '$go_compile_clause'(G,V,Pos,N,Mod,Mod,Source).
 
'$go_compile_clause'(G,_,_,_,_,_,Source) :-
	var(G), !,
	'$do_error'(instantiation_error,assert(Source)).	
'$go_compile_clause'((G:-_),_,_,_,_,_,Source) :-
	var(G), !,
	'$do_error'(instantiation_error,assert(Source)).	
'$go_compile_clause'(M:G,V,Pos,N,_,_,Source) :- !,
	  '$go_compile_clause'(G,V,Pos,N,M,M,Source).
'$go_compile_clause'((M:H :- B),V,Pos,N,_,BodyMod,Source) :- !,
	  '$go_compile_clause'((H :- B),V,Pos,N,M,BodyMod,Source).
'$go_compile_clause'(G,V,Pos,N,HeadMod,BodyMod,Source) :- !,
	 '$prepare_term'(G, V, Pos, G0, G1, BodyMod, HeadMod, Source),
	 '$$compile'(G1, G0, N, HeadMod).

 '$prepare_term'(G, V, Pos, G0, G1, BodyMod, SourceMod, Source) :-
	 (
	     get_value('$syntaxcheckflag',on)
          ->
	     '$check_term'(Source, G, V, Pos, BodyMod)
	 ;
	     true 
	 ),
	 '$precompile_term'(G, G0, G1, BodyMod, SourceMod).

 % process an input clause
 '$$compile'(G, G0, L, Mod) :-
	 '$head_and_body'(G,H,_),
	 '$flags'(H, Mod, Fl, Fl),
	 is(NFl, /\, Fl, 0x00002000),
	 (
	  NFl \= 0
	 ->
	  '$assertz_dynamic'(L,G,G0,Mod)
	 ;
	  '$nb_getval'('$assert_all',on,fail)
	 ->
	  functor(H,N,A),
	  '$dynamic'(N/A,Mod),
	  '$assertz_dynamic'(L,G,G0,Mod)
	 ;
	  '$not_imported'(H, Mod),
	  '$compile'(G, L, G0, Mod)
	 ).

%
% check if current module redefines an imported predicate.
% and remove import.
%
'$not_imported'(H, Mod) :-
	recorded('$import','$import'(NM,Mod,NH,H,_,_),R),
	NM \= Mod,
	functor(NH,N,Ar),
	print_message(warning,redefine_imported(Mod,NM,N/Ar)),
	erase(R),
	fail.
'$not_imported'(_, _).


'$check_if_reconsulted'(N,A) :- 
         once(recorded('$reconsulted',N/A,_)), 
	 recorded('$reconsulted',X,_), 
	 ( X = N/A , !; 
	   X = '$', !, fail; 
	   fail 
	 ). 

'$inform_as_reconsulted'(N,A) :-
	 recorda('$reconsulted',N/A,_).

'$clear_reconsulting' :-
	recorded('$reconsulted',X,Ref),
	erase(Ref),
	X == '$', !,
	( recorded('$reconsulting',_,R) -> erase(R) ).

'$prompt_alternatives_on'(determinism).

/* Executing a query */

'$query'(end_of_file,_).

'$query'(G,[]) :-
	 '$prompt_alternatives_on'(OPT),
	 ( OPT = groundness ; OPT = determinism), !,
	 '$yes_no'(G,(?-)).
'$query'(G,V) :-
	 (
	  '$current_choice_point'(CP),
	  '$current_module'(M),
	  '$user_call'(G, M),
	  '$current_choice_point'(NCP),
	  '$delayed_goals'(G, V, NV, LGs, DCP),
	  '$write_answer'(NV, LGs, Written),
	  '$write_query_answer_true'(Written),
	  (
	   '$prompt_alternatives_on'(determinism), CP == NCP, DCP = 0 
	   ->
	   format(user_error, '.~n', []),
	   !
	  ;
	   '$another',
	   !
	  ),
	  fail	 
	 ;
	  '$out_neg_answer'
	 ).

 '$yes_no'(G,C) :-
	 '$current_module'(M),
	 '$do_yes_no'(G,M),
	 '$delayed_goals'(G, [], NV, LGs, _),
	 '$write_answer'(NV, LGs, Written),
	 ( Written = [] ->
	   !,'$present_answer'(C, true)
	 ;
	   '$another', !
	 ),
	 fail.
 '$yes_no'(_,_) :-
	 '$out_neg_answer'.

'$add_env_and_fail' :- fail.

%
% *-> at this point would require compiler support, which does not exist.
%
'$delayed_goals'(G, V, NV, LGs, NCP) :-
	(
	  CP is '$last_choice_pt',
	  '$current_choice_point'(NCP1),
	  '$attributes':delayed_goals(G, V, NV, LGs),
	  '$current_choice_point'(NCP2),
	  '$clean_ifcp'(CP),
	   NCP is NCP2-NCP1
	  ;
	   copy_term_nat(V, NV), 
	   LGs = [], 
%	   term_factorized(V, NV, LGs),
	   NCP = 0
        ).

'$out_neg_answer' :-
	 ( '$undefined'(print_message(_,_),prolog) -> 
	    '$present_answer'(user_error,'false.~n', [])
	 ;
	    print_message(help,false)
	 ),
	 fail.

'$do_yes_no'([X|L], M) :-
	!,
	'$csult'([X|L], M).
'$do_yes_no'(G, M) :-
	'$user_call'(G, M).

'$write_query_answer_true'([]) :- !,
	format(user_error,'true',[]).
'$write_query_answer_true'(_).


%
% present_answer has three components. First it flushes the streams,
% then it presents the goals, and last it shows any goals frozen on
% the arguments.
%
'$present_answer'(_,_):-
        flush_output,
	fail.
'$present_answer'((?-), Answ) :-
	'$swi_current_prolog_flag'(break_level, BL ),
	( BL \= 0 -> 	format(user_error, '[~p] ',[BL]) ;
			true ),
        ( recorded('$print_options','$toplevel'(Opts),_) ->
	   write_term(user_error,Answ,Opts) ;
	   format(user_error,'~w',[Answ])
        ),
	format(user_error,'.~n', []).

'$another' :-
	format(user_error,' ? ',[]),
	get0(user_input,C),
	'$do_another'(C).

'$do_another'(C) :-
	(   C== 0'; ->  skip(user_input,10), %'
	%    '$add_nl_outside_console',
	    fail
	;
	    C== 10 -> '$add_nl_outside_console',
		( '$undefined'(print_message(_,_),prolog) -> 
			format(user_error,'yes~n', [])
	        ;
		   print_message(help,yes)
		)
	;
	    C== 13 -> 
	    get0(user_input,NC),
	    '$do_another'(NC)	    
	;
	    C== -1 -> halt
	;
	    skip(user_input,10), '$ask_again_for_another'
	).

%'$add_nl_outside_console' :-
%	'$is_same_tty'(user_input, user_error), !.
'$add_nl_outside_console' :-
	format(user_error,'~n',[]).

'$ask_again_for_another' :-
	format(user_error,'Action (\";\" for more choices, <return> for exit)', []),
	'$another'.

'$write_answer'(_,_,_) :-
        flush_output,
	fail.
'$write_answer'(Vs, LBlk, FLAnsw) :-
	'$purge_dontcares'(Vs,IVs),
	'$sort'(IVs, NVs),
	'$prep_answer_var_by_var'(NVs, LAnsw, LBlk),
	'$name_vars_in_goals'(LAnsw, Vs, NLAnsw),
        '$write_vars_and_goals'(NLAnsw, first, FLAnsw).

'$purge_dontcares'([],[]).
'$purge_dontcares'([Name=_|Vs],NVs) :- 
	atom_codes(Name, [C|_]), C is "_", !,
	'$purge_dontcares'(Vs,NVs).
'$purge_dontcares'([V|Vs],[V|NVs]) :-
	'$purge_dontcares'(Vs,NVs).


'$prep_answer_var_by_var'([], L, L).
'$prep_answer_var_by_var'([Name=Value|L], LF, L0) :- 
	'$delete_identical_answers'(L, Value, NL, Names),
	'$prep_answer_var'([Name|Names], Value, LF, LI),
	'$prep_answer_var_by_var'(NL, LI, L0).

% fetch all cases that have the same solution.
'$delete_identical_answers'([], _, [], []).
'$delete_identical_answers'([(Name=Value)|L], Value0, FL, [Name|Names]) :-
	Value == Value0, !,
	'$delete_identical_answers'(L, Value0, FL, Names).
'$delete_identical_answers'([VV|L], Value0, [VV|FL], Names) :-
	'$delete_identical_answers'(L, Value0, FL, Names).

% now create a list of pairs that will look like goals.
'$prep_answer_var'(Names, Value, LF, L0) :- var(Value), !,
	'$prep_answer_unbound_var'(Names, LF, L0).
'$prep_answer_var'(Names, Value, [nonvar(Names,Value)|L0], L0).

% ignore unbound variables
'$prep_answer_unbound_var'([_], L, L) :- !.
'$prep_answer_unbound_var'(Names, [var(Names)|L0], L0).

'$gen_name_string'(I,L,[C|L]) :- I < 26, !, C is I+65.
'$gen_name_string'(I,L0,LF) :-
	I1 is I mod 26,
	I2 is I // 26,
	C is I1+65,
	'$gen_name_string'(I2,[C|L0],LF).

'$write_vars_and_goals'([], _, []).
'$write_vars_and_goals'([nl,G1|LG], First, NG) :- !,
	nl(user_error),
	'$write_goal_output'(G1, First, NG, Next, IG),
	'$write_vars_and_goals'(LG, Next, IG).
'$write_vars_and_goals'([G1|LG], First, NG) :-
	'$write_goal_output'(G1, First, NG, Next, IG),
	'$write_vars_and_goals'(LG, Next, IG).

'$goal_to_string'(Format, G, String) :-
	format(codes(String),Format,G).

'$write_goal_output'(var([V|VL]), First, [var([V|VL])|L], next, L) :- !,
        ( First = first -> true ; format(user_error,',~n',[]) ),
	format(user_error,'~a',[V]),
	'$write_output_vars'(VL).
'$write_goal_output'(nonvar([V|VL],B), First, [nonvar([V|VL],B)|L], next, L) :- !,
        ( First = first -> true ; format(user_error,',~n',[]) ),
	format(user_error,'~a',[V]),
	'$write_output_vars'(VL),
	format(user_error,' = ', []),
        ( recorded('$print_options','$toplevel'(Opts),_) ->
	   write_term(user_error,B,[priority(699)|Opts]) ;
	   write_term(user_error,B,[priority(699)])
        ).
'$write_goal_output'(nl, First, NG, First, NG) :- !,
	format(user_error,'~n',[]).
'$write_goal_output'(Format-G, First, NG, Next, IG) :- !,
	G = [_|_], !,
	% dump on string first so that we can check whether we actually
	% had any output from the solver.
	'$goal_to_string'(Format, G, String),
	( String == [] ->
	    % we didn't
	    IG = NG, First = Next
	;
	    % we did
	    ( First = first -> true ; format(user_error,',~n',[]) ),
	    format(user_error, '~s', [String]),
	    NG = [G|IG]
	).
'$write_goal_output'(_-G, First, [G|NG], next, NG) :- !,
        ( First = first -> true ; format(user_error,',~n',[]) ),
        ( recorded('$print_options','$toplevel'(Opts),_) ->
	   write_term(user_error,G,Opts) ;
	   format(user_error,'~w',[G])
        ).
'$write_goal_output'(_M:G, First, [G|NG], next, NG) :- !,
        ( First = first -> true ; format(user_error,',~n',[]) ),
        ( recorded('$print_options','$toplevel'(Opts),_) ->
	   write_term(user_error,G,Opts) ;
	   format(user_error,'~w',[G])
        ).
'$write_goal_output'(G, First, [M:G|NG], next, NG) :-
	'$current_module'(M),
        ( First = first -> true ; format(user_error,',~n',[]) ),
        ( recorded('$print_options','$toplevel'(Opts),_) ->
	   write_term(user_error,G,Opts) ;
	   format(user_error,'~w',[G])
        ).

'$name_vars_in_goals'(G, VL0, G) :-
	'$name_well_known_vars'(VL0),
	'$variables_in_term'(G, [], GVL),
	'$name_vars_in_goals1'(GVL, 0, _).

'$name_well_known_vars'([]).
'$name_well_known_vars'([Name=V|NVL0]) :-
	var(V), !,
	V = '$VAR'(Name),
	'$name_well_known_vars'(NVL0).
'$name_well_known_vars'([_|NVL0]) :-
	'$name_well_known_vars'(NVL0).

'$name_vars_in_goals1'([], I, I).
'$name_vars_in_goals1'(['$VAR'(Name)|NGVL], I0, IF) :-
	I is I0+1,
	'$gen_name_string'(I0,[],SName), !,
	atom_codes(Name, [95|SName]),
	'$name_vars_in_goals1'(NGVL, I, IF).
'$name_vars_in_goals1'([NV|NGVL], I0, IF) :-
	nonvar(NV),
	'$name_vars_in_goals1'(NGVL, I0, IF).

'$write_output_vars'([]).
'$write_output_vars'([V|VL]) :-
	format(user_error,' = ~s',[V]),
	'$write_output_vars'(VL).

call(G) :- '$execute'(G).

incore(G) :- '$execute'(G).

%
% standard meta-call, called if $execute could not do everything.
%
'$meta_call'(G, M) :-
	'$current_choice_point'(CP),
	'$call'(G, CP, G, M).

'$user_call'(G, M) :-
	 ( '$$save_by'(CP),
	 '$enable_debugging',
	 '$call'(G, CP, M:G, M),
	 '$$save_by'(CP2),
	 (CP == CP2 -> ! ; ( true ; '$enable_debugging', fail ) ),
	 '$disable_debugging'
     ;
	'$disable_debugging',
	fail
    ).

'$enable_debugging' :-
	'$swi_current_prolog_flag'(debug, false), !.
'$enable_debugging' :-
	'$nb_getval'('$trace', on, fail), !,
	'$creep'.
'$enable_debugging'.

'$disable_debugging' :-
	'$stop_creeping'.


','(X,Y) :-
	yap_hacks:env_choice_point(CP),
	'$current_module'(M),
        '$call'(X,CP,(X,Y),M),
        '$call'(Y,CP,(X,Y),M).
';'((X->A),Y) :- !,
	yap_hacks:env_choice_point(CP),
	'$current_module'(M),
        ( '$execute'(X)
	->
	  '$call'(A,CP,(X->A;Y),M)
	;
	  '$call'(Y,CP,(X->A;Y),M)
	).
';'((X*->A),Y) :- !,
	yap_hacks:env_choice_point(CP),
	'$current_module'(M),
	(
	 yap_hacks:current_choice_point(DCP),
	 '$execute'(X),
	 yap_hacks:cut_at(DCP),
	 '$call'(A,CP,((X*->A),Y),M)
        ;
	 '$call'(Y,CP,((X*->A),Y),M)
	).
';'(X,Y) :-
	yap_hacks:env_choice_point(CP),
	'$current_module'(M),
        ( '$call'(X,CP,(X;Y),M) ; '$call'(Y,CP,(X;Y),M) ).
'|'(X,Y) :-
	yap_hacks:env_choice_point(CP),
	'$current_module'(M),
        ( '$call'(X,CP,(X|Y),M) ; '$call'(Y,CP,(X|Y),M) ).
'->'(X,Y) :-
	yap_hacks:env_choice_point(CP),
	'$current_module'(M),
        ( '$call'(X,CP,(X->Y),M) -> '$call'(Y,CP,(X->Y),M) ).
'*->'(X,Y) :-
	yap_hacks:env_choice_point(CP),
	'$current_module'(M),
        ( '$call'(X,CP,(X*->Y),M), '$call'(Y,CP,(X*->Y),M) ).
\+(G) :-     \+ '$execute'(G).
not(G) :-    \+ '$execute'(G).

'$cut_by'(CP) :- '$$cut_by'(CP).

%
% do it in ISO mode.
%
'$meta_call'(G,_ISO,M) :-
	'$iso_check_goal'(G,G),
	'$current_choice_point'(CP),
	'$call'(G, CP, G, M).

'$meta_call'(G, CP, G0, M) :-
	'$call'(G, CP, G0, M).

'$call'(G, CP, G0, _, M) :-  /* iso version */
	'$iso_check_goal'(G,G0),
	'$call'(G, CP, G0, M).


'$call'(M:_,_,G0,_) :- var(M), !,
	'$do_error'(instantiation_error,call(G0)).
'$call'(M:G,CP,G0,_) :- !,
        '$call'(G,CP,G0,M).
'$call'((X,Y),CP,G0,M) :- !,
        '$call'(X,CP,G0,M),
        '$call'(Y,CP,G0,M).
'$call'((X->Y),CP,G0,M) :- !,
	(
	 '$call'(X,CP,G0,M)
          ->
	 '$call'(Y,CP,G0,M)
	).
'$call'((X*->Y),CP,G0,M) :- !,
	'$call'(X,CP,G0,M),
	'$call'(Y,CP,G0,M).
'$call'((X->Y; Z),CP,G0,M) :- !,
	(
	    '$call'(X,CP,G0,M)
         ->
	    '$call'(Y,CP,G0,M)
        ;
	    '$call'(Z,CP,G0,M)
	).
'$call'((X*->Y; Z),CP,G0,M) :- !,
	(
	 '$current_choice_point'(DCP),
	 '$call'(X,CP,G0,M),
	 yap_hacks:cut_at(DCP),
	 '$call'(Y,CP,G0,M)
        ;
	 '$call'(Z,CP,G0,M)
	).
'$call'((A;B),CP,G0,M) :- !,
	(
	    '$call'(A,CP,G0,M)
        ;
	    '$call'(B,CP,G0,M)
	).
'$call'((X->Y| Z),CP,G0,M) :- !,
	(
	    '$call'(X,CP,G0,M)
         ->
	 '$call'(Y,CP,G0,M)
        ;
	'$call'(Z,CP,G0,M)
	).
'$call'((X*->Y| Z),CP,G0,M) :- !,
	(
	 '$current_choice_point'(DCP),
	 '$call'(X,CP,G0,M),
	 yap_hacks:cut_at(DCP),
	 '$call'(Y,CP,G0,M)
        ;
	 '$call'(Z,CP,G0,M)
	).
'$call'((A|B),CP, G0,M) :- !,
	(
	    '$call'(A,CP,G0,M)
        ;
	    '$call'(B,CP,G0,M)
	).
'$call'(\+ X, _CP, _G0, M) :- !,
	'$current_choice_point'(CP),
	\+  '$call'(X,CP,G0,M).
'$call'(not(X), _CP, _G0, M) :- !,
	\+  '$call'(X,CP,G0,M).
'$call'(!, CP, _,_) :- !,
	'$$cut_by'(CP).
'$call'([A|B], _, _, M) :- !,
	'$csult'([A|B], M).
'$call'(G, CP, G0, CurMod) :-
	( '$is_expand_goal_or_meta_predicate'(G,CurMod) ->
	   (
	     '$do_goal_expansion'(G, CurMod, NG) ->
	     '$call'(NG, CP, G0,CurMod)
	     ;
	       % repeat other code.
             '$is_metapredicate'(G,CurMod) ->
	       (
	         '$meta_expansion'(G,CurMod,CurMod,CurMod,NG,[]) ->
	         '$execute0'(NG, CurMod)
	       ;
	         '$execute0'(G, CurMod)
	       )
	   ;
	     '$execute0'(G, CurMod)
	   )
	;
	  '$execute0'(G, CurMod)
	).

'$check_callable'(V,G) :- var(V), !,
	'$do_error'(instantiation_error,G).
'$check_callable'(M:_G1,G) :- var(M), !,
	'$do_error'(instantiation_error,G).
'$check_callable'(_:G1,G) :- !,
	'$check_callable'(G1,G).
'$check_callable'(A,G) :- number(A), !,
	'$do_error'(type_error(callable,A),G).
'$check_callable'(R,G) :- db_reference(R), !,
	'$do_error'(type_error(callable,R),G).
'$check_callable'(_,_).

% Called by the abstract machine, if no clauses exist for a predicate
'$undefp'([M|G]) :-
	'$find_goal_definition'(M, G, NM, NG),
	'$execute0'(NG, NM).

'$find_goal_definition'(M, G, NM, NG) :-
	% make sure we do not loop on undefined predicates
        % for undefined_predicates.
	'$enter_undefp',
	(
	 '$get_undefined_pred'(G, M, Goal, NM)
	->
	 '$exit_undefp',
	 Goal \= fail,
	 '$complete_goal'(M, Goal, NM, G, NG)
	;
	 '$find_undefp_handler'(G, M),
	 NG = G, NM = M
	).

'$complete_goal'(M, G, CurMod, G0, NG) :-
	  (
	   '$is_metapredicate'(G,CurMod)
	  ->
	   '$meta_expansion'(G, CurMod, M, M, NG,[])
	  ;
	   NG = G
	  ).

'$find_undefp_handler'(G,M,NG,user) :-
	functor(G, Na, Ar),
	user:exception(undefined_predicate,M:Na/Ar,Action), !,
	'$exit_undefp',
	(
	     Action == fail
	 ->
	  NG = fail
      ;
	 Action == retry
     ->
	 NG = G
     ;
	 Action == error
     ->
	 '$unknown_error'(M:G)
     ;
	 '$do_error'(type_error(atom, Action),M:G)
     ).

'$find_undefp_handler'(G,M) :-
	 '$exit_undefp',
	'$swi_current_prolog_flag'(M:unknown, Action),
	(
	 Action == fail
	->
	 fail
	;
	 Action == warning
	->
	 '$unknown_warning'(M:G),
	 fail
	;
	 '$unknown_error'(M:G)
	).

'$silent_bootstrap'(F) :-
	'$init_globals',
	nb_setval('$if_level',0),
	'$swi_current_prolog_flag'(verbose_load, OldSilent),
	'$swi_set_prolog_flag'(verbose_load, silent),
	bootstrap(F),
	% -p option must be processed after initializing the system
	'$swi_set_prolog_flag'(verbose_load, OldSilent).

bootstrap(F) :-
%	'$open'(F, '$csult', Stream, 0, 0, F),
%	'$file_name'(Stream,File),
	open(F, read, Stream),
	stream_property(Stream, file_name(File)),
	'$start_consult'(consult, File, LC),
	file_directory_name(File, Dir),
	working_directory(OldD, Dir),
	(
	  '$swi_current_prolog_flag'(verbose_load, silent)
	->
	  true
	;
	  H0 is heapused, '$cputime'(T0,_),
	  format(user_error, '~*|% consulting ~w...~n', [LC,F])
	),
	'$loop'(Stream,consult),
	working_directory(_, OldD),
	'$end_consult',
	(
	  '$swi_current_prolog_flag'(verbose_load, silent)
	->
	  true
	;
	  H is heapused-H0, '$cputime'(TF,_), T is TF-T0,
	  format(user_error, '~*|% ~w consulted ~w bytes in ~d msecs~n', [LC,F,H,T])
	),
	!,
	close(Stream).

'$loop'(Stream,exo) :-
	prolog_flag(agc_margin,Old,0),	
	prompt1('|     '), prompt(_,'| '),
	'$current_module'(OldModule),
	repeat,
		'$system_catch'(dbload_from_stream(Stream, OldModule, exo), '$db_load', Error,
			 user:'$LoopError'(Error, Status)),
	prolog_flag(agc_margin,_,Old),
	!.
'$loop'(Stream,db) :-
	prolog_flag(agc_margin,Old,0),	
	prompt1('|     '), prompt(_,'| '),
	'$current_module'(OldModule),
	repeat,
		'$system_catch'(dbload_from_stream(Stream, OldModule, db), '$db_load', Error,
			 user:'$LoopError'(Error, Status)),
	prolog_flag(agc_margin,_,Old),
	!.
'$loop'(Stream,Status) :-
	repeat,
		prompt1('|     '), prompt(_,'| '),
		'$current_module'(OldModule),
		'$system_catch'('$enter_command'(Stream,OldModule,Status), OldModule, Error,
			 user:'$LoopError'(Error, Status)),
	!.

'$enter_command'(Stream,Mod,Status) :-
	read_term(Stream, Command, [module(Mod), variable_names(Vars), term_position(Pos), syntax_errors(dec10), process_comment(true), singletons( Singletons ) ]),
	( Singletons == []
         -> 
	 true
        ;
	  get_value('$syntaxchecksinglevar',on)
        ->
	 '$sv_warning'(Singletons, Command )
        ;
	  true
        ),
	'$command'(Command,Vars,Pos,Status).

'$abort_loop'(Stream) :-
	'$do_error'(permission_error(input,closed_stream,Stream), loop).

/* General purpose predicates				*/

'$head_and_body'((H:-B),H,B) :- !.
'$head_and_body'(H,H,true).

%
% split head and body, generate an error if body is unbound.
%
'$check_head_and_body'((H:-B),H,B,P) :- !,
	'$check_head'(H,P).
'$check_head_and_body'(H,H,true,P) :-
	'$check_head'(H,P).

'$check_head'(H,P) :- var(H), !,
	'$do_error'(instantiation_error,P).
'$check_head'(H,P) :- number(H), !,
	'$do_error'(type_error(callable,H),P).
'$check_head'(H,P) :- db_reference(H), !,
	'$do_error'(type_error(callable,H),P).
'$check_head'(_,_).

% term expansion
%
% return two arguments: Expanded0 is the term after "USER" expansion.
%                       Expanded is the final expanded term.
%
'$precompile_term'(Term, Expanded0, Expanded, BodyMod, SourceMod) :-
%format('[ ~w~n',[Term]),  
	'$module_expansion'(Term, Expanded0, ExpandedI, BodyMod, SourceMod), !,
%format('      -> ~w~n',[Expanded0]),  
	(
	 '$access_yap_flags'(9,1)      /* strict_iso on */
        ->
	 Expanded = ExpandedI,
	 '$check_iso_strict_clause'(Expanded0)
        ;
	 '$expand_array_accesses_in_term'(ExpandedI,Expanded)
	).
'$precompile_term'(Term, Term, Term, _, _).
	

expand_term(Term,Expanded) :-
	( '$do_term_expansion'(Term,Expanded)
        ->
	   true
        ;
	  '$expand_term_grammar'(Term,Expanded)
	).

%
% Grammar Rules expansion
%
'$expand_term_grammar'((A-->B), C) :-
	'$translate_rule'((A-->B),C), !.
'$expand_term_grammar'(A, A).

%
% Arithmetic expansion
%
'$expand_array_accesses_in_term'(Expanded0,ExpandedF) :-
	'$array_refs_compiled',
	'$c_arrays'(Expanded0,ExpandedF), !.
'$expand_array_accesses_in_term'(Expanded,Expanded).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   catch/throw implementation

% at each catch point I need to know:
% what is ball;
% where was the previous catch	
catch(G, C, A) :-
	'$catch'(C,A,_),
	'$$save_by'(CP0),
	'$execute'(G),
	'$$save_by'(CP1),
	(CP0 == CP1 -> !; true ).

% makes sure we have an environment.
'$true'.


% system_catch is like catch, but it avoids the overhead of a full
% meta-call by calling '$execute0' instead of $execute.
% This way it
% also avoids module preprocessing and goal_expansion
%
'$system_catch'(G, M, C, A) :-
	% check current trail
	'$catch'(C,A,_),
	'$$save_by'(CP0),
	'$execute_nonstop'(G, M),
	'$$save_by'(CP1),
	(CP0 == CP1 -> !; true ).

%
% throw has to be *exactly* after system catch!
%
throw(_Ball) :-
	% use existing ball
	'$get_exception'(Ball),
	!,
	'$jump_env_and_store_ball'(Ball).
throw(Ball) :-
	( var(Ball) -> 
	    '$do_error'(instantiation_error,throw(Ball))
	;
	% get current jump point
	    '$jump_env_and_store_ball'(Ball)
	).


% just create a choice-point
'$catch'(_,_,_).
'$catch'(_,_,_) :- fail.

'$handle_throw'(_, _, _).
'$handle_throw'(C, A, _Ball) :-
	'$reset_exception'(Ball),
        % reset info
	(catch_ball(Ball, C) ->
	    '$execute'(A)
	    ;
	    throw(Ball)
	).

catch_ball(Abort, _) :- Abort == '$abort', !, fail.
% system defined throws should be ignored by used, unless the
% user is hacking away.
catch_ball(Ball, V) :-
	var(V),
	nonvar(Ball),
	Ball = error(Type,_), % internal error ??
	functor(Type, Name, _),
	atom_codes(Name, [0'$|_]), %'0
	!, fail.
catch_ball(C, C).

'$run_toplevel_hooks' :-
	'$swi_current_prolog_flag'(break_level, 0 ),
	recorded('$toplevel_hooks',H,_), 
	H \= fail, !,
	( call(user:H1) -> true ; true).
'$run_toplevel_hooks'.

'$run_at_thread_start' :-
	recorded('$thread_initialization',M:D,_),
	'$meta_call'(D, M),
	fail.
'$run_at_thread_start'.





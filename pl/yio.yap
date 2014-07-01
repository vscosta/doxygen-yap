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
* File:		yio.yap							 *
* Last rev:								 *
* mods:									 *
* comments:	Input output predicates			 		 *
*									 *
*************************************************************************/

/* stream predicates							*/

/* check whether a list of options is valid */
'$check_io_opts'(V,G) :- var(V), !,
	'$do_error'(instantiation_error,G).
'$check_io_opts'([],_) :- !.
'$check_io_opts'([H|_],G) :- var(H), !,
	'$do_error'(instantiation_error,G).
'$check_io_opts'([Opt|T],G) :- !,
	'$check_opt'(G,Opt,G),
	'$check_io_opts'(T,G).
'$check_io_opts'(T,G) :-
	'$do_error'(type_error(list,T),G).

'$check_opt'(read_term(_,_),Opt,G) :-
	'$check_opt_read'(Opt, G).
'$check_opt'(stream_property(_,_),Opt,G) :-
	'$check_opt_sp'(Opt, G).

'$check_opt_read'(variables(_), _) :- !.
'$check_opt_read'(variable_names(_), _) :- !.
'$check_opt_read'(singletons(_), _) :- !.
'$check_opt_read'(syntax_errors(T), G) :- !,
	'$check_read_syntax_errors_arg'(T, G).
'$check_opt_read'(term_position(_), _) :- !.
'$check_opt_read'(term_position(_), _) :- !.
'$check_opt_read'(comments(_), _) :- !.
'$check_opt_read'(module(_), _) :- !.
'$check_opt_read'(A, G) :-
	'$do_error'(domain_error(read_option,A),G).

'$check_opt_sp'(file_name(_), _) :- !.
'$check_opt_sp'(mode(_), _) :- !.
'$check_opt_sp'(input, _) :- !.
'$check_opt_sp'(output, _) :- !.
'$check_opt_sp'(alias(_), _) :- !.
'$check_opt_sp'(position(_), _) :- !.
'$check_opt_sp'(end_of_stream(_), _) :- !.
'$check_opt_sp'(eof_action(_), _) :- !.
'$check_opt_sp'(reposition(_), _) :- !.
'$check_opt_sp'(type(_), _) :- !.
'$check_opt_sp'(bom(_), _) :- !.
'$check_opt_sp'(encoding(_), _) :- !.
'$check_opt_sp'(representation_errors(_), _) :- !.
'$check_opt_sp'(A, G) :-
	'$do_error'(domain_error(stream_property,A),G).

'$check_read_syntax_errors_arg'(X, G) :- var(X), !,
	'$do_error'(instantiation_error,G).
'$check_read_syntax_errors_arg'(dec10,_) :- !.
'$check_read_syntax_errors_arg'(fail,_) :- !.
'$check_read_syntax_errors_arg'(error,_) :- !.
'$check_read_syntax_errors_arg'(quiet,_) :- !.
'$check_read_syntax_errors_arg'(X,G) :-
	'$do_error'(domain_error(read_option,syntax_errors(X)),G).

'$check_boolean'(X, _, _, G) :- var(X), !,
	'$do_error'(instantiation_error,G).
'$check_boolean'(true,_,_,_) :- !.
'$check_boolean'(false,_,_,_) :- !.
'$check_boolean'(X,B,T,G) :-
	'$do_error'(domain_error(B,T),G).

socket(Domain, Sock) :-
	(
	 '$undefined'(ip_socket(_,_),yap_sockets)
	->
	 load_files(library(sockets), [silent(true),if(not_loaded)])
	;
	 true
	),
	yap_sockets:ip_socket(Domain, Sock).

socket(Domain, Type, Protocol, Sock) :-
	(
	 '$undefined'(ip_socket(_,_),yap_sockets)
	->
	 load_files(library(sockets), [silent(true),if(not_loaded)])
	;
	 true
	),
	yap_sockets:ip_socket(Domain, Type, Protocol, Sock).

socket_connect(Sock, Host, Read) :-
	(
	 '$undefined'(ip_socket(_,_),yap_sockets)
	->
	 load_files(library(sockets), [silent(true),if(not_loaded)])
	;
	 true
	),
	yap_sockets:ip_socket(Domain, Type, Protocol, Sock).

open_pipe_streams(Read, Write) :-
	(
	 '$undefined'(pipe(_,_),unix)
	->
	 load_files(library(unix), [silent(true),if(not_loaded)])
	;
	 true
	),
	unix:pipe(Read, Write),
	yap_flag(encoding, X),
	set_stream(Read, encoding(X) ),
	set_stream(Write, encoding(X) ).

fileerrors :- 	'$swi_set_prolog_flag'(fileerrors, true).

nofileerrors :- '$swi_set_prolog_flag'(fileerrors, false).

exists(F) :-
	absolute_file_name(F, _, [file_errors(fail),access(exist),expand(true)]).

/* Term IO	*/

read(T) :-
	read_term(T, []).

read(Stream,T) :-
	read_term(Stream, T, []).


/* meaning of flags for '$write' is
	 1	quote illegal atoms
	 2	ignore operator declarations
	 4	output '$VAR'(N) terms as A, B, C, ...
	 8	use portray(_)

   flags are defined in yapio.h
*/

display(T) :-
	   current_output(Out),
	   write_term(Out, T, [ignore_ops(true)]).

display(Stream, T) :-
	   write_term(Term, T, [ignore_ops(true)]).

format(T) :-
	format(T, []).

writeln(T) :-
	write(T),
	nl.

/* interface to user portray	*/
'$portray'(T) :-
	\+ '$undefined'(portray(_),user),
	'$system_catch'(call(portray(T)),user,Error,user:'$Error'(Error)), !,
	set_value('$portray',true), fail.
'$portray'(_) :- set_value('$portray',false), fail.

/* character I/O	*/

ttyget(N) :- get(user_input,N).

ttyget0(N) :- get0(user_input,N).

ttyskip(N) :-  N1 is N, '$skip'(user_input,N1).

ttyput(N) :-  N1 is N, put(user_output,N1).

ttynl :- nl(user_output).

current_line_number(N) :-
	current_input(Stream),
	line_count(Stream, N).

current_line_number(Stream,N) :-
	line_count(Stream, N).

stream_position(Stream, Position) :-
	stream_property(Stream, position(Position)).

stream_position(Stream, Position, NewPosition) :-
	stream_property(Stream, position(Position)),
	set_stream_position(Stream, NewPosition).

at_end_of_line :-
	current_input(S),
	at_end_of_line(S).

at_end_of_line(S) :-
	current_stream(S, end_of_stream(past)), !.
at_end_of_line(S) :-
	peek(S,N), ( N = 10 -> true ; N = -1).


consult_depth(LV) :- '$show_consult_level'(LV).

current_char_conversion(X,Y) :-
	var(X), !,
	'$all_char_conversions'(List),
	'$fetch_char_conversion'(List,X,Y).
current_char_conversion(X,Y) :-
	'$current_char_conversion'(X,Y).


'$fetch_char_conversion'([X,Y|_],X,Y).
'$fetch_char_conversion'([_,_|List],X,Y) :-
	'$fetch_char_conversion'(List,X,Y).


current_stream(File, Mode, Stream) :-
    stream_property(Stream, mode(Mode)),
    '$stream_name'(Stream, File).

'$stream_name'(Stream, File) :-
    stream_property(Stream, file_name(File)), !.
'$stream_name'(Stream, file_no(File)) :-
    stream_property(Stream, file_no(File)), !.
'$stream_name'(Stream, Stream).

'$extend_file_search_path'(P) :-
	atom_codes(P,S),
	'$env_separator'(ES),
	'$split_for_path'(S,0'=,ES,Paths), %'
	'$add_file_search_paths'(Paths).

'$split_for_path'([], _, _, []).
'$split_for_path'(S, S1, S2, [A1=A2|R]) :-
	'$fetch_first_path'(S, S1, A1, SR1),
	'$fetch_second_path'(SR1, S2, A2, SR),
	'$split_for_path'(SR, S1, S2, R) .

'$fetch_first_path'([S1|SR],S1,[],SR) :- !.
'$fetch_first_path'([C|S],S1,[C|F],SR) :-
	'$fetch_first_path'(S,S1,F,SR).

'$fetch_second_path'([],_,[],[]).
'$fetch_second_path'([S1|SR],S1,[],SR) :- !.
'$fetch_second_path'([C|S],S1,[C|A2],SR) :-
	'$fetch_second_path'(S,S1,A2,SR).

'$add_file_search_paths'([]).
'$add_file_search_paths'([NS=DS|Paths]) :-
	atom_codes(N,NS),
	atom_codes(D,DS),
	assert(user:file_search_path(N,D)),
	'$add_file_search_paths'(Paths).


'$format@'(Goal,Out) :-
	with_output_to(codes(Out), Goal).

sformat(String, Form, Args) :-
	format(codes(String, []), Form, Args).

write_depth(T,L) :- write_depth(T,L,_).

%%      stream_position_data(?Field, +Pos, ?Date)
%
%       Extract values from stream position objects. '$stream_position' is
%       of the format '$stream_position'(Byte, Char, Line, LinePos)

stream_position_data(Prop, Term, Value) :-
        nonvar(Prop), !,
        (   '$stream_position_field'(Prop, Pos)
        ->  arg(Pos, Term, Value)
        ;   throw(error(domain_error(stream_position_data, Prop)))
        ).
stream_position_data(Prop, Term, Value) :-
        '$stream_position_field'(Prop, Pos),
        arg(Pos, Term, Value).

'$stream_position_field'(char_count,    1).
'$stream_position_field'(line_count,    2).
'$stream_position_field'(line_position, 3).
'$stream_position_field'(byte_count,    4).


'$default_expand'(Expand) :-
	get_value('$open_expands_filename',Expand).

'$set_default_expand'(true) :- !,
	set_value('$open_expands_filename',true).
'$set_default_expand'(false) :- !,
	set_value('$open_expands_filename',false).
'$set_default_expand'(V) :- !,
	'$do_error'(domain_error(flag_value,V),yap_flag(open_expands_file_name,X)).

prolog_file_name(File, PrologFileName) :-
	var(File), !,
	'$do_error'(instantiation_error, prolog_file_name(File, PrologFileName)).
prolog_file_name(user, Out) :- !, Out = user.
prolog_file_name(File, PrologFileName) :-
	atom(File), !,
	operating_system_support:true_file_name(File, PrologFileName).
prolog_file_name(File, PrologFileName) :-
	'$do_error'(type_error(atom,T), prolog_file_name(File, PrologFileName)).


'$codes_to_chars'(String0, String, String0) :- String0 == String, !.
'$codes_to_chars'(String0, [Code|String], [Char|Chars]) :-
	atom_codes(Char, [Code]),
	'$codes_to_chars'(String0, String, Chars).







/*************************************************************************
*									 *
*	 YAP Prolog 	%W% %G%
*									 *
*	Yap Prolog was developed at NCCUP - Universidade do Porto	 *
*									 *
* Copyright L.Damas, V.S.Costa and Universidade do Porto 1985-1997	 *
*									 *
**************************************************************************
*									 *
* File:		setof.pl						 *
* Last rev:								 *
* mods:									 *
* comments:	set predicates						 *
*									 *
*************************************************************************/

%   The "existential quantifier" symbol is only significant to bagof
%   and setof, which it stops binding the quantified variable.
%   op(200, xfy, ^) is defined during bootstrap.

% this is used by the all predicate

:- op(50,xfx,same).

_^Goal :-
	'$execute'(Goal).


%   findall/3 is a simplified version of bagof which has an implicit
%   existential quantifier on every variable.


findall(Template, Generator, Answers) :-
	( '$is_list_or_partial_list'(Answers) ->
		true
	;
		'$do_error'(type_error(list,Answers), findall(Template, Generator, Answers))
	),
	'$findall'(Template, Generator, [], Answers).


% If some answers have already been found
findall(Template, Generator, Answers, SoFar) :-
	'$findall'(Template, Generator, SoFar, Answers).

% starts by calling the generator,
% and recording the answers
'$findall'(Template, Generator, SoFar, Answers) :-
	nb:nb_queue(Ref),
	(
	  '$execute'(Generator),
	  nb:nb_queue_enqueue(Ref, Template),
	 fail
	;
	 nb:nb_queue_close(Ref, Answers, SoFar)
	).



% findall_with_key is very similar to findall, but uses the SICStus
% algorithm to guarantee that variables will have the same names.
%
'$findall_with_common_vars'(Template, Generator, Answers) :-
	nb:nb_queue(Ref),
	(
	  '$execute'(Generator),
	  nb:nb_queue_enqueue(Ref, Template),
	  fail
	;
	  nb:nb_queue_close(Ref, Answers, []),
	  '$collect_with_common_vars'(Answers, _)
	).

'$collect_with_common_vars'([], _).
'$collect_with_common_vars'([Key-_|Answers], VarList) :-
	'$variables_in_term'(Key, _, VarList),
	'$collect_with_common_vars'(Answers, VarList).
	
% This is the setof predicate

setof(Template, Generator, Set) :-
	( '$is_list_or_partial_list'(Set) ->
		true
	;
		'$do_error'(type_error(list,Set), setof(Template, Generator, Set))
	),
	'$bagof'(Template, Generator, Bag),
	'$sort'(Bag, Set).

% And this is bagof

% Either we have excess of variables
% and we need to find the solutions for each instantiation
% of these variables

bagof(Template, Generator, Bag) :-
	( '$is_list_or_partial_list'(Bag) ->
		true
	;
		'$do_error'(type_error(list,Bag), bagof(Template, Generator, Bag))
	),
	'$bagof'(Template, Generator, Bag).

'$bagof'(Template, Generator, Bag) :-
	'$free_variables_in_term'(Template^Generator, StrippedGenerator, Key),
	%format('TemplateV=~w v=~w ~w~n',[TemplateV,Key, StrippedGenerator]),
	( Key \== '$' ->
		'$findall_with_common_vars'(Key-Template, StrippedGenerator, Bags0),
		'$keysort'(Bags0, Bags),
		'$pick'(Bags, Key, Bag)
	;
		'$findall'(Template, StrippedGenerator, [], Bag0),
		Bag0 \== [],
		Bag = Bag0
	).


% picks a solution attending to the free variables
'$pick'([K-X|Bags], Key, Bag) :-
	'$parade'(Bags, K, Bag1, Bags1),
	'$decide'(Bags1, [X|Bag1], K, Key, Bag).

'$parade'([K-X|L1], Key, [X|B], L) :- K == Key, !,
	'$parade'(L1, Key, B, L).
'$parade'(L, _, [], L).

%
% The first argument to decide gives if solutions still left;
% The second gives the solution currently found;
% The third gives the free variables that are supposed to be bound;
% The fourth gives the free variables being currently used.
% The fifth  outputs the current solution.
%
'$decide'([], Bag, Key0, Key, Bag) :- !,
	Key0=Key.
'$decide'(_, Bag, Key, Key, Bag).
'$decide'(Bags, _, _, Key, Bag) :-
	'$pick'(Bags, Key, Bag).

% as an alternative to setof you can use the predicate all(Term,Goal,Solutions)
% But this version of all does not allow for repeated answers
% if you want them use findall	

all(T, G same X,S) :- !, all(T same X,G,Sx), '$$produce'(Sx,S,X).
all(T,G,S) :- 
	'$init_db_queue'(Ref),
	( '$catch'(Error,'$clean_findall'(Ref,Error),_),
	  '$execute'(G),
	  '$db_enqueue'(Ref, T),
	  fail
        ;
	  '$$set'(S,Ref)
        ).

% $$set does its best to preserve space
'$$set'(S,R) :- 
       '$$build'(S0,_,R),
        S0 = [_|_],
	S = S0.

'$$build'(Ns,S0,R) :- '$db_dequeue'(R,X), !,
	'$$build2'(Ns,S0,R,X).
'$$build'([],_,_).

'$$build2'([X|Ns],Hash,R,X) :-
	'$$new'(Hash,X), !,
	'$$build'(Ns,Hash,R).
'$$build2'(Ns,Hash,R,_) :-
	'$$build'(Ns,Hash,R).

'$$new'(V,El) :- var(V), !, V = n(_,El,_).
'$$new'(n(R,El0,L),El) :- 
	compare(C,El0,El),
	'$$new'(C,R,L,El).

'$$new'(=,_,_,_) :- !, fail.
'$$new'(<,R,_,El) :- '$$new'(R,El).
'$$new'(>,_,L,El) :- '$$new'(L,El).


'$$produce'([T1 same X1|Tn],S,X) :- '$$split'(Tn,T1,X1,S1,S2),
	( S=[T1|S1], X=X1;
	  !, produce(S2,S,X) ).

'$$split'([],_,_,[],[]).
'$$split'([T same X|Tn],T,X,S1,S2) :- '$$split'(Tn,T,X,S1,S2).
'$$split'([T1 same X|Tn],T,X,[T1|S1],S2) :- '$$split'(Tn,T,X,S1,S2).
'$$split'([T1|Tn],T,X,S1,[T1|S2]) :- '$$split'(Tn,T,X,S1,S2).



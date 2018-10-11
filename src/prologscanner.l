/******************************************************************************
 *
 *
 *
 * copyright487 (C) 1997-2014 by Dimitri van Heesch.
 *
* Permission to use, copy, modify, and distribute this software and its
* documentation under the terms of the GNU General Public License is hereby
 * granted. No representations are made about the suitability of this software
* for any purpose. It is provided "as is" without express or implied warranty.
* See the GNU General Public License for more details.c
 *
 * Documents produced by Doxygen are derivative works derived from the
 * input used in their production; they are not affected by this license.
 *
 */
/*  This code is based on the doxygen python module, initially developed by the MoxyPyDoxy team
 *  (Linda Leong, Mike Rivera, Kim Truong, and Gabriel Estrada)
 *  in Spring 2005 as part of CS 179E: Compiler Design Project
 *  at the University of California, Riverside; the course was
 *  taught by Peter H. Froehlich <phf@acm.org>.
 *
 *  The code was extensively rewritten
 *  by Vitor Santos Costa to
 *  support Prolog.
 */

%option never-interactive
%option prefix="prologscannerYY"


%{

/*
 *	includes
 */
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <ctype.h>

#include <qarray.h>
#include <qstack.h>
#include <qregexp.h>
#include <unistd.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qdir.h>
#include <string.h>

#include "prologscanner.h"
// have access to anchors before Entry
#include "outputgen.h"
#include "entry.h"
#include "message.h"
#include "config.h"
#include "doxygen.h"
#include "util.h"
#include "defargs.h"
#include "language.h"
#include "commentscan.h"
#include "prologcode.h"
#include "arguments.h"

// Toggle for some debugging info
//#define DBG_CTX(x) fprintf x
#define DBG_CTX(x)                                                             \
  do {                                                                         \
  } while (0)

#define YY_NEVER_INTERACTIVE 1
#define YY_NO_INPUT 1

#include "prologf.h"


  //-----------------------------------------------------------------------------
  /* ----------------------------------------------------------------- */
#undef	YY_INPUT
#define	YY_INPUT(buf,result,max_size) result=yyread(buf,max_size);

  static int yyread(char *buf,int max_size)
  {
    int c=0;
    while ( c < max_size && inputString[inputPosition] )
      {
	*buf = inputString[inputPosition++] ;
	c++; buf++;
	}
    return c;
  }

%}

/* start command character */



B                 [ \t]*
BB                [ \t]+



NEWLINE           \n
BN                [ \t\n]
BNS               [ \t\n]*

/* unicode based in the macros for the TXR language, see
   http://stackoverflow.com/questions/9611682/flexlexer-support-for-unicode
   and
   http://www.kylheku.com/cgit/txr/tree/parser

   The idea right now is just to copy them out to the output.
*/

ASC     [\x00-\x7f]
ASCN    [\x00-\t\v-\x7f]
U       [\x80-\xbf]
U2      [\xc2-\xdf]
U3      [\xe0-\xef]
U4      [\xf0-\xf4]

UANY    {ASC}|{U2}{U}|{U3}{U}{U}|{U4}{U}{U}{U}
UANYN   {ASCN}|{U2}{U}|{U3}{U}{U}|{U4}{U}{U}{U}
UONLY   {U2}{U}|{U3}{U}{U}|{U4}{U}{U}{U}


/* Prolog end of term marker */
EOT               {BNS}"."{BN}

DIGIT             [0-9]

HEXD              [0-9a-fA-F]
HEXNUMBER         "0"[xX][0-9a-fA-F]+[lL]?

OCTD              [0-7]
OCTNUMBER         "0"[0-7]+[lL]?
DECNUMBER         {DIGIT}+
CHAR              "0'"(.)

INTNUMBER         {HEXNUMBER}|{OCTNUMBER}|{DECNUMBER}
FLOATNUMBER       {DIGIT}+"."{DIGIT}+([eE][+\-]?{DIGIT}+)?[jJ]?

NUMBER		  [+\-]?({FLOATNUMBER}|{INTNUMBER}|{CHAR})
LETTER            [A-Za-z\x80-\xFF]
NONEMPTY          [A-Za-z0-9_\x80-\xFF]
IDENTIFIER        ([a-z]({LETTER}|{DIGIT}|"_")*)

VAR	          [A-Z_]({LETTER}|{DIGIT}|"_")*

BORDER            ([^A-Za-z0-9])

STRINGCHAR         [^\\"'\n]
ESCAPESEQ          ("\\"[\\n\\abdefnrstvz'"`]|"\\b"{BN}{BNS}|"\\u"{HEXD}+|"\\x"{HEXD}*|"\\"{OCTD}+)
QSTRINGITEM        ({STRINGCHAR}|{ESCAPESEQ}|"''"|"\\'"|"\"")
DQSTRINGITEM       ({STRINGCHAR}|{""|"'")

SQSTRING           ("'"({QSTRINGITEM})*"'")
DQSTRING           ("\""({QSTRINGITEM})*"\"")

SY		   [#&*+\-/:<=>?@\\^`~]
SYNOSTAR	   [#&+.\-/:<=>?@\\^`~]
SYNOSLASH	   [#&+.\-:<=>?@\\^`~]
SYDOT		   [#&*+.\-/:<=>?@\\^`~]

SYMBOL		  ("*"|"/"|{SY}+"."{SYDOT}*|"."{SYDOT}+|"/"{SYNOSTAR}{SYDOT}*|"*"{SYNOSLASH}+|{SYNOSLASH}{SYDOT}*|".")


/* do not treat , and ; as atoms. */
SOLO		  [!]

CMD [@\\][a-zA-z0-9_]+

ATOM		   ({IDENTIFIER}|{SQSTRING}|{SYMBOL}|{SOLO})

NOC	   ({IDENTIFIER}|{SQSTRING})

ATOMIC             ({ATOM}|{VAR}|{NUMBER}|{DQSTRING})


INDICATOR          (({ATOM}":"|"(")?{ATOM}(")")?("/"|"//"){DECNUMBER})

OPDEC		   {IDENTIFIER}"("{BNS}{INTNUMBER}{BNS}","{BNS}{IDENTIFIER}{BNS}","{BNS}("("{BNS})?{ATOM}({BNS}")")?{BNS}")"

META		   {ATOM}"("{BNS}[0-9:?\-+]{BNS}(","{BNS}[0-9:?\-+]{BNS})*{BNS}")"

PATH		   (("/")?{ATOM}("/"{ATOM})*)

LIBRARY		   (({ATOM}"("{BNS}{PATH}{BNS}")")|({PATH}))

FLOWKW             ("spy"|"nospy"|"same"|"block"|"^"|"**"|"\\"|"rem"|"mod"|">>"|"<<"|"//"|"/"|"*"|"xor"|"div"|"rdiv"|"#"|"><"|"\\/"|"/\\"|"-"|"-"|"+"|"+"|":"|"as"|">="|"=<"|">"|"<"|"=\\="|"=:="|"\\=@="|"=@="|"@>="|"@=<"|"@>"|"@<"|"\\=="|"=="|"=.."|"is"|"\\="|"="|"not"|"\\+"|"uncutable"|"table"|"discontiguous"|"module_transparent"|"meta_predicate"|"multifile"|"public"|"mode"|"volatile"|"initialization"|"thread_local"|"dynamic")

PREDTAG               ("det"|"semidet"|"failure"|"nondet"|"multi"|"iso"|"deprecated"|"dynamic"|"directive"|"meta")

PARAMETERDESCRIPTOR   ([+\-?:@!0-9]?{BNS}(({VAR}":"{IDENTIFIER})|{VAR}|{IDENTIFIER}|({BNS}"."+{BNS})+)){BNS}

        /* [+\-?:@!]?{VAR}{BNS}(":"{BNS}{IDENTIFIER})?{BNS} */
VARPARAMETERDESCRIPTOR   [+\-?:@!]?{VAR}{B}*(":"{B}*{IDENTIFIER})?

PREDINFO              (".")?({BB}"is"{BB}{PREDTAG}(".")?({B}","{BB}{PREDTAG}(".")?)*)?{B}

COMPOUND	      {ATOM}"("

%option noyywrap
%option nounput
%option yylineno

%x Search
%x SearchMemVars

			    /* Mid-comment states */

			    /* %x FuncDoubleComment */
			    /* %x ClassDoubleComment */
%x TryClassDocString
%x TripleComment
%x SkipComment
%x SpecialComment
%x SWISpecialComment
%x SpecialLineComment
%x SWISpecialLineComment
%x SWIQuoted
%x SWIInline
%x SWIBold
%x Inline
%x ExtraCommentArgs

			    /* Function states */

%x FunctionDec
%x FunctionParams
%x FunctionBody
%x FunctionParamDefVal
%x CallArgs
%x TakeList
%x HeadOperator
%x Predinfo

			    /* import */
%x Directive
%x ImportList
%x ExportList
%x ReExportList
%x Import
%x Metas

%x DocBlockShortMsg

%x Indicator

%%

			    /* ------------ Indicator recognition rules -------------- */


			    /* ------------ Function recognition rules -------------- */


<Search>{

  {B}+               {
    // just ignore white space
  }

  ":-"{B}        { // start of directive
    g_packageCommentAllowed = FALSE;
    BEGIN( Directive );
  }

  "?-"{B}        { // start of directive
    g_packageCommentAllowed = FALSE;
    BEGIN( Directive );
  }


  {NEWLINE}   {
  }


  ({ATOM}":")?{COMPOUND}{B}	{
    // must be start of a function/clause definition
    searchFoundDef();

    if (current->type.isEmpty())
      {
	current->type = "method";
      }
    current->program = yytext;
    QCString s = yytext;
    s = s.stripWhiteSpace();
    uint len = s.length()-1;
    current->name = s.remove(len,1);
    current_clause = current;
    g_arity = 0;
    g_atCall = true;
    g_argLevel = 1;
    g_callLevel = 1;
    g_defVal = "";
    g_headDone = FALSE;
    g_call = current;
    BEGIN( FunctionParams );
  }


  ({NUMBER}|{VAR})"::"{COMPOUND}{B}     {
    // must be start of a function/clause definition
    searchFoundDef();

    if (current->type.isEmpty())
      {
        current->type = "method";
      }
    current->program = yytext;
    QCString s = yytext;
    s = s.stripWhiteSpace();
    int i = s.find("::");
    s=s.remove(0,i+2);
    uint len = s.length()-1;
    current->name = s.remove(len,1);
    current_clause = current;
    g_arity = 0;
    g_argLevel = g_callLevel = 1;
    g_defVal = "";
    g_headDone = FALSE;
    g_call = current;
    g_atCall = true;
    BEGIN( FunctionParams );
  }



  ({ATOM}":")?{ATOM}{B}":-"  {

    {
      current->type = "method";
    }
    current->program = yytext;
    current->name = QCString( yytext );
    current->name.remove(current->name.length()-2,2);
    current->name = current->name.stripWhiteSpace();
    current->name += " /0";
    newClause(  );
    g_defVal = "";
    g_headDone = TRUE;
    current->bodyLine  = yylineno;
    BEGIN( FunctionBody );
  }

  ({ATOM}":")?{ATOM}{B}"-->"  {

    {
      current->type = "method";
    }
    g_grammar = TRUE;
    current->program = yytext;
    current->name = QCString( yytext );
    current->name.remove(current->name.length()-3,3);
    current->name = current->name.stripWhiteSpace();
        current->name += " /2";
newClause(  );
    g_defVal = "";
    g_headDone = TRUE;
    current->bodyLine  = yylineno;
    BEGIN( FunctionBody );
  }

  ({ATOM}":")?{ATOM}  {
    //found function name, but no arity
    {
      current->type = "method";
    }
    current->program = yytext;
    current->name = QCString( yytext );
    current->name = current->name.stripWhiteSpace();
    current_clause = current;
    g_defVal = "";
    g_headDone = TRUE;
    BEGIN( HeadOperator );
  }

 ({NUMBER}|{VAR})"::"{ATOM}  {
    //found function name, but no arity
    {
      current->type = "method";
    }
    current->program = yytext;
    QCString s = yytext;
    s = s.stripWhiteSpace();
    int i = s.find("::");
    s=s.remove(0,i+2);
    current->name = s;
    current->name += " /0";
    current_clause = current;
    g_defVal = "";
    g_headDone = TRUE;
    BEGIN( HeadOperator );
 }

  {EOT}         {
    g_grammar = FALSE;
  }


 "mod( "{ATOM}" , "{ATOM}" )." {
   QCString pname=yytext;
   pname = pname.stripWhiteSpace();
   pname = pname.remove(0, strlen("mod("));
   pname = pname.remove(pname.length()-3, 3);
   pname = pname.stripWhiteSpace();
   int comma = pname.find(",");
   QCString mod = pname.left(comma).stripWhiteSpace();
   QCString f = pname.right(pname.length()-comma);
   g_prologFileCache.insert( f, qstrdup( mod ) );
   BEGIN(Search);
 }

 {INDICATOR}"  foreign "{ATOM}" at "{PATH}" - "{NUMBER}"." {
   // connect foreign preds
   QCString pname=yytext;
   int fg = pname.find(" foreign ");
    int end = strlen(yytext)-1;
   QCString predName = Pred(pname.left( fg )).name();
   int fge = fg + strlen(" foreign ");
   QCString func = pname.right( end - fge );
   g_foreignCache.insert( predName, qstrdup( func ) );
 }                    

 "sys "{INDICATOR}{EOT} {
   // connect imports
   QCString pname=yytext;
   int fg = strlen("sys ");
   int lim = pname.findRev(".");
   pname = Pred( pname.mid(fg,lim-fg ) ).name();
   g_systemPredTable.insert( pname, qstrdup(pname) );
   BEGIN(Search);
 }

 }

<HeadOperator>{

  {B}":-"    {
    if (!g_headDone) {
      current->name = QCString( "op" );
      g_headDone= TRUE;
    }
    g_grammar = FALSE;
    current->program+=yytext;
    current->bodyLine  = yylineno;
    BEGIN( FunctionBody );
  }

  {B}"-->"    {
    if (!g_headDone) {
      current->name =  "op" ;
      g_headDone= TRUE;
    }
    g_grammar = TRUE;
    current->program+=yytext;
    current->bodyLine  = yylineno;
    BEGIN( FunctionBody );
  }

  {B}{EOT}         {
    // facts
    current->program+=yytext;
    //printf("\nDONE\n %s \n*******\n", current->program.data());
    endOfDef();
    BEGIN(Search);

  }

  \n       {
    current->program+=yytext;
  }

  [^\n]       {
    current->program+=yytext;
    g_defVal += yytext;

  }
 }


<FunctionParams>{

  {COMPOUND}{B}	{
    current->program += yytext;
    if (current_clause && current_clause != current)
      current_clause->program+=yytext;
    g_argLevel++;
    g_defVal += yytext;
  }

  {ATOM} { //
    g_defVal += yytext;
    current->program+=yytext;
    if (current_clause && current_clause != current)
      current_clause->program+=yytext;
  }

  {VAR}|{NUMBER} { //
    g_defVal += yytext;
    current->program+=yytext;
    if (current_clause && current_clause != current)
      current_clause->program+=yytext;
  }

  ","|"|"        {
    current->program+=yytext;
    if (current_clause && current_clause != current)
      current_clause->program+=yytext;
    if (g_argLevel == g_callLevel) {
      Argument *a = new Argument;

      a->name = g_defVal.copy().stripWhiteSpace();
      a->type = "Term";
      a->docs = "";
      g_call->argList->append(a);
      g_defVal = "";
      g_arity ++;
    }
    }

    {B}{EOT} {
    current->program+=yytext;
    if (current_clause) {

     if ( current_clause != current)
      current_clause->program+=yytext;
    if (current_clause->section == Entry::CLAUSE_SEC) {
	endOfDef();
}
 g_argLevel = g_callLevel = 0;
 g_arity = 0;
      BEGIN(Search);
      }

  }

 \n       {
   current->program+=yytext;
   if (current_clause && current_clause != current)
     current_clause->program+=yytext;
  }

  "("|"["|"{" {
    current->program+=yytext;
    if (current_clause && current_clause != current)
      current_clause->program+=yytext;
    // we're outside
    if (g_argLevel == g_callLevel) {
      if (yytext[0] == '(' ||
	  (yytext[0] == '{' && g_grammar)) {
	g_callLevel++;
      }
    }
    g_argLevel++;
  }

  "]"|"}" {
    current->program+=yytext;
    if (current_clause && current_clause != current)
      current_clause->program+=yytext;
    if (g_argLevel > g_callLevel ) {
      g_argLevel--;
      foundTerm();
    } else {
      g_argLevel--;
      g_callLevel--;
      if (g_callLevel == 0) {
	if (g_headDone) {
	  BEGIN( FunctionBody );
	} else {
	  g_headDone = TRUE;
	  BEGIN( HeadOperator );
	}
      }
    }
  }

    ")"{B}/(","|";"|"]"|")"|"}"|"|"|":-"|"-->"|".") {
    current->program+=yytext;
    if (current_clause && current_clause != current)
      current_clause->program+=yytext;
    if (g_argLevel== g_callLevel) {
      g_argLevel--;
      g_callLevel--;
      Argument *a = new Argument;

      a->name = g_defVal.copy().stripWhiteSpace();
      a->type = "Term";
      a->docs = "";
      g_call->argList->append(a);
      g_defVal = "";
      g_arity++;
      if (g_atCall) {

if (g_headDone) {
	  doneCall();
	  BEGIN( FunctionBody );
} else {
	  g_atCall = false;
	  newClause(  );
	  g_headDone = true;
	  BEGIN( HeadOperator );
	}
}
    } else {
      g_argLevel--;
      foundTerm();
    }
  }

")"{B}/[,;\])}] {
  assert ( current_clause );
    current_clause->program+=yytext;
  if (g_argLevel== g_callLevel) {
    g_argLevel--;
    g_callLevel--;
    g_atCall = false;
    if (g_headDone) {
      BEGIN( FunctionBody );
    } else {
      newClause(  );
      BEGIN( HeadOperator );
    }
  } else {
    g_argLevel--;
    foundTerm();
  }
                }

  . {
           assert (current_clause );
        current_clause->program+=yytext;
    }

 }

  <FunctionBody>{

  {EOT}         {
    // end of a rule
    assert (current_clause);
 {
      current_clause->program+=yytext;
      if (current_clause->section == Entry::CLAUSE_SEC) {
	endOfDef();
      }
  g_argLevel = g_callLevel = 0;
 g_arity = 0;
     BEGIN(Search);
    }
  }

  <<EOF>>         {
    // end of a rule
    if (current_clause) {
      endOfDef();
    }
    yyterminate();
  }

  {BB}(^{BB}\n)*	      {   // skip spaces
    current_clause->program+=yytext;
  }

  "->"|"*->"|[{};[\]()]             {
    current_clause->program+=yytext;
  }

  {BB}*(";"|"->"|"->*"){BB}* { //  skip control
   current_clause->program+=yytext;
    // printf( "%p %d %s\n",current, g_headDone,current->program.data());
  }

  {BB}*","{BB}* { //
    g_arity++;
    current_clause->program+=yytext;
    // printf( "%p %d %s\n",current, g_headDone,current->program.data());
  }

   ({ATOM}":")?{ATOM}"(" { // call
     current_clause->program+=yytext;
     g_callLevel++;
     g_argLevel++;
     g_arity = 0;
     g_pName = yytext;
     g_pName.truncate(g_pName.length()-1);
      foundCall( g_pName  );
     current->name = g_pName;
    g_atCall = true;
     BEGIN( FunctionParams );
  }

   ({ATOM}":")?{ATOM} { // call
    current->program=yytext;
    current_clause->program+=yytext;
    g_pName = yytext;
    foundCall(  g_pName );
    g_arity = 0;
    if (strcmp(yytext, "=:="))
      doneCall();
  }

  "[" {
    current_clause->program+=yytext;
  }

   ("("|"{") { //
    current_clause->program+=yytext;

   }

   (")"|"}"|"]") {
    //
    current_clause->program+=yytext;
 }

 \n       {
   current_clause->program+=yytext;
  }

 .       {
   current_clause->program+=yytext;
 }

 }


<Directive>{

  "module("{B}{ATOM}{B}"," {
      // define/ module  ATOM
    QCString modn = strrchr( yytext, '(')+1;
    modn = modn.remove(modn.length()-1,1);
    g_packageName=modn;
    g_new_module = true;
   current_module = createModuleEntry(modn);
current_module_name = current_module->name;
   g_argLevel = 0;
      BEGIN(ExportList);
  }

 "system_module("{B}{ATOM}{B}"," {
      // define/ module  ATOM
    QCString modn = strrchr( yytext, '(')+1;
    modn = modn.remove(modn.length()-1,1);
    modn = modn.stripWhiteSpace();
    g_packageName=modn;
    g_system_module = true;
    modn = "prolog";
    current_module = createModuleEntry(modn);
current_module_name = current_module->name;

    //BEGIN(ExportList);
  }

   "multifile("{B}*{INDICATOR}{B}*")" { // define module  ATOM
      QCString l = yytext;
int beg = l.find('(')+1;
      // never trust yytext
           addPredDecl( l.mid(beg, l.findRev(')')-1-beg) ) ;
  }

   "multifile"{B} { // define module  ATOM
    BEGIN(ExportList);
  }

  "meta_predicate"{B} { // define module  ATOM
  }

  "meta_predicate"{B} { // define module  ATOM
    BEGIN(Metas);
  }

  "use_module("{BNS}{LIBRARY}{BNS}")"{BNS}{EOT} {
    g_packageName=yytext;
    QCString item=g_packageName;
    item = removeRedundantWhiteSpace(sliceArgument(item.data(), ')' ));
    current->name = fileToModule(item);
    //createModuleEntry( current->name );
  //  current_module->addSubEntry( current  );
  //  current->section=Entry::USINGDECL_SEC;
    newEntry();
    BEGIN(Search);
  }


  ("use_module("|"reexport("){BNS}{LIBRARY}{BNS}","{BNS} {
    g_packageName=yytext;
    QCString item=g_packageName;
    item = removeRedundantWhiteSpace(sliceArgument(item.data(), ',' ));
    if (item.find("library(") == 0) item = item.mid(8,item.length()-9).stripWhiteSpace();
    current->name = fileToModule(item);
    //current_module->addSubEntry( current  );
    // current->section=Entry::USINGDECL_SEC;
     newEntry();
    BEGIN(ReExportList);
  }

  ("system_")?"module("{BNS}{ATOM}{BNS}"," { // define module  ATOM
     QCString l = yytext;
   if (l.find("system_module") == 0) {
   g_packageName = yytext;;
 current_module = createModuleEntry("prolog");
    current_module_name = current_module->name;
   
   BEGIN(ImportList);
    } else {
    QCString modn = l.mid( l.find('('),l.find(')'));
    modn = modn.stripWhiteSpace();
    modn = modn.remove(modn.length()-1,1);
    g_packageName=modn;
    //current_module = createModuleEntry(modn);
    //current_module_name = current_module->name;
     // g_new_module = true;
 BEGIN(ExportList);
    }
  }

  "foreign( "{ATOM}":"{INDICATOR}" , "{ATOM}", "{ATOM}" , "{NUMBER}" )"{EOT} {
    QCString pname=yytext;
    pname = pname.stripWhiteSpace();
    pname = pname.remove(0, strlen("foreign_predicate( "));
    int colomn = pname.find(":");
    int slash = pname.find("/", colomn);
    int comma0 = pname.find(" , ", slash);
    int comma1 = pname.find(" , ", comma0+3);
    int comma2 = pname.find(" , ", comma1+3);
    int end = pname.find(" )", comma2+3);
    QCString modName=pname.left(colomn);
    QCString predName=pname.mid(colomn+1, comma0-(colomn+1));
    QCString funcName=pname.mid(comma0+3, comma1-(comma0+3));
    QCString fileName=pname.mid(comma1+3, comma2-(comma1+3));
    Pred p = Pred(modName, predName);
    int line=pname.mid(comma2+3, end-(comma2+3)).toInt();
    current->reset();
    current->name = p.name();
    current->fileName = fileName;
    current->section=Entry::PREDDOC_SEC;
    current->startLine = line;
    current->bodyLine  = line;
    current->artificial  = true;
    Entry *e = predBind( p );
    g_entries->append(e);
    newEntry();
    current->name = funcName;
    current->fileName = fileName;
    current->section=Entry::FUNCTION_SEC;
    current->startLine = line;
    current->bodyLine  = line;
   g_entries->append(current);
   newEntry();
    BEGIN(Search);
  }


  "use_system_module("{B}{LIBRARY}{B}","{B} {
  
    createModuleEntry("prolog");
    BEGIN(ImportList);

  }

  \n		      {
  }

  {EOT}	      {
 g_argLevel = g_callLevel = 0;
 g_arity = 0;
    BEGIN(Search);
  }
"]"?{B}*")"?{B}*{EOT}	      {
    BEGIN(Search);
  }

  [^\n]		      {
  }

 }

<Metas>{

  {META} {
  }

  \n		      {
  }
  ("("|")"|",") {
  }

  {EOT} {
    BEGIN(Search);
}

  [^\n] {
  }

 }

<ImportList>{

  {B}"["{B}  {
    g_argLevel = 1;
  }

  {B}"]"{B}  {
    g_argLevel--;
  }

  {B}","{B}  {
  }

  "_"  {
    /*
      current->name="_";
      current->fileName = yyFileName;

      current->section=Entry::USINGDECL_SEC;
      current_module->removeSubEntry(current);
      current_module->addSubEntry(current);
      current = new Entry ;
      initEntry(current);
    */
    if (g_argLevel > 0) exit(1);
  }

  {INDICATOR}  {
    /* current->name=yytext;
       current->name = current->name.stripWhiteSpace();
       current->fileName = yyFileName;
       current->section=Entry::USINGDECL_SEC;
       current_module->addSubEntry(current);
       newEntry(); */
  }

  \n		{
  }

  {OPDEC}  {
  }

  {B}")"{B}{EOT}		{
    g_grammar = FALSE;
    BEGIN(Search);

  }
 }


<ExportList>{

  {BNS}"]"{BNS}","{BNS}"["{BNS}  {
    if(g_argLevel== 1) {
      g_argLevel = 0;
      BEGIN(Search);
    } else {
      g_argLevel--;
    }
  }

  {BNS}"["{BNS}  {
    g_argLevel += 1;
  }

  {BNS}"]"{BNS}  {
    g_argLevel--;
  }

  {BNS}","{BNS}  {
    /* skip to next entry */
  }

  {INDICATOR}  {
      QCString l = yytext;
      // never trust yytext
           addPredDecl( l );
     }


  {OPDEC}  {
  }

  "-" {
 }

  {FLOWKW} {
}

  \n		{
  }

  {B}")"{EOT}		{

    BEGIN(Search);
  }

  {B}")"           {
    g_argLevel--;

  }


{B}{EOT}		{
    g_grammar = FALSE;
    BEGIN(Search);
  }

 }



<ReExportList>{

  {BNS}"]"{BNS}","{BNS}"["{BNS}  {
    if(g_argLevel== 1) {
      g_argLevel = 0;
      BEGIN(Search);
    } else {
      g_argLevel--;
    }
  }

  {BNS}"["{BNS}  {
    g_argLevel += 1;
  }

  {BNS}"]"{BNS}  {
    g_argLevel--;
  }

  {BNS}","{BNS}  {
    /* skip to next entry */
  }

  {INDICATOR}  {
      QCString l = yytext;
      // never trust yytext
           addPredDecl( l );
     }

  {INDICATOR}{B}+"as"{B}+{ATOM}  {
      QCString om, on, key;
      uint arity;
      QCString l = yytext;
      // never trust yytext
      int l0 = l.find("//");
      if (l0 < 0) {
      l0 = l.find("/");
      }
      int l1 = l.find(" ");
      QCString a = l.mid(l1-l0-1);
      QCString n =  l.right(l.length()-l.findRev(' '));
           addPredDecl( n+"/"+a );
     }


  {OPDEC}  {
  }

  "-" {
 }

  {FLOWKW} {
}

  \n		{
  }

  {B}")"{EOT}		{

    BEGIN(Search);
  }

  {B}")"           {
    g_argLevel--;

  }


{B}{EOT}		{
    g_grammar = FALSE;
    BEGIN(Search);
  }

 }



<Indicator>{

    {B}{ATOM}{B}":" {
    // notice that the first rule may match
    // several times.
        ind_mod = QCString(yytext, strlen(yytext)-1);
        ind_mod.stripWhiteSpace();
    }

    {B}{ATOM} {
        ind_name = yytext;
        ind_name.stripWhiteSpace();
        if (ind_name[0] == '\'' &&
            ind_name[ind_name.length()-1] == '\'')
            ind_name = ind_name.mid(1, ind_name.length()-2);
    }

    {B}"/"{B}{INTNUMBER} {
        ind_arity = yytext;
        ind_arity.stripWhiteSpace();
            ind_arity.remove(0,1);
        ind_arity.stripWhiteSpace();
    }

{B} {
     }
<<EOF>>   { yyterminate(); }
}


  /* ------------ Default rules -------------- */


<*>"/*"([^*]|("*"+[^*/]))*"*"+"/" {
    if ((yytext[2] == '*' || yytext[2] == '!') &&
       (yytext[3] == ' ' || yytext[3] == '\t' || yytext[3] == '\n')
    ) {
        if ( prepComment( yytext, docBrief, true) ) {
            startCommentBlock( docBrief );
//            fprintf(stderr,"*****? %s\n", docBlock.data());
            handleCommentBlock(docBlock, docBrief);
        }
    }
}

<*>"%".*"\n"("%".*"\n"|[ \t]+"\n")* {
    if ((yytext[1] == '%' || yytext[1] == '!') &&
       (yytext[2] == ' ' || yytext[2] == '\t' || yytext[2] == '\n')
    ) {
        if ( prepComment( yytext, docBrief,false) ) {
            startCommentBlock( docBrief );
//            fprintf(stderr,"*****? %s\n", docBlock.data());
            handleCommentBlock(docBlock, docBrief);
        }
    }
}

<*>{UONLY} {
    if (current) {
      current->program+=yytext;
      g_defVal += yytext;
    }
  }

<FunctionParams,FunctionBody,TakeList>{ATOMIC}	{
    if (current) {
      current->program+=yytext;
      g_defVal += yytext;
    }
  }


<<EOF>>	      {
   yyterminate();
 }

<Search,FunctionParams,FunctionBody,HeadOperator,TakeList,Directive,ImportList,ExportList>{BB}	      {   // skip spaces quickly
  if (current) {
    current->program+=yytext;
    g_defVal += yytext;
  }
 }

 <*>[\x00]/([^\n]|"\n") {
 /* yes, it happens */ }

%%

static bool innerParse(const QCString text, int Lab)
{
  //printf("**** parsePrototype(%s) begin\n",text.data());
  if (text.isEmpty())
    {
      warn(yyFileName,yylineno,"Empty prototype found!");
      return false;
    }
  int start = YY_START;
  g_specialBlock = false;
  g_packageCommentAllowed = FALSE;

  const char *orgInputString;
  int orgInputPosition;

  // save scanner state
  YY_BUFFER_STATE orgState = YY_CURRENT_BUFFER;
  yy_switch_to_buffer(yy_create_buffer(prologscannerYYin, YY_BUF_SIZE));
  orgInputString = inputString;
  orgInputPosition = inputPosition;

  // set new string
  inputString = text;
  inputPosition = 0;
  prologscannerYYrestart( prologscannerYYin );

  BEGIN( Lab );

  prologscannerYYlex();
  g_lexInit=TRUE;

  if (Lab == FunctionDec ) {
    current->name = current->name.stripWhiteSpace();
    if (current->section == Entry::MEMBERDOC_SEC && current->args.isEmpty())
      current->section = Entry::VARIABLEDOC_SEC;
  }
  // restore original scanner state

  YY_BUFFER_STATE tmpBuf = YY_CURRENT_BUFFER;
  if (orgState) {
    yy_switch_to_buffer(orgState);
  }
  yy_delete_buffer(tmpBuf);

  inputString = orgInputString;
  inputPosition = orgInputPosition;
  BEGIN( start );
  //printf("**** parsePrototype end\n");
   return true;
}

static void parsePrototype(const QCString &text) {
    innerParse( text, FunctionDec);
}

//----------------------------------------------------------------------------

void prologscanFreeScanner()
{
#if defined(YY_FLEX_SUBMINOR_VERSION)
  if (g_lexInit)
    {
      prologscannerYYlex_destroy();
    }
#endif
}

#define DEBUG_ALL 0

#if DEBUG_ALL
static void
  showScannerNode( uint off, Entry *ce , bool show) {
  const char * s;
  if (show && ce->brief.data()) {
    printf("        brief=[line=%d\n%s]\n", ce->briefLine,ce->brief.data());
  }
  if (show && ce->doc.data()) {
    printf("        docs=[line=%d\n%s]\n", ce->docLine,ce->doc.data());
  }
  if (show && ce->inbodyDocs.data()) {
    printf("        inbody=[line=%d\n%s]\n", ce->inbodyLine,ce->inbodyDocs.data());
      }
  switch (ce->section) {
  case Entry::CLASS_SEC:
  if (ce->spec == ClassDef::Predicate) s = "PREDICATE_SEC";
  else
    s = "CLASS_SEC";
    break;
   case Entry::PREDICATE_SEC:
      s = "PREDICATE_SEC";
      break;
  case Entry::NAMESPACE_SEC:
    s = "NAMESPACE_SEC";
    break;
  case Entry::CLASSDOC_SEC:
    s = "CLASSDOC_SEC";
    break;
  case Entry::PREDDOC_SEC:
    s = "PREDDOC_SEC";
    ce->protection = Public;
    break;
  case Entry::STRUCTDOC_SEC:
    s = "STRUCTDOC_SEC";
    break;
  case Entry::UNIONDOC_SEC:
    s = "UNIONDOC_SEC";
    break;
  case Entry::EXCEPTIONDOC_SEC:
    s = "EXCEPTIONDOC_SEC";
    break;
  case Entry::NAMESPACEDOC_SEC:
    s = "NAMESPACEDOC_SEC";
    break;
  case Entry::INTERFACEDOC_SEC:
    s = "INTERFACEDOC_SEC";
    break;
  case Entry::PROTOCOLDOC_SEC:
    s = "PROTOCOLDOC_SEC";
    break;
  case Entry::CATEGORYDOC_SEC:
    s = "CATEGORYDOC_SEC";
    break;
  case Entry::SERVICEDOC_SEC:
    s = "SERVICEDOC_SEC";
    break;
  case Entry::SINGLETONDOC_SEC:
    s = "SINGLETONDOC_SEC";
    break;
  case Entry::SOURCE_SEC:
    s = "SOURCE_SEC";
    break;
  case Entry::HEADER_SEC:
    s = "HEADER_SEC";
    break;
  case Entry::ENUMDOC_SEC:
    s = "ENUMDOC_SEC";
    break;
  case Entry::ENUM_SEC:
    s = "ENUM_SEC";
    break;
  case Entry::EMPTY_SEC:
    s = "EMPTY_SEC";
    break;
  case Entry::PAGEDOC_SEC:
    s = "PAGEDOC_SEC";
    break;
  case Entry::VARIABLE_SEC:
    s = "VARIABLE_SEC";
    break;
  case Entry::FUNCTION_SEC:
    s = "FUNCTION_SEC";
    break;
  case Entry::TYPEDEF_SEC:
    s = "TYPEDEF_SEC";
    break;
  case Entry::MEMBERDOC_SEC:
    s = "MEMBERDOC_SEC";
    break;
  case Entry::OVERLOADDOC_SEC:
    s = "OVERLOADDOC_SEC";
    break;
  case Entry::EXAMPLE_SEC:
    s = "EXAMPLE_SEC";
    break;
  case Entry::VARIABLEDOC_SEC:
    s = "VARIABLEDOC_SEC";
    break;
  case Entry::FILEDOC_SEC:
    s = "FILEDOC_SEC";
    break;
  case Entry::DEFINEDOC_SEC:
    s = "DEFINEDOC_SEC";
    break;
  case Entry::INCLUDE_SEC:
    s = "INCLUDE_SEC";
    break;
  case Entry::DEFINE_SEC:
    s = "DEFINE_SEC";
    break;
  case Entry::GROUPDOC_SEC:
    s = "GROUPDOC_SEC";
    break;
  case Entry::USINGDIR_SEC:
    s = "USINGDIR_SEC";
    break;
  case Entry::MAINPAGEDOC_SEC:
    s = "MAINPAGEDOC_SEC";
    break;
  case Entry::MEMBERGRP_SEC:
    s = "MEMBERGRP_SEC";
    break;
  case Entry::USINGDECL_SEC:
    s = "USINGDECL_SEC";
    break;
  case Entry::PACKAGE_SEC:
    s = "PACKAGE_SEC";
    break;
  case Entry::PACKAGEDOC_SEC:
    s = "PACKAGEDOC_SEC";
    break;
  case Entry::OBJCIMPL_SEC:
    s = "OBJCIMPL_SEC";
    break;
  case Entry::DIRDOC_SEC:
    s = "DIRDOC_SEC";
    break;
/*  case Entry::EXPORTED_INTERFACE_SEC:
    s = "EXPORTED_INTERFACE";
v    break;
*/
  case Entry::INCLUDED_SERVICE_SEC:
    s = "INCLUDED_SERVICE";
    break;
  case Entry::CLAUSE_SEC:
    s = "CLAUSE_SEC";
    break;
  }
  if ( ! ce->parent() )
    fprintf(stderr,"%*s (%d) -> %s %d\n",off+20, s, (ce->protection == Public ? 1 : 0), ce->name.data(), ce->mGrpId /*, ce->program.data() */);
  else
    fprintf(stderr,"%*s (%d) -> %s %d\n",off+20, s, (ce->protection == Public ? 1 : 0), ce->name.data(), ce->mGrpId /*, ce->program.data() */);
}
#endif

void
showScannerTree(uint off, Entry *current) {
#if DEBUG_ALL
  //return;
  showScannerNode( off, current, true );
  EntryListIterator eli(*current->children());
  Entry *ce;
  for (;(ce=eli.current());++eli)
    {
      if (ce->parent() != current ) {
	printf("UGH %p %p instead of %p\n", ce , ce->parent(), current );
      }
      showScannerTree(off+4, eli);
    }
#endif
}


//----------------------------------------------------------------------------

void PrologLanguageScanner::parseInput(const char *fileName,
                                       const char *fileBuf,
                                       Entry *root,
                                       bool /*sameTranslationUnit*/,
                                       QStrList & /*filesInSameTranslationUnit*/)
{
  g_thisParser = this;
  g_predNameCache.clear();
  g_moduleEntryCache.clear();
  Entry *oc = current_module;
 printlex(yy_flex_debug, TRUE, __FILE__, fileName);
  ::parseMain(fileName,fileBuf,root);

   showScannerTree(0, root);
  printlex(yy_flex_debug, FALSE, __FILE__, fileName);

  //      delete current_module;
  if (oc) current_module=oc;
  // May print the AST for debugging purposes
  // printAST(global_root);

 }

bool PrologLanguageScanner::needsPreprocessing(const QCString &)
{
  return FALSE;
}

void PrologLanguageScanner::parseCode(CodeOutputInterface &codeOutIntf,
				      const char *scopeName,
				      const QCString &input,
				      SrcLangExt /*lang*/,
				      bool isExampleBlock,
				      const char *exampleName,
				      FileDef *fileDef,
				      int startLine,
				      int endLine,
				      bool inlineFragment,
				      MemberDef *memberDef,
				      bool showLineNumbers,
				      Definition *searchCtx,
				      bool collectXRefs
				      )
{
  ::parsePrologCode(codeOutIntf,scopeName,input,isExampleBlock,exampleName,
                    fileDef,startLine,endLine,inlineFragment,memberDef,
                    showLineNumbers,searchCtx,collectXRefs);
}

static void parseMain(const char *fileName,const char *fileBuf,Entry *rt)
{
    Entry *e, *pl;
       g_entries = new EntryList();
 initParser();

  inputString = fileBuf;
  inputPosition = 0;

  protection    = Private;
  mtype         = Method;
  gstat         = false;
  virt          = Normal;
  g_specialBlock = false;
  g_SWIStyle = false;
  g_system_module = false;
  g_new_module = false;

  inputFile.setName(fileName);
  if (inputFile.open(IO_ReadOnly))
    {
      yylineno= 1 ;
      yyFileName = fileName;
      //setContext();
      msg("Parsing file %s...\n",yyFileName.data());

    current_root  = rt;
  current       = new Entry;
   {
      current->name    = yyFileName;
      current->section =Entry::SOURCE_SEC;
      g_entries->append(current);
      current          = new Entry;
    }
       current->reset();
    initEntry( current );
    e = current_module;
    pl =  current_module = createModuleEntry("prolog");
current_module_name = current_module->name;
  current_predicate = 0;
  current_clause=0;

         initParser();
    groupEnterFile(yyFileName,yylineno);

       prologscannerYYrestart( prologscannerYYin );
      BEGIN( Search );
      prologscannerYYlex();
      g_lexInit=TRUE;

current_module = pl;
 if (current_module)
 current_module_name =  current_module->name;
     if (current_root  == 0);
  //showScannerNode( off, current, true );
  EntryListIterator eli(*g_entries);
  Entry *ce;
  for (;(ce=eli.current());++eli)
    {  
      if (ce->section != Entry::USINGDECL_SEC) {
     current_root->addSubEntry(ce);
       ce->setParent(current_root);

      }
    }
    //  showScannerTree(off+4, eli);
    // current_root      = new Entry;
    //   QDictIterator<Entry> di(g_moduleEntryCache);
    // Entry *e;
    // for (;(e=di.current());++di)
    // {
    //   e->setParent(current_root);
    //   current_root->addSubEntry(e);
    // }
    groupLeaveFile(yyFileName,yylineno);

      current_root->program.resize(0);
      current = 0;
      current_root = 0;
      g_firstCall = false;
      g_entries = 0;

      //    parseCompounds(current_root);

      inputFile.close();
    }

}

void PrologLanguageScanner::parsePrototype(const char *text)
{
  ::parsePrototype(text);

}

void PrologLanguageScanner::resetCodeParserState()
{
  ::resetPrologCodeParserState();
}

//----------------------------------------------------------------------------

#if !defined(YY_FLEX_SUBMINOR_VERSION)
//----------------------------------------------------------------------------
 extern "C" { // some bogus code to keep the compiler happy
  void prologscannerYYdummy() { yy_flex_realloc(0,0); }
}
#endif

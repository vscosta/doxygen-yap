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

SY		   [#&*+\-/:<=>?@\\\^`~]
SYNOSTAR	   [#&+.\-/:<=>?@\\\^`~]
SYNOSLASH	   [#&+.\-:<=>?@\\\^`~]
SYDOT		   [#&*+.\-/:<=>?@\\\^`~]

SYMBOL		  ("*"|"/"|{SY}+"."{SYDOT}*|"."{SYDOT}+|"/"{SYNOSTAR}{SYDOT}*|"*"{SYNOSLASH}+|{SYNOSLASH}{SYDOT}*|".")


/* do not treat , and ; as atoms. */
SOLO		  [!]

CMD [@\\][a-zA-z0-9_]+

ATOM		   ({IDENTIFIER}|{SQSTRING}|{SYMBOL}|{SOLO})

NOC	   ({IDENTIFIER}|{SQSTRING})

ATOMIC             ({ATOM}|{VAR}|{NUMBER}|{DQSTRING})


INDICATOR          (({ATOM}":")*("("{ATOM}")"|{ATOM})("/"|"//"){DECNUMBER})

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
%x SkipCode
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
%x PrepareExportList
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

  {B}               {
    // just ignore white space
  }

  {NEWLINE}   {
  }

{ATOM}":"/[^-] {
QCString s = yytext;
s = s.left(s.length()-1);
 
g_text += yytext;
if (g_clause.q.size()) {
if(g_clause.q.back().t <= Literal::PL_INNER_SQB) {
    Literal *l = new Literal(Literal::PL_ENTER_MODULE,g_source_module,s,0);
g_clause.q.push_back(*l);
}
g_source_module =s;
}
// can safely ignore.

}


 {B}"$"?{ATOM}("."({ATOM}|{VAR}))*("("|"["|"{"){B}	{
     QCString s = yytext;
     bool done = false;
     Literal::token_t tag;
     s = s.stripWhiteSpace();
     uint len = s.length()-1;
     s = s.remove(len,1);
     if ( g_clause.q.empty() && g_clause.state == Clause::CLI_DIRECTIVE) {
	 if ( s == "module" || s=="system_module") {
	     BEGIN(ExportList);
	 } else { 
	     BEGIN(SkipCode);

	 }
     } else {
	 if (g_clause.q.empty() && g_clause.state == Clause::CLI_NONE) {
	     searchFoundDef();
	     g_clause.state =Clause::CLI_HEAD;
	 }
     }
     if (!done) {
	 if (  g_clause.q.empty()  || g_clause.q.back().t < Literal::PL_ENTER_COMPOUND) {
	     tag = Literal::PL_ENTER_GOAL;
	     current->program = yytext;
	 } else {
	     tag = Literal::PL_ENTER_COMPOUND;
	     current->program += yytext;
	 }
	 Literal l = *new Literal(tag, g_source_module.copy(), s.copy(), 1);
	 if (g_clause.state == Clause::CLI_NONE)
	     g_clause.state = Clause::CLI_HEAD;
	 else if (g_clause.state == Clause::CLI_NECK)
	     g_clause.state = Clause::CLI_BODY;
	 g_clause.q.push_back(l);
     }

 }


 {B}(":-"|"-->"|"->"|";"|"|"){B} {
     // must be start of a function/clause definition
     QCString s = yytext;
     s = s.stripWhiteSpace();
     bool done = false;
     while (g_clause.q.size() &&
            g_clause.q.back().t <= Literal::PL_GOAL) 
	 g_clause.q.pop_back();
     current->program += yytext;
     if (g_clause.state == Clause::CLI_NONE && g_clause.q.empty() && s == ":-") {
	 g_clause.state = Clause::CLI_DIRECTIVE;
	 done = true;
     } else if ( !g_clause.q.size()) {
	 done = true;
     }
     if (!done) {
	 Literal l = g_clause.q.back();
	 if ((s==":-" || s=="-->" ) &&g_clause.state == Clause::CLI_NECK) {
	     g_clause.state = Clause::CLI_BODY;
	     if (s == "-->") l.a += 2;

	     g_clause.m = l.m.copy();
	     g_arity = g_clause.a = l.a;
	     g_pName = g_clause.n =(l.n.copy());
	     g_clause.state = Clause::CLI_BODY;
	     g_clause.q.pop_back();
	 } else if (s==',') {
size_t n = g_clause.q.size();
	     g_clause.q[n-1].a = l.a+1;
	 }
     }     
 }   
 
	
 {B}(","){B} {
     // must be start of a function/clause definition
     QCString s = yytext;
     s = s.stripWhiteSpace();
     while (g_clause.q.size() &&
            g_clause.q.back().t <= Literal::PL_GOAL&&
            g_clause.q.back().t <= Literal::PL_GOAL>= 0) 
	 g_clause.q.pop_back();
size_t n = g_clause.q.size();
if (n)
	     g_clause.q[n-1].a++;
	 }
 				

{B}("("|"["|"{"){B} {
    QCString s = yytext;
    s = s.stripWhiteSpace();

Literal::token_t tag;
			     if (g_clause.q.empty() ||
                                g_clause.q.back().t <= Literal::PL_ENTER_COMPOUND) {
     if ( s == "(")  tag = Literal::PL_INNER_BRA ;
     else if (	     s == "[" )  tag = Literal::PL_INNER_SQB ;
		     else tag = Literal::PL_INNER_CRB;
			     } else {

     if ( s == "(")  tag = Literal::PL_ENTER_BRA ;
     else if (	     s == "[")   tag = Literal::PL_ENTER_SQB ;
		     else tag = Literal::PL_ENTER_CRB;
			     }
 g_clause.q.push_back(* new Literal(tag,g_source_module.copy(),s.copy(),0));
			 }

{B}(")"|"]"|"}"){B} {
Literal::token_t tag;
	 while (g_clause.q.size() && g_clause.q.back().t <= Literal::PL_GOAL) 
            g_clause.q.pop_back();
if (g_clause.q.size()) {
Literal l = g_clause.q.back();
    if (l.t == Literal::PL_ENTER_GOAL) {
	if (g_clause.state == Clause::CLI_HEAD &&
	    g_clause.q.size() == 1) {
	g_clause.m = l.m.copy();
	g_arity = g_clause.a = l.a;
	g_pName = g_clause.n = (l.n.copy());
	g_clause.state = Clause::CLI_NECK;
}
	g_clause.q.pop_back();
		}
    int n = g_clause.q.size();
if (n)		g_clause.q[n-1].t = tag;
}
}

 ":-"{B}*"reexport("{B}{LIBRARY}{B}","{BNS} {
Literal::token_t tag;
    g_packageName=yytext;
    QCString item=g_packageName;
    item = removeRedundantWhiteSpace(sliceArgument(item.data(), ',' ));
    if (item.find("library(") == 0) item = item.mid(8,item.length()-9).stripWhiteSpace();
    current->name = fileToModule(item);
     BEGIN(ExportList);
  }


  ":-"{B}*"private(" { // define module  ATOM
       QCString l = yytext;
      protection = Private;
     BEGIN(ExportList);
      }


  ":-"{B}*"meta_predicate" { // define module  ATOM
       QCString l = yytext;
      protection = Private;
     BEGIN(SkipCode);
      }



  ":-"{B}*"op(" { // define module  ATOM
       QCString l = yytext;
      protection = Private;
     BEGIN(SkipCode);
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
    Pred p = Pred( predName);
    int line=pname.mid(comma2+3, end-(comma2+3)).toInt();
    current->reset();
    current->name = p.predName();
    current->fileName = fileName;
    current->section=Entry::CLASSDOC_SEC;
    current->startLine = line;
    current->bodyLine  = line;
    current->artificial  = true;
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



  ({NUMBER}|{VAR})"::"   {
     current->program+=yytext;
 
  }




  {ATOM}  {
QCString s = yytext;
     current->program+=s;
     g_clause.q.push_back(* new Literal(Literal::PL_ATOM,g_source_module.copy(), s.copy(),0));
  }

 ({NUMBER}|{VAR}|{DQSTRING}) {
QCString s = yytext;
     current->program+=s;
     g_clause.q.push_back(* new Literal(Literal::PL_ATOMIC,g_source_module.copy(), s.copy(),0));
}

		{EOT} {
    current->program+=yytext;
   newClause();
g_clause.reset();
	}


		{B}|\n {

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
    g_clause.reset();
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

<SkipCode>{
 [^%/.]*{EOT}         {
     g_clause.reset();
     BEGIN(Search);
 }
"/"[^*] {
}

 [^.%/]*\n       {
  }
}


<Metas>{

  {META} {
  }

\n {}

  ("("|")"|",") {
  }

  {EOT} {
    BEGIN(Search);
}

  [^\n] {
  }

 }


<SkipCode>{
 [^/%.'`"]*{EOT}         {
     BEGIN(Search);
 }

 [^/%."`']+\n       {
  }

"/"[^*] {}

		{SQSTRING} {}

}1

<ExportList>{

    {ATOM}{B}","{B}"["{B} {
	QCString s = yytext;
	s = s.left(s.findRev("[")-1).stripWhiteSpace();
	if (g_pName == "module") {
	    createModuleEntry(s);
		 current_module = g_source_module = s;
	    } else /*if (s == "system_module")*/ {
		 current_module = g_source_module = "prolog";
	    }
    }



    
  {BNS}"]"{BNS}  {
      BEGIN(SkipCode);
  }

  {BNS}","{BNS}  {
    /* skip to next entry */
  }

  {INDICATOR}  {
      QCString l = yytext;
      yyless(0);
      BEGIN(Indicator);
      }

  {B}+"as"{B}+{ATOM}  {
  QCString l = yytext;
  l = l.stripWhiteSpace();
  l = l.right(l.length()-2).stripWhiteSpace();
            // addPredDecl( g_source_module, l, ind_arity.toUInt() );
         }


  {OPDEC}  {
  }

  "-" {
 }

  {FLOWKW} {
}

  \n		{
  }

  {B}")"{EOT}		{   BEGIN(Search);
  }


		{EOT}		{
    BEGIN(Search);
  }

 }



<Indicator>{

    {B}*{ATOM}{B}*":"/[^-] {
    // notice that the first rule may match
    // several times.
        QCString ind_mod = QCString(yytext, strlen(yytext)-1);
        ind_mod.stripWhiteSpace();
g_source_module =  ind_mod;
    }

    {B}*{ATOM} {
        ind_name = yytext;
        ind_name.stripWhiteSpace();
        if (ind_name[0] == '\'' &&
            ind_name[ind_name.length()-1] == '\'')
            ind_name = ind_name.mid(1, ind_name.length()-2);
    }

   {B}*"("{B}*{ATOM}{B}*")" {
        ind_name = yytext;
        ind_name.stripWhiteSpace();
        if (ind_name[0] == '\'' &&
            ind_name[ind_name.length()-1] == '\'')
            ind_name = ind_name.mid(1, ind_name.length()-2);
    }

    "/"{B}{INTNUMBER} {
        ind_arity = yytext;
        ind_arity.stripWhiteSpace();
            ind_arity=ind_arity.right(ind_arity.length()-1);
        ind_arity.stripWhiteSpace();
      
           addPredDecl(g_source_module+":"+ind_name+
"/"+ind_arity );
BEGIN(ExportList);
    }

    "//"{B}{INTNUMBER} {
        ind_arity = yytext;
        ind_arity.stripWhiteSpace();
            ind_arity=ind_arity.right(ind_arity.length()-2);
        ind_arity.stripWhiteSpace();
           addPredDecl(g_source_module+":"+ind_name+
"/"+ind_arity);
BEGIN(ExportList);        
      }

{B}+ {
     }

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
  BEGIN(Search);
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
  BEGIN(Search);
}


<FunctionBody,TakeList>{ATOMIC}	{
    if (current) {
      current->program+=yytext;
      g_defVal += yytext;
    }

 }

<Search,FunctionBody,HeadOperator,TakeList,Directive,SkipCode,ExportList>{BB}	      {   // skip spaces quickly
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
  case Entry::NAMESPACE_SEC:
    s = "NAMESPACE_SEC";
    break;
  case Entry::CLASSDOC_SEC:
    s = "CLASSDOC_SEC";
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
  case Entry::DIRDOC_SEC:
    s = "DIRDOC_SEC";
    break;
/*  case Entry::EXPORTED_INTERFACE_SEC:
    s = "EXPORTED_INTERFACE";
    break;
*/
  case Entry::INCLUDED_SERVICE_SEC:
    s = "INCLUDED_SERVICE";
    break;
   }
  if ( ! ce->parent() )
    fprintf(stderr,"%*s (%d) -> %s %d\n",off+20, s, (ce->protection == Public ? 1 : 0), ce->name.data(), ce->mGrpId /*, ce->program.data() */);
  else
    fprintf(stderr,"%*s (%d) -> %s %d\n",off+20, s, (ce->protection == Public ? 1 : 0), ce->name.data(), ce->mGrpId /*, ce->program.data() */);
}


void
showScannerTree(uint off, Entry *current) {
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
}


//----------------------------------------------------------------------------

void PrologLanguageScanner::parseInput(const char *fileName,
                                       const char *fileBuf,
                                       Entry *root,
                                       bool /*sameTranslationUnit*/,
                                       QStrList & /*filesInSameTranslationUnit*/)
{
  g_thisParser = this;
    QCString oc = current_module;
 printlex(yy_flex_debug, TRUE, __FILE__, fileName);
  ::parseMain(fileName,fileBuf,root);
#if DEBUG_ALL
   showScannerTree(0, root);
#endif
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

static void parseMain(const char *fileName,const char *fileBuf,Entry *rt)
{
    Entry *e, *pl;
  initParser();
 int off = 4;

  inputString = fileBuf;
  inputPosition = 0;

  protection    = Public;
  mtype         = Method;
  gstat         = false;
  virt          = Normal;
  g_specialBlock = false;
  g_SWIStyle = false;
  g_system_module = false;
  g_new_module = false;
   current_predicate = 0;
   g_clause.reset();
  current_root = rt;

  inputFile.setName(fileName);
  if (inputFile.open(IO_ReadOnly))
    {
      yylineno= 1 ;
      QCString yyFileName = fileName;
      //setContext();
      msg("Parsing file %s...\n",yyFileName.data());
    Doxygen::docGroup.enterFile(yyFileName,yylineno);
    current            = new Entry;
    current->name      = "prolog";
    current->section   = Entry::NAMESPACE_SEC;
    current->type      = "namespace";
    current->fileName  = yyFileName;
    current->startLine = yylineno;
    current->bodyLine  = yylineno;
g_source_module = current_module = "prolog";
 g_clause.reset();
 initParser();
    newEntry();



       prologscannerYYrestart( prologscannerYYin );
      BEGIN( Search );
      prologscannerYYlex();
      g_lexInit=TRUE;

      // current_root      = new Entry;
    //   QDictIterator<Entry> di(g_moduleEntryCache);
    // Entry *e;
    // for (;(e=di.current());++di)
    // {
    //   e->setParent(current_root);
    //   current_root->addSubEntry(e);
    // }





    Doxygen::docGroup.leaveFile(yyFileName,yylineno);

      current_root->program.resize(0);
      current = 0;
      current_root = 0;
      current_module = 0;
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



void PrologLanguageScanner::parseCode(CodeOutputInterface &codeOutIntf,
    const char *scopeName,
    const QCString &input,
    SrcLangExt lang,
    bool isExampleBlock,
    const char *exampleName,
    FileDef *fileDef,
    int startLine,
    int endLine,
    bool inlineFragment,
    const MemberDef *memberDef,
    bool showLineNumbers,
    const Definition *searchCtx,
    bool collectXRefs
    )
{
    ::parsePrologCode(codeOutIntf,scopeName,input,lang,isExampleBlock,exampleName,
                    fileDef,startLine,endLine,inlineFragment,memberDef,
                    showLineNumbers,searchCtx,collectXRefs);
}

//----------------------------------------------------------------------------

#if !defined(YY_FLEX_SUBMINOR_VERSION)
//----------------------------------------------------------------------------
 extern "C" { // some bogus code to keep the compiler happy
  void prologscannerYYdummy() { yy_flex_realloc(0,0); }
}
#endif


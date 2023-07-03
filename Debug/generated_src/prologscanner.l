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
`x * See the GNU General Public License for more details.c
 *
 * Documents produced by Doxygen are derivative works derived from the
 * input used in their production; they are not affected by this license.
 *
 */
/*  This code is based on the doxygen Prolog module, initially developed by the MoxyPyDoxy team
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
%option reentrant
%option extra-type="struct prologscannerYY_state *"
%top{
#include <stdint.h>
}


%{

    /*
     *	includes
     */
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <ctype.h>

#include <string>

    // have access to anchors before Entry

    class Pred;

#include "outputgen.h"
#include "entry.h"
#include "fileinfo.h"
#include "dir.h"
#include "message.h"
#include "config.h"
#include "doxygen.h"
#include "util.h"
#include "defargs.h"
#include "language.h"
#include "commentscan.h"
#include "prologscanner.h"
#include "prologcode.h"
#include "arguments.h"
#include "markdown.h"
#include <deque>

    /* -----------------------------------------------------------------
     *
     * static
     */

#include "entry.h"
#include "groupdef.h"
#include "membergroup.h"
#include "debug.h"
#include "qcstring.h"
#include "prolog.h"

#define YY_NO_INPUT 1
#define YY_NO_UNISTD_H 1

#define USE_STATE2STRING 0

    struct prologscannerYY_state
    {
	prologscannerYY_state()  {}
	CommentScanner          commentScanner;
	OutlineParserInterface *thisParser = 0;
	const char *inputString = 0;
	yy_size_t inputPosition = 0;
	int ignore;

	Protection protection;

	std::shared_ptr<Entry> current_root;
	std::shared_ptr<Entry> current_comment;
std::shared_ptr<Entry> current;
std::shared_ptr<Entry> previous;
	std::shared_ptr<Entry> bodyEntry;
	int yyLineCms = 0;
	QCString yyFileName;
	int yyLineNr;
	EntryList *entries = 0;
	MethodTypes mtype;
	bool stat;
	QCString text, ind_name;
QCString ind_arity, ind_mod;
	Specifier virt;
	bool system_module;
	bool new_module;
    int docBlockContext = 0;
	int savedDocBlockOuter;
	int savedDocBlockInner;
	QCString docBlock, docBlockSpecial;
	QCString docBlockName;
	bool docBlockInBody;
	bool docBlockJavaStyle;
	bool docBrief;

	QCString docComment;

	bool specialBlock;
	bool grammar;

	uint arity;

	StringUnorderedMap prologFileCache;
	StringUnorderedMap systemPredTable;
	StringUnorderedMap exportNameCache;
	StringUnorderedMap groupEntryCache;
	QCString current_module = 0, source_module;
	StringUnorderedMap foreignCache;

	QCString packageScope;
	QCString pName;

	// bool             insideConstructor;

	QCString moduleScope;
	QCString packageName;

	// bool             hideClassDocs;

	QCString defVal;

	bool lexInit = FALSE;
	bool packageCommentAllowed;
	bool slashStarComment;
	bool SWIStyle;
Clause current_clause;
	/* algorithmm is:
	   - empty space: call = 0 && arg = 0;
	   - a(: = arg++;
	   - ( && arg == call: arg++, call++;
	   - ( && arg > call: arg++
	   - { && no { before && grammar: arg++, call++
	   - {, [ otherwise: arg++
	   - }, ) && arg == call: arg--, call--
	   - arg--
	*/
	unsigned int callLevel = 0;
	unsigned int argLevel = 0;

	std::shared_ptr<Entry> call = 0;
	std::shared_ptr<Entry> callStore = 0;

	std::shared_ptr<Entry> current_predicate = 0;

	bool headDone, atCall;
	bool firstCall = true;
    };

    static std::shared_ptr<Entry> predBind(yyscan_t yyscanner, Pred p);



/*
    static QRegExp ra("/[0-9]+$");
    static QRegExp rm("^[a-z][a-zA-Z_0-9]*:");
    static QRegExp rmq("^'[^']+':");
*/

    static void newEntry( yyscan_t yyscanner );
    static bool prepComment( yyscan_t yyscanner, const char * text, bool &brief, bool slash_star);
    static void handleCommentBlock( yyscan_t yyscanner, const QCString &doc, bool brief);
    static void endOfDef( yyscan_t yyscanner);
    static bool addPredDecl( yyscan_t yyscanner, QCString name);
    static bool addPredDecl( yyscan_t yyscanner, QCString mod, QCString name, uint arity);
    static char *sliceArgument(const char *inp, int c) ;
    static void startCommentBlock( yyscan_t yyscanner, bool brief);
    const char *fileToModule(yyscan_t yyscanner, QCString item);


#if USE_STATE2STRING
static const char *stateToString(int state);
#endif


    static yy_size_t yyread(yyscan_t yyscanner, char *buf,yy_size_t max_size);

    //-----------------------------------------------------------------------------
    /* ----------------------------------------------------------------- */
#undef	YY_INPUT
#define	YY_INPUT(buf,result,max_size) result=yyread(yyscanner, buf,max_size);



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
EOT               "."{BN}

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
QCStringITEM        ({STRINGCHAR}|{ESCAPESEQ}|"''"|"\\'"|"\"")
DQCStringITEM       ({STRINGCHAR}|{""|"'")

SQCString           ("'"({QCStringITEM})*"'")
DQCString           ("\""({QCStringITEM})*"\"")

SY		   [#&*+\-/:<=>?@\\\^`~]
SYNOSTAR	   [#&+.\-/:<=>?@\\\^`~]
SYNOSLASH	   [#&+.\-:<=>?@\\\^`~]
SYDOT		   [#&*+.\-/:<=>?@\\\^`~]

SYMBOL		  ("*"|"/"|{SY}+"."{SYDOT}*|"."{SYDOT}+|"/"{SYNOSTAR}{SYDOT}*|"*"{SYNOSLASH}+|{SYNOSLASH}{SYDOT}*|".")


/* do not treat , and ; as atoms. */
SOLO		  [!]

CMD [@\\][a-zA-z0-9_]+

ATOM		   ({IDENTIFIER}|{SQCString}|{SYMBOL}|{SOLO})

NOC	   ({IDENTIFIER}|{SQCString})

ATOMIC             ({ATOM}|{VAR}|{NUMBER}|{DQCString})


INDICATOR          (({ATOM}":")*("("{ATOM}")"|{ATOM})("/"|"//"){DECNUMBER})

OPDEC		   {IDENTIFIER}"("{BNS}{INTNUMBER}{BNS}","{BNS}{IDENTIFIER}{BNS}","{BNS}("("{BNS})?{ATOM}({BNS}")")?{BNS}")"

META		   {ATOM}"("{BNS}[0-9:?\-+]{BNS}(","{BNS}[0-9:?\-+]{BNS})*{BNS}")"

PATH		   (("/")?{ATOM}("/"{ATOM})*)

LIBRARY		   (({ATOM}"("{BNS}{PATH}{BNS}")")|({PATH}))

FLOWKW             ("spy"|"nospy"|"same"|"block"|"^"|"**"|"\\"|"rem"|"mod"|">>"|"<<"|"//"|"/"|"*"|"xor"|"div"|"rdiv"|"#"|"><"|"\\/"|"/\\"|"-"|"-"|"+"|"+"|":"|"as"|">="|"=<"|">"|"<"|"=\\="|"=:="|"\\=@="|"=@="|"@>="|"@=<"|"@>"|"@<"|"\\=="|"=="|"=.."|"is"|"\\="|"="|"not"|"\\+"|"uncutable"|"table"|"discontiguous"|"module_transparent"|"meta_predicate"|"multifile"|"public"|"mode"|"volatile"|"initialization"|"thread_local"|"dynamic")

PREDTAG               ("det"|"semidet"|"failure"|"nondet"|"multi"|"iso"|"deprecated"|"dynamic"|"direcxotive"|"meta")

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

%x Head
%x Body
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

<Search>{BN} {

}

<*>{ATOM}":"/[^-] {
QCString s = yytext;
s = s.left(s.length()-1);
yyextra->source_module = *new QCString(s);


}



<Search>{BN}(":-"|"?-"){BN} {
     // must be start of a function/clause definition
     QCString s = yytext;
     s = s.stripWhiteSpace();
   	     yyextra->current_clause.state = Clause::CLI_BODY;
   
 }



	     
<Body,Head>{BN}(","|";"|"->"){BN} {

     // must be start of a function/clause definition
     QCString s = yytext;
     s = s.stripWhiteSpace();
          while (yyextra->current_clause.q.size() &&
            yyextra->current_clause.q.back().t <= Literal::PL_GOAL&&
            yyextra->current_clause.q.back().t <= Literal::PL_GOAL )
	 yyextra->current_clause.q.pop_back();
//size_t n = yyextra->current_clause.q.size();
//if (n)
//	     yyextra->current_clause.q[n-1].t++;
	 }

<Body,Head>({B}("("|"["|"{"){B}) {
    QCString s = yytext;
    s = s.stripWhiteSpace();
 Literal::token_t tag;
bool e = yyextra->current_clause.q.empty();
			     if (!e &&
                                yyextra->current_clause.q.back().t <= Literal::PL_ENTER_COMPOUND) {
     if ( s == "(")  tag = Literal::PL_INNER_BRA ;
     else if (	     s == "[" )  tag = Literal::PL_INNER_SQB ;
		     else tag = Literal::PL_INNER_CRB;
			     } else {

     if ( s == "(")  tag = Literal::PL_ENTER_BRA ;
     else if (	     s == "[")   tag = Literal::PL_ENTER_SQB ;
		     else tag = Literal::PL_ENTER_CRB;
			     }
 yyextra->current_clause.q.push_back(* new Literal(tag,yyextra->source_module,s,0));
}

<Search>{B}("("|"["|"{"){B} {
    QCString s = yytext;
Literal::token_t tag;    s = s.stripWhiteSpace();
     if ( s == "(")  tag = Literal::PL_ENTER_BRA ;
     else if (	     s == "[")   tag = Literal::PL_ENTER_SQB ;
		     else tag = Literal::PL_ENTER_CRB;
			    
     yyextra->current_clause.q = std::vector<Literal>( 1,Literal(tag,yyextra->source_module,s,tag));
			 }

	 


<Body,Head>{B}(")"|"]"|"}"){B} {
	 while (yyextra->current_clause.q.size() && yyextra->current_clause.q.back().t <= Literal::PL_GOAL)
            yyextra->current_clause.q.pop_back();
if (yyextra->current_clause.q.size()) {
Literal l = yyextra->current_clause.q.back();
    if (l.t == Literal::PL_ENTER_GOAL) {
	if (yyextra->current_clause.state == Clause::CLI_HEAD &&
	    yyextra->current_clause.q.size() == 1) {
	yyextra->current_clause.m = l.m;
	yyextra->arity = yyextra->current_clause.a = l.a;
	yyextra->pName = yyextra->current_clause.n = (l.n);
	yyextra->current_clause.state = Clause::CLI_NECK;
}
	yyextra->current_clause.q.pop_back();
		}
}
}

<Search>":-"{BN}*("module"|"system_module"|"reexport")"("{BN}{LIBRARY}{BN}","{BNS} {
    yyextra->packageName=yytext;
    QCString item=yyextra->packageName;
    item = removeRedundantWhiteSpace(sliceArgument(item.data(), ',' ));
    if (item.find("library(") == 0) item = item.mid(8,item.length()-9).stripWhiteSpace();
//    yyextra->current->name = fileToModule(item);
yyextra->source_module = item;
     BEGIN(ExportList);
  }


<Search>":-"{B}"private(" { // define module  ATOM
       QCString l = yytext;
      yyextra->protection = Protection::Private;
     BEGIN(ExportList);
      }

<Search>":-"{B}*"meta_predicate" { // define module  ATOM
       QCString l = yytext;
      yyextra->protection = Protection::Private;
      }



<Search>":-"{B}"op(" {
       QCString l = yytext;
      yyextra->current->protection = Protection::Private;
      }


<Search>":-"{B}"foreign( "{ATOM}":"{INDICATOR}" , "{ATOM}", "{ATOM}" , "{NUMBER}" )"{EOT} {
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
    Pred p = Pred( predName, yyextra->source_module);
    int line=pname.mid(comma2+3, end-(comma2+3)).toInt();
    yyextra->current->reset();
    yyextra->current->name = p.predName(yyextra->current_module);
    yyextra->current->fileName = fileName;
    yyextra->current->section=Entry::CLASSDOC_SEC;
    yyextra->current->spec = ClassDef::Class;
    yyextra->current->startLine = line;
    yyextra->current->bodyLine  = line;
    yyextra->current->artificial  = true;
    newEntry(yyscanner);
    yyextra->current->name = funcName;
    yyextra->current->fileName = fileName;
    yyextra->current->section=Entry::FUNCTION_SEC;
    yyextra->current->startLine = line;
    yyextra->current->bodyLine  = line;
   newEntry(yyscanner);
    BEGIN(Search);
  }



<Search>({NUMBER}|{VAR})"::"   {
     yyextra->current->program<<yytext;

  }

 <Search>({ATOM}|{NUMBER}|{VAR}|{DQCString}|{B}|{NEWLINE}) {
     yyextra->current->program<<yytext;
    BEGIN(Head);
  }



<Head,Body>({ATOM}|{NUMBER}|{VAR}|{DQCString}|{B}|{NEWLINE}) {
     yyextra->current->program<<yytext;
  }

{EOT} {
    yyextra->current->program<<yytext;
    BEGIN(Search);
		}


<Head>{
  {B}":-"    {
    if (!yyextra->headDone) {
      yyextra->current->name = QCString( "op" );
      yyextra->headDone= TRUE;
    }
    yyextra->grammar = FALSE;
    yyextra->current->program<<yytext;
    yyextra->current->bodyLine  = yylineno;
    BEGIN( Body );
  }

  {B}"-->"    {
    if (!yyextra->headDone) {
      yyextra->current->name =  "op" ;
      yyextra->headDone= TRUE;
    }
    yyextra->grammar = TRUE;
    yyextra->current->program<<yytext;
    yyextra->current->bodyLine  = yylineno;
    BEGIN( Body );
  }


  {B}{EOT}         {
    // facts
    //yyextra->current->program<<yytext;
    //printf("\nDONE\n %s \n*******\n", yyextra->current->program.data());
    endOfDef(yyscanner);
    yyextra->current_clause.reset(yyextra->current_module);
    BEGIN(Search);

  }

  [^\n]       {
    yyextra->current->program<<yytext;
    yyextra->defVal += yytext;
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


"/"[^*] {}

		{SQCString} {}



<ExportList>{

    {ATOM}{B}","{B}"["{B} {
	QCString s = yytext;
	s = s.left(s.findRev("[")-1).stripWhiteSpace();
	if (yyextra->pName == "module") {
	//    createModuleEntry(s);
		 yyextra->current_module = yyextra->source_module = s;
	    } else /*if (s == "system_module")*/ {
		 yyextra->current_module = yyextra->source_module = "prolog";
	    }
    }




  {BNS}"]"{BNS}  {
  }

  {BNS}"]"{EOT}  {
  }

 {BNS}"]"{BNS}","{BNS}  {
       BEGIN(Search);
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
  addPredDecl(  yyscanner, yyextra->source_module, l, yyextra->ind_arity.toUInt() );
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
yyextra->current_module =  ind_mod;
    }

    {B}*{ATOM} {
        yyextra->ind_name = yytext;
        yyextra->ind_name.stripWhiteSpace();
        if (yyextra->ind_name[0] == '\'' &&
            yyextra->ind_name[yyextra->ind_name.length()-1] == '\'')
            yyextra->ind_name = yyextra->ind_name.mid(1, yyextra->ind_name.length()-2);
    }

   {B}*"("{B}*{ATOM}{B}*")" {
        yyextra->ind_name = yytext;
        yyextra->ind_name.stripWhiteSpace();
        if (yyextra->ind_name[0] == '\'' &&
            yyextra->ind_name[yyextra->ind_name.length()-1] == '\'')
            yyextra->ind_name = yyextra->ind_name.mid(1, yyextra->ind_name.length()-2);
    }

    "/"{B}{INTNUMBER} {
        yyextra->ind_arity = yytext;
        yyextra->ind_arity.stripWhiteSpace();
            yyextra->ind_arity=yyextra->ind_arity.right(yyextra->ind_arity.length()-1);
        yyextra->ind_arity.stripWhiteSpace();

           addPredDecl(yyscanner,yyextra->source_module+":"+yyextra->ind_name+
"/"+yyextra->ind_arity );
BEGIN(ExportList);
    }

    "//"{B}{INTNUMBER} {
        yyextra->ind_arity = yytext;
        yyextra->ind_arity.stripWhiteSpace();
            yyextra->ind_arity=yyextra->ind_arity.right(yyextra->ind_arity.length()-2);
        yyextra->ind_arity.stripWhiteSpace();
	addPredDecl(yyscanner, yyextra->source_module+":"+yyextra->ind_name+
"/"+yyextra->ind_arity);
BEGIN(ExportList);
      }

{B}+ {
     }

}


  /* ------------ Default rules -------------- */


<*>{
"/*"([^*]|("*"+[^*/]))*"*"+"/" {
    if ((yytext[2] == '*' || yytext[2] == '!') &&
       (yytext[3] == ' ' || yytext[3] == '\t' || yytext[3] == '\n')
    ) {
        if ( prepComment( yyscanner, yytext, yyextra->docBrief, true) ) {
            startCommentBlock( yyscanner, yyextra->docBrief );
            //fprintf(stderr,"*****? %s\n", yyextra->docBlock.data());
            handleCommentBlock(yyscanner, yyextra->docBlock, yyextra->docBrief);
        }
    }
}

<*>"%".*"\n"("%".*"\n"|[ \t]+"\n")* {
    if ((yytext[1] == '%' || yytext[1] == '!') &&
       (yytext[2] == ' ' || yytext[2] == '\t' || yytext[2] == '\n')
    ) {
        if ( prepComment( yyscanner, yytext, yyextra->docBrief,false) ) {
            startCommentBlock( yyscanner, yyextra->docBrief );
          //  fprintf(stderr,"*****? %s\n", yyextra->docBlock.data());
            handleCommentBlock(yyscanner, yyextra->docBlock, yyextra->docBrief);
        }
    }
		}



 }

 <*>[\x00]/([^\n]|"\n") {
 /* yes, it happens */

 }


%%

#if DEBUG_ALL
void showScannerTree( yyscan_t yyscanner, uint off, std::shared_ptr<Entry> current, bool show);
static void showScannerNode( yyscan_t yyscanner, uint off, std::shared_ptr<Entry> current, bool show);
#endif
//-----------------------------------------------------------------------------

// We should accept ({atom}":")*{atom}("/"{nat})?
// in this case, as no grouping operators are available
//  we step backwards
//
//

static void initParser( yyscan_t yyscanner) {
  struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  yyextra->protection = Protection::Private;
  yyextra->mtype = MethodTypes::Method;
  yyextra->stat = FALSE;
  yyextra->virt = Specifier::Normal;
  yyextra->previous = 0;
  yyextra->packageCommentAllowed = TRUE;
 yyextra->current_clause =  	Clause("prolog");
if (yyextra->firstCall) {
    yyextra->exportNameCache.clear();
  }
}

static void initEntry( yyscan_t yyscanner) {
  struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  // current->prolog = TRUE;
  yyextra->current->protection = yyextra->protection ;
  yyextra->current->mtype      = yyextra->mtype;
  yyextra->current->virt       = yyextra->virt;
  //yyextra->current->isStatic   = yyextra->isStatic;
  yyextra->current->lang       = SrcLangExt_Prolog;
   yyextra->commentScanner.initGroupInfo(yyextra->current.get());
   yyextra->stat = FALSE;
}

static void newEntry( yyscan_t yyscanner ) {
  //        if (current && entry->current->parent())
  //     printf("||%p %s -< %p %s||\n", entry->current->parent(),
  //     entry->current->parent()->name.data() , entry->current, entry->current->name.data() /*,
  //     entry->current->program.data() */);

  // if (current->section!=Entry::PREDDOC_SEC)

  struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  yyextra->previous = yyextra->current;
  yyextra->current_root->moveToSubEntryAndRefresh(yyextra->current);
      yyextra->current            = std::make_shared<Entry>();
initEntry(yyscanner);

}

void foundVariable( yyscan_t yyscanner ) {
  struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  return;
  std::shared_ptr<Entry> n = std::make_shared<Entry>();
  n->name = QCString(yytext);
  if (!strncmp(yytext, "_", 1)) {
    n->protection = Protection::Private;
  } else {
    n->protection = yyextra->current->protection;
  }
  //	    yyextra->moduleNameCache.insert(mname, n );
  n->section = Entry::VARIABLE_SEC;
  n->type = "variable";
  n->fileName = yyextra->yyFileName;
  n->startLine = yyextra-> yyLineNr;
  n->bodyLine = yyextra-> yyLineNr;
//  assert(n->name);
}

static char *sliceArgument(const char *inp, int c) {
  size_t sz0 = strlen(inp);
  char *ptr;
  const char *tmp = inp, *end = inp + sz0;
  int ch;

  while ((ch = *inp++) && (ch != '(')) {
    if (ch == '\'') {
      while ((ch = *inp++) && ch != '\'')
        if (ch == '\\')
          inp++;
    }
  }
  while ((ch = *inp++) && isblank(ch))
    ;
  if (ch != '\'')
    inp--;
  // skipped the beginning, skip the end now
  tmp = end - 1;
  while (*tmp != c)
    tmp--; // reach ')'
  tmp--;
  while (isblank(*tmp))
    tmp--;
  if (*tmp == '\'')
    tmp--;
  sz0 = (tmp - inp) + 1;
  ptr = (char *)malloc(sz0 + 1);
  if (!ptr)
    return NULL;
  strncpy(ptr, inp, sz0);
  ptr[sz0] = '\0';
  return ptr;
}

//-----------------------------------------------------------------------------

//void brk( yyscan_t yyscanner ) { printf("broken\n"); }


//-----------------------------------------------------------------
static void startCommentBlock( yyscan_t yyscanner, bool brief) {
   struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
 yyextra->specialBlock = true;
  if (brief) {
    yyextra->current->briefFile = yyextra->yyFileName;
    yyextra->current->briefLine = yyextra-> yyLineNr;
  } else {
    yyextra->current->docFile = yyextra->yyFileName;
    yyextra->current->docLine = yyextra-> yyLineNr;
  }
  }

typedef enum { BRIEF, BRIEF_EMPTY, BLANK_LINE, DOC } state_t;

static bool prepComment( yyscan_t yyscanner, const char * txt, bool &brief, bool slash_star) {
QCString t;
 QCString text = txt;
 struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  yyextra->docBlockContext   = YY_START;
  yyextra->docBlockInBody    = FALSE;
  yyextra->docBlockJavaStyle = TRUE;
  yyextra->docBrief = TRUE;
  yyextra->docBlock.resize(0);
  QCString otext = "", line;
  int c = (slash_star ? 3 : 2);
  int ch;
 while ((ch=text[c++])!='\n' && ch) otext += ch;
 otext += '\n';

 while (ch!='\0') {
    line = "";
        while ((ch=text[c++])!='\n' && ch

        ) {
     line += ch;
     }
         int i = 0;
        if (line[0] == ' ') {
            if (line[1] == ' ') {
              if (line[2] == ' ') {
                 i = 3;
                 } else {
                 i = 2;
                 } }else  {i = 1; }
                 }

                 if (line[i] == '*') {
                      if (line[i+1] == ' ' || line[i+1]=='\n')
                      i ++;
               } else if (line[i] == '/' && line[i+1] == '*') {
                     if (line[i+2] == ' ' || line[i+2] == '\n')
                     i +=2;
                     } else  if (line[i] == '%') {
                         if (line[++i] != '%')
                            i--;
                         if (line[++i] == ' '||line[i] == '\n') {
                         i ++;
                         } else {
                         i = 0;
                         }
                         } else {
                         i = 0;
                         }

                        otext += line.data()+i;
 otext+= '\n';

}
    	  while ((c=otext.find("*/\n")) > 0 )
    	  otext = otext.remove(c,2);

  yyextra->docBlock = * new QCString (otext);
  return true;
}


static void handleCommentBlock( yyscan_t yyscanner, const QCString &doc, bool brief) {
    struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;

  yyextra->docBlockInBody=FALSE;

  if (!yyextra->current->doc.isEmpty())
  {
    yyextra->current->doc=yyextra->current->doc.stripWhiteSpace()+"\n\n";
  }
  if (yyextra->docBlockInBody && yyextra->previous && !yyextra->previous->doc.isEmpty())
  {
    yyextra->previous->doc=yyextra->previous->doc.stripWhiteSpace()+"\n\n";
  }

  int position = 0;
  bool needsEntry = false;
  int lineNr = brief ? yyextra->current->briefLine : yyextra->current->docLine;
  Markdown markdown(yyextra->yyFileName,lineNr);
  QCString processedDoc = Config_getBool(MARKDOWN_SUPPORT) ? markdown.process(doc,lineNr) : doc;
  while (yyextra->commentScanner.parseCommentBlock(
        yyextra->thisParser,
        (yyextra->docBlockInBody && yyextra->previous) ? yyextra->previous.get() : yyextra->current.get(),
        processedDoc, // text
        yyextra->yyFileName,   // file
        lineNr,
        yyextra->docBlockInBody ? FALSE : brief, 
        yyextra->docBlockJavaStyle, // javadoc style // or FALSE,
        yyextra->docBlockInBody,
        yyextra->protection,
        position,
        needsEntry,
        Config_getBool(MARKDOWN_SUPPORT))
     ) // need to start a new entry
  {
    if (needsEntry){

  newEntry(yyscanner);
    }
  }
  if (needsEntry)
  {
    newEntry(yyscanner);
  }
}

static void endOfDef( yyscan_t yyscanner ) {

  struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  // printf("endOfDef at=%d\n",yyextra->yyLineNr);static void endOfDef( yyscan_t yyscanner ) {

  newEntry(yyscanner);
  // reset depth of term.
  yyextra->callLevel = yyextra->argLevel = 0;
  yyextra->current_clause.reset(yyextra->source_module);
  // yyextra->insideConstructor = FALSE;
}


static std::shared_ptr<Entry> buildPredEntry(yyscan_t yyscanner, Pred p) {
    struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
    std::shared_ptr<Entry> newp;
    //fprintf(stderr,"|| ************* %s  \n", p.predName(yyextra->current_module).data());
    QCString pname = *new QCString(p.predName(yyextra->current_module));
    QCString mod = * new QCString(  p.m);

    if (yyextra->current && pname == yyextra->current->name) {
	return yyextra->current;
    }

    if (yyextra->current_comment &&
      (yyextra->current->name.isEmpty() || yyextra->current_comment->name == pname)) {
    yyextra->current_comment->name = pname;
    //      newp = yyextra->current_comment;
    // return newp;
    //} else {
    newp =yyextra->current_comment;
  } else {
  yyextra->current_root->moveToSubEntryAndRefresh(newp);
  }
  yyextra->current->argList.clear();
	 yyextra->current->section = Entry::CLASS_SEC;
  yyextra->current->spec = ClassDef::Class;
//yyextra->current->type = "predicate";
  yyextra->current->name = p.link();
  if (mod == "user" || (mod == "prolog" && pname.find("\'") < 0)) {
    //groupEnterCompound(yyFileName, yyextra-> yyLineNr,p.predName());
    // groupLeaveCompound(yyFileName, yyextra-> yyLineNr,p.predName());
    yyextra->current->protection = Protection::Public;
  } else
    yyextra->current->protection = Protection::Private;
    unsigned int arity = QCString(yyextra->ind_arity).toUInt();
  for (uint i = 0; i < arity; i++) {

    char buf[16];
    Argument a ;
    snprintf(buf, sizeof(buf), "A%u", i + 1);
    a.name = buf;
    a.type = "Term";
    yyextra->current->argList.push_back(a);
  }
  if (yyextra->ind_mod.isEmpty()) {
    yyextra->ind_mod = yyextra->current_module;
  }
  if (yyextra->ind_mod.isEmpty()) {
    yyextra->ind_mod = "prolog";
  }
  //->copyToSubEntry(newp);
  yyextra->current_predicate = yyextra->current;
  //     fprintf(stderr,"|| *************                    <- %p %s||\n" ,
  //     newp,x newp->name.data());
  return yyextra->current;
}

// normalize
static std::shared_ptr<Entry> predBind(yyscan_t yyscanner, Pred p) {
    struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
// use an hash table to store all predi≈ cate calls, so that we can track down
  // arity; if we have comments available, it's our chance....
  std::shared_ptr<Entry> e;
  e =  yyextra->current            = std::make_shared<Entry>();

  e = buildPredEntry(yyscanner,p);
  yyextra->current_comment = 0;
  // if (yyextra->specialBlock)
  //  return NULL;
  return e;
}

static bool addPredDecl( yyscan_t yyscanner, QCString name) {
    struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  std::shared_ptr<Entry> e;
  QCString s;

  Pred p = Pred(name, yyextra->source_module);
  e = predBind(yyscanner, p);
  e->protection = Protection::Public;
  e->section = Entry::CLASSDOC_SEC;
  e->spec = ClassDef::Class;
  //yyextra->exportNameCache.insert(e->name, e->name.data());
  if (e == yyextra->current)
    newEntry(yyscanner);
  return true;
}


static bool addPredDecl( yyscan_t yyscanner, QCString mod, QCString name, uint arity) {
    std:: shared_ptr<Entry> e;
    QCString s;

    Pred *p = new Pred( mod, name, arity);
    e = predBind(yyscanner,*p);
    e->protection = Protection::Public;
    e->section = Entry::USINGDECL_SEC;
    e->spec = ClassDef::Class;
    e->name = p->link();
   // yyextra->exportNameCache.insert(p->link(), p->predName(yyextra->current_module).data());
    newEntry(yyscanner);
    return true;
}


static QCString symbs = "#&*+;-./:<=>?@\\^~";

int quoted_end(  QCString text, int begin) {
 int ch;
  int i = begin + 1;
  if (text[begin] != '\'')
    return -1;
  while ((ch = text[i++])) {
    if (ch == '\0')
      return -1;
    if (ch == '\\') {
      i++;
    } else if (ch == '\'') {
      ch = text[i];
      if (ch == '\0')
        return i;
      if (ch == '\'') {
        i++;
      }
      return i;
    }
  }
  return -1;
}

int get_atom( yyscan_t yyscanner, QCString text) {
 int i = 0, ch, level = 0;
 restart:
  ch = text[i++];
  if (ch == '\0')
    return -1;
  if (ch == '\'') {
    int o = quoted_end( text, i - 1);
    return o;
  } else if (ch == '(') {
    level++;
    goto restart;
  } else if (isalpha(ch) || ch == '_' || ch == '$') {

    while (isalnum((ch = text[i])) || ch == '_')
      i++;
  } else if (symbs.contains(ch)) {
    while (symbs.contains((ch = text[i]))) {
      i++;
    }
    if (level == 0 && i > 1 && text[i - 1] == '/' && isdigit(ch))
      i--;
  } else
    return -1;
  while (level > 0) {
    while (isblank(ch))
      ch = text[i++];
    if (ch == ')') {
      if (--level == 0)
        return i + 1;
    } else
      return -1;
  }
  return i;
  }

inline QCString get_module(yyscan_t yyscanner,QCString curMod) {
      struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  if (curMod.isEmpty()) {
    if (yyextra->current_module == 0) {
      return QCString("prolog");
    } else {
       return  yyextra->current_module;
    }
  } else {
      return  curMod;
    }
  }


extern void mymsg( yyscan_t yyscanner, const char *input);
void mymsg( yyscan_t yyscanner, const char *input) { /* printf("Got you %s", input );*/ }


bool normalizePredName__( yyscan_t yyscanner, QCString curMod, const char *input, QCString &omod,
                         QCString &oname, uint &arity) {
  QCString text = input, txt;
    text = text.stripWhiteSpace();
    QCString newE;
    int  i = 0;
    {
        bool ok;
        //fprintf(stderr, "************ %s %s", curMod.data(), text.data());

        do {
        unsigned int p;
            if ((p = text.findRev("/")) > 0 && (arity = (text.right(text.length() - p - 2)
                    .toUInt(&ok))) && ok) {
                text = text.left(p).stripWhiteSpace();

            }
            break;
        } while (false);
    }
    omod = get_module(yyscanner, curMod);
    while (true) {
        i = get_atom(yyscanner,text);
        if (i < 0) {
            i = text.find("::");
            if (i > 0) {
                bool ok;
                QCString left = text.left(i - 1);
                left.toUInt(&ok);
                if (ok)
                text = text.right(text.length() - i - 2).stripWhiteSpace();
            } else {
                break;
            }
        } else {
            size_t l = text.length();
            QCString right, left;
            // dox we have a module?
            left = text.left(i).stripWhiteSpace();
            right = text.right(l - i).stripWhiteSpace();
            if (right.isEmpty())
                break;
            if (right.find("::" == 0)) {
                text = right.right(l - 2).stripWhiteSpace();
                omod = left;
            } else if (right.find(":" == 0)) {
                text = right.right(l - 1).stripWhiteSpace();
                omod = left;
            } else if (right.find("." == 0)) {
                text = right.right(l - 1).stripWhiteSpace();
                while ((i = get_atom(yyscanner,text)) > 0) {
                    omod += "." + text.left(i).stripWhiteSpace();;
                    text = right.right(l - 1).stripWhiteSpace();
                }
            } else {
                break;
            }
        }
    }
    oname = text;
  //  fprintf(stderr, "************ %s %s/%u", curMod.data(), text.data(), arity);
    return true;
}


Pred::Pred(QCString s, QCString current_module )
{
bool ok=false;
int np = s.findRev("//");
if (np >= 0) {
a = s.right(s.length()-(np+2)).toUInt(&ok);
}
if (!ok) {
np = s.findRev("/");
    if (np >= 0) {
        a = s.right(s.length()-(np+1)).toUInt(&ok);
    }
}

if (!ok){
fprintf(stderr,"bad arity at %s\n",s.data());
}
QCString name = s.left(np);
int nm;
m = current_module;
while ((nm=name.find(":"))>=0) {
if (name[nm] == ':' && name[nm+1] != ':' && (nm==0||name[nm-1] != ':')) {
m = name.left(nm-1);
    //createModuleEntry(* new QCString(m));

name = name.right(name.length()-nm-1);
} else {
break;
}
}
n = name;
//fprintf(stderr, "+++ %s %s/%u\n", m.data(), n.data(), a);

foreign = nullptr;
}


//----------------------------------------------------------------------------

void prologscanFreeScanner(  yyscan_t yyscanner)
{
#if defined(YY_FLEX_SUBMINOR_VERSION)
   struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
 if (yyextra->lexInit)
    {
      prologscannerYYlex_destroy(yyscanner);
    }
#endif
}

#if defined(DEBUG)
 void
  showScannerNode( yyscan_t yyscanner, uint off, std::shared_ptr<Entry> ce , bool show) {
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
  if (ce->spec == ClassDef::Class) s = "CLASS_SEC";
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
  case Entry::OBJCIMPL_SEC:
    s = "OBJCIMPL_SEC";
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
    fprintf(stderr,"%*s (%d) -> %s %d\n",off+20, s, (ce->protection == Protection::Public ? 1 : 0), ce->name.data(), ce->mGrpId /*, ce->program.data() */);
  else
    fprintf(stderr,"%*s (%d) -> %s %d\n",off+20, s, (ce->protection == Protection::Public ? 1 : 0), ce->name.data(), ce->mGrpId /*, ce->program.data() */);
}
#endif


void
showScannerTree(yyscan_t yyscanner, uint off, std::shared_ptr<Entry> current, bool show) {
#if defined(DEBUG)
   struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  showScannerNode( yyscanner, off, yyextra->current, show );
  std::shared_ptr<Entry> ce;
  for (const auto &child : current->children())
    {
      showScannerTree(yyscanner, off+4, child, show);
    }
#endif
}



static yy_size_t yyread(yyscan_t yyscanner,char *buf,yy_size_t max_size)
{
  struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  yy_size_t c=0;
  const char *p = yyextra->inputString + yyextra->inputPosition;
  while ( c < max_size && *p ) { *buf++ = *p++; c++; }
  yyextra->inputPosition+=c;
  return c;
}
//----------------------------------------------------------------------------

struct PrologOutlineParser::Private
{
  yyscan_t yyscanner;
  prologscannerYY_state state;
};

PrologOutlineParser::PrologOutlineParser() : p(std::make_unique<PrologOutlineParser::Private>())
{

  prologscannerYYlex_init_extra(&p->state,&p->yyscanner);
//p->stat.prologFileCache = QDict<char>(257) {};
//p->stat.systemPredTable = new QDict<char>(257);
//p->>stat.varNameCache(257);
//p->stat.exportNameCache = new QDict<char>(257);
//p->stat.groupEntryCache = new QDict<char>(257);
//p->current_module = 0;
//p->stat.foreignCache(257);
#ifdef FLEX_DEBUG
  prologscannerYYset_debug(1,p->yyscanner);
#endif
}


static void parseCompounds(yyscan_t yyscanner,std::shared_ptr<Entry> rt)
{
    return;
  struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  //printf("parseCompounds(%s)\n",rt->name.data());
  for (size_t i=0; i<rt->children().size(); ++i)
  {
    std::shared_ptr<Entry> ce = rt->children()[i];
    if (!ce->program.empty())
    {
      //fprintf(stderr,"parseCompounds: -- %s (line %d) ---------\n%s\n---------------\n",
      //  ce->name.data(), ce->bodyLine, ce->program.data());
      // init scanner state
      //yyextra->inputString = ce->program;
      yyextra->inputPosition = 0;
      prologscannerYYrestart( 0, yyscanner );
      if (ce->section&Entry::COMPOUND_MASK)
      {
        yyextra->current_root = ce;
        BEGIN( Search );
      }
      else if (ce->parent())
      {
        yyextra->current_root = rt;
	//printf("Searching for member variables in %s parent=%s\n",
	//    ce->name.data(),ce->parent->name.data());
	BEGIN( SearchMemVars );
      }
      yyextra->yyFileName = ce->fileName;
      yyextra->yyLineNr   = ce->bodyLine ;
      newEntry(yyscanner);

      QCString name = ce->name;
      yyextra->commentScanner.enterCompound(yyextra->yyFileName,yyextra->yyLineNr,name);

       prologscannerYYlex(yyscanner) ;
      yyextra->lexInit=TRUE;
      //ce->program.resize(0);

      yyextra->commentScanner.leaveCompound(yyextra->yyFileName,yyextra->yyLineNr,name);

    }
    parseCompounds(yyscanner,ce);
  }
}

 static void parseMain(yyscan_t yyscanner, const QCString &fileName,
 const char *fileBuf,const std::shared_ptr<Entry> &
			rt)
{

   struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
 initParser(yyscanner);
 int off = 4;
 if (fileBuf==0 || fileBuf[0]=='\0') return;

  yyextra->inputString = fileBuf;
  yyextra->inputPosition = 0;
      yyextra->current            = std::make_shared<Entry>();
  yyextra->protection    = Protection::Private;
  yyextra->mtype         = MethodTypes::Method;
  yyextra->stat         = FALSE;
  yyextra->virt          = Specifier::Normal;
 yyextra->current_root=rt;
 yyextra->specialBlock = false;

  yyextra->SWIStyle = false;
  yyextra->system_module = false;
  yyextra->new_module = false;
 yyextra->current_clause = Clause("prolog");

       yyextra->yyLineNr = 1 ;
      yyextra-> yyFileName = fileName;
      //setContext();
     msg("Parsing file %s...\n",yyextra->yyFileName.data());

FileInfo fi(fileName.str());
  QCString baseName=fi.baseName();

  yyextra->current            = std::make_shared<Entry>();
  initEntry(yyscanner);
    yyextra->current->name      = "prolog";
    yyextra->current->section   = Entry::NAMESPACE_SEC;
    yyextra->current->type      = "namespace";
    yyextra->current->fileName  = yyextra->yyFileName;
    yyextra->current->startLine = yyextra->yyLineNr;
    yyextra->current->bodyLine  = yyextra->yyLineNr;


  rt->moveToSubEntryAndRefresh(yyextra->current);


 initParser(yyscanner);



  yyextra->commentScanner.enterFile(yyextra->yyFileName,yyextra->yyLineNr);

  yyextra->current->reset();
  initEntry(yyscanner);
yyextra->current_module = "prolog";
 yyextra->current_clause.reset(yyextra->current_module);
       prologscannerYYrestart(0, yyscanner );
      BEGIN( Search );
      prologscannerYYlex(yyscanner);
      yyextra->lexInit=TRUE;

     if (yyextra->current_root  != 0)
  showScannerTree( yyscanner,off, rt, true );
  yyextra->commentScanner.leaveFile(yyextra->yyFileName,yyextra->yyLineNr);

 // yyextra->current_root->program.resize(0);


  //yyextra->current_root      = new std::shared_ptr<Entry>;
    // std::shared_ptr<Entry> e;
    // for (;(e=di.yyextra->current());++di)
    // {
    //   e->setParent(yyextra->current_root);
    //   yyextra->current_root->copyToSubEntry(e);
    // }





      yyextra->commentScanner.leaveFile(yyextra->yyFileName,yyextra->yyLineNr);

   //   yyextra->current_root->program.resize(0);
      yyextra->current = 0;
      yyextra->current_root = 0;
      yyextra->current_module = 0;
      yyextra->firstCall = false;
      yyextra->entries = 0;

      parseCompounds(yyscanner,yyextra->current_root);

      //yyextra->inputFile.close();
}


PrologOutlineParser::~PrologOutlineParser()
{
 prologscannerYYlex_destroy(p->yyscanner);
}



void PrologOutlineParser::parseInput(const QCString &fileName,
                                                               const char *fileBuf,
                                                               const std::shared_ptr<Entry> &root,
                                                               ClangTUParser * /*clangParser*/)
{
  struct yyguts_t *yyg = (struct yyguts_t*)p->yyscanner;
  yyextra->thisParser = this;
  DebugLex debugLex(Debug::Lex_pyscanner, __FILE__, qPrint(fileName));
    ::parseMain(p->yyscanner, fileName,fileBuf,root);

  // May print the AST for debugging purposes
  // printAST(global_root);
}

 bool PrologOutlineParser::needsPreprocessing(const QCString &)
 const
{
  return FALSE;
}

 void PrologOutlineParser::parsePrototype(const QCString &text)
{
//  ::parsePrototype(p->yyscanner,text);

}
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------

#if USE_STATE2STRING
#include "prologscanner.l.h"
#endif


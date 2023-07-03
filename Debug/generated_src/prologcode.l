
%option never-interactive
%option prefix="prologcodeYY"
%option reentrant
%option extra-type="struct prologcodeYY_state *"
%option noyy_top_state
%top{
#include <stdint.h>
}

%{

#include <vector>
#include <unordered_map>
#include <string>
#include <stack>

#include <stdio.h>

#include "prologcode.h"
#include "message.h"
#include "scanner.h"
#include "entry.h"
#include "doxygen.h"
#include "outputlist.h"
#include "util.h"
#include "membername.h"
#include "searchindex.h"
#include "config.h"
#include "groupdef.h"
#include "classlist.h"
#include "filedef.h"
#include "namespacedef.h"
#include "tooltip.h"
#include "scopedtypevariant.h"
#include "symbolresolver.h"
#include "debug.h"

#include "prolog.h"

// Toggle for some debugging info
//#define DBG_CTX(x) fprintf x
#define DBG_CTX(x) do { } while(0)

#define YY_NO_INPUT 1
#define YY_NO_UNISTD_H 1

#define USE_STATE2STRING 0

struct prologcodeYY_state
{
  std::unordered_map< std::string, ScopedTypeVariant > codeClassMap;
 QCString       curClassName;
 QCString       comment;


  OutputCodeList *  code = 0;
  const char *   inputString;     //!< the code fragment as text
  int	      inputPosition;   //!< read offset during parsing
  QCString      fileName;
  const char *   currentFontClass;
bool          insideCodeLine = FALSE;
bool           needsTermination;
  const Definition   * searchCtx;
  bool           collectXrefs;
  int            inputLines;      //!< number of line in the code fragment
  int	          yyLineNr;        //!< current line number
  std::unique_ptr<FileDef> exampleFileDef;
  const FileDef *    sourceFileDef = 0;
  const MemberDef *    currentMemberDef;
   const Definition *   currentDefinition;
   bool           includeCodeFragment;
  QCString       realScope;
//  bool           insideBody;
  int            bodyCurlyCount;
  bool           searchingForBody;
  int            paramParens;
//  int            anchorCount;

  bool           exampleBlock;
  QCString       exampleName;
  QCString       exampleFile;

  QCString       type;
  QCString       module;
  QCString       name;
  QCString       buf;

  QCString       text;

 QCString             source_module, current_module;

  bool           doubleStringIsDoc;

  unsigned long int     level,  arity;

 CallContext      theCallContext;
  TooltipManager tooltipManager;
  SymbolResolver symbolResolver;


};


static void startFontClass(yyscan_t yyscanner,const char *s);
 static void endFontClass(yyscan_t yyscanner);

static void endCodeLine(yyscan_t yyscanner);
static void nextCodeLine(yyscan_t yyscanner);
static QCString cannonical_module( QCString text , const char *mod0);
static int countLines(yyscan_t yyscanner);
static void setCurrentDoc(yyscan_t yyscanner,const QCString &anchor);
static void addToSearchIndex(const char *text);
static void startCodeLine(yyscan_t yyscanner);
static void codify(yyscan_t yyscanner,QCString & text);
static void codify(yyscan_t yyscanner,const char * text);
static void endCodeLine(yyscan_t yyscanner);
static int yyread(yyscan_t yyscanner, char *buf,int max_size);
static void codifyLines(yyscan_t yyscanner, char *text);
static void codifyLines(yyscan_t yyscanner, const QCString &str);
static void     txtToGoal( yyscan_t yyscanner, QCString name );
static void
     indToGoal(yyscan_t yyscanner, QCString name );


//-------------------------------------------------------------------

static std::mutex g_searchIndexMutex;

//-------------------------------------------------------------------

#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) result=yyread(yyscanner,buf,max_size);


%}



/* start command character */



B                 [ \t]*
BB                [ \t]+
NEWLINE           \n
BN                [ \t\n]
BNS               [ \t\n]*

/* Prolog end of term marker */
EOT               {B}"."{BN}


LETTER            [A-Za-z\x80-\xFF]
DIGIT             [0-9]

HEXD              [0-9a-fA-F]
HEXNUMBER         "0"[xX][0-9a-fA-F]+[lL]?

OCTD              [0-7]
OCTNUMBER         "0"[0-7]+[lL]?
NUMBER            {DIGIT}+
CHAR              "0'"(.)

INTNUMBER         {HEXNUMBER}|{OCTNUMBER}|{NUMBER}
FLOATNUMBER       {DIGIT}+"."{DIGIT}+([eE][+\-]?{DIGIT}+)?[jJ]?
EXPCHAR           [#(){}\[\],:./\\=`*~|&<>!;+-]
IDENTIFIER        ([a-z]({LETTER}|{DIGIT}|"_")*)

VAR	              [A-Z_]({LETTER}|{DIGIT}|"_")*

BORDER            ([^A-Za-z0-9])

STRINGCHAR         [^\\"'\n]
ESCAPESEQ          ("\\"[\\n\\abdefnrstvz'"`]|"\\b"{BN}{BNS}|"\\u"{HEXD}+|"\\x"{HEXD}*|"\\"{OCTD}+)
QSTRINGITEM        ({STRINGCHAR}|{ESCAPESEQ}|"''"|"\\'"|"\"")
BQSTRINGITEM        ({STRINGCHAR}|{ESCAPESEQ}|"``"|"\\`"|"\"")
DQSTRINGITEM       ({STRINGCHAR}|{ESCAPESEQ}|"\"\""|"\\\""|"'")

SQSTRING           ("'"({QSTRINGITEM})*"'")
DQSTRING           ("\""({DQSTRINGITEM})*"\"")
BQSTRING           ("`"({BQSTRINGITEM})*"`")

SYMBOL		   ("/"[#&+-./:<>=?@^~`\\]|[#&*+-.:<>=?@^~`\\][#&*+-./:<>=?@^~`\\])([#&*+-./:<>=?@^~`\\])*

SOLO		  [;!]

KEYWORD		   ({SYMBOL}+|{SOLO})

QATOM		   {SQSTRING}

ATOM		   ({IDENTIFIER}|{SQSTRING}|{SYMBOL}+|{SOLO})

ATOMIC             ({ATOM}|{VAR}|{NUMBER}|{SYMBOL}|{DQSTRING})

INDICATOR          (({ATOM}|"("{BN}{ATOM}{BN}")")":")*{ATOM}("/"|"//"){NUMBER}

OPDEC		   {IDENTIFIER}"("{B}{NUMBER}{B}","{B}{IDENTIFIER}{B}","{B}{ATOM}{B})"

LIBRARY		   (({ATOM}"("{B}{ATOM}{B}")")|{ATOM})

FLOWKW             ("spy"|"nospy"|"same"|"block"|"^"|"**"|"\\"|"rem"|"mod"|">>"|"<<"|"//"|"/"|"*"|"r"|"div"|"rdiv"|"#"|"><"|"\\/"|"/\\"|"-"|"-"|"+"|"+"|":"|"as"|">="|"=<"|">"|"<"|"=\\="|"=:="|"\\=@="|"=@="|"@>="|"@=<"|"@>"|"@<"|"\\=="|"=="|"=.."|"is"|"\\="|"="|"not"|"\\+"|"."|","|"*->"|"->"|";"|"|"|"uncutable"|"table"|"discontiguous"|"module_transparent"|"meta_predicate"|"multifile"|"public"|"mode"|"volatile"|"initialization"|"thread_local"|"dynamic"|"?-"|"-->"|":-"|":-")

PERCCOMMENT      "%".*

SLASHSTARSTARTCOMMENT "/*"
SLASHSTARENDCOMMENT   "*/"

PREDTAG               ("det"|"semidet"|"failure"|"nondet"|"multi"|"iso"|"deprecated"|"dynamic"|"directive")

PARAMETERDESCRIPTOR   ([+-?:@!]?({VAR}":"){IDENTIFIER})

PREDINFO              ({BB}"is"{BB}{PREDTAG}({B}","{B}{PREDTAG})*{B}{NEWLINE})

COMPOUND	      {ATOM}"("

%option noyywrap
%option stack
						
%x Program

%x FunctionParams
%x FunctionParams0

%x Body

%x SkipComment

%%

<Program>{



    ":-"{B}*("system_")?"module("{B}*{ATOM}         {
	// a function
	 yyextra->text = yytext;
	 yyextra->level = 0;
	const char *s = yytext+2;
	while (*s != 's' && *s != 'm') s++;
	const char *parent_mod = (s[0] == 'm' ? yyextra->current_module.data() : "prolog");
	 yyextra->source_module = yyextra->current_module;
	size_t i =  yyextra->text.find("(");
	startFontClass( yyscanner, "keyword");
	QCString t =  yyextra->text.left(i+1);
	codify( yyscanner,t);
	endFontClass(yyscanner);
	 yyextra->text =  yyextra->text.remove(0, i+1);
	startFontClass( yyscanner, "preprocessor");
	codify( yyscanner,yyextra->text);
	endFontClass(yyscanner);
	if (s[0] == 'm') {
	     yyextra->text = cannonical_module(  yyextra->text , parent_mod);
	} else {
	     yyextra->text = "prolog";
	}
	yyextra->current_module =  yyextra->text;
	 yyextra->source_module = yyextra->current_module;
	 yyextra->level = 0;
	BEGIN( FunctionParams );
    }

    ":-"{B}          {
	codify(yyscanner,yytext);
	BEGIN( Body );
    }


    . {
	unput(yytext[0]);
	BEGIN( Body );
    }

}

<Body>{b


    {B}*({ATOM}|{VAR})("."({ATOM}|{VAR}))*("("|"{"|"["){B} {
	 yyextra->text = yytext;
	 yyextra->name =  yyextra->text;
	int f =  yyextra->text.find("(");
	if (f < 0) f =  yyextra->text.find("[");
	else if (f < 0) f =  yyextra->text.find("{");
	 yyextra->name  =  yyextra->name.left(f);
	 yyextra->name =  yyextra->name.stripWhiteSpace();
	if (((size_t)f > yyextra->name.length())) {
	    codify( yyscanner, yyextra->text.left(f- yyextra->name.length()).data());
	}
	 yyextra->buf =  yyextra->text.right( yyextra->text.length()-f);
	 yyextra->level =1;
	 yyextra->arity = 0;
	BEGIN( FunctionParams0 );

    }

  
    ","                   {
	 yyextra->text += yytext;
	if ( yyextra->level == 1) {
	     yyextra->arity++;
	}
	codify(yyscanner,yytext);
	// Parses delimiters
    }

    {B}*("["|"{"|"(")  {
	 yyextra->text += yytext;
	codify( yyscanner,yytext);
	 yyextra->level++;
    }


    ({SQSTRING}|{DQSTRING}|{BQSTRING})         {
	startFontClass( yyscanner, "stringliteral");
	 yyextra->text += yytext;
	codify( yyscanner,yytext);
	endFontClass( yyscanner);
    }

    {FLOWKW}					{

	startFontClass( yyscanner, "keyword");
	 yyextra->text += yytext;
	codify( yyscanner,yytext);
	endFontClass( yyscanner);
    }

    {VAR}					{

	startFontClass( yyscanner, "charliteral");
	codify( yyscanner,yytext);

	 yyextra->text += yytext;
	endFontClass( yyscanner);
    }

    ("]"|")"|"}")                             {
	 yyextra->text  += yytext;
	 yyextra->level--;
	codify( yyscanner,yytext);
	 yyextra->name = "";
    }

    {ATOM}					{

	 yyextra->text += yytext;
	if (  yyextra->level == 0) {
	     yyextra->arity=0;
	    txtToGoal( yyscanner, yyextra->name );
	} else {
	    codify( yyscanner,yytext);
	}
    }

    {NUMBER}					{
	 yyextra->text += yytext;
	startFontClass( yyscanner, "vhldigit");
	codify( yyscanner,yytext);
	endFontClass( yyscanner);

    }
 
    .  {

	 yyextra->text += yytext;
	codify( yyscanner,yytext);

    }



    {EOT} {
	codifyLines(yyscanner,yytext);
	BEGIN(Program);
    }


 }



<FunctionParams0>{

    ","                      {
	if ( yyextra->level == 1)
	     yyextra->arity++;
         yyextra->buf += yytext;
	// Parses delimiters
    }

    ("["|"("|"{") {
	 yyextra->level++;
	 yyextra->buf += yytext;
    }
 
\n {
     yyextra->buf += yytext;
}

({SQSTRING}|{DQSTRING}|{BQSTRING}|{NUMBER}|{VAR}|{ATOM}|{BN}|";"|"|")         {
     yyextra->buf += yytext;
}

(")"|"]"|"}")                             {
     yyextra->buf += yytext;
     yyextra->level--;
    if (  yyextra->level == 0) {
	 yyextra->arity += 1;
	txtToGoal( yyscanner, yyextra->name );
	const char *ds =  yyextra->buf.data();
	for (int i=  yyextra->buf.size()-1; i>= 0; i--) {
	    unput( ds[i]);
	}
	 yyextra->level = 0;
	BEGIN( FunctionParams ) ;
    }
}


. {
	     yyextra->buf += yytext;
	     }
}


<FunctionParams>{

	","                      {
codify( yyscanner,yytext);
		 yyextra->text += yytext;
 		// Parses delimiters
	}

	 {B}*("("|"["|"{") {
   codify( yyscanner,yytext);
 		 yyextra->level++;
	}

		{B}*(")"|"]"|"}") {
		 yyextra->text += yytext;
 codify( yyscanner,yytext);
 		 yyextra->level--;
		if (  yyextra->level == 0) {
		 BEGIN( Body ) ;
		}
	}

 ({SQSTRING}|{DQSTRING}|{BQSTRING})         {
	startFontClass( yyscanner, "stringliteral");
  codify( yyscanner,yytext);
 		 yyextra->text += yytext;
                        endFontClass( yyscanner);
}

{FLOWKW}					{                                                                          
	startFontClass( yyscanner, "keyword");
		 yyextra->text += yytext;
codify( yyscanner,yytext);
    endFontClass( yyscanner);
 }

{VAR}					{

                          startFontClass( yyscanner, "charliteral");

 codify( yyscanner,yytext);
		 yyextra->text += yytext;
                         endFontClass( yyscanner);
}

{ATOM}					{

		 yyextra->text += yytext;
codify( yyscanner,yytext);
 }

{NUMBER}					{

		 yyextra->text += yytext;
  startFontClass( yyscanner, "vhldigit");
  codify( yyscanner,yytext);
 endFontClass( yyscanner);

 }
 
}

<SkipComment>{
    "*"+"/"			{
         yyextra->comment += yytext;
	codifyLines( yyscanner,yyextra->comment);
	endFontClass( yyscanner);
	BEGIN( Program ) ; }

    ("*"+|[^*\n]+)					{

	 yyextra->comment += yytext;
    }

    "\n"					{
	 yyextra->comment += yytext;
    }

 }

<*>{SLASHSTARSTARTCOMMENT}	{
	startFontClass( yyscanner, "comment");
	 yyextra->comment = yytext;
	BEGIN( SkipComment );

}


<*>"%".*  {
                // This eats EVERYTHING
                startFontClass( yyscanner, "comment");
                codifyLines(yyscanner,yytext);
                endFontClass( yyscanner);
            }


<*>{FLOWKW}         {
	// flow keyword like "!", ".", ";"
	startFontClass( yyscanner, "keyword");
	codifyLines(yyscanner,yytext);
	if (! yyextra->text.isEmpty())
		endFontClass( yyscanner);
	 yyextra->text += yytext;
}


<*>{INDICATOR}             {
  			 yyextra->arity =0;
   indToGoal( yyscanner,yytext );

}


<*>.                           {
	// printf("[prologcode] '%s' [ state %d ]  [line %d] no match\n",
	//        yytext, YY_START,  yyextra->yyLineNr);

	//endFontClass( yyscanner);
  	codify( yyscanner,yytext);

}

<*>\n                          {
    endCodeLine(yyscanner);
	// codify( yyscanner,"\n");
	// printf("[prologcode] '%s' [ state %d ]  [line %d] no match\n",
	//        yytext, YY_START,  yyextra->yyLineNr);
     yyextra->yyLineNr++;
    startCodeLine(yyscanner);
	//endFontClass( yyscanner);

}

<*><<EOF>> {
                            yyterminate();
}


%%

/*@ ----------------------------------------------------------------------------
 */




static QCString
  cannonical_module( QCString text , const char *mod0)
{
  if (mod0 && strncmp(mod0, "prolog", 6) == 0)
    return "prolog";
  if (text.isEmpty())
    return mod0;
  text = text.stripWhiteSpace();
  const char *s = text.data();
  size_t last = strlen(s) - 1;
  if (s[0] == '\''&& s[last] == '\'') {
    text.remove(last , 1);
    text.remove(0, 1);
  }
  return text;
}

/*! counts the number of lines in the input */
static int countLines(yyscan_t yyscanner)
{
   struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
 const char *p= yyextra->inputString;
  char c;
  int count=1;
  while ((c=*p))
  {
    p++ ;
    if (c=='\n') count++;
  }
  if (p> yyextra->inputString && *(p-1)!='\n')
  { // last line does not end with a \n, so we add an extra
    // line and explicitly terminate the line after parsing.
    count++,
     yyextra->needsTermination=TRUE;
  }
  return count;
}

static void setCurrentDoc(yyscan_t yyscanner,const QCString &anchor)
{
  struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  if (Doxygen::searchIndex)
  {
    if ( yyextra->searchCtx)
    {
      Doxygen::searchIndex->setCurrentDoc(  yyextra->searchCtx, yyextra->searchCtx->anchor(),FALSE);
    }
    else
    {
      Doxygen::searchIndex->setCurrentDoc(  yyextra->sourceFileDef,anchor,TRUE);
    }
  }
}

static void addToSearchIndex(const char *text)
{
  if (Doxygen::searchIndex)
  {
    Doxygen::searchIndex->addWord(text,FALSE);
  }
}



/*! start a new line of code, inserting a line number if  yyextra->sourceFileDef
 * is TRUE. If a definition starts at the current line, then the line
 * number is linked to the documentation of that definition.
 */
static void startCodeLine(yyscan_t yyscanner)
{
    struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  //if ( yyextra->currentFontClass) {  yyextra->code->endFontClass(); }
  if ( yyextra->sourceFileDef)
  {
    //QCString lineNumber,lineAnchor;
    //lineNumber.sprintf("%05d", yyextra->yyLineNr);
    //lineAnchor.sprintf("l%05d", yyextra->yyLineNr);

    const Definition *d   =  yyextra->sourceFileDef->getSourceDefinition( yyextra->yyLineNr);
    //printf("startCodeLine %d d=%p\n", yyextra->yyLineNr,d);
    // yyextra->code->startLineNumber();

    if (! yyextra->includeCodeFragment && d && d->isLinkableInProject())
    {
       yyextra->currentDefinition = d;
       yyextra->currentMemberDef =  yyextra->sourceFileDef->getSourceMember( yyextra->yyLineNr);
      // yyextra->insideBody = FALSE;
       yyextra->searchingForBody = TRUE;
       yyextra->realScope = d->name();
      //printf("Real scope: '%s'\n", yyextra->realScope.data());
       yyextra->bodyCurlyCount = 0;
      QCString lineAnchor;
      lineAnchor.sprintf("l%05d", yyextra->yyLineNr);
      if ( yyextra->currentMemberDef)
      {
         yyextra->code->writeLineNumber( yyextra->currentMemberDef->getReference(),
	                         yyextra->currentMemberDef->getOutputFileBase(),
	                         yyextra->currentMemberDef->anchor(), yyextra->yyLineNr,
                                !yyextra->includeCodeFragment);
        setCurrentDoc( yyscanner, lineAnchor);
      }
      else
      {
         yyextra->code->writeLineNumber(d->getReference(),
	                        d->getOutputFileBase(),
	                        0, yyextra->yyLineNr,
                                !yyextra->includeCodeFragment);
        setCurrentDoc( yyscanner, lineAnchor);
      }
    }
    else
    {
      // yyextra->code->codify(lineNumber);
       yyextra->code->writeLineNumber(0,0,0, yyextra->yyLineNr,
                                !yyextra->includeCodeFragment);
    }
    // yyextra->code->endLineNumber();
  }
   yyextra->code->startCodeLine(     yyextra->sourceFileDef);
  yyextra->insideCodeLine = TRUE;
  if ( yyextra->currentFontClass)
  {
     yyextra->code->startFontClass(  yyextra->currentFontClass);
  }
}

static void codify( yyscan_t yyscanner,const char* text)
{
    struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
   yyextra->code->codify(text);
}


static void codify( yyscan_t yyscanner,QCString & text)
{
    struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
   yyextra->code->codify(text.data());
}

static void endCodeLine(yyscan_t yyscanner)
{
     struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
 endFontClass( yyscanner);
   yyextra->code->endCodeLine();
  yyextra->insideCodeLine=false;
}

//-------------------------------------------------------------------------------

static void nextCodeLine(yyscan_t yyscanner)
{
  struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  const char *fc = yyextra->currentFontClass;
  if (yyextra->insideCodeLine)
  {
    endCodeLine(yyscanner);
  }
  if (yyextra->yyLineNr<yyextra->inputLines)
  {
    yyextra->currentFontClass = fc;
    startCodeLine(yyscanner);
  }
}


/*! writes a link to a fragment \a text that may span multiple lines, inserting
 * line numbers for each line. If \a text contains newlines, the link will be
 * split into multiple links with the same destination, one for each line.
 */
static void writeMultiLineCodeLink(yyscan_t yyscanner,
    OutputCodeList &ol,
                  const Definition *d,
                  const QCString &text)
{
    struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
  bool sourceTooltips = Config_getBool(SOURCE_TOOLTIPS);
  yyextra->tooltipManager.addTooltip(d);
  QCString ref  = d->getReference();
  QCString file = d->getOutputFileBase();
  QCString anchor = d->anchor();

  QCString tooltip;
  if (!sourceTooltips) // fall back to simple "title" tooltips
  {
    tooltip = d->briefDescriptionAsTooltip();
  }
  bool done=FALSE;
  const char *p=text.data();
  while (!done)
  {
    const char *sp=p;
    char c;
    while ((c=*p++) && c!='\n') { }
    if (c=='\n')
    {
       yyextra->yyLineNr++;
      //printf("writeCodeLink(%s,%s,%s,%s)\n",ref,file,anchor,sp);
      ol.writeCodeLink(d->codeSymbolType(),ref,file,anchor,QCString(sp,p-sp-1),tooltip);
      nextCodeLine(yyscanner);
    }
    else
    {
      //printf("writeCodeLink(%s,%s,%s,%s)\n",ref,file,anchor,QCString(sp,p-sp-1),tooltip);
      ol.writeCodeLink(d->codeSymbolType(),ref,file,anchor,sp,tooltip);
      done=TRUE;
    }
  }
}


 #undef YY_INPUT
 #define YY_INPUT(buf,result,max_size) result=yyread(buf,max_size);

 static int yyread(yyscan_t yyscanner, char *buf,int max_size)
 {
   struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
    int c=0;
     while( c < max_size &&  yyextra->inputString[ yyextra->inputPosition] )
     {
         *buf =  yyextra->inputString[ yyextra->inputPosition++] ;
         c++; buf++;
     }
     return c;
 }

static void codifyLines(yyscan_t yyscanner, char *text)
{
   struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
 //printf("codifyLines(%d,\"%s\")\n", yyextra->yyLineNr,text);
  char *p=text,*sp=p;
  char c;
  bool done=FALSE;
  const char *  tmp_currentFontClass =  yyextra->currentFontClass;
  while (!done)
  {
    sp=p;

    while ((c=*p++) && c!='\n') { }
    if (c=='\n')
    {
       yyextra->yyLineNr++;
      *(p-1)='\0';
       yyextra->code->codify(sp);
      endCodeLine(yyscanner);
      if ( yyextra->yyLineNr< yyextra->inputLines)
      {
        startCodeLine(   yyscanner);
      }
      if (tmp_currentFontClass)
      {
        startFontClass(yyscanner, tmp_currentFontClass);
      }
    }
    else
    {
       yyextra->code->codify(sp);
      done=TRUE;
    }
  }
}

static void codifyLines(yyscan_t yyscanner, const QCString &str)
{
  char *tmp= (char *)malloc(str.length()+1);
  qstrcpy(tmp, str.data());
  codifyLines(yyscanner, tmp);
  free(tmp);
}


/*
  For a given string in the source code,
  finds its class or global id and links to it.
*/
static bool
generateClassOrGlobalLink(yyscan_t yyscanner, OutputCodeList &ol,const QCString className, QCString oname)
{
   // Don't do anything for empty text
  if (className.isEmpty()) return false;
  ClassDef *cd = getClass(className);  /** Class def that we may find */
  //printf("%s cd=%p\n",className.data(),cd);
  if (cd && cd->isLinkable()) // is it a linkable class
	{
		writeMultiLineCodeLink(yyscanner, ol,cd,oname);
		addToSearchIndex(className.data());
        return true;
        }
        return false;
}


 static void startFontClass(yyscan_t yyscanner,const char *s)
 {
    struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
   endFontClass( yyscanner);
      yyextra->code->startFontClass(  s);
      yyextra->currentFontClass=s;
 }

 static void endFontClass(yyscan_t yyscanner)
 {
   struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
    if ( yyextra->currentFontClass)
     {
          yyextra->code->endFontClass();
          yyextra->currentFontClass=0;
     }
 }

 static void
     txtToGoal( yyscan_t yyscanner, QCString name )
 {
    struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
   Pred inp = Pred(yyextra->current_module, name,  yyextra->arity);

     startFontClass( yyscanner, "stringliteral");

     if (generateClassOrGlobalLink(yyscanner, * yyextra->code, inp.link(), name) ) {
         endFontClass(yyscanner);
     } else {
         endFontClass(yyscanner);
         codifyLines( yyscanner, name );
     }
}



 static void
     indToGoal(yyscan_t yyscanner, QCString name )
 {
   struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;
    Pred inp = Pred( name, yyextra->current_module );

     startFontClass(   yyscanner, "stringliteral");

     if (generateClassOrGlobalLink(yyscanner, * yyextra->code, inp.link(), inp.predName(yyextra->current_module) ) ) {
         endFontClass( yyscanner);
     } else {
         endFontClass( yyscanner);
         codifyLines( yyscanner, name );
     }
}

struct  PrologCodeParser::Private
{
  yyscan_t yyscanner;
  prologcodeYY_state state;
};

 PrologCodeParser:: PrologCodeParser() : p(std::make_unique<Private>())
{
  prologcodeYYlex_init_extra(&p->state,&p->yyscanner);
#ifdef FLEX_DEBUG
  prologcodeYYset_debug(1,p->yyscanner);
#endif
  resetCodeParserState();
}

 PrologCodeParser::~ PrologCodeParser()
{
  prologcodeYYlex_destroy(p->yyscanner);
}

void  PrologCodeParser::resetCodeParserState()
{
   struct yyguts_t *yyg = (struct yyguts_t*)p->yyscanner;
  yyextra->currentMemberDef = 0;
   yyextra->doubleStringIsDoc = FALSE;
   yyextra->paramParens = 0;
  BEGIN( Program );
}

void  PrologCodeParser::parseCode(OutputCodeList &codeOutIntf,
                                            const QCString &scopeName,
                                            const QCString &input,
                                            SrcLangExt lang,
                                            bool isExampleBlock,
                                            const QCString &exampleName,
                                            const FileDef *fileDef,
                                            int startLine,
                                            int endLine,
                                            bool inlineFragment,
                                            const MemberDef *memberDef,
                                            bool showLineNumbers,
                                            const Definition *searchCtx,
                                            bool collectXrefs
                            )
{
  yyscan_t yyscanner = p->yyscanner;
  struct yyguts_t *yyg = (struct yyguts_t*)yyscanner;

  //--------------------------------------
  if (input.isEmpty()) return;
  DebugLex debugLex(Debug::Lex_pycode, __FILE__, fileDef ? qPrint(fileDef->fileName()): NULL);
  yyextra->fileName      = fileDef ? fileDef->fileName():"";
   yyextra->code = &codeOutIntf;
   yyextra->inputString   = input.data();
   yyextra->inputPosition = 0;
   yyextra->currentFontClass = 0;
   yyextra->needsTermination = FALSE;
   yyextra->searchCtx=searchCtx;
  yyextra->collectXrefs=collectXrefs;

  if (startLine!=-1)
     yyextra->yyLineNr    = startLine;
  else
     yyextra->yyLineNr    = 1;
  if (endLine!=-1)
     yyextra->inputLines  =       endLine+1;
  else
     yyextra->inputLines  = countLines( p->yyscanner);

   yyextra->exampleBlock  = isExampleBlock;
   yyextra->exampleName   = exampleName;
   yyextra->sourceFileDef =fileDef;
    yyextra->symbolResolver.setFileScope(fileDef);

//  bool cleanupSourceDef = FALSE;
  if (yyextra->exampleBlock && fileDef==0)
  {
    // create a dummy filedef for the example
    yyextra->exampleFileDef = createFileDef("",(!exampleName.isEmpty()?qPrint(exampleName):"generated"));
    yyextra->sourceFileDef = yyextra->exampleFileDef.get();
  }
  if ( yyextra->sourceFileDef)
  {
    setCurrentDoc( yyscanner, "l00001");
  }
  
  yyextra->current_module = "user";
     yyextra->includeCodeFragment = inlineFragment;
yyextra->source_module = yyextra->current_module;

   yyextra->includeCodeFragment = inlineFragment;
   // Starts line 1 on the output
    startCodeLine(yyscanner);

    prologcodeYYrestart(0,yyscanner);

    prologcodeYYlex(yyscanner);


    if (yyextra->needsTermination)
    {
      endCodeLine(yyscanner);
    }

if (yyextra->insideCodeLine)
  {
    endCodeLine(yyscanner);
  }

  if (yyextra->exampleFileDef)
  {
    // delete the temporary file definition used for this example
    yyextra->exampleFileDef.reset();
    yyextra->sourceFileDef=0;
  }
  // write the tooltips
  yyextra->tooltipManager.writeTooltips(codeOutIntf);

}



#if !defined(YY_FLEX_SUBMINOR_VERSION)
//----------------------------------------------------------------------------
extern "C" { // some bogus code to keep the compiler happy
  void prologscannerYYdummy() { yy_flex_realloc(0,0); }
}
#endif


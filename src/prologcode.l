/******************************************************************************
 *
 *
 *
 * Copyright (C) 1997-2014 by Dimitri van Heesch.
 *
 * Permission to use, copy, and distribute this software and its
 * documentation under the terms of the GNU General Public License is hereby
 * granted. We make no representations about the suitability of this software
 * for any purpose. doxygen-yap is provided "as is" without express or implied warranty.
 * See the GNU General Public License for more details.
 *
 * Documents produced by Doxygen are derivative works derived from the
 * input used in their production; they are not affected by this license.
 *
 */
/*  This code is based on the work done by the MoxyPyDoxy team
 *  (Linda Leong, Mike Rivera, Kim Truong, and Gabriel Estrada)
 *  in Spring 2005 as part of CS 179E: Compiler Design Project
 *  at the University of California, Riverside; the course was
 *  taught by Peter H. Froehlich <phf@acm.org>.
 */

%option never-interactive
%option prefix="prologcodeYY"

%{


#include <stdio.h>
#include "prologcode.h"
#include "prologscanner.h"
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

// Toggle for some debugging info
//#define DBG_CTX(x) fprintf x
#define DBG_CTX(x) do { } while(0)

#define YY_NO_INPUT 1
#define YY_NO_UNISTD_H 1

static ClassSDict    g_codeClassSDict(17);
static QCString      g_curClassName;
static QCString      g_comment;


static CodeOutputInterface * g_code;
static const char *  g_inputString;     //!< the code fragment as text
static int	     g_inputPosition;   //!< read offset during parsing
static const char *  g_currentFontClass;
static bool          g_needsTermination;
static Definition   *g_searchCtx;
static bool          g_collectXRefs;
static int           g_inputLines;      //!< number of line in the code fragment
//static int	         yylineno;        //!< current line number
 static FileDef *     g_sourceFileDef;
 static MemberDef *   g_currentMemberDef;
 static Definition *  g_currentDefinition;
 static bool          g_includeCodeFragment;
static QCString      g_realScope;
//static bool          g_insideBody;
static int           g_bodyCurlyCount;
static bool          g_searchingForBody;
static int           g_paramParens;
//static int           g_anchorCount;

static bool          g_exampleBlock;
static QCString      g_exampleName;
static QCString      g_exampleFile;

static QCString      g_type;
static QCString      g_name;
static QCString      g_buf;

static QCString      g_text;

QCString            current_module_name;

static bool          g_doubleStringIsDoc;

unsigned long int    g_level, g_arity;

static void endFontClass( void );

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

class PrologCallContext
{
  public:
    struct Ctx
    {
      Ctx() : name(g_name), type(g_type), cd(0) {}
      QCString name;
      QCString type;
      ClassDef *cd;
    };

    PrologCallContext()
    {
      m_classList.append(new Ctx);
      m_classList.setAutoDelete(TRUE);
    }

    virtual ~PrologCallContext() {}

    void setClass(ClassDef *cd)
    {
      Ctx *ctx = m_classList.getLast();
      if (ctx)
      {
        ctx->cd=cd;
      }
    }
    void pushScope()
    {
      m_classList.append(new Ctx);
    }

    void popScope()
    {
      if (m_classList.count()>1)
      {
	Ctx *ctx = m_classList.getLast();
	if (ctx)
	{
	  g_name = ctx->name;
	  g_type = ctx->type;
	}
	m_classList.removeLast();
      }
      else
      {
      }
    }

    void clear()
    {
      m_classList.clear();
      m_classList.append(new Ctx);
    }

    ClassDef *getClass() const
    {
      Ctx *ctx = m_classList.getLast();

      if (ctx)
        return ctx->cd;
      else
        return 0;
    }

  private:
    QList<Ctx> m_classList;
};

static PrologCallContext g_theCallContext;


/*! counts the number of lines in the input */
static int countLines()
{
  const char *p=g_inputString;
  char c;
  int count=1;
  while ((c=*p))
  {
    p++ ;
    if (c=='\n') count++;
  }
  if (p>g_inputString && *(p-1)!='\n')
  { // last line does not end with a \n, so we add an extra
    // line and explicitly terminate the line after parsing.
    count++,
    g_needsTermination=TRUE;
  }
  return count;
}

static void setCurrentDoc(const QCString &anchor)
{
  if (Doxygen::searchIndex)
  {
    if (g_searchCtx)
    {
      Doxygen::searchIndex->setCurrentDoc(g_searchCtx,g_searchCtx->anchor(),FALSE);
    }
    else
    {
      Doxygen::searchIndex->setCurrentDoc(g_sourceFileDef,anchor,TRUE);
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



/*! start a new line of code, inserting a line number if g_sourceFileDef
 * is TRUE. If a definition starts at the current line, then the line
 * number is linked to the documentation of that definition.
 */
static void startCodeLine()
{
  //if (g_currentFontClass) { g_code->endFontClass(); }
  if (g_sourceFileDef)
  {
    //QCString lineNumber,lineAnchor;
    //lineNumber.sprintf("%05d",yylineno);
    //lineAnchor.sprintf("l%05d",yylineno);

    Definition *d   = g_sourceFileDef->getSourceDefinition(yylineno);
    //printf("startCodeLine %d d=%p\n",yylineno,d);
    //g_code->startLineNumber();
    if (!g_includeCodeFragment && d && d->isLinkableInProject())
    {
      g_currentDefinition = d;
      g_currentMemberDef = g_sourceFileDef->getSourceMember(yylineno);
      //g_insideBody = FALSE;
      g_searchingForBody = TRUE;
      g_realScope = d->name().copy();
      //printf("Real scope: `%s'\n",g_realScope.data());
      g_bodyCurlyCount = 0;
      QCString lineAnchor;
      lineAnchor.sprintf("l%05d",yylineno);
      if (g_currentMemberDef)
      {
        g_code->writeLineNumber(g_currentMemberDef->getReference(),
	                        g_currentMemberDef->getOutputFileBase(),
	                        g_currentMemberDef->anchor(),yylineno);
        setCurrentDoc(lineAnchor);
      }
      else
      {
        g_code->writeLineNumber(d->getReference(),
	                        d->getOutputFileBase(),
	                        0,yylineno);
        setCurrentDoc(lineAnchor);
      }
    }
    else
    {
       //QCString lineAnchor;
     // lineAnchor.sprintf("l%05d",yylineno);
     // g_code->codify(lineAnchor);
      g_code->writeLineNumber(0,0,0,yylineno);
    }
    //g_code->endLineNumber();
  } else {
      g_code->writeLineNumber(0,0,0,yylineno);
  }
  g_code->startCodeLine(g_sourceFileDef);
  if (g_currentFontClass)
  {
    g_code->startFontClass(g_currentFontClass);
  }
}

static void codify(const char* text)
{
  g_code->codify(text);
}

static void endCodeLine()
{
  endFontClass();
  g_code->endCodeLine();
}

static void nextCodeLine()
{
  const char *fc = g_currentFontClass;
  endCodeLine();
  if (yylineno<g_inputLines)
  {
    g_currentFontClass = fc;
    startCodeLine();
  }
}

static int
ils(char *space) // ignore a char
{
    int count=0, ch;
    char *ptr = space;
    while ((ch = *ptr++)) {
        if (ch == '\n' && (ptr[0] == '\n' || ptr[0]=='\0'))
        count++;
    }
    return count;
}

/*! writes a link to a fragment \a text that may span multiple lines, inserting
 * line numbers for each line. If \a text contains newlines, the link will be
 * split into multiple links with the same destination, one for each line.
 */
static void writeMultiLineCodeLink(CodeOutputInterface &ol,
                  Definition *d,
                  const char *text)
{
  static bool sourceTooltips = Config_getBool(SOURCE_TOOLTIPS);
  TooltipManager::instance()->addTooltip(d);
  QCString ref  = d->getReference();
  QCString file = d->getOutputFileBase();
  QCString anchor = d->anchor();
  QCString tooltip;
  if (!sourceTooltips) // fall back to simple "title" tooltips
  {
    tooltip = d->briefDescriptionAsTooltip();
  }
  bool done=FALSE;
  char *p=(char *)text;
  while (!done)
  {
    char *sp=p;
    char c;
    while ((c=*p++) && c!='\n') { }
    if (c=='\n')
    {
      yylineno++;
      *(p-1)='\0';
      //printf("writeCodeLink(%s,%s,%s,%s)\n",ref.data(),file.data(),anchor.data(),sp);
      ol.writeCodeLink(ref,file,anchor,sp,tooltip);
      nextCodeLine();
    }
    else
    {
        //        printf("writeCodeLink(%s,%s,%s,%s)\n",ref.data(),file.data(),anchor.data(),sp);
      ol.writeCodeLink(ref,file,anchor,sp,tooltip);
      done=TRUE;
    }
  }
}


static void codifyLines(const char *text)
{
  const char *p=text;
  char n[1024];
  char c;
  bool done=FALSE;

  while (!done)
  {
    char *o=n;
    while ((c=*p++) && c!='\n') {
    *o++ =  c;
    }
    if (c=='\n')
    {
      yylineno++;
      o[0]='\0';
      g_code->codify(n);
      nextCodeLine();
      n[0] ='\0';
    }
    else
    {
      o[0]='\0';
      g_code->codify(n);
      done=true;
    }
  }
}
//void j_bug(void);
//void j_bug(void) { printf("%s\n", g_text.data()); }


/*
  For a given string in the source code,
  finds its class or global id and links to it.
*/
static bool
generateClassOrGlobalLink(CodeOutputInterface &ol,const QCString className, QCString oname)
{
   // Don't do anything for empty text
  if (className.isEmpty()) return false;
  ClassDef *cd = getClass(className);  /** Class def that we may find */
  printf("%s cd=%p\n",className.data(),cd);
  if (cd && cd->isLinkable()) // is it a linkable class
	{
		writeMultiLineCodeLink(ol,cd,oname);
		addToSearchIndex(className);
        return true;
        }
        return false;
}


 static void startFontClass(const char *s)
 {
     endFontClass();
     g_code->startFontClass(s);
     g_currentFontClass=s;
 }

 static void endFontClass()
 {
     if (g_currentFontClass)
     {
         g_code->endFontClass();
         g_currentFontClass=0;
     }
 }

 #undef YY_INPUT
 #define YY_INPUT(buf,result,max_size) result=yyread(buf,max_size);

 static int yyread(char *buf,int max_size)
 {
     int c=0;
     while( c < max_size && g_inputString[g_inputPosition] )
     {
         *buf = g_inputString[g_inputPosition++] ;
         c++; buf++;
     }
     return c;
 }


 static void
     txtToGoal( QCString name )
 {
Pred inp = Pred(current_module_name, name, g_arity);

     startFontClass("stringliteral");

          fprintf( stderr,"***** %s :> %s : %lu ---> %s\n", current_module_name.data(), name.data(), g_arity, inp.link().data());
     if (generateClassOrGlobalLink(*g_code, inp.link(), name) ) {
         endFontClass();
     } else {
         endFontClass();
         codifyLines( name );
     }
}



 static void
     indToGoal( QCString name )
 {
Pred inp = Pred(current_module_name, name
);

     startFontClass("stringliteral");

//          fprintf( stderr,"***** %s :> %s : %lu ---> %s\n", current_module_name.data(), name.data(), g_arity, nname.data());
     if (generateClassOrGlobalLink(*g_code, inp.link(), inp.predName() ) ) {
         endFontClass();
     } else {
         endFontClass();
         codifyLines( name );
     }
}

%}



/* start command character */



B                 [ \t]*
BB                [ \t]+



NEWLINE           \n
BN                [ \t\n]
BNS               [ \t\n]*

/* Prolog end of term marker */
EOT               {B}"."{BN}

DIGIT             [0-9]

HEXD              [0-9a-fA-F]
HEXNUMBER         "0"[xX][0-9a-fA-F]+[lL]?

OCTD              [0-7]
OCTNUMBER         "0"[0-7]+[lL]?
NUMBER            {DIGIT}+
CHAR              "0'"(.)

INTNUMBER         {HEXNUMBER}|{OCTNUMBER}|{NUMBER}
FLOATNUMBER       {DIGIT}+"."{DIGIT}+([eE][+\-]?{DIGIT}+)?[jJ]?
LETTER            [A-Za-z\x80-\xFF]
NONEMPTY          [A-Za-z0-9_\x80-\xFF]
EXPCHAR           [#(){}\[\],:./\\=`*~|&<>!;+-]
IDENTIFIER        ([a-z]({LETTER}|{DIGIT}|"_")*)

VAR	              [A-Z_]({LETTER}|{DIGIT}|"_")*

BORDER            ([^A-Za-z0-9])

STRINGCHAR         [^\\"'\n]
ESCAPESEQ          ("\\"[\\n\\abdefnrstvz'"`]|"\\b"{BN}{BNS}|"\\u"{HEXD}+|"\\x"{HEXD}*|"\\"{OCTD}+)
QSTRINGITEM        ({STRINGCHAR}|{ESCAPESEQ}|"''"|"\\'"|"\"")
DQSTRINGITEM       ({STRINGCHAR}|{ESCAPESEQ}|"\"\""|"\\\""|"'")

SQSTRING           ("'"({QSTRINGITEM})*"'")
DQSTRING           ("\""({QSTRINGITEM})*"\"")

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

%x Program

%x FunctionParams
%x FunctionParams0

%x Body

%x SkipComment

%%

<Program>{

{B}({ATOM}{B}:)?{B}{ATOM}"(" {
  g_name = yytext;
 g_name  = g_name.left(g_name.size()-1);
  g_buf = "(";
 g_level =1;
 g_arity = 0;
  BEGIN( FunctionParams0 );

}


{B}({ATOM}{B}:)?{B}{ATOM} {
  g_name = yytext;
 g_name  = g_name.left(g_name.size());
  g_buf = "";
 g_arity = 0;
  BEGIN( Body );
g_text = "";

}


	":-"{B}("system_")?"module("{B}{ATOM}          {
	  // a function
	  g_text = yytext;
	  g_level = 0;
	  const char *s = yytext+2;
	  while (*s != 's' && *s != 'm') s++;
	  const char *parent_mod = (s[0] == 'm' ? current_module_name.data() : "prolog");
	  size_t i = g_text.find("(");
	  startFontClass("keyword");
	  codify(g_text.left(i+1).data());
	  endFontClass();
	  g_text = g_text.remove(0, i+1);
	  startFontClass("preprocessor");
	  codify(g_text.data());
	  endFontClass();
      if (s[0] == 'm') {
	  g_text = cannonical_module( g_text , parent_mod);
      } else {
g_text = "prolog";
}
	  current_module_name = g_text;
g_level = 1;
  BEGIN( Body );
}

	":-"{B}          {
  codify(yytext);
  BEGIN( Body );
}

}

<FunctionParams0>{

	","                      {
		if (g_level == 1)
         g_arity++;
        g_buf += yytext;
 		// Parses delimiters
	}

	[({[]  {
 		g_level++;
      g_buf += yytext;
 	}
	[\]}]  {
 		g_level--;
      g_buf += yytext;
 	}

	\n {
     g_buf += yytext;
   	}

 ({SQSTRING}|{DQSTRING})         {
      g_buf += yytext;
 }

                {NUMBER} {
      g_buf += yytext;
 }

{VAR}					{
      g_buf += yytext;
 }

	")"                             {
       g_buf += yytext;
		 g_level--;
		if ( g_level == 0) {
			g_arity += 1;
   txtToGoal( g_name );
    const char *ds = g_buf.data();
     for (int i= g_buf.size()-1; i>= 0; i--) {
	unput( ds[i]);
	 }
	g_level = 1;
		 BEGIN( FunctionParams ) ;
		}
	}


<*><INDICATOR> {

      g_buf += yytext;

}
{ATOM} {

      g_buf += yytext;
 }

	. {
      g_buf += yytext;
  	}



}



<FunctionParams>{

	","                      {
		g_text += yytext;
 codify(yytext);
 		// Parses delimiters
	}

	[({[]  {
   codify(yytext);
 		g_level++;
	}

	[\]}]  {
		g_text += yytext;
 codify(yytext);
 		g_level--;
	}

 ({SQSTRING}|{DQSTRING})         {
	startFontClass("stringliteral");
  codify(yytext);
 		g_text += yytext;
                        endFontClass();
}

{FLOWKW}					{                                                                          
	startFontClass("keyword");
		g_text += yytext;
codify(yytext);
    endFontClass();
 }

{VAR}					{

                          startFontClass("charliteral");

 codify(yytext);
		g_text += yytext;
                         endFontClass();
}

	")"                             {
        g_text  += yytext;
 codify(yytext);
 		g_level--;
		if ( g_level == 0) {
		 BEGIN( Body ) ;
		}
	}

{ATOM}					{

		g_text += yytext;
codify(yytext);
 }
{NUMBER}					{

		g_text += yytext;
  startFontClass("vhldigit");
  codify(yytext);
 endFontClass();

 }
 
 .  {

		g_text += yytext;
  codify(yytext);

 }

}

<Body>{


{B}({ATOM}{B}:)?{B}{ATOM}"(" {
g_name = yytext;
 g_text = yytext;
 g_name  = g_name.left(g_name.size()-1);
  g_buf = "(";
 g_level =1;
 g_arity = 0;
  BEGIN( FunctionParams );

  }

  
","                      {
g_text += yytext;
 codify(yytext);
 // Parses delimiters
	}

	[({[]  {
   codify(yytext);
 		g_level++;
	}

	[\]}]  {
		g_text += yytext;
 codify(yytext);
 		g_level--;
	}

 ({SQSTRING}|{DQSTRING})         {
	startFontClass("stringliteral");
  codify(yytext);
 		g_text += yytext;
                        endFontClass();
}

{FLOWKW}					{

	startFontClass("keyword");
		g_text += yytext;
codify(yytext);
    endFontClass();
 }

{VAR}					{

                          startFontClass("charliteral");

 codify(yytext);
		g_text += yytext;
                         endFontClass();
}

	")"                             {
        g_text  += yytext;
 codify(yytext);
 		g_level--;
		if ( g_level == 0) {
		 BEGIN( Body ) ;
		}
	}

{ATOM}					{

		g_text += yytext;
codify(yytext);
 }
{NUMBER}					{

		g_text += yytext;
  startFontClass("vhldigit");
  codify(yytext);
 endFontClass();

 }
 
 .  {

		g_text += yytext;
  codify(yytext);

 }



               {EOT} {
codifyLines(yytext);
BEGIN(Program);
}


}

<SkipComment>{
	"*"+"/"			{
        g_comment += yytext;
		codifyLines(g_comment);
		endFontClass();
		BEGIN( Program ) ; }

	("*"+|[^*\n]+)					{

			g_comment += yytext;
	}

	"\n"					{
g_comment += yytext;
	}

}

<*>{SLASHSTARSTARTCOMMENT}	{
	startFontClass("comment");
	g_comment = yytext;
	BEGIN( SkipComment );

}


<*>"%".*  {
                // This eats EVERYTHING
                startFontClass("comment");
                codifyLines(yytext);
                endFontClass();
            }


<*>{FLOWKW}         {
	// flow keyword like "!", ".", ";"
	startFontClass("keyword");
	codifyLines(yytext);
	if (!g_text.isEmpty())
		endFontClass();
	g_text += yytext;
}


<*>{INDICATOR} {
  			g_arity =0;
   indToGoal( yytext );

}

<*>[ \t]                      {
	codify(yytext);
}

<*>.                           {
	// printf("[prologcode] '%s' [ state %d ]  [line %d] no match\n",
	//        yytext, YY_START, yylineno);

	//endFontClass();
  	codify(yytext);

}

<*>\n                          {
    endCodeLine();
	// codify("\n");
	// printf("[prologcode] '%s' [ state %d ]  [line %d] no match\n",
	//        yytext, YY_START, yylineno);
    yylineno++;
    startCodeLine();
	//endFontClass();

}


%%

/*@ ----------------------------------------------------------------------------
 */

void resetPrologCodeParserState()
{
  g_currentDefinition = 0;
  g_currentMemberDef = 0;
  g_doubleStringIsDoc = FALSE;
  g_paramParens = 0;
  BEGIN( Program );
}

void parsePrologCode(CodeOutputInterface &od,const char * /*className*/,
                 const QCString &s,bool exBlock, const char *exName,
		 FileDef *fd,int startLine,int endLine,bool /*inlineFragment*/,
		 MemberDef *,bool,Definition *searchCtx,bool collectXRefs)
{

  //printf("***parseCode()\n");

  //--------------------------------------
  if (s.isEmpty()) return;
  //printlex(yy_flex_debug, TRUE, __FILE__, fd ? fd->fileName().data(): NULL);
  TooltipManager::instance()->clearTooltips();
  g_code = &od;
  g_inputString   = s;
  g_inputPosition = 0;
  g_currentFontClass = 0;
  g_needsTermination = FALSE;
  g_searchCtx=searchCtx;
  g_collectXRefs=collectXRefs;

  if (endLine!=-1)
    g_inputLines  = endLine+1;
  else
    g_inputLines  = countLines();

  if (startLine!=-1)
    yylineno    = startLine;
  else
    yylineno    = 1;
  g_ignore = 0;

  g_exampleBlock  = exBlock;
  g_exampleName   = exName;
  g_sourceFileDef = fd;

  bool cleanupSourceDef = FALSE;
  if (fd==0)
  {
    // create a dummy filedef for the example
    g_sourceFileDef = new FileDef("",(exName?exName:"generated"));
    cleanupSourceDef = TRUE;
  }
  if (g_sourceFileDef)
  {
    setCurrentDoc("l00001");
  }
  current_module_name = "user";

  // Starts line 1 on the output
  startCodeLine();

  prologcodeYYrestart( prologcodeYYin );

  prologcodeYYlex();

  if (g_needsTermination)
  {
    endCodeLine();
  }
  if (fd)
  {
    TooltipManager::instance()->writeTooltips(*g_code);
  }
  if (cleanupSourceDef)
  {
    // delete the temporary file definition used for this example
    delete g_sourceFileDef;
    g_sourceFileDef=0;
  }
  //printlex(yy_flex_debug, FALSE, __FILE__, fd ? fd->fileName().data(): NULL);
  return;
}


#if !defined(YY_FLEX_SUBMINOR_VERSION)
//----------------------------------------------------------------------------
extern "C" { // some bogus code to keep the compiler happy
  void prologscannerYYdummy() { yy_flex_realloc(0,0); }
}
#endif

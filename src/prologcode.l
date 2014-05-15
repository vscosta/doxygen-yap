/******************************************************************************
 *
 * 
 *
 * Copyright (C) 1997-2014 by Dimitri van Heesch.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation under the terms of the GNU General Public License is hereby 
 * granted. No representations are made about the suitability of this software 
 * for any purpose. It is provided "as is" without express or implied warranty.
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


%{

#include <stdio.h>
#include <qvaluestack.h>

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

// Toggle for some debugging info
//#define DBG_CTX(x) fprintf x
#define DBG_CTX(x) do { } while(0)

#define YY_NEVER_INTERACTIVE 1
#define YY_NO_INPUT 1

static ClassSDict    g_codeClassSDict(17);
static QCString      g_curClassName;
static QStrList      g_curClassBases;


static CodeOutputInterface * g_code;
static const char *  g_inputString;     //!< the code fragment as text
static int	     g_inputPosition;   //!< read offset during parsing 
static const char *  g_currentFontClass;
static bool          g_needsTermination;
static Definition   *g_searchCtx;
static bool          g_collectXRefs;
static int           g_inputLines;      //!< number of line in the code fragment
static int	         g_yyLineNr;        //!< current line number
static FileDef *     g_sourceFileDef;
static Definition *  g_currentDefinition;
static MemberDef *   g_currentMemberDef;
static bool          g_includeCodeFragment;
static QCString      g_realScope;
//static bool          g_insideBody;
static int           g_bodyCurlyCount;
static bool          g_searchingForBody;
static QCString      g_classScope;
static int           g_paramParens;
//static int           g_anchorCount;

static bool          g_exampleBlock;
static QCString      g_exampleName;
static QCString      g_exampleFile;

static QCString      g_type;
static QCString      g_name;

static QCString      g_text;

static QCString      current_module;


static bool          g_doubleStringIsDoc;

unsigned long int    g_level, g_arity;

static void endFontClass( void );

static QCString
cannonical_module( QCString text )
{
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


static ClassDef *stripClassName(const char *s,Definition *d=g_currentDefinition)
{
  int pos=0;
  QCString type = s;
  QCString className;
  QCString templSpec;
  while (extractClassNameFromType(type,pos,className,templSpec)!=-1)
  {
    QCString clName=className+templSpec;

    ClassDef *cd=0;
    if (!g_classScope.isEmpty())
    {
      cd=getResolvedClass(d,g_sourceFileDef,g_classScope+"::"+clName);
    }
    if (cd==0)
    {
      cd=getResolvedClass(d,g_sourceFileDef,clName);
    }
    if (cd)
    {
      return cd;
    }
  }

  return 0;
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
    //lineNumber.sprintf("%05d",g_yyLineNr);
    //lineAnchor.sprintf("l%05d",g_yyLineNr);
   
    Definition *d   = g_sourceFileDef->getSourceDefinition(g_yyLineNr);
    //printf("startCodeLine %d d=%p\n",g_yyLineNr,d);
    //g_code->startLineNumber();
    if (!g_includeCodeFragment && d && d->isLinkableInProject())
    {
      g_currentDefinition = d;
      g_currentMemberDef = g_sourceFileDef->getSourceMember(g_yyLineNr);
      //g_insideBody = FALSE;
      g_searchingForBody = TRUE;
      g_realScope = d->name().copy();
      //printf("Real scope: `%s'\n",g_realScope.data());
      g_bodyCurlyCount = 0;
      QCString lineAnchor;
      lineAnchor.sprintf("l%05d",g_yyLineNr);
      if (g_currentMemberDef)
      {
        g_code->writeLineNumber(g_currentMemberDef->getReference(),
	                        g_currentMemberDef->getOutputFileBase(),
	                        g_currentMemberDef->anchor(),g_yyLineNr);
        setCurrentDoc(lineAnchor);
      }
      else
      {
        g_code->writeLineNumber(d->getReference(),
	                        d->getOutputFileBase(),
	                        0,g_yyLineNr);
        setCurrentDoc(lineAnchor);
      }
    }
    else
    {
       QCString lineAnchor;
      lineAnchor.sprintf("l%05d",g_yyLineNr);
      //g_code->codify(lineNumber);
      g_code->writeLineNumber(0,0,0,g_yyLineNr);
    }
    //g_code->endLineNumber();
  } else {
      g_code->writeLineNumber(0,0,0,g_yyLineNr);
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
  if (g_yyLineNr<g_inputLines) 
  {
    g_currentFontClass = fc;
    startCodeLine();
  }
}


/*! writes a link to a fragment \a text that may span multiple lines, inserting
 * line numbers for each line. If \a text contains newlines, the link will be 
 * split into multiple links with the same destination, one for each line.
 */
static void writeMultiLineCodeLink(CodeOutputInterface &ol,
                  Definition *d,
                  const char *text)
{
  static bool sourceTooltips = Config_getBool("SOURCE_TOOLTIPS");
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
      g_yyLineNr++;
      *(p-1)='\0';
      //printf("writeCodeLink(%s,%s,%s,%s)\n",ref,file,anchor,sp);
      ol.writeCodeLink(ref,file,anchor,sp,tooltip);
      nextCodeLine();
    }
    else
    {
      //printf("writeCodeLink(%s,%s,%s,%s)\n",ref,file,anchor,sp);
      ol.writeCodeLink(ref,file,anchor,sp,tooltip);
      done=TRUE;
    }
  }
}


static void codifyLines(char *text)
{
  //printf("codifyLines(%d,\"%s\")\n",g_yyLineNr,text);
  char *p=text,*sp=p;
  char c;
  bool done=FALSE;
  while (!done)
  {
    sp=p;
    while ((c=*p++) && c!='\n') { }
    if (c=='\n')
    {
      g_yyLineNr++;
      *(p-1)='\0';
      g_code->codify(sp);
      nextCodeLine();
    }
    else
    {
      g_code->codify(sp);
      done=TRUE;
    }
  }
}
//void j_bug(void);
//void j_bug(void) { printf("%s\n", g_text.data()); }

static bool getLinkInScope(const QCString &c,  // scope
                           const QCString &m,  // member
			   const char *memberText, // exact text
			   CodeOutputInterface &ol,
			   const char *text
			  )
{
  MemberDef    *md;
  ClassDef     *cd;
  FileDef      *fd;
  NamespaceDef *nd;
  GroupDef     *gd;
  if (getDefs(c,m,"()",md,cd,fd,nd,gd,FALSE,g_sourceFileDef) && 
      md->isLinkable())
  {
    //Definition *d=0;
    //if (cd) d=cd; else if (nd) d=nd; else if (fd) d=fd; else d=gd;

    Definition *d = md->getOuterScope()==Doxygen::globalScope ?
	            md->getBodyDef() : md->getOuterScope();
    if (md->getGroupDef()) d = md->getGroupDef();
    if (d && d->isLinkable())
    {
      g_theCallContext.setClass(stripClassName(md->typeString(),md->getOuterScope()));
      //printf("g_currentDefinition=%p g_currentMemberDef=%p\n",
      //        g_currentDefinition,g_currentMemberDef);

      if (g_currentDefinition && g_currentMemberDef &&
	  md!=g_currentMemberDef && g_collectXRefs)
      {
	addDocCrossReference(g_currentMemberDef,md);
      }
      //printf("d->getReference()=`%s' d->getOutputBase()=`%s' name=`%s' member name=`%s'\n",d->getReference().data(),d->getOutputFileBase().data(),d->name().data(),md->name().data());
     
      writeMultiLineCodeLink(ol,md, text ? text : memberText);
      addToSearchIndex(text ? text : memberText);
      return TRUE;
    } 
  }
  return FALSE;
}

static bool getLink(const char *className,
                    const char *memberName,
		    CodeOutputInterface &ol,
		    const char *text=0)
{
  QCString m=removeRedundantWhiteSpace(memberName);
  QCString c=className;
  if (!getLinkInScope(c,m,memberName,ol,text))
  {
    if (!g_curClassName.isEmpty())
    {
      if (!c.isEmpty()) c.prepend(":");
      c.prepend(g_curClassName);
      return getLinkInScope(c,m,memberName,ol,text);
    }
    return FALSE;
  }
  return TRUE;
}



/*
  For a given string in the source code,
  finds its class or global id and links to it.
*/
static void generateClassOrGlobalLink(CodeOutputInterface &ol,char *clName)
{
	QCString className=clName;


	// Don't do anything for empty text
	if (className.isEmpty()) return;

	DBG_CTX((stderr,"generateClassOrGlobalLink(className=%s)\n",className.data()));

	ClassDef *cd=0,*lcd=0;  /** Class def that we may find */
	MemberDef *md=0;        /** Member def that we may find */
	//bool isLocal=FALSE;

	{
		Definition *d = g_currentDefinition;
		QCString scope = substitute(className,".","::");

		cd = getResolvedClass(d,g_sourceFileDef,substitute(className,".","::"),&md);

		DBG_CTX((stderr,"d=%s g_sourceFileDef=%s\n",
				d?d->displayName().data():"<null>",
						g_currentDefinition?g_currentDefinition->displayName().data():"<null>"));
		DBG_CTX((stderr,"is found as a type %s\n",cd?cd->name().data():"<null>"));

		if (cd==0 && md==0) // also see if it is variable or enum or enum value
		{
			NamespaceDef *nd = getResolvedNamespace( substitute(className,".","::") );
			if (nd)
			{
				writeMultiLineCodeLink(ol,nd,clName);
				addToSearchIndex(className);
				return;
			}
			else if (getLink(g_classScope,clName,ol,clName))
			{
				return;
			}
		}
	}

	if (cd && cd->isLinkable()) // is it a linkable class
	{
		writeMultiLineCodeLink(ol,cd,clName);
		addToSearchIndex(className);
		if (md)
		{
			Definition *d = md->getOuterScope()==Doxygen::globalScope ?
					md->getBodyDef() : md->getOuterScope();
			if (md->getGroupDef()) d = md->getGroupDef();
			if (d && d->isLinkable() && md->isLinkable() && 
					g_currentMemberDef && g_collectXRefs)
			{
				addDocCrossReference(g_currentMemberDef,md);
			}
		}
	} else {

		// nothing found, just write out the word
		codifyLines(clName);
		addToSearchIndex(clName);
	}
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

VAR	          [A-Z_]({LETTER}|{DIGIT}|"_")* 

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

ATOMIC                   ({ATOM}|{VAR}|{NUMBER}|{SYMBOL}|{DQSTRING})

INDICATOR          (({ATOM}":"|"(")?{ATOM}(")")?("/"|"//"){NUMBER})

OPDEC		   {IDENTIFIER}"("{B}{NUMBER}{B}","{B}{IDENTIFIER}{B}","{B}{ATOM}{B})"

LIBRARY		   (({ATOM}"("{B}{ATOM}{B}")")|{ATOM})

FLOWKW             ("spy"|"nospy"|"same"|"block"|"^"|"**"|"\\"|"rem"|"mod"|">>"|"<<"|"//"|"/"|"*"|"xor"|"div"|"rdiv"|"#"|"><"|"\\/"|"/\\"|"-"|"-"|"+"|"+"|":"|"as"|">="|"=<"|">"|"<"|"=\\="|"=:="|"\\=@="|"=@="|"@>="|"@=<"|"@>"|"@<"|"\\=="|"=="|"=.."|"is"|"\\="|"="|"not"|"\\+"|"."|","|"*->"|"->"|";"|"|"|"uncutable"|"table"|"discontiguous"|"module_transparent"|"meta_predicate"|"multifile"|"public"|"mode"|"volatile"|"initialization"|"thread_local"|"dynamic"|"?-"|"-->"|":-"|":-")

PERCCOMMENT      ("%"[^\n]*"\n")*

SLASHSTARSTARTCOMMENT "/*"
SLASHSTARENDCOMMENT   "*/"

PREDTAG               ("det"|"semidet"|"failure"|"nondet"|"multi"|"iso"|"deprecated"|"dynamic")

PARAMETERDESCRIPTOR   ([+-?:@!]?({VAR}":"){IDENTIFIER})

PREDINFO              ({BB}"is"{BB}{PREDTAG}({B}","{B}{PREDTAG})*{B}{NEWLINE})

COMPOUND	      {ATOM}"("


%option noyywrap

%x Body

%x FunctionDec
%x FunctionParams

%x Suite
%x SuiteCaptureIndent
%x SuiteStart
%x SuiteMaintain
%x SuiteContinuing

%x SkipComment

%x LongString

%x SingleQuoteString
%x DoubleQuoteString

%%


<Body>{
	{KEYWORD}"("                    {
		// a function
		g_text = yytext;
		g_arity = 0;
		g_level ++;
		startFontClass("keyword");
		g_text.remove(g_text.length()-1,1);
		if (yytext[0]=='\'') {
			codify("'");
		}
		generateClassOrGlobalLink(*g_code,g_text.data());
		if (yytext[0]=='\'') {
			codify("'(");
		}
		endFontClass();
		codify("(");
		BEGIN( FunctionParams );
	}

	{QATOM}"("                    {
		// a function
		g_text = yytext;
		g_arity = 0;
		g_level ++;
		g_text.remove(g_text.length()-1,1);
		startFontClass("stringliteral");
		if (yytext[0] == '\'') {
			codify("'");
			g_text.remove(g_text.length()-1,1);
			g_text.remove(0,1);
		}
		generateClassOrGlobalLink(*g_code,g_text.data());
		if (yytext[0] == '\'') {
			codify("'");
		}
		endFontClass();
		codify("(");
		BEGIN( FunctionParams );
	}

	({ATOM}":")?{IDENTIFIER}"("                    {
		// a function
		g_text = yytext;
		g_arity = 0;
		g_level ++;
		generateClassOrGlobalLink(*g_code,g_text.remove(g_text.length()-1,1).data());
		codify("(");
		BEGIN( FunctionParams );
	}

	":-"{B}                     {
		startFontClass("keyword");
		codify(yytext);
		endFontClass();
	}

	":-"{B}("system_")?"module("{B}{ATOM}          {
		// a function
		g_text = yytext;
		g_level = 0;
		size_t i = g_text.find	("(");
		startFontClass("keyword");
		codify(g_text.left(i+1).data());
		endFontClass();
		g_text.remove(0, i+1);
		startFontClass("preprocessor");
		codify(g_text.data());
		endFontClass();
		g_text = cannonical_module( g_text );
		current_module = g_text;

	}

	"--->"{BB}                   {
		g_level = 0;
		g_text += yytext;
		startFontClass("keyword");
		codify(yytext);
		endFontClass();
	}
}

<FunctionParams>{
	","                      {
		if (g_level == 1) {
			g_arity++;
		}
		g_text += yytext;
		codify(",");
		// Parses delimiters
		codify(yytext);
	}

	"("  {
		g_text += yytext;
		codify(yytext);
		g_level++;
	}

	")"                             {
		codify(yytext);
		g_text += yytext;
		g_level--;
		if ( g_level == 0) {
			g_arity += 1;
			QCString s;
			s = current_module;
			s += "::";
			int i =  0;
			while (g_text[i] != '(') {
				if (g_text[i] != '\'') {
					s += g_text[i];
				}
				i++;
			}
			s += "_";
			char buf[16];
			snprintf( buf, sizeof(buf), "%u\n", i+1);
			s += buf;
			BEGIN( Body ) ;
		}
	}

}


<SkipComment>{
	"*"+"/"			{ 
		startFontClass("comment");
		codify(yytext);
		endFontClass();
		BEGIN( Body ) ; }

	("*"+|[^*\n]+)					{ 

		startFontClass("comment");
		codify(yytext);
		endFontClass();
	}

	"\n"					{ 

		startFontClass("comment");
		codifyLines(yytext);
		endFontClass();
	}

}


<*>({SQSTRING}|{DQSTRING})         { // Single quoted string like 'That\'s a """nice""" string!'
	startFontClass("stringliteral");
	codifyLines(yytext);
	if (!g_text.isEmpty())
		g_text += yytext;
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

<*>{VAR}					{ 

	//                             startFontClass("charliteral");
	codify(yytext);
	//                     endFontClass();
}

<*>{SLASHSTARSTARTCOMMENT}	{
	startFontClass("comment");
	codify(yytext);
	endFontClass();
	BEGIN( SkipComment );

}

<*>{PERCCOMMENT}              {
	if (YY_START==SingleQuoteString || 
			YY_START==DoubleQuoteString 
	)
	{
		REJECT;
	}
	// This eats EVERYTHING
	// except the newline
	startFontClass("comment");
	codifyLines(yytext);
	endFontClass();
}
<*>{NEWLINE}                   {
	codifyLines(yytext);
	//printf("[prologcode] %d NEWLINE [line %d] no match\n",
	//       YY_START, g_yyLineNr);
	//endFontClass();
	BEGIN(Body);
}

<*>[ \t]+                      {
	codify(yytext);
	BEGIN(Body);					
}
<*>.                           {
	codify(yytext);
	// printf("[prologcode] '%s' [ state %d ]  [line %d] no match\n",
	//        yytext, YY_START, g_yyLineNr);

	//endFontClass();
	BEGIN(Body);					
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
  BEGIN( Body );
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
  current_module = "user";
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
    g_yyLineNr    = startLine;
  else
    g_yyLineNr    = 1;
  
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
extern "C" { // some bogus code to keep the compiler happY
  void prologcodeYYdummy() { yy_flex_realloc(0,0); } 
}
#elif YY_FLEX_SUBMINOR_VERSION<33
#error "You seem to be using a version of flex newer than 2.5.4. These are currently incompatible with 2.5.4, and do NOT work with doxygen! Please use version 2.5.4 or expect things to be parsed wrongly! A bug report has been submitted (#732132)."
#endif


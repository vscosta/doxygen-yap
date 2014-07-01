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
/*  This code is based on the doxygen python module, based on the work by the MoxyPyDoxy team
 *  (Linda Leong, Mike Rivera, Kim Truong, and Gabriel Estrada)
 *  in Spring 2005 as part of CS 179E: Compiler Design Project
 *  at the University of California, Riverside; the course was
 *  taught by Peter H. Froehlich <phf@acm.org>. 
 *
 *  The code was extensively rewritten
 *  by Vitor Santos Costa to 
 *  support Prolog.
 */


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
#define DBG_CTX(x) do { } while(0)

#define YY_NEVER_INTERACTIVE 1
  //#define YY_NO_INPUT 1

/* -----------------------------------------------------------------
 *
 *	statics
 */

  
static ParserInterface *g_thisParser;
static const char *     inputString;
static int		inputPosition;
static QFile            inputFile;

static Protection	protection;

static Entry*		current_root = 0 ;
static bool		current_pred = FALSE ;
static Entry*		current      = 0 ;
static Entry*		previous     = 0 ;
static Entry*		bodyEntry    = 0 ;
static int		yyLineNr     = 1 ;
static int		yyLineCms     = 0 ;
static QCString		yyFileName;
static Entry   	       *current_module = 0;
static Entry   	       *current_clause = 0;
static MethodTypes 	mtype;
static bool    		gstat;
static Specifier 	virt;

static int              docBlockContext;
static int              docBlockMain;
static QCString         docBlock;
static QCString         docBlockName;
static bool             docBlockInBody;
static bool             docBlockJavaStyle;
static bool             docBrief;

static bool             g_specialBlock;

static QDict<QCString>  g_packageNameCache(257);
static QDict<QCString>  g_functionNameCache(257);

static QDict<Entry>     g_predNameCache(257);
static QDict<Entry>     g_moduleNameCache(257);
static QDict<Entry>     g_varNameCache(257);

static QCString         g_packageScope;
static QCString         g_pName;

//static bool             g_insideConstructor;

static QCString         g_moduleScope;
static QCString         g_packageName;

//static bool             g_hideClassDocs;

static QCString         g_defVal;

static bool             g_lexInit = FALSE;
static bool             g_packageCommentAllowed;
static bool		g_slashStarComment;
static bool	        g_SWIStyle;

static unsigned int     g_callLevel = 0;

static unsigned int     g_argLevel = 0;

QStack<unsigned int> g_arityStack;
static void newClause( Entry *parent_module );

static Entry *newModule(const char *modname, Protection prot);

static bool				g_headDone;


static void parseMain(const char *fileName,const char *fileBuf,Entry *rt);

#define DEBUG_ALL 1

#if DEBUG_ALL
 void      
   show_scanner_tree(uint off, Entry *current);
#endif
//-----------------------------------------------------------------------------

static QCString
stripQuotes(QCString item)
{
        if (item.isEmpty())
        	return item;
	const char *s = item.data();
	size_t last = strlen(s) - 1;
	if (s[0] == '\''&& s[last] == '\'') {
		item.remove(last , 1);
		item.remove(0, 1);
	}
	return item;
}

static QCString	
normalizePredName(char *inp)
{
  QCString rc;
  Entry *e = current_module;
  char *s = inp, *ns;
    while ((ns = strchr(s, ':'))) {
      // is module qualified
      ns[0] = '\0';
      e = newModule(s, Public);
      while (*++ns == ':');
      inp = ns;
    }
  rc = e->name.copy();
  rc += "::";  
  bool is_quoted = (inp[0] == '\'');
  if (is_quoted) {
    inp += 1;
    rc += inp;
    rc.remove(rc.length()-1,1);
  } else {
    rc += inp;
  }
  /*
  rc += "_";
  char arcs[20];
  snprintf(arcs, 20, "%u", arity);
  rc += arcs;
  */
  return rc;
}

static QCString	
normalizeIndicator(char *inp)
{
  char *ptr = inp+strlen(inp);
  while ((*--ptr) != '/');
  ptr[0] = '\0';
  return normalizePredName( inp );
}

static void initParser( void )
{
  protection = Public;
  mtype = Method;
  gstat = FALSE;
  virt = Normal;
  previous = 0;
  g_packageCommentAllowed = TRUE;

  g_packageNameCache.setAutoDelete(TRUE);
  g_predNameCache.setAutoDelete(FALSE);  // this is just a cache
  g_moduleNameCache.setAutoDelete(FALSE);  // this is just a cache
  g_varNameCache.setAutoDelete(FALSE); // just another cache
  g_functionNameCache.setAutoDelete(TRUE);
}

static void initEntry( void )
{
  //current->prolog = TRUE;
  current->protection = protection ;
  current->mtype      = mtype;
  current->virt       = virt;
  current->stat       = gstat;
  current->lang       = SrcLangExt_Prolog; 
  current->setParent(current_root);
  current->argList->clear();
  initGroupInfo(current);
  gstat = FALSE;
}

static void newEntry( void )
{
  //  else   if (current->section!=Entry::CLASSDOC_SEC)
  current->parent()->addSubEntry(current);
  current = new Entry ;
  initEntry();
}

static void foundCall( QCString name )
{
	return;
	Entry *n = new Entry;
	char *s = (char *)name.data();
	QCString pname;
	if (s)	   	pname = normalizePredName( s );
		  //n->prolog = TRUE;
		  n->mtype      = mtype;
		  n->virt       = virt;
		  n->stat       = gstat;
		  n->lang       = SrcLangExt_Prolog; 
		  n->setParent(current);
		  initGroupInfo(n);
		  gstat = FALSE;
	   n->section = Entry::CLASS_SEC;
	   n->argList->clear();
	   n->type = "predicate" ;
	   n->fileName  = yyFileName;
	   n->startLine  = yyLineNr;
	   n->bodyLine  = yyLineNr;
	   n->name = pname.copy();
	   if (!n->name.isEmpty() && n->name.at(0)=='$') // mark as private
	     {
	       n->protection = protection=Private;
	     }
	   else 
	     {
	       n->protection = protection=Public;
	     }
	   current->addSubEntry(n);	
}

static void foundTerm( void )
{
}


 void foundVariable( void )
{
	return;
  Entry *n = new Entry;
  n->name = QCString( yytext );
  if (!strcmp(yytext, "_") ) {
	    n ->protection=Private;
  } else {
	    n ->protection=current->protection;
  }
//	    g_moduleNameCache.insert(mname, n );
  n ->section   = Entry::VARIABLE_SEC;
  n ->type = "variable" ;
  n ->fileName  = yyFileName;
  n ->startLine  = yyLineNr;
  n ->bodyLine  = yyLineNr;
  n ->setParent( current ); 
  current->addSubEntry(n);
}

static char *
  sliceArgument(char *inp, int c)
{
  size_t sz0 = strlen(inp);
  char *ptr, *tmp = inp, *end = inp+sz0;
  int ch;
  
  while ((ch = *inp++) && (ch != '(')) {
    if (ch == '\'') {
      while ((ch = *inp++) && ch != '\'')
	if (ch == '\\') inp++;
    }
  }
  while ((ch = *inp++) && isblank(ch));
  if (ch != '\'') inp--;
  // skipped the beginning, skip the end now
  tmp= end-1;
  while (*tmp != c) tmp--; // reach ')'
  tmp--;
  while (isblank(*tmp)) tmp--;
  if (*tmp == '\'') tmp--;
  sz0 = (tmp-inp)+1;
  ptr = (char *) malloc(sz0+1);
  if (!ptr)
    return NULL;
  strncpy( ptr, inp, sz0);
  ptr[sz0] = '\0';
  return ptr;
}

//-----------------------------------------------------------------------------

static void 
lineCount( void )
{
  //  DBG_CTX((stderr,"yyLineNr=%d\n",yyLineNr));
  for (const char *p = yytext; *p; ++p)
  {
    yyLineNr += (*p == '\n') ;
    if (*p == '\n')
      printf("CO yyLineNr=%d\n", yyLineNr);
  }
}

static void 
lineComments( void )
{
  //  DBG_CTX((stderr,"yyLineNr=%d\n",yyLineNr));
  for (const char *p = yytext; *p; ++p)
  {
     if (*p == '\n')
      printf("CM yyLineNr=%d\n", yyLineNr);
   yyLineCms += (*p == '\n') ;
    yyLineNr += (*p == '\n') ;
  }
}

static void 
incLineNr( void )
{
  return lineCount();
  //yyLineNr++;
}

//-----------------------------------------------------------------

//-----------------------------------------------------------------
static void 
  startCommentBlock(bool brief,  Entry *owner )
{

  if (brief)
  {
    owner->briefFile = yyFileName;
    owner->briefLine = yyLineNr;
  }
  else
  {
    owner->docFile = yyFileName;
    owner->docLine = yyLineNr;
  }
}

/*
static void appendDocBlock() {
  previous = current;
  current_root->addSubEntry(current);
  current = new Entry;
  initEntry();
}
*/

static void addToDocBlock(const char *s) {
  for (const char *p = s; *p; ++p)
  {
       yyLineNr += (*p == '\n') ;
    if (*p == '\n')
      printf("CN yyLineNr=%d\n", yyLineNr);

  }
  docBlock += s;
}


static void
handleCommentBlock(const QCString &doc,bool brief)
{
  printf("handleCommentBlock(doc=[%s] brief=%d docBlockInBody=%d docBlockJavaStyle=%d\n",
      doc.data(),brief,docBlockInBody,docBlockJavaStyle);

  // TODO: Fix me
  //  current = docOwner;
  docBlockInBody=FALSE;
  
  if (docBlockInBody && previous && !previous->doc.isEmpty())
  {
    previous->doc=previous->doc.stripWhiteSpace()+"\n\n";
  }

  int position = 0;
  bool needsEntry;
  int lineNr = brief ? current->briefLine : current->docLine;
  if (docBlock.at(docBlock.length()-1) != '\n')
    docBlock += "\n";
  while (parseCommentBlock(
	g_thisParser,
	(docBlockInBody && previous) ? previous : current,
	doc,     // text
	yyFileName, // file
	lineNr,
	docBlockInBody ? FALSE : brief, 
	docBlockJavaStyle, // javadoc style // or FALSE,
	docBlockInBody,
	protection,
        position,
        needsEntry)
     ) // need to start a new entry
  {
    if (needsEntry  )
      newEntry(  );
  }
  if (needsEntry)
  {
    newEntry(  );
  }
  current_pred = FALSE;
  g_specialBlock = FALSE;
}

static void endOfDef(int correction=0)
{
  // printf("endOfDef at=%d\n",yyLineNr);
  //printf("endOfDef %s\n", current->name.data());
  newClause( current_module );
  if (bodyEntry)
  {
    bodyEntry->endBodyLine  = yyLineNr-correction;
    bodyEntry = 0;
  }
  newEntry(  );

  //g_insideConstructor = FALSE;
}

static void initSpecialBlock( Entry *owner )
{
  docBlockContext   = YY_START;
  docBlockInBody    = FALSE;
  docBlockJavaStyle = TRUE;
  docBrief = TRUE;
  docBlock.resize(0);
  g_specialBlock = TRUE;
  startCommentBlock(TRUE, owner);
}

static void initSWIComment( const char *text )
{
  const char *s = strstr( text, "<module>");
  if (s) {
    s += +strlen("<module>");
    docBlock = "@defgroup ";
    docBlock += current_module->name.data();
    docBlock += " ";
    docBlock += s;
    current->briefLine = yyLineNr;
    current->briefFile = yyFileName;
  } else {
    s = text;
    if (s[0] == '%' || s[0] == '/') {
      do (s++); while (!isblank(s[0]));
      while (isblank(s[0])) s++;
    }
    docBlock = s;
  }
  g_SWIStyle = TRUE;
}

 static Entry *newModule( const char *modname, Protection prot )
{
  Entry * newp;
  QCString mname = modname;
  mname = mname.stripWhiteSpace();
  mname = stripQuotes( mname );

  if (!(newp = g_moduleNameCache.find(mname))) {
     // add a new module
    Entry *bkup = current;
    newp = current = new Entry;
    initEntry();
    g_moduleNameCache.insert(mname, current);
    current->section = Entry::NAMESPACE_SEC;
    current->type = "module" ;
    current->fileName  = yyFileName;
    current->startLine  = yyLineNr;
    current->bodyLine  = yyLineNr;
    current->name = mname.copy();
    current->setParent( current_root ); 
    current->parent()->addSubEntry(current);
    current->protection = prot;
    current = bkup;
  } 
  return newp;
}

static Entry *fetchGroup(Entry *rt)
{
  // search a group decl from initial comment
  EntryListIterator eli(*rt->children());
  Entry *ce;
  for (;(ce=eli.current());++eli)
  {
    if (ce->section == Entry::GROUPDOC_SEC)
      return ce;
  }
  return rt;
}


 static void searchFoundDef(){
  current->fileName  = yyFileName;
  current->startLine = yyLineNr;
  current->bodyLine  = yyLineNr;
  current->section = Entry::CLAUSE_SEC;
  current->protection = Package;
  current->lang = SrcLangExt_Prolog;
  current->virt = Normal;
  current->stat = gstat;
  current->mtype = mtype = Method;
  current->type.resize(0);
  current->name.resize(0);
  current->args.resize(0);
  current->argList->clear();
  g_packageCommentAllowed = TRUE;
  gstat=FALSE;
}

static void newFunction()
{
  current->bodyLine  = yyLineNr;

}

 static char *protectChars( char *s0 )
{
  char *s1;
  int ch;

  if (!(s1 = (char *)malloc(2*strlen(s0)+1)))
    return NULL;
  char *rc = s1;
  while ((*s1++ = ch = *s0++)) {
    if (ch == '/') s1[-1] = '_';
  }
  return rc;
}

 static void
 buildPredEntry( QCString pname, Protection protection )
 {
   initEntry();
   current->section = Entry::CLASS_SEC;
   current->type = "predicate" ;
   current->fileName  = yyFileName;
   current->startLine  = yyLineNr;
   current->bodyLine  = yyLineNr;
   current->name = pname.copy();
   if (!current->name.isEmpty() && current->name.at(0)=='$') // mark as private
     {
       current->protection = Private;
     }
   else 
     {
       current->protection = Public;
     }
 }

static void newClause( Entry *parent_module ) {
   Entry *newp;

   QCString pname = current->name;
   char *s = pname.data();
   if ( !(newp = g_predNameCache.find(s)) ) {
     Entry *bkup = current; // keep the current object, it will now be a predicate ( class ); 
     // create a predicate entry
     newp = current = new Entry;
     // insert new entry
     g_predNameCache.insert(pname, current);
     buildPredEntry( pname , parent_module->protection );
     uint arity = bkup->argList->count();
     for (uint i=0; i<arity; i++) {
       char buf[16];
       Argument *a = new Argument;
       snprintf( buf, sizeof(buf), "A%u\n", i+1);
       a->name += buf;
       a->type = "Term";
       current->argList->append(a);
     }
     // insert clause in parent's chain
     current->setParent( parent_module );
     parent_module->addSubEntry(current);
     // we have the predicate declared, back to business.
     // switch, move clause up to head.
     previous = newp;
     current = bkup;
   } else {
     current_root = newp;
   }
   current->setParent( newp );
   current->protection = newp->protection;
  //   size_t i = current->name.findRev( '_', -1 );
   // current->name.truncate( i );
   current_clause = current;
 }

 static void addPredDecl( Entry *current_module )
 {
   //unsigned int arity = current->argList->count();
  Entry * newp, *mod = current_module;
  QCString pname;
  char *s = current->name.data();

  // second definition for same predicate, just ignore
  if (current_pred)
    return;
  if ( s ) {
    pname = normalizePredName( s ). data();
    addToDocBlock( "\n@anchor " );
    addToDocBlock( protectChars( pname.data() ) );
    addToDocBlock( "\n" );
  } else {
    pname = "none";
  }
  if (!(newp = g_predNameCache.find(pname))) {
     // add a new predicate
    g_predNameCache.insert(pname, current);
		  printf("PD %s\n", pname.data());
    current->section = Entry::CLASS_SEC;
    current->type = "predicate" ;
    current->setParent( mod );
    current->name = pname.copy();
    current->fileName  = yyFileName;
    current->startLine  = yyLineNr;
    current->bodyLine  = yyLineNr;
    if (!current->name.isEmpty() && current->name.at(1)=='$') // mark as private
      {
	current->protection = protection=Private;
      }
    else 
      {
	current->protection = protection=Public;
      }
    newEntry(  );
    current_pred = FALSE;
   } else {
    newp->fileName  = yyFileName;
    newp->startLine  = yyLineNr;
    newp->bodyLine  = yyLineNr;
    newp->argList = current->argList->deepCopy();
  }
} 
 

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

/* Prolog end of term marker */
EOT               {B}"."{BN}

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
DQSTRINGITEM       ({STRINGCHAR}|{ESCAPESEQ}|"\"\""|"\\\""|"'")

SQSTRING           ("'"({QSTRINGITEM})*"'")
DQSTRING           ("\""({QSTRINGITEM})*"\"")

SY		   [#&*+\-/:<=>?@\\^`~]
SYNOSTAR	   [#&+.\-/:<=>?@\\^`~]
SYDOT		   [#&*+.\-/:<=>?@\\^`~]

SYMBOL		  ({SY}+"."{SYDOT}*|"."{SYDOT}+|"/"{SYNOSTAR}{SYDOT}*|{SY}{SYDOT}*|".")

SOLO		  [;!]

ATOM		   ({IDENTIFIER}|{SQSTRING}|{SYMBOL}|{SOLO})

ATOMIC             ({ATOM}|{VAR}|{NUMBER}|{DQSTRING})

INDICATOR          (({ATOM}":"|"(")?{ATOM}(")")?("/"|"//"){DECNUMBER})

OPDEC		   {IDENTIFIER}"("{B}{INTNUMBER}{B}","{B}{IDENTIFIER}{B}","{B}("("{B})?{ATOM}({B}")")?{B}")"

PATH		   (("/")?{ATOM}("/"{ATOM})*)

LIBRARY		   (({ATOM}"("{B}{PATH}{B}")")|({PATH}))

FLOWKW             ("spy"|"nospy"|"same"|"block"|"^"|"**"|"\\"|"rem"|"mod"|">>"|"<<"|"//"|"/"|"*"|"xor"|"div"|"rdiv"|"#"|"><"|"\\/"|"/\\"|"-"|"-"|"+"|"+"|":"|"as"|">="|"=<"|">"|"<"|"=\\="|"=:="|"\\=@="|"=@="|"@>="|"@=<"|"@>"|"@<"|"\\=="|"=="|"=.."|"is"|"\\="|"="|"not"|"\\+"|"uncutable"|"table"|"discontiguous"|"module_transparent"|"meta_predicate"|"multifile"|"public"|"mode"|"volatile"|"initialization"|"thread_local"|"dynamic")

SPECIALPERCCOMMENT      "%"[%!]+(" "|"\t")("\n"("%")+{B}*)*

PERCCOMMENT      ("%\n"|("%"[^%!\n][^\n]*"\n"))


SLASHSTARSTARTCOMMENT "/*"([^\*\!]|"*"[^ \t\n]|"!"[^ \t\n])
SLASHSTAREMPTYCOMMENT "/*/"
SLASHSTARENDCOMMENT   "*/"

PREDTAG               ("det"|"semidet"|"failure"|"nondet"|"multi"|"iso"|"deprecated"|"dynamic")

PARAMETERDESCRIPTOR   ([+-?:@!]?(({VAR}":"{IDENTIFIER})|{VAR}|{IDENTIFIER}))

PREDINFO              ({BB}"is"{BB}{PREDTAG}({B}","{B}{PREDTAG})*{B}{NEWLINE})

COMPOUND	      {ATOM}"("

%option noyywrap

  /* Main start state */

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

  /* import */
%x Directive
%x ImportList
%x ExportList
%x Import

%%

      /* ------------ Function recognition rules -------------- */

<Search,FunctionParams,FunctionDec,FunctionBody,CallArgs,HeadOperator,Directive,ImportList,ExportList,Import>{PERCCOMMENT} {
	lineComments();
	if ( g_specialBlock ) {
		g_specialBlock += yytext;
	}
	docBlockContext = YY_START;
}


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


	("/**"|"/*!"){BN}	{
		g_packageCommentAllowed = TRUE;
		initSpecialBlock( current );
		docBlockContext = YY_START;
		g_slashStarComment = TRUE;
		if (g_SWIStyle) {
		  initSWIComment( yytext );
		  BEGIN( SWISpecialComment );
		} else {
		  BEGIN( SpecialComment );
		}
	}

	("/**"|"/*!"){BN}"<module>"[^\n]+"\n"	{
		lineComments();
		g_packageCommentAllowed = TRUE;
		initSpecialBlock( current_module );
		docBlockContext = YY_START;
		g_slashStarComment = TRUE;
		initSWIComment( yytext );
		BEGIN( SWISpecialComment );
	}

	{SLASHSTARSTARTCOMMENT}    { // normal comment 
		g_packageCommentAllowed = FALSE;
		docBlockContext = YY_START;
		BEGIN(SkipComment);
	}

	{NEWLINE}+    {
		lineCount(); 
	}


	({ATOM}":")?{COMPOUND}{B}	{
		// must be start of a function/clause definition
		searchFoundDef();
		//found function name
		if (current->type.isEmpty()) 
		{
			current->type = "method";
		}
		current->program = yytext;
		for (size_t i = 0; i < strlen(yytext)-1; i++) {
		   int ch =  yytext[i];
		   if (ch == '(')
			  break;
		   current->name += ch;
		}
		current->name = current->name.stripWhiteSpace();
		current_clause = current;
		g_argLevel = 1;
		g_defVal = "";
		g_headDone = FALSE;
		BEGIN( FunctionParams );
	}


	{ATOM}":-"  {
		//found function name, but no arity
		{
			current->type = "method";
		}
		current->program = yytext;
		current->name = QCString( yytext );
		current->name = current->name.stripWhiteSpace();
		current_clause = current;
		g_argLevel = 0;
		g_defVal = "";
		g_headDone = TRUE;
		current->bodyLine  = yyLineNr;
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
		g_argLevel = 0;
		g_defVal = "";
		g_headDone = TRUE;
		BEGIN( HeadOperator );
	}

	{EOT}         {
	}

	.    {
	}

}

<HeadOperator>{

	{B}(":-"|"-->")    {
		if (!g_headDone) {
		  current->name = QCString( "op" );
			g_headDone= TRUE;
		}
		current->program+=yytext;
		current->bodyLine  = yyLineNr;
		BEGIN( FunctionBody ); 
	}

	{EOT}         {
		// facts
		current->program+=yytext;
		lineCount(); 
//		printf("\nDONE\n %s \n*******\n", current->program.data());
		endOfDef();
		BEGIN(Search);

	}

	\n       {
		lineCount(); 
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
		g_argLevel++;
		g_defVal = yytext;
	}

	{ATOM} { //
		g_defVal += yytext;
		current->program+=yytext;
	}

	{VAR}|{NUMBER} { //
		g_defVal += yytext;
		current->program+=yytext;
	}

	","           {
			current->program+=yytext;
			if (g_argLevel == 0 ) {
				// Name of parameter
				Argument *a = new Argument;
				a->name = g_defVal.copy().stripWhiteSpace();
				a->type = "";
				current->argList->append(a);
				g_defVal = "";
			}
	}

	"|"           {
			current->program+=yytext;
	}

	("("|"{"|"[")         {
		current->program+=yytext;
		g_defVal += yytext;
		g_argLevel++;
	}

	("]"|"}")         {
		current->program+=yytext;
		g_defVal += yytext;
		g_argLevel--;
	}

	")"   { // end of parameter list
		current->program+=yytext;
		g_argLevel--;
		//printf("RET %d %d\n", g_argLevel, g_headDone);
		if (g_argLevel== 0) {
			//unsigned int arity = current->argList->count()+1;
			newFunction();
			Argument *a = new Argument;

			a->name = g_defVal.copy().stripWhiteSpace();
			a->type = "";
			current->argList->append(a);
			if (current->name.data()) {
				current->name = normalizePredName( current->name.data() );
			} else {
				current->name = "op/2"; // assume that we have a binary operator.
			}
			g_defVal = "";
		      if (g_callLevel) {
			   foundCall( g_pName );
			   BEGIN( FunctionBody );			foundTerm();
		      } else
			if (g_headDone) {
			   foundCall( g_pName );
			   BEGIN( FunctionBody );
			} else {
			    g_headDone = TRUE;
			    BEGIN( HeadOperator );
			}
		}
	}

}


<FunctionBody>{

	{EOT}         {
		// end of a rule
		lineCount(); 
		Entry *c = current;
		if (c) {
			current->program+=yytext;
			//printf("\nDONE\n %s \n*******\n", current->program.data());
			if (current->section == Entry::CLAUSE_SEC) {
				endOfDef();
			}	
			BEGIN(Search);
		}
	}

	<<EOF>>        {
		// end of a rule
		lineCount(); 
		Entry *c = current;
		if (c) {
			if (current->section == Entry::CLAUSE_SEC) {
				endOfDef();
			}	
		}
		yyterminate();
	}

	{BB}(^{BB}\n)*	      {   // skip spaces
		lineCount(); 
		current->program+=yytext;
	}

	{BB}*(","|";"|"->"|"->*"){BB}* { //
		current->program+=yytext;
		// printf( "%p %d %s\n",current, g_headDone,current->program.data());
	}

	({ATOM}":")?{ATOM}"(" { // call
		current->program+=yytext;
		g_argLevel = 1;
		g_pName = yytext;
		BEGIN( FunctionParams );
	}

	({ATOM}":")?{ATOM} { // call
		current->program+=yytext;
	}

	"[" {
		current->program+=yytext;
		g_argLevel = 1;
		BEGIN( FunctionParams);
	}

	("("|"{") { //
		current->program+=yytext;
		g_callLevel++;
	}

	(")"|"}"|"]") { 
		//
		current->program+=yytext;
		g_callLevel--;
	}

}	


<Directive>{
    ("system_")?"module("{B}{ATOM}{B}"," { // define module  ATOM 
		QCString modn = strrchr( yytext, '(')+1;
		modn = modn.remove(modn.length()-1,1);
		modn = modn.stripWhiteSpace();
		g_packageName=modn;
		current_root = fetchGroup( current_root );
		QCString item=g_packageName;
		if (yytext[0] == 's')
			current_module = newModule("prolog", Private);
		else
			current_module = newModule(item.data(), Private);
		current_root->fileName = yyFileName; 
		BEGIN(ExportList);
	}

	"use_module("{B}{LIBRARY}{B}")"{B}{EOT} {
		lineCount(); 
		g_packageName=yytext;
		QCString item=g_packageName;
		current->name = removeRedundantWhiteSpace(sliceArgument(item.data(), ')' ));
		current->fileName = yyFileName; 
		current->section=Entry::USINGDECL_SEC;
		current_root->removeSubEntry(current);
		current_root->addSubEntry(current);
		current->startLine = yyLineNr;
		current->bodyLine  = yyLineNr;
		current = new Entry ;
		initEntry();			 
		BEGIN(Search);
	}


	"use_module("{B}{LIBRARY}{B}","{B} {
		g_packageName=yytext;
		QCString item=g_packageName;
		current->name =removeRedundantWhiteSpace(sliceArgument(item.data(), ',' ));
		current->fileName = yyFileName; 
		current->section=Entry::USINGDECL_SEC;
		current_root->removeSubEntry(current);
		current_root->addSubEntry(current);
		current->startLine = yyLineNr;
		current->bodyLine  = yyLineNr;
		current = new Entry ;
		initEntry();			 
		BEGIN(ImportList);
	}

	"use_system_module("{B}{LIBRARY}{B}")"{B}{EOT} {
		lineCount(); 
		g_packageName=yytext;
		QCString item=g_packageName;
		current->name =removeRedundantWhiteSpace(sliceArgument(item.data(), ')' ));
		current->fileName = yyFileName; 
		current->section=Entry::USINGDECL_SEC;
		current_root->removeSubEntry(current);
		current_root->addSubEntry(current);
		current->startLine = yyLineNr;
		current->bodyLine  = yyLineNr;
		current = new Entry ;
		initEntry();			 
		BEGIN(Search);
	}


	"use_system_module("{B}{LIBRARY}{B}","{B} {
		g_packageName=yytext;
		QCString item=g_packageName;
		current->name =removeRedundantWhiteSpace(sliceArgument(item.data(), ',' ));
		current->fileName = yyFileName; 
		current->section=Entry::USINGDECL_SEC;
		current_root->removeSubEntry(current);
		current_root->addSubEntry(current);
		current->startLine = yyLineNr;
		current->bodyLine  = yyLineNr;
		current = new Entry ;
		initEntry();			 
		BEGIN(ImportList);
	}

	\n		      {
		incLineNr();
	}
	
	{EOT}	      {
		incLineNr();
		BEGIN(Search);
	}
	
	[^\n]		      {
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
		current_root->removeSubEntry(current);
		current_root->addSubEntry(current);
		current->startLine = yyLineNr;
		current->bodyLine  = yyLineNr;
		current = new Entry ;
		initEntry();
	  */
	  if (g_argLevel > 0) exit(1);
	}

	{INDICATOR}  {
		/* current->name=yytext;
	  current->name = current->name.stripWhiteSpace();
	  current->fileName = yyFileName; 
	  current->section=Entry::USINGDECL_SEC;
	  current_root->addSubEntry(current);
	  current->startLine = yyLineNr;
	  current->bodyLine  = yyLineNr;
	  newEntry(); */
	}
	\n		{
		incLineNr();
	}

	{OPDEC}  {
		lineCount(); 
	}

	{B}")"{B}{EOT}		{
		lineCount(); 
		BEGIN(Search);
	}
}


<ExportList>{

  {B}"["{B}  {
    g_argLevel = 1;
  }

  {B}"]"{B}  {
    g_argLevel--;
  }

 {B}","{B}  {
   /* skip to next entry */
  }

{INDICATOR}  {
	QCString pname=normalizeIndicator(yytext); 
	buildPredEntry( pname , Public );
	current->section=Entry::EXPORTED_INTERFACE_SEC;
	current->protection = Public;
	newEntry();
 
}

	{OPDEC}  {
		lineCount(); 
	}

	\n		{
		incLineNr();
	}
	
	{B}")"{EOT}		{
		lineCount(); 
		BEGIN(Search);
	}
}

<SkipComment>{
	\n					{  lineComments(); }

	"*"+/[^/]	{ 
	}

	"*/"		{
		BEGIN( docBlockContext );
	}

	[A-Za-z0-9#&+-./:<>=?@^~`\\# \t]+ {
	}

	. {
	}

}

<SWISpecialComment,SpecialComment,SWISpecialLineComment,SpecialLineComment>{

	{INDICATOR}             {
		docBlock+='[';
		addToDocBlock( yytext );
		addToDocBlock( "](@ref " );
		{
		  int i = 0, ch;
		  while ((ch = yytext[i++]) != '/')
		    docBlock+=ch;
		}
		docBlock+=')';
	}

	{B}({ATOM}":")?{ATOM}"("{BB}         {
		addToDocBlock( yytext );
		/* found predicate name */
		if ( !current_pred ) {
			char *v;
			if ((v = strchr( yytext, '(')) != NULL) {
				v[0] = '\0';
				docBrief = FALSE;
				
				current->name = QCString( yytext );
				current->name = current->name.stripWhiteSpace();
				g_argLevel = 0;

				docBlockMain   = YY_START;
				BEGIN( ExtraCommentArgs ) ; 
			}
		}
	}

	"\n"{B}"~~"("~")*("{"[^\n]+"}")?"\n"		{
	  addToDocBlock( yytext );
	  docBlockMain   = YY_START;
	  BEGIN(Inline);
	}

 }

<SWISpecialComment,SWISpecialLineComment>{
	"=|"  {
	  docBlock += '`';
	  docBlockMain   = YY_START;
	  BEGIN( SWIQuoted );
	}

	{SQSTRING} {
	  addToDocBlock( yytext );
	}

         "\n==\n"		{
	   addToDocBlock( "\n~~~~~~~~~~{.prolog}\n" );
	  docBlockMain   = YY_START;
	  BEGIN(SWIInline);
	}
}

<SWISpecialComment,SpecialComment>{
  [^*\n]     { addToDocBlock( yytext ); } 
  
  "*"/[^/]    { addToDocBlock( yytext ); }

  "\n"        { addToDocBlock( yytext ); }

  "\n"{B}("*"{B})+/[^/]  { addToDocBlock( "\n" ); }

 	"*/"		{
	  handleCommentBlock(docBlock, docBrief);
	  BEGIN( docBlockContext );
	}
 }

<SWISpecialLineComment,SpecialLineComment>{
  "\n"{B}("%"{B})+  { addToDocBlock( "\n"); }

  [^\n]     { addToDocBlock( yytext ); } 
  
  "\n" { addToDocBlock( "\n" ); 
    handleCommentBlock(docBlock, docBrief);
    BEGIN(docBlockContext); }
 }


<SWIQuoted>{
  [^|\n]*     { addToDocBlock( yytext ); }   
  "|"+[^=]*   { addToDocBlock( yytext ); }
  "\n"        { addToDocBlock( yytext ); }
  "|="       {  addToDocBlock( "`" ); BEGIN(docBlockMain); }

}

<SWIInline>{
  "\n==\n"       {  addToDocBlock( "\n~~~~~~~~~~\n" ); BEGIN(docBlockMain); }
  [^\n]*      { addToDocBlock( yytext ); }   
  "\n"        { addToDocBlock( yytext ); }

}

<Inline>{
	  "~~~"("~")*"\n"       { 
	    addToDocBlock( yytext ); 
	    BEGIN(docBlockMain);
	  }
  [^\n]*      { addToDocBlock( yytext ); }   
  "\n"        { addToDocBlock( yytext ); }

}

<ExtraCommentArgs>{

	{PARAMETERDESCRIPTOR} {
		addToDocBlock( yytext );


		Argument *a = new Argument;
		char *v, *w;
		if ((v = strchr( yytext, ':')) != NULL) {
			v[0] = '\0';
			v += 1;
			a->type = yytext;
			a->type = a->type.stripWhiteSpace();
		} else {
			a->type = "";
			v = yytext;
		}
		if ((w = strchr( v, ',')) != NULL) {
			w[0] = '\0';
			a->name = v;
			a->name = a->type.stripWhiteSpace();
		} else {
			a->name = "";
		}
		current->argList->append(a);
	}

	{ATOMIC} {
		addToDocBlock( yytext );
	}

	("("|"["|"{") {
		addToDocBlock( yytext );
		g_argLevel++;
	}

	("]"|"}") {
		addToDocBlock( yytext );
		g_argLevel--;
	}

	")"({PREDINFO})? {
	  if (g_argLevel == 0) {
		addToDocBlock( yytext );
		if (current->briefLine == yyLineNr) {
		  addPredDecl( current_module );
		}
		BEGIN(docBlockMain);
	  } else {
		g_argLevel--;
		addToDocBlock( yytext );
	  }
	}

	{NEWLINE} {
		// terminate after a nl
	  addToDocBlock( yytext );
		BEGIN(docBlockMain);
	} 
	
	{B}","{B} {
	  addToDocBlock( yytext );
	}

}

      /* ------------ Default rules -------------- */

<Search,FunctionParams,FunctionBody,HeadOperator,TakeList,Directive,ImportList,ExportList>{SLASHSTARSTARTCOMMENT}	{
	lineComments();
	g_packageCommentAllowed = FALSE;
	docBlockContext = YY_START;
	BEGIN( SkipComment );
}

<SpecialComment>{SLASHSTARSTARTCOMMENT}	{
	g_specialBlock += yytext;
}

<Search>{SPECIALPERCCOMMENT}{BN}"<module>"[^\n]+"\n"	{
		lineComments();
		g_packageCommentAllowed = TRUE;
		initSpecialBlock( current_module );
		docBlockContext = YY_START;
		g_slashStarComment = FALSE;
		initSWIComment( yytext );
		BEGIN( SWISpecialLineComment );
	}

<Search>{SPECIALPERCCOMMENT}	{
        initSpecialBlock( current_module );
	g_packageCommentAllowed = TRUE;
	docBlockContext = YY_START;
	 g_slashStarComment = FALSE;
	 docBlockContext = YY_START;
	 if ( g_SWIStyle) {
	   initSWIComment( yytext );
	   BEGIN( SWISpecialLineComment );
	 } else {
	   BEGIN( SpecialLineComment );
	 }

}

<FunctionParams,FunctionBody,TakeList>{ATOMIC}	{ 
	if (current) {
		current->program+=yytext;
		g_defVal += yytext;
	}
}    	  

<*>{NEWLINE}	      { 
	if ( g_specialBlock ) {
	  addToDocBlock( yytext );
	} else if (current) {
	  current->program+=yytext;
	  g_defVal += yytext;
	  incLineNr(); 
	}
}


<Search,FunctionParams,HeadOperator,TakeList,Directive,ImportList,ExportList,SkipComment,ExtraCommentArgs,SpecialComment><<EOF>>	      {
  yyterminate();
}

<Search,FunctionParams,FunctionBody,HeadOperator,TakeList,Directive,ImportList,ExportList,ExtraCommentArgs>{BB}	      {   // skip spaces quickly
	if (current) {
		current->program+=yytext;
		g_defVal += yytext;
	}
}

%%


//----------------------------------------------------------------------------

static void parsePrototype(const QCString &text)
{
  //printf("**** parsePrototype(%s) begin\n",text.data());
  if (text.isEmpty()) 
  {
    warn(yyFileName,yyLineNr,"Empty prototype found!");
    return;
  }

  g_specialBlock = FALSE;
  g_packageCommentAllowed = FALSE;

  const char *orgInputString;
  int orgInputPosition;
  YY_BUFFER_STATE orgState;
  
  // save scanner state
  orgState = YY_CURRENT_BUFFER;
  yy_switch_to_buffer(yy_create_buffer(prologscannerYYin, YY_BUF_SIZE));
  orgInputString = inputString; 
  orgInputPosition = inputPosition;

  // set new string
  inputString = text;
  inputPosition = 0;
  prologscannerYYrestart( prologscannerYYin );

  BEGIN( FunctionDec );

  prologscannerYYlex();
  g_lexInit=TRUE;

  current->name = current->name.stripWhiteSpace();
  if (current->section == Entry::MEMBERDOC_SEC && current->args.isEmpty())
    current->section = Entry::VARIABLEDOC_SEC;

  // restore original scanner state

  YY_BUFFER_STATE tmpBuf = YY_CURRENT_BUFFER;
  yy_switch_to_buffer(orgState);
  yy_delete_buffer(tmpBuf);

  inputString = orgInputString; 
  inputPosition = orgInputPosition;

  //printf("**** parsePrototype end\n");
}

void prologscanFreeScanner()
{
#if defined(YY_FLEX_SUBMINOR_VERSION) 
  if (g_lexInit)
  {
    prologscannerYYlex_destroy();
  }
#endif
}

#if DEBUG_ALL
 void      
show_scanner_tree(uint off, Entry *current) {
	 const char * s;
	 switch (current->section) {
	 case Entry::CLASS_SEC:
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
	 case Entry::EXPORTED_INTERFACE_SEC:
		 s = "EXPORTED_INTERFACE";
		 break;
	 case Entry::INCLUDED_SERVICE_SEC:
		 s = "INCLUDED_SERVICE";
		 break;
	 case Entry::CLAUSE_SEC:
		 s = "CLAUSE_SEC";
		 break;
	}
	printf("%*s -> %s\n",off+20, s, current->name.data() /*, current->program.data() */);
	EntryListIterator eli(*current->children());
	Entry *ce;
	for (;(ce=eli.current());++eli)
	  {
	    if (ce->parent() != current )
	      printf("UGH %p %p instead of %p\n", ce , ce->parent(), current );
	    show_scanner_tree(off+4, eli);
	  }
      }

#endif

//----------------------------------------------------------------------------

void PrologLanguageScanner::parseInput(const char *fileName,
                                       const char *fileBuf,
                                       Entry *root,
                                       bool /*sameTranslationUnit*/,
                                       QStrList & /*filesInSameTranslationUnit*/)
{
  g_thisParser = this;
  printlex(yy_flex_debug, TRUE, __FILE__, fileName);
  ::parseMain(fileName,fileBuf,root);
#if DEBUG_ALL
  show_scanner_tree(0, root);
#endif
  printlex(yy_flex_debug, FALSE, __FILE__, fileName);

  // May print the AST for debugging purposes
  //printAST(root);
  g_predNameCache.clear();
  g_moduleNameCache.clear();
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
  initParser();

  inputString = fileBuf;
  inputPosition = 0;

  protection    = Public;
  mtype         = Method;
  gstat         = FALSE;
  virt          = Normal;
  current_root  = rt;
  g_specialBlock = FALSE;
  g_SWIStyle = FALSE;

  inputFile.setName(fileName);
  if (inputFile.open(IO_ReadOnly))
  {
    yyLineNr= 1 ; 
    yyFileName = fileName;

    //setContext();
    msg("Parsing file %s...\n",yyFileName.data());
    current = rt ;
    initParser();
    g_predNameCache.clear();
    g_moduleNameCache.clear();
    current_module = newModule( "user", Public );
    current            = new Entry;
    current->reset();
    initEntry();

    groupEnterFile(yyFileName,yyLineNr);

    // make user default module
    prologscannerYYrestart( prologscannerYYin );
    BEGIN( Search );
    prologscannerYYlex();
    g_lexInit=TRUE;

    groupLeaveFile(yyFileName,yyLineNr);

    current_root->program.resize(0);
    delete current; current=0;

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


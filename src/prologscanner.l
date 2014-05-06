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
/*  This code is based on the python module, based on the work by the MoxyPyDoxy team
 *  (Linda Leong, Mike Rivera, Kim Truong, and Gabriel Estrada)
 *  in Spring 2005 as part of CS 179E: Compiler Design Project
 *  at the University of California, Riverside; the course was
 *  taught by Peter H. Froehlich <phf@acm.org>, but was extensively changed to 
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
#define YY_NO_INPUT 1

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
static QCString         docBlock;
static QCString         docBlockName;
static bool             docBlockInBody;
static bool             docBlockJavaStyle;
static bool             docBrief;

static bool             g_specialBlock;
static int              g_stringContext;
static QGString *       g_copyString;

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

static unsigned int     g_callLevel = 0;

static unsigned int     g_arglevel = 0;

QStack<unsigned int> g_arityStack;
static void newClause( Entry *parent_module );


//-----------------------------------------------------------------------------


static QCString	
stripQuotesAndAddArity(char *inp, uint arity)
{
  QCString rc;
  size_t sz = strlen(inp);
  char * quoted = strchr( inp, '\'');
  char * modulesep = strchr( inp, ':');

  if (modulesep) {
    if (quoted && modulesep +1 != quoted) 
      return 0;
    rc = inp;
    if (quoted) {
      if (inp[sz-1] != '\'')
	return 0;
      rc.remove(sz-1,1);
      rc.remove(quoted-inp,1);
    }
  } else {
    if (quoted && inp != quoted) 
      return 0;
    rc = inp;
    if (quoted) {
      if (inp[sz-1] != '\'')
	return 0;
      rc.remove(sz-1,1);
      rc.remove(0,1);
    }
  }
  rc += "/";
  char arcs[20];
  snprintf(arcs, 20, "%u", arity);
  rc += arcs;
  return rc;
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

static void foundCall( QCString name, unsigned int arity )
{
	return;
	Entry *n = new Entry;
	char *s = (char *)name.data(), *ns;
	QCString pname;
	if ( s ) {
		     if ((ns = strchr(s, ':'))) {
		       // is module qualified
		       ns[0] = '\0';
		       s = ns+1;
		   	pname = stripQuotesAndAddArity( s , arity );
		     }
		   }
		  //n->prolog = TRUE;
		  n->protection = protection ;
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
	   n->protection = protection;
	   n->name = pname.data();
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
  n->name = yytext;
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
sliceArgument(char *inp)
{
  char *ptr = (char *)malloc(strlen(inp)+1), *tmp = inp;
  int ch;

  if (!ptr)
    return NULL;
  while ((ch = *inp++) && (ch != '(')) {
    if (ch == '\'') {
      while ((ch = *inp++) && ch != '\'')
	if (ch == '\\') inp++;
    }
  }
  while ((ch = *inp++) && isblank(ch));
  if (ch != '\'') inp--;
  tmp= inp+strlen(inp);
  ch = *tmp; tmp--;
  strncpy( ptr, inp, tmp-inp);
  ptr[tmp-inp] = '\0';
  if (ptr[tmp-(inp+1)] == '\'')
    ptr[tmp-(inp+1)] = '\0';
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
  }
}

static void 
lineComments( void )
{
  //  DBG_CTX((stderr,"yyLineNr=%d\n",yyLineNr));
  for (const char *p = yytext; *p; ++p)
  {
    yyLineCms += (*p == '\n') ;
  }
}

static void 
incLineNr( void )
{
  return lineCount();
  //  yyLineNr++;
}

//-----------------------------------------------------------------

//-----------------------------------------------------------------
static void 
startCommentBlock(bool brief)
{
  if (brief)
  {
    current->briefFile = yyFileName;
    current->briefLine = yyLineNr;
  }
  else
  {
    current->docFile = yyFileName;
    current->docLine = yyLineNr;
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

static void
handleCommentBlock(const QCString &doc,bool brief)
{
  //printf("handleCommentBlock(doc=[%s] brief=%d docBlockInBody=%d docBlockJavaStyle=%d\n",
  //    doc.data(),brief,docBlockInBody,docBlockJavaStyle);

  // TODO: Fix me
  docBlockInBody=FALSE;
  
  if (docBlockInBody && previous && !previous->doc.isEmpty())
  {
    previous->doc=previous->doc.stripWhiteSpace()+"\n\n";
  }

  int position = 0;
  bool needsEntry;
  int lineNr = brief ? current->briefLine : current->docLine;
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
  if (needsEntry || current_pred)
  {
    newEntry(  );
  }
  current_pred = FALSE;
}

static void endOfDef(int correction=0)
{
  // printf("endOfDef at=%d\n",yyLineNr);
  // printf("endOfDef %s\n", current->program.data());
  newClause( current_module );
  if (bodyEntry)
  {
    bodyEntry->endBodyLine  = yyLineNr-correction;
    bodyEntry = 0;
  }
  newEntry(  );

  //g_insideConstructor = FALSE;
}

static inline void addToString(const char *s)
{
  if (g_copyString) (*g_copyString)+=s;
}

static void initSpecialBlock()
{
  docBlockContext   = YY_START;
  docBlockInBody    = FALSE;
  docBlockJavaStyle = TRUE;
  docBrief = TRUE;
  docBlock.resize(0);
  startCommentBlock(TRUE);
}


 static Entry *newModule( const char *modname )
{
  Entry * newp;
  QCString mname = modname;

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
    current->name = mname;
    current->setParent( current_root ); 
    current->parent()->addSubEntry(current);
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
  current->section = Entry::FUNCTION_SEC;
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
  //printf("searchFoundDef at=%d\n",yyLineNr);
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
 buildPredEntry( QCString pname )
 {
   initEntry();
   current->section = Entry::CLASS_SEC;
   current->argList->clear();
   current->type = "predicate" ;
   current->fileName  = yyFileName;
   current->startLine  = yyLineNr;
   current->bodyLine  = yyLineNr;
   current->protection = protection;
   current->name += pname.copy();
   if (!current->name.isEmpty() && current->name.at(0)=='$') // mark as private
     {
       current->protection = protection=Private;
     }
   else 
     {
       current->protection = protection=Public;
     }
 }


static void newClause( Entry *parent_module ) {
   Entry *newp;

   QCString pname = current->name;
   unsigned int nth = 1;
   char *s = pname.data(), *ns;
   if ( s ) {
     if ((ns = strchr(s, ':'))) {
       // is module qualified
       ns[0] = '\0';
       parent_module = newModule(s);
       s = ns+1;
       pname = s;
     }
   }
   if ( !(newp = g_predNameCache.find(pname)) ) {
     Entry *bkup = current; // keep the current object, it will now be a predicate ( class ); 

     // create a predicate entry
     newp = current = new Entry;
     // insert new entry
     g_predNameCache.insert(pname, current);
     buildPredEntry( pname );
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
     nth = 1;
     // switch, move clause up to head.
     previous = newp;
     current = bkup;
   } else {
     current_root = newp;
     nth = newp->children()->count()+1;
   }
   current->setParent( newp );

   if (!current->name.isEmpty() && current->name.at(0)=='$') // mark as private
     {
       current->protection = protection=Private;
     }
   else 
     {
       current->protection = protection=Public;
     }

   char buf[32];
   snprintf( buf, sizeof(buf), "%s_c%u", current->name.data(), nth);
   current->name = buf;
   current_clause = current;
 }

 static void addPredDecl( Entry *current_module )
{
  unsigned int arity = current->argList->count();
  Entry * newp, *mod = current_module;
  QCString pname;
  char *s = current->name.data();

  // second definition for same predicate, just ignore
  if (current_pred)
    return;
  if ( s ) {
    char *ns;

    while ((ns = strchr(s, ':'))) {
      // is module qualified
      ns[0] = '\0';
      mod = newModule(s);
      s = ns+1;
      pname = s;
    }
    pname = stripQuotesAndAddArity( s, arity ). data();
    docBlock += "\n@anchor ";
    docBlock +=  protectChars( pname.data() );
    docBlock += "\n";
    //        pname.prepend("prolog::");
  } else {
    pname = "none/0";
  }
  if (!(newp = g_predNameCache.find(pname))) {
     // add a new predicate
    g_predNameCache.insert(pname, current);
    current->section = Entry::CLASS_SEC;
    current->type = "predicate" ;
    current->fileName  = yyFileName;
    current->startLine  = yyLineNr;
    current->bodyLine  = yyLineNr;
    current->bodyLine  = yyLineNr;
    current->setParent( mod );
    current->name = pname;
    if (!current->name.isEmpty() && current->name.at(1)=='$') // mark as private
      {
	current->protection = protection=Private;
      }
    else 
      {
	current->protection = protection=Public;
      }
  } else {
    newp->argList = current->argList->deepCopy();
    current = newp;
  }

  current_pred = TRUE;
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
NUMBER            {DIGIT}+
CHAR              "0'"(.)

INTNUMBER         {HEXNUMBER}|{OCTNUMBER}|{NUMBER}
FLOATNUMBER       {DIGIT}+"."{DIGIT}+([eE][+\-]?{DIGIT}+)?[jJ]?
LETTER            [A-Za-z\x80-\xFF]
NONEMPTY          [A-Za-z0-9_\x80-\xFF]
EXPCHAR           [#(){}\[\],:.%/\\=`*~|&<>!;+-]
IDENTIFIER        ([a-z]({LETTER}|{DIGIT}|"_")*)  

VAR	          [A-Z_]({LETTER}|{DIGIT}|"_")* 

BORDER            ([^A-Za-z0-9])

STRINGCHAR         [^\\"'\n]
ESCAPESEQ          ("\\"[\\n\\abdefnrstvz'"`]|"\\b"{BN}{BNS}|"\\u"{HEXD}+|"\\x"{HEXD}*|"\\"{OCTD}+) 
QSTRINGITEM        ({STRINGCHAR}|{ESCAPESEQ}|"''"|"\\'"|"\"")
DQSTRINGITEM       ({STRINGCHAR}|{ESCAPESEQ}|"\"\""|"\\\""|"'")

SQSTRING           ("'"({QSTRINGITEM})*"'")
DQSTRING           ("\""({QSTRINGITEM})*"\"")

SYMBOL		   [#&*+-./:<>=?@^~`\\]

SOLO		  [;!]

ATOM		   ({IDENTIFIER}|{SQSTRING}|{SYMBOL}+|{SOLO})

INDICATOR          (({ATOM}":")?{ATOM}("/"|"//"){NUMBER})

LIBRARY		   (({ATOM}"("{B}{ATOM}{B}")")|{ATOM})

FLOWKW             ("spy"|"nospy"|"same"|"block"|"^"|"**"|"\\"|"rem"|"mod"|">>"|"<<"|"//"|"/"|"*"|"xor"|"div"|"rdiv"|"#"|"><"|"\\/"|"/\\"|"-"|"-"|"+"|"+"|":"|"as"|">="|"=<"|">"|"<"|"=\\="|"=:="|"\\=@="|"=@="|"@>="|"@=<"|"@>"|"@<"|"\\=="|"=="|"=.."|"is"|"\\="|"="|"not"|"\\+"|"."|","|"*->"|"->"|";"|"|"|"uncutable"|"table"|"discontiguous"|"module_transparent"|"meta_predicate"|"multifile"|"public"|"mode"|"volatile"|"initialization"|"thread_local"|"dynamic"|"?-"|"-->"|":-"|":-")

POUNDCOMMENT      "%"[^%\n][^\n]* 
STARTDOCSYMS      ("%!"|"%%")<BN>

SLASHSTARSTARTCOMMENT "/*"
SLASHSTARTSPECIAL     "/*"[!*]<BN>
SLASHSTAREMPTYCOMMENT "/*/"
SLASHSTARENDCOMMENT   "*/"

PREDTAG               ("det"|"semidet"|"failure"|"nondet"|"multi"|"iso"|"deprecated"|"dynamic")

PARAMETERDESCRIPTOR   ([+-?:@!]?({VAR}":"){IDENTIFIER})

PREDINFO              ({BB}"is"{BB}{PREDTAG}({B}","{B}{PREDTAG})*{B}{NEWLINE})

%option noyywrap

  /* Main start state */

%x Search
%x SearchMemVars

  /* Mid-comment states */

  /* %x FuncDoubleComment */
  /* %x ClassDoubleComment */
%x TryClassDocString
%x TripleComment
%x SpecialComment
%x SkipComment
%x StarSpecialComment
%x ExtraCommentArgs

  /* Function states */

%x FunctionDec
%x FunctionParams
%x FunctionBody
%x FunctionNeck
%x FunctionParamDefVal
%x CallArgs

  /* Class states */

%x ClassDec
%x ClassInheritance
%x ClassCaptureIndent
%x ClassBody

  /* String states */

%x SingleQuoteString
%x DoubleQuoteString


  /* import */
%x Directive
%x ImportList
%x ExportList
%x Import

%%

  /* ------------ Function recognition rules -------------- */

<Search>{
    {B}+               { // just ignore white space 
                       }

     {B}":-"{B}        { // start of directive
			  g_packageCommentAllowed = FALSE;
                          BEGIN( Directive );
                       }
			   

     ("/**"|"/*!"){BN}	{
                        lineComments();
			g_packageCommentAllowed = FALSE;
			initSpecialBlock();
                        BEGIN( StarSpecialComment );
		      }

     {STARTDOCSYMS}/[^%]    {  // start of a special comment
       lineComments(); 
       g_packageCommentAllowed = FALSE;
			initSpecialBlock();
			BEGIN(SpecialComment);
                      }

    {SLASHSTARSTARTCOMMENT}	{
                        lineComments();
			g_packageCommentAllowed = FALSE;
                        BEGIN( SkipComment );
		      }
    {POUNDCOMMENT}    { // normal comment 
      lineComments(); 
      g_packageCommentAllowed = FALSE;
      		      }
    {NEWLINE}+        { // new line
			lineCount(); 
                      }

    [^\n]             { 
			// must be start of a function/clause definition
                          unput(*yytext);
			  searchFoundDef();
			  BEGIN( FunctionDec );
			  
			// any other character...
                        // This is the major default
                        // that should catch everything
                        // else in Body.
                      }
}

<FunctionDec>{

    {ATOM}            {
			      //found function name
			      if (current->type.isEmpty()) 
			      {
				  current->type = "method";
			      }
			      current->program += yytext;
			      current->name = yytext;
			      current->name = current->name.stripWhiteSpace();
                            }
    [ "(" ]    	             {
    		   current_clause = current;
    		   current->program+=yytext;
			      g_arglevel = 0;
			      g_defVal = "";
			      BEGIN( FunctionParams );
    }
}

<FunctionParams>{
      [","]            {
                          current->program+=yytext;
			  if (g_arglevel == 0) {
			    // Name of parameter
			    Argument *a = new Argument;
			    a->name = g_defVal.stripWhiteSpace();
			    a->type = "";
			    current->argList->append(a);
			    g_defVal = "";
			  }
                        }
    [(\[\{(]            {
			      current->program+=yytext;
			      g_defVal += yytext;
                           g_arglevel++;
                        }
    [\]\}]              {
			      current->program+=yytext;
			      g_defVal += yytext;
                           g_arglevel--;
                        }
      {DQSTRING}	{ // double-quoted string
    	  // just copy
	      current->program+=yytext;
	      g_defVal += yytext;
      }    	  

	")"   { // end of parameter list
	current->program+=yytext;
	if (g_arglevel == 0) {
	  unsigned int arity = current->argList->count()+1;
	  newFunction();
	  Argument *a = new Argument;
	  
	  current->argList->append(a);
	  current->argList->getLast()->name = g_defVal.stripWhiteSpace();
	  current->argList->getLast()->type = "";
	  if (current->name.data()) {
	    current->name = stripQuotesAndAddArity( current->name.data(), arity ).data();
	    //	    current->name.prepend("prolog::");
	  } else {
	    current->name = "op/2"; // assume that we have a binary operator.
	  }
	  g_defVal = "";
	  BEGIN( FunctionNeck );
	} else {
	  g_arglevel--;
	}
      }
	
     . { 
	// default rule
       g_defVal += yytext;
       current->program+=yytext;
      }
 


}


<FunctionNeck>{

	{B}(":-"|"-->")    {
		current->program+=yytext;
		current->bodyLine  = yyLineNr;
		BEGIN( FunctionBody ) ; 
	}

	<<EOF>>	      {
		endOfDef();
		yyterminate();
	}
	{EOT}         {
		// facts
		endOfDef();
		lineCount(); 
		BEGIN(Search);

	}
}

<FunctionBody>{

	{BB}	      {   // skip spaces
		current->program+=yytext;
	}
	
	^{BB}/\n	      { // skip empty line
		current->program+=yytext;
	}
	
	{STARTDOCSYMS}    {  // start of a special comment
		initSpecialBlock();
		BEGIN(SpecialComment);
	}
	
	{ATOM}"(" { // call
		current->program+=yytext;
		unsigned int a0=1;
		g_arityStack.push(&a0);
		g_pName = yytext;
		if (g_callLevel == 0)
			g_callLevel = g_arityStack.count();
	}
	
	{POUNDCOMMENT}    {
		//catch a line
		// current->program+=yytext;
	}
	
	{NEWLINE}	      { 
		incLineNr(); 
		current->program+=yytext;
	}

	<<EOF>>	      {
		endOfDef();
		yyterminate();
	}
	
	{ATOM} { //
		current->program+=yytext;
	}
	
	{VAR} { //
		current->program+=yytext;
		foundVariable();
	}
	
	"," { //
		current->program+=yytext;
		if ( !g_arityStack.isEmpty()) {
			unsigned int i = *g_arityStack.pop();
			i++;
			g_arityStack.push(&i);
		}
	}
	
	{NUMBER} {
		current->program+=yytext;
	}
	
	[)\]\}] { //
		unsigned int arity = *g_arityStack.pop();
		current->program+=yytext;
		g_arglevel--;
		if (g_arityStack.count()+1 == g_callLevel) {
			foundCall( g_pName, arity );
			g_callLevel = 0;
		} else {
			foundTerm();
		}
	}
	
	[(\[\{] { //
		current->program+=yytext;
		unsigned int i = 1;
		g_arityStack.push(&i);
	}

	[^ \t\n.]	    { // non-special stuff like '
		current->program+=yytext;
		g_specialBlock = FALSE; 
	}
	
	{EOT}         {
		// facts
		endOfDef();
		lineCount(); 
		BEGIN(Search);

	}

}


<Directive>{
  "system_module("{B}{ATOM}{B}"," { // define module  ATOM 
	  g_packageName=yytext;
	  current_root = fetchGroup( current_root );
	  QCString item=g_packageName;
	  item.remove(strlen(yytext)-1,1);
	  item.remove(0, strlen("system_module("));
	  item.stripWhiteSpace();
	  current_module = newModule(item.data());
	  current_root->fileName = yyFileName; 
	  BEGIN(ExportList);
	}

	"module("{B}{ATOM}"," { // define module  ATOM 
	  g_packageName=yytext+7;
	  current_root = current;
	  QCString item=g_packageName;
	  // remove comma
	  item.remove(item.length(), 1);
	  item.stripWhiteSpace();
	  current_module = newModule( item.data() );
	  current_root->fileName = yyFileName; 
	  BEGIN(ExportList);
	}

	"use_module("{B}{LIBRARY}{B}")"{B}{EOT} {
	  lineCount(); 
	  g_packageName=yytext;
	  QCString item=g_packageName;
	  current->name =removeRedundantWhiteSpace(sliceArgument(item.data()));
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


	"use_module("{B}({LIBRARY}){B}","{B} {
	  g_packageName=yytext;
	  QCString item=g_packageName;
	  current->name =removeRedundantWhiteSpace(sliceArgument(item.data()));
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
	  current->name =removeRedundantWhiteSpace(sliceArgument(item.data()));
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


	"use_system_module("{B}({LIBRARY}){B}","{B} {
	  g_packageName=yytext;
	  QCString item=g_packageName;
	  current->name =removeRedundantWhiteSpace(sliceArgument(item.data()));
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
	
{EOT} {
	  lineCount(); 		 
	  BEGIN(Search);
	}
	\n		      {
                        incLineNr();
                      }
  .		      {
		      }

 }

<ImportList>{
	"_"  {    
	  current->name="_";
	  current->fileName = yyFileName; 

	  current->section=Entry::USINGDECL_SEC;
	  current_root->removeSubEntry(current);
	  current_root->addSubEntry(current);
	  current->startLine = yyLineNr;
	  current->bodyLine  = yyLineNr;
	  current = new Entry ;
	  initEntry();
	}

	{INDICATOR}  {
	  /* current->name=yytext;
	  current->name = current->name.stripWhiteSpace();
	  current->fileName = yyFileName; 
	  current->section=Entry::USINGDECL_SEC;
	  current_root->addSubEntry(current);
	  current->startLine = yyLineNr;
	  current->bodyLine  = yyLineNr;
	    current = new Entry ;
	    initEntry(); */
	}
	\n		{
	  incLineNr();
	}
	{B}")"{B}{EOT}		{
	  BEGIN(Search);
	}
}


<ExportList>{

	{INDICATOR}  {
		/*	  current->name=substitute(yytext,","," ");
	  current->name = current->name.stripWhiteSpace();
	  current->fileName = yyFileName; 
	  current->section=Entry::EXPORTED_INTERFACE_SEC;
	  current_module->addSubEntry(current);
	  current->startLine = yyLineNr;
	  current->bodyLine  = yyLineNr;
	  current = new Entry ;
	  initEntry(); */
	}

	\n		{
		incLineNr();
	}
	{B}")"{B}{EOT}		{
		lineCount(); 
		BEGIN(Search);
	}
}

      <SkipComment>{
[^\*\n]+

  \n					{  lineComments(); }

 {INDICATOR}                   {
   
 }

  {B}"*/"			{ BEGIN( Search ) ; }
}


<StarSpecialComment>{
	"*/"			{ 
	  docBlock+="\n";

	  handleCommentBlock(docBlock, docBrief);
	  BEGIN( Search ) ; 
	}

	{INDICATOR}             {
	  docBlock+='[';
	  docBlock+=yytext;
	  docBlock+="](@ref ";
	  {
	    int i = strlen(yytext);
	    while (yytext[--i] != '/');
	    if (i > 1 && yytext[i-1] == '/') { // a//i

	      yytext[i] = '\0';
	      docBlock+=yytext;
	    } else {
	      yytext[i] = '_';
	      docBlock+=yytext;
	    }
	  }
	  docBlock+=')';
	}

        ({ATOM}":")?{ATOM}"("         {
	   docBlock+=yytext;
	   /* found predicate name */
	   if ( !current_pred ) {
	     char *v;
	     if ((v = strchr( yytext, '(')) != NULL) {
	       v[0] = '\0';
	       docBrief = FALSE;

	       current->name = yytext;
	       current->name = current->name.stripWhiteSpace();

	     BEGIN( ExtraCommentArgs ) ; 
	     }
	   }
	}

	{NEWLINE}	{  
	  docBlock+='\n';
	  docBrief = ( strstr( docBlock.data(), "@brief") == NULL && docBrief);
	  startCommentBlock( docBrief );
	  lineComments();
	}

	. {
	  putchar(*yytext);
	  docBlock+=*yytext;  
        }

}


<ExtraCommentArgs>{

  {PARAMETERDESCRIPTOR} {
    docBlock+=yytext;


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

  ")"({PREDINFO})? {
    docBlock+=yytext;
    addPredDecl( current_module );
    BEGIN( StarSpecialComment );
  }

  {NEWLINE} {
      docBlock+=*yytext;
      lineComments();
      BEGIN( StarSpecialComment );
  } 
 
  [^\n] {
      docBlock+=*yytext;
  } 

  
}


	<SpecialComment>{
	
		^{B}"%"("%")*|^{B}"%"("!")*	{ // skip leading hashes
		}
	
		\n/{B}"%"		{ // continuation of the comment on the next line
			docBlock+='\n';
			docBrief = FALSE;
			startCommentBlock(FALSE);
			lineComments();
		}
		[^%\n]+             { // any other stuff
			docBlock+=yytext;
		}
		\n			{ // new line that ends the comment
			handleCommentBlock(docBlock, docBrief);
			lineComments();
			BEGIN(docBlockContext);
		}
		.			{ // anything we missed
			docBlock+=*yytext;
		}
	}

<SingleQuoteString>{
	\\{B}\n                    { // line continuation
		addToString(yytext);
		incLineNr();
	}
	\\.			       { // espaced char
		addToString(yytext);
	}
	"'"			       { // end of the string
		addToString(yytext);
		BEGIN(g_stringContext);
	}
	[^"'\n\\]+	               { // normal chars like "
	 addToString(yytext);
}
.			       { // normal char
	addToString(yytext);
}
}

<DoubleQuoteString>{
    \\{B}\n                    { // line continuation
      			         addToString(yytext);
      				 incLineNr();
                               }
    \\.			       { // espaced char
      			         addToString(yytext);
                               }
    "\""		       { // end of the string
      			         addToString(yytext);
      		                 BEGIN(g_stringContext);
                               }
    [^"'\n\\]+	               { // normal chars like "
      			         addToString(yytext);
                               }
    .			       { // normal char
      			         addToString(yytext);
                               }
}

  /* ------------ End rules -------------- */

  /*
<*>({NONEMPTY}|{EXPCHAR}|{BB})           { // This should go one character at a time.
//				 printf("[prologscanner] '%s' [ state %d ]  [line %d] no match\n",
				        yytext, YY_START, yyLineNr);

                               }
  */

<*>{NEWLINE}                   {
	//printf("[prologscanner] %d NEWLINE [line %d] no match\n",
	//			        YY_START, yyLineNr);

			incLineNr(); 
                               }

<*>.                           {
	//		 printf("[prologscanner] '%s' [ state %d ]  [line %d] no match\n",
	//			        yytext, YY_START, yyLineNr);

}


%%

//----------------------------------------------------------------------------

static void parseCompounds(Entry *rt)
{
  //printf("parseCompounds(%s)\n",rt->name.data());
  EntryListIterator eli(*rt->children());
  Entry *ce;
  for (;(ce=eli.current());++eli)
  {
    if (!ce->program.isEmpty())
    {
      //printf("-- %s ---------\n%s\n---------------\n",
      //  ce->name.data(),ce->program.data());
      // init scanner state
      inputString = ce->program;
      inputPosition = 0;
      prologscannerYYrestart( prologscannerYYin ) ;
      if (ce->section&Entry::COMPOUND_MASK)
      {
        current_root = ce ;
        BEGIN( Search );
      }
      else if (ce->parent())
      {
        current_root = ce->parent();
	//printf("Searching for member variables in %s parent=%s\n",
	//    ce->name.data(),ce->parent->name.data());
	BEGIN( SearchMemVars );
      }
      yyFileName = ce->fileName;
      yyLineNr   = ce->bodyLine ;
      if (current) delete current;
      current = new Entry;
      initEntry();

      groupEnterCompound(yyFileName,yyLineNr,ce->name);
      
      prologscannerYYlex() ;
      g_lexInit=TRUE;
      delete current; current=0;
      ce->program.resize(0);

      groupLeaveCompound(yyFileName,yyLineNr,ce->name);

    }
    parseCompounds(ce);
  }
}

//----------------------------------------------------------------------------


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

    parseCompounds(current_root);

    inputFile.close();
  }
  
}

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

#define DEBUG_ALL 1

#if DEBUG_ALL
 void      
show_scanner_tree(uint off, Entry *current)
      {  
	if (current->section == Entry::FUNCTION_SEC)
	  printf("%*s %p %s\n",off+20, "FUNCTION", current, current->name.data() /*, current->program.data() */);
	else if (current->section == Entry::EMPTY_SEC)
	  printf("%*s %p %s %s\n",off+20, "EMPTY", current, current->name.data(), current->program.data());
	else if (current->section == Entry::USINGDECL_SEC)
	  printf("%*s %p %s %s\n",off+20, "USINGDECL_SEC", current, current->name.data(), current->program.data());
	else if (current->section == Entry::EXPORTED_INTERFACE_SEC)
	  printf("%*s %p %s %s\n",off+20, "EXPORTED_INTERFACE_SEC", current, current->name.data(), current->program.data());
	else if (current->section == Entry::NAMESPACE_SEC)
	  printf("%*s %p %s %s\n",off+20, "NAMESPACE_SEC", current, current->name.data(), current->program.data());
	else if (current->section == Entry::CLASS_SEC)
	  printf("%*s %p %s %s\n",off+20, "CLASS_SEC", current, current->name.data(), current->program.data());
	else if (current->section == Entry::PAGEDOC_SEC)
	  printf("%*s %p %s %s\n",off+20, "PAGEDOC_SEC", current, current->name.data(), current->program.data());
	else if (current->section == Entry::CLASSDOC_SEC)
	  printf("%*s %p %s %s\n",off+20, "CLASSDOC_SEC", current, current->name.data(), current->program.data());
	else if (current->section == Entry::GROUPDOC_SEC)
	  printf("%*s %p %s %s\n",off+20, "GROUPDOC_SEC", current, current->name.data(), current->program.data());
	else 
	  printf("%*x %p %s %s\n",off+20, current->section, current, current->name.data(), current->program.data());
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
  // printAST(global_root);
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


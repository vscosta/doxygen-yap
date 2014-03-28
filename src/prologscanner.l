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
static Entry*		current      = 0 ;
static Entry*		previous     = 0 ;
static Entry*		bodyEntry    = 0 ;
static int		yyLineNr     = 1 ;
static QCString		yyFileName;
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
static QCString         g_packageScope;

static char             g_atomStart;
static char             g_atomEnd;
static int              g_atomCount;

//static bool             g_insideConstructor;

static QCString         g_moduleScope;
static QCString         g_packageName;

//static bool             g_hideClassDocs;

static QCString         g_defVal;

static bool             g_lexInit = FALSE;
static bool             g_packageCommentAllowed;

static unsigned int     arglevel = 0;

//-----------------------------------------------------------------------------


static void initParser()
{
  protection = Public;
  mtype = Method;
  gstat = FALSE;
  virt = Normal;
  previous = 0;
  g_packageCommentAllowed = TRUE;
  g_packageNameCache.setAutoDelete(TRUE);
}

static void initEntry()
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

static void newEntry()
{
  previous = current;
  current_root->addSubEntry(current);
  current = new Entry ;
  initEntry();
}

static void newVariable()
{
  if (!current->name.isEmpty() && current->name.at(0)=='_') // mark as private
  {
    current->protection=Private;
  }
  if (current_root->section&Entry::COMPOUND_MASK) // mark as class variable
  {
    current->stat = TRUE;
  }
  newEntry();
}

static void newFunction()
{
}


static QCString findPackageScopeFromPath(const QCString &path)
{
  QCString *pScope = g_packageNameCache.find(path);
  if (pScope)
  {
    return *pScope;
  }
  QFileInfo pf(path+"/__init__.py"); // found package initialization file
  if (pf.exists())
  {
    int i=path.findRev('/');
    if (i!=-1)
    {
      QCString scope = findPackageScopeFromPath(path.left(i));
      if (!scope.isEmpty())
      {
	scope+="::";
      }
      scope+=path.mid(i+1);
      g_packageNameCache.insert(path,new QCString(scope));
      return scope;
    }
  }
  return "";
}
  
static QCString findPackageScope(const char *fileName)
{
  if (fileName==0) return "";
  QFileInfo fi(fileName);
  return findPackageScopeFromPath(fi.dirPath(TRUE).data());
}

//-----------------------------------------------------------------------------

static void lineCount()
{
  DBG_CTX((stderr,"yyLineNr=%d\n",yyLineNr));
  for (const char *p = yytext; *p; ++p)
  {
    yyLineNr += (*p == '\n') ;
  }
}

static void incLineNr()
{
  DBG_CTX((stderr,"yyLineNr=%d\n",yyLineNr));
  yyLineNr++;
}

//-----------------------------------------------------------------

//-----------------------------------------------------------------
static void startCommentBlock(bool brief)
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

static void handleCommentBlock(const QCString &doc,bool brief)
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
    if (needsEntry)
    {
      newEntry();
    }
  }
  if (needsEntry)
  {
    newEntry();
  }

}

static void endOfDef(int correction=0)
{
  //printf("endOfDef at=%d\n",yyLineNr);
  if (bodyEntry)
  {
    bodyEntry->endBodyLine  = yyLineNr-correction;
    bodyEntry = 0;
  }
  newEntry();
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

static void searchFoundDef()
{
  current->fileName  = yyFileName;
  current->startLine = yyLineNr;
  current->bodyLine  = yyLineNr;
  current->section = Entry::FUNCTION_SEC;
  current->protection = protection = Public;
  current->lang = SrcLangExt_Prolog;
  current->virt = Normal;
  current->stat = gstat;
  current->mtype = mtype = Method;
  current->type.resize(0);
  current->name.resize(0);
  current->args.resize(0);
  current->argList->clear();
  g_packageCommentAllowed = FALSE;
  gstat=FALSE;
  //printf("searchFoundDef at=%d\n",yyLineNr);
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
    //printf("%d (%c)\n",*buf,*buf);
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

DIGIT             [0-9]

HEXNUMBER         "0"[xX][0-9a-fA-F]+[lL]?
OCTNUMBER         "0"[0-7]+[lL]?
NUMBER            {DIGIT}?
INTNUMBER         {HEXNUMBER}|{OCTNUMBER}|{NUMBER}
FLOATNUMBER       {DIGIT}+"."{DIGIT}+([eE][+\-]?{DIGIT}+)?[jJ]?
LETTER            [A-Za-z\x80-\xFF]
NONEMPTY          [A-Za-z0-9_\x80-\xFF]
EXPCHAR           [#(){}\[\],:.%/\\=`*~|&<>!;+-]
IDENTIFIER        (a-z)({LETTER}|{DIGIT}|"_")*  
VAR	              (A-Z_)({LETTER}({LETTER}|{DIGIT}|"_")*  
BORDER            ([^A-Za-z0-9])

QESCAPESEQ         ("\\")(.)
ATOM		      ("'"{QSHORTSTRINGITEM}*"'"|IDENTIFIER)
SHORTSTRING       ("'"{QSHORTSTRINGITEM}*"'"|'"'{DQSHORTSTRINGITEM}*'"')
QSHORTSTRINGITEM  ({QSHORTSTRINGCHAR}|{QESCAPESEQ})
QSHORTSTRINGCHAR   [^\\\n"]
FLOWKW            ("or"|"and"|"is"|"not"|"print"|"for"|"in"|"if"|"try"|"except"|"yield"|"raise"|"break"|"continue"|"pass"|"if"|"return"|"while"|"elif"|"else"|"finally")
POUNDCOMMENT      "%"[^%\n][^\n]* 

STARTDOCSYMS      "%!"

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

  /* Function states */

%x FunctionDec
%x FunctionParams
%x FunctionBody
%x FunctionParamDefVal

  /* Class states */

%x ClassDec
%x ClassInheritance
%x ClassCaptureIndent
%x ClassBody

  /* Variable states */
%x VariableDec
%x VariableEnd
%x VariableAtom

  /* String states */

%x SingleQuoteString
%x DoubleQuoteString
%x TripleString

  /* import */
%x FromMod
%x FromModItem
%x Import

%%

  /* ------------ Function recognition rules -------------- */

<Search>{

    ^{BB}{NONEMPTY}" :"{BB}       { // start of a function/clause definition with indent
      			  DBG_CTX((stderr,"Found def at %d\n",yyLineNr));
			  searchFoundDef();
			  BEGIN( FunctionDec );
      			}
     ^{B}":-"{B}"use_module("   	       { // start of an from import
			  g_packageCommentAllowed = FALSE;
                          BEGIN( FromMod );
                       }

    {POUNDCOMMENT}    { // normal comment 
			g_packageCommentAllowed = FALSE;
      		      }
    {IDENTIFIER}      { // some other identifier
			g_packageCommentAllowed = FALSE;
		      }

    {NEWLINE}+        { // new line
                        lineCount();
                      }

     {STARTDOCSYMS}/[^%]    {  // start of a special comment
			g_packageCommentAllowed = FALSE;
			initSpecialBlock();
			BEGIN(SpecialComment);
                      }
    [^\n]             { // any other character...
                        // This is the major default
                        // that should catch everything
                        // else in Body.
                      }
}


<FromMod>{
  {ATOM}"("{B}{ATOM} |
     {ATOM} { // from package import 
                        g_packageName=yytext;
		      }
  \n		      {
                        incLineNr();
                      }
  {B}		      {
		      }
 }

<FromModItem>{
  "_"		{ // import all
                  QCString item=g_packageName;
		  current->name=removeRedundantWhiteSpace(substitute(item,".","::"));
		  current->fileName = yyFileName; 
		  //printf("Adding using directive: found:%s:%d name=%s\n",yyFileName.data(),yyLineNr,current->name.data());
		  current->section=Entry::USINGDIR_SEC;
		  current_root->addSubEntry(current);
		  current = new Entry ;
		  initEntry();
                  BEGIN(Search);
    		}
  {IDENTIFIER}/{B}","{B} {
                   QCString item=g_packageName+"."+yytext;
		  current->name=removeRedundantWhiteSpace(substitute(item,".","::"));
		  current->fileName = yyFileName; 
		  //printf("Adding using declaration: found:%s:%d name=%s\n",yyFileName.data(),yyLineNr,current->name.data());
		  current->section=Entry::USINGDECL_SEC;
		  current_root->addSubEntry(current);
		  current = new Entry ;
		  initEntry();
		}
  {IDENTIFIER}  {
                  QCString item=g_packageName+"."+yytext;
		  current->name=removeRedundantWhiteSpace(substitute(item,".","::"));
		  current->fileName = yyFileName; 
		  //printf("Adding using declaration: found:%s:%d name=%s\n",yyFileName.data(),yyLineNr,current->name.data());
		  current->section=Entry::USINGDECL_SEC;
		  current_root->addSubEntry(current);
		  current = new Entry ;
		  initEntry();
                  BEGIN(Search);
		}
  \n		{
                  incLineNr();
                  BEGIN(Search);
                }
  {B}		{
		}
  ","		{ 
  		}
  .             {
                  unput(*yytext);
                  BEGIN(Search);
                }
}


<FunctionBody>{
    \n{B}/{IDENTIFIER}{BB}  {
                        DBG_CTX((stderr,"body at line %d\n",incLineNr()));
      		          current->program+=yytext;
                      }
    \n{B}/"%!"	      {
 			  incLineNr();
      		          current->program+=yytext;
      		      }
    <<EOF>>	      {
			endOfDef();
			yyterminate();
      		      }
    ^{BB}/\n	      { // skip empty line
      		        current->program+=yytext;
      	              }
    "\""              { // start of a double quoted string
      		        current->program+=yytext;
       			g_stringContext=YY_START;
		        g_specialBlock = FALSE; 
			g_copyString=&current->program;
                        BEGIN( DoubleQuoteString );
                      }
    [^ \t\n#'".]+     { // non-special stuff
      		        current->program+=yytext;
		        g_specialBlock = FALSE; 
                      }
    ^{POUNDCOMMENT}   { // normal comment 
      		        current->program+=yytext;
      		      }
    "#".*             { // comment half way
      		        current->program+=yytext;
                      }
    {NEWLINE}	      { 
			incLineNr(); 
      		        current->program+=yytext;
		      }
    .                 { // any character
      		        current->program+=*yytext;
		        g_specialBlock = FALSE; 
                      }

    {STARTDOCSYMS}/[^#]  {  // start of a special comment
			initSpecialBlock();
			BEGIN(SpecialComment);
                      }
    
}

<FunctionDec>{

    {IDENTIFIER}            {
			      //found function name
			      if (current->type.isEmpty()) 
			      {
				  current->type = "def";
			      }
			      current->name = yytext;
			      current->name = current->name.stripWhiteSpace();
			      newFunction();
                            }
     "("                  {
			       BEGIN( FunctionParams );
		            }
}

<FunctionParams>{
    ","                 {
                        }
    [(\[\{]             {
                           arglevel++;
                        }
    [\]\}]             {
                           arglevel--;
                        }

    {IDENTIFIER}        { // Name of parameter
			  lineCount();
			  Argument *a = new Argument;
			  current->argList->append(a);
			  current->argList->getLast()->name = QCString(yytext).stripWhiteSpace();
			  current->argList->getLast()->type = "";
                        }
 
     ")"                { // end of parameter list
                          if (arglevel) arglevel--;
                        }


}

<VariableDec>{
   "="                { // the assignment operator
                        //printf("====== VariableDec at line %d\n",yyLineNr);
			current->initializer = yytext;
			current->initializer += " ";
                      }
   {B}                { // spaces
	              }
   {INTNUMBER}	      { // integer value
			current->type = "int";
			current->initializer += yytext;
			BEGIN(VariableEnd);
		      }
   {FLOATNUMBER}      { // floating point value
			current->type = "float";
			current->initializer += yytext;
			BEGIN(VariableEnd);
		      }
   "["                { // list
			current->type = "list";
      		        current->initializer+=*yytext;
                        g_atomStart='[';
			g_atomEnd=']';
			g_atomCount=1;
			BEGIN( VariableAtom );
                      }
   "{"		      { // dictionary
			current->type = "dictionary";
      		        current->initializer+=*yytext;
                        g_atomStart='{';
			g_atomEnd='}';
			g_atomCount=1;
			BEGIN( VariableAtom );
                      }
   "#".*              { // comment
                        BEGIN( VariableEnd ); 
                      }
   {IDENTIFIER}	      {
      		        current->initializer+=yytext;
	              }
   .		      {
      		        current->initializer+=*yytext;
                      }
   \n		      {
     		        unput('\n');
     			BEGIN( VariableEnd );
     		      }
}

<VariableAtom>{
    [\(\[\{]	      {
      		        current->initializer+=*yytext;
                        if (g_atomStart==*yytext)
			{
			  g_atomCount++;
			}
                      }
    [\)\]\}]	      {
      		        current->initializer+=*yytext;
                        if (g_atomEnd==*yytext)
			{
			  g_atomCount--;
			}
			if (g_atomCount==0)
			{
			  BEGIN(VariableEnd);
			}
                      }
   "\""	              {
       			g_stringContext=YY_START;
			current->initializer+="\"";
			g_copyString=&current->initializer;
                        BEGIN( DoubleQuoteString );
                      }
   {IDENTIFIER}       {
      		        current->initializer+=yytext;
	              }
   .		      {
      		        current->initializer+=*yytext;
                      }
   \n		      {
      		        current->initializer+=*yytext;
     			incLineNr();
     		      }

}

<VariableEnd>{
    \n                {
                        incLineNr();
			newVariable();
                        BEGIN(Search);
                      }
    .		      { 
                        unput(*yytext);
			newVariable();
                        BEGIN(Search);
      		      }
    <<EOF>>           { yyterminate();
                        newEntry();
                      }
}

<SpecialComment>{
    
        ^{B}"%"("%")*|^{B}"%"("!")*	{ // skip leading hashes
    		}

    \n/{B}"%"		{ // continuation of the comment on the next line
      			  docBlock+='\n';
			  docBrief = FALSE;
                          startCommentBlock(FALSE);
			  incLineNr();
      			}
    [^%\n]+             { // any other stuff
      			  docBlock+=yytext;
      			}
    \n			{ // new line that ends the comment
			  handleCommentBlock(docBlock, docBrief);
      			  incLineNr();
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
    "\"\"\""		       { // tripple double quotes
      			         addToString(yytext);
      			       }
    "'"			       { // end of the string
      			         addToString(yytext);
      		                 BEGIN(g_stringContext);
                               }
    [^"'\n\\]+	               { // normal chars
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
    [^"'\n\\]+	               { // normal chars
      			         addToString(yytext);
                               }
    .			       { // normal char
      			         addToString(yytext);
                               }
}

  /* ------------ End rules -------------- */

  /*
<*>({NONEMPTY}|{EXPCHAR}|{BB})           { // This should go one character at a time.
				 // printf("[prologscanner] '%s' [ state %d ]  [line %d] no match\n",
				 //       yytext, YY_START, yyLineNr);

                               }
  */

<*>{NEWLINE}                   {
				 //printf("[prologscanner] %d NEWLINE [line %d] no match\n",
				 //       YY_START, yyLineNr);

                                 lineCount();
                               }

<*>.                           {
				 //printf("[prologscanner] '%s' [ state %d ]  [line %d] no match\n",
				 //       yytext, YY_START, yyLineNr);

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

    QFileInfo fi(fileName);
    g_moduleScope = findPackageScope(fileName);
    QCString baseName=fi.baseName().utf8();
g_moduleScope+=baseName;

    current            = new Entry;
    initEntry();
    current->name      = g_moduleScope;
    current->section   = Entry::NAMESPACE_SEC;
    current->type      = "namespace";
    current->fileName  = yyFileName;
    current->startLine = yyLineNr;
    current->bodyLine  = yyLineNr;

    rt->addSubEntry(current);

    current_root  = current ;
    initParser();
    current       = new Entry;

    groupEnterFile(yyFileName,yyLineNr);
    
    current->reset();
    initEntry();
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
  printlex(yy_flex_debug, FALSE, __FILE__, fileName);

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


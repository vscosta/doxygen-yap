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
  static Entry*		current_group = 0 ;
  static Entry*		g_root = 0 ;
  static Entry*		current_predicate = 0 ;
  static Entry*		current      = 0 ;
  static Entry*		previous     = 0 ;
  static Entry*		bodyEntry    = 0 ;
  static int		yyLineCms     = 0 ;
  static int		yyLineNo     = 0 ;
  static QCString		yyFileName;
  static Entry   	       *current_module = 0;
  static Entry   	       *current_clause = 0;
  static MethodTypes 	mtype;
  static bool    		gstat;
  static Specifier 	virt;

  static int              savedDocBlockOuter;
  static int              savedDocBlockInner;
  static QCString         docBlock;
  static QCString         docBlockName;
  static bool             docBlockInBody;
  static bool             docBlockJavaStyle;
  static bool             docBrief;

  static bool             g_specialBlock;
  static bool             g_grammar;

  static QDict<QCString>  g_packageNameCache(257);
  static QDict<QCString>  g_functionNameCache(257);

  QDict<QCString>  g_predNameStore(257);
  static QDict<Entry>     g_predNameCache(257);
  static QDict<Entry>     g_moduleNameCache(257);
  static QDict<Entry>     g_varNameCache(257);
  static QDict<QCString>  g_exportNameCache(257);
  static QDict<QCString>  g_foreignCache(257);

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
  static Entry *     g_call = 0;
  static Entry *     g_callStore = 0;

  static unsigned int     g_argLevel = 0;

  QStack<unsigned int> g_arityStack;

  static Entry *newModule(const char *modname, Protection prot);

  static bool				g_headDone;


  static void parseMain(const char *fileName,const char *fileBuf,Entry *rt);

  static void fillArgs();

#define DEBUG_ALL 1

#if DEBUG_ALL
  void      
    showScannerTree(uint off, Entry *current);
  static void
    showScannerNode( uint off, Entry *current, bool show );
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

  Entry *	
    normalizePredName(Entry *e, uint arity, Entry * curModule )
  {
    QCString rc = e->name;

    if (rc.isNull())
      return 0;
   // keep the arity separate
    int j;
    QCString tmp;
    uint l = rc.length();
    if ((j = rc.findRev("//", l , TRUE)) >= 0) {
      int n = (rc.mid(j+1, l ).toInt())+2;
      tmp = tmp.setNum(n);
      tmp = tmp.prepend("/");
      rc.truncate( j );
    } else if ((j = rc.findRev('/', l , TRUE)) >= 0) {
      tmp = rc.mid(j, l );
      rc.truncate( j );
    } else if (g_grammar) {
     j = rc.length();
      tmp.setNum( arity+2 );
      tmp = tmp.prepend( "/" );
     } else {
      j = rc.length();
      tmp.setNum( arity );
      tmp = tmp.prepend( "/" );
    }
    // right now, tmp has the arity and rc the name
    if (!curModule)
      curModule = newModule("user", Public);
    rc = rc.stripWhiteSpace();
    if (rc.data()[0] == '(' && rc.data()[j-1] == ')') {
	rc = rc.remove(j-1,1);
	rc = rc.remove(0,1);
        j -= 2;
    }
    if (rc.data()[0] == '\'' && rc.data()[j-1] == '\'') {
	rc = rc.remove(j-1,1);
	rc = rc.remove(0,1);
        j -= 2;
    }
    int i;
    if (!strcmp(rc.data(), "=:=")) {
      i = 0;
    } else if (!strcmp(rc.data(), "::")) {
      i = 0;
    } else if ((i = rc.findRev("::", j, TRUE)) > 0 ) {
      if (i > 0) {
	QCString s = rc.left(i);
	curModule = newModule(s.data(), Private);      }
      i += 2;
    } else if ((i = rc.findRev(":", j, TRUE)) > 0 ) {
      QCString s = rc.left(i);
      i += 1;
      curModule = newModule(s.data(), Private);
    } else
      i = 0;
    rc = rc.mid(i,j-i);
    j -= i;
    if (rc.findRev("=:=", 0, TRUE) == 0 ||
	rc.findRev("::", 0, TRUE) == 0) {
      curModule = newModule("prolog", Public) ;
    }
    rc = rc.append(tmp.data());
    e->name = rc.data();
    rc = rc.prepend("::");
    rc = rc.prepend(curModule->name);
    QCString *import;
    while ( (import = g_exportNameCache.find(rc) ) ) {
      // follow import chain
      int i = import->find( "::" );
      rc = import->right(i+2);
      curModule = newModule(import->left(i).data(), Public);
      j = rc.findRev("/");
      // set j appropriately
    }
    QCString store = rc.mid(0,j);
    const QCString *nrc;
    
    if (!g_predNameStore.find(store.data())) {
      nrc =  new QCString(rc.data()) ;
      
      g_predNameStore.insert(store.data(), nrc);
    }

    return curModule;
  }

 static void initParser( void )
  {
    protection = Private;
    mtype = Method;
    gstat = FALSE;
    virt = Normal;
    previous = 0;
    g_packageCommentAllowed = TRUE;

    g_packageNameCache.setAutoDelete(TRUE);
    g_predNameStore.setAutoDelete(TRUE);  
    g_predNameCache.setAutoDelete(FALSE);  // this is just a cache
    g_moduleNameCache.setAutoDelete(FALSE);  // this is just a cache
    g_varNameCache.setAutoDelete(FALSE); // just another cache
    g_functionNameCache.setAutoDelete(TRUE);
  }

  static void initEntry( Entry * current )
  {
    //current->prolog = TRUE;
    current->protection = protection ;
    current->mtype      = mtype;
    current->virt       = virt;
    current->stat       = gstat;
    current->lang       = SrcLangExt_Prolog; 
    current->argList->clear();
    initGroupInfo(current);
    gstat = FALSE;
  }

  static void newEntry( void )
  {
    //    if (current && current->parent())
    // printf("||%p %s -> %p %s||\n", current->parent(), current->parent()->name.data() , current, current->name.data() /*, current->program.data() */);

    //  else   if (current->section!=Entry::CLASSDOC_SEC)
    if (current->parent() )
      current->parent()->addSubEntry(current);
    current = new Entry ;
    initEntry( current );
  }

  static void foundCall(  )
  {
    if (!g_callStore)
      g_callStore = new Entry;
    g_call = g_callStore;
    Entry *n = g_call;
    
    QCString pname;
    //n->prolog = TRUE;
    n->mtype      = mtype;
    n->virt       = virt;
    n->stat       = gstat;
    n->lang       = SrcLangExt_Prolog; 
    initGroupInfo(n);
    gstat = FALSE;
    n->section = Entry::CLASS_SEC;
    n->argList->clear();
    n->type = "predicate" ;
    n->fileName  = yyFileName;
    n->startLine  = yyLineNo;
    n->name = pname.copy();
    if (!n->name.isEmpty() && n->name.at(0)=='$') // mark as private
      {
	n->protection = protection= Private;
      }
    else 
      {
	n->protection = Private;
      }
    // n->setParent(current);
    //current->addSubEntry(n);	
  }

  static void doneCall( )
  {
    g_call = current;
  }

  static QCString skipToBlanks( QCString & s )
  {
    //    QRegExp rx( regexp );
    if (s.isNull())
      return s;
      QCString rc;
      int ch;
      s = s.stripWhiteSpace();
    if (s.isNull())
      return s;
      while ((ch = s.data()[0]) && !isblank(ch)) {
	rc += ch;
	s.remove(0, 1);
      }
      return rc;
  }

  static void getParameter( QCString s, Argument *arg, Entry *current )
  {
    char *v, *p = s.data();
    int ch;
    if (s.isNull() || s.isEmpty()) {
      arg->type = "term" ;
      arg->name = current->argList->count() ;		
      arg->name.prepend("A");
      current->argList->append(arg);
      return;
    }
    while ((ch = *p) && !isblank((ch)))
      p++;
    QCString r = s.left( p - s.data() ); 
    ch = s.data()[0];
    p = s.data();
    arg->docs += s.data();
    switch (ch ) {
    case '+':
    case '-':
    case '?':
    case ':':
    case '/':
    case '!':
    case '^':
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      arg->attrib = ch;
      arg->name = yytext + 1;
      break;
    default:
      arg->attrib = 0;
      arg->name = p;
    }
    arg->name = arg->name.stripWhiteSpace();
    if (arg->attrib && !arg->name.isNull()) {
      ch = arg->name.data()[0];
      if ((ch >= 'A' && ch <= 'Z') || ch == '_') {
	v = strchr( arg->name.data(), ':');
	if (v) {
	  // got a name and type;
	  // skip :
	  v += 1;
	  arg->type = arg->name.data()+(v - arg->name.data()) ;
	  //arg->name.truncate((v-1) - arg->name.data());
	}
      } else {
	arg->type = arg->name ;
	arg->name = current->argList->count() ;		
	arg->name.prepend("A");
      }
    } else if (arg->attrib) {
      arg->type = "term" ;
      arg->name = current->argList->count() ;		
      arg->name.prepend("A");
    }
    current->argList->append(arg);
  }



  static void foundTerm(  )
  {
  }


  void foundVariable(  )
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
    n ->startLine  = yyLineNo;
    n ->bodyLine  = yyLineNo;
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

  static inline void increaseLine() {
     yyLineNo ++;
  }

  void brk() {printf("broken\n");}

static inline void 
    increaseLines(  )
  {
    //  DBG_CTX((stderr,"yyLineNo=%d\n",yyLineNo));
    for (const char
     *p = yytext; *p; ++p)
      {
	//     if (*p == '\n')
	//      printf("CM yyLineNo=%d\n", yyLineNo);
	if (*p == '\n') {
	  yyLineNo ++;

	}
      }
  }


  static void 
    lineComments(  )
  {
    //  DBG_CTX((stderr,"yyLineNo=%d\n",yyLineNo));
    for (const char
     *p = yytext; *p; ++p)
      {
	//     if (*p == '\n')
	//      printf("CM yyLineNo=%d\n", yyLineNo);
	if (*p == '\n') {
	  yyLineCms ++;
	  yyLineNo ++;

	}
      }
  }

  //-----------------------------------------------------------------

  //-----------------------------------------------------------------
  static void 
    startCommentBlock(bool brief )
  {
    g_specialBlock = true;
    if (brief)
      {
	current->briefFile = yyFileName;
	current->briefLine = yyLineNo;
      }
    else
      {
	current->docFile = yyFileName;
	current->docLine = yyLineNo;
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
    docBlock += s;
  }

  static void linkComment(  ) {
    if ( current->section == Entry::GROUPDOC_SEC ||
      current->section == Entry::FILEDOC_SEC) {
       current->setParent( current_root );
       current_group = current;
       current->protection = Public;
    } else if (current->section == Entry::NAMESPACE_SEC ||
	 current->section == Entry::NAMESPACEDOC_SEC) {
       current->setParent( current_root );
       current->protection = Public;
     /* 	current_group = current; */
    /*   } */
    } else if (current->section == Entry::CLASSDOC_SEC ||
	       current->section == Entry::PREDDOC_SEC ||
	       current->section == Entry::USINGDECL_SEC) {
      current->setParent( predBind(  current, current_module, current->argList->count() ) );
      if (current->section != Entry::USINGDECL_SEC) {
	current->parent()->protection = current->protection = 
	  Public;
      }
    } else if (current->section == Entry::EMPTY_SEC) {
      return;
    } else {
      fprintf( stderr, "Unexpected item type 0x%x in Comment %s at line %d\n", current->section, yyFileName.data(), yyLineNo );
      return;
    }
    
    newEntry(  );
  }

  static void
    handleCommentBlock(const QCString &doc,bool brief)
  {
    //printf("handleCommentBlock(doc=[%s] brief=%d docBlockInBody=%d docBlockJavaStyle=%d\n",
    //	   doc.data(),brief,docBlockInBody,docBlockJavaStyle);

    if (doc.isNull() || doc.isEmpty())
      return;

    docBlockInBody=FALSE;

    if (docBlockInBody && previous && !previous->doc.isEmpty())
      {
	previous->doc=previous->doc =
	  previous->doc=previous->doc.stripWhiteSpace()+"\n\n";
      }

    int position = 0;
    bool needsEntry;
    Entry *commentEntry;
    commentEntry = current; // (docBlockInBody && previous) ? previous : current;
    int lineNr = brief ? commentEntry->briefLine : commentEntry->docLine;
    if (docBlock.at(docBlock.length()-1) != '\n')
      docBlock += "\n";
    while (parseCommentBlock(
			     g_thisParser,
			     commentEntry,
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
	linkComment();
      }
    linkComment();
    g_specialBlock = FALSE;

  }

  static void endOfDef(int correction=0)
  {
    // printf("endOfDef at=%d\n",yyLineNo);
    //printf("endOfDef %s\n", current->name.data());
    if (bodyEntry)
      {
	bodyEntry->endBodyLine = bodyEntry->parent()->endBodyLine = yyLineNo-correction;
	bodyEntry = 0;
      }
    newEntry(  );

    //g_insideConstructor = FALSE;
  }

  static void initSpecialBlock(  )
  {
    docBlockInBody    = FALSE;
    docBlockJavaStyle = FALSE;
    docBrief = TRUE;
    // I don't know what I am;
    docBlock.resize(0);
    g_specialBlock = TRUE;
    startCommentBlock(TRUE);
  }

  static const char *skipSpecialStart( const char *text )
  {
    int i, ch;
    if ( g_slashStarComment ) {
      i = 3;
      do { ch = text[i]; if (!isblank(ch) && ch != '\n' && ch != '*') break; else i++; } while (TRUE );
    } else {
      i = 2;
      do { ch = text[i]; if (!isblank(ch) && ch != '\n' && ch != '%') break; else i++; } while (TRUE );
    }
    return text+i;
  }

  static void initSWIComment( const char *text )
  {
    current->briefLine = yyLineNo;
    current->briefFile = yyFileName;
    g_SWIStyle = TRUE;
    if ( text )  {
      docBlock = "\\defgroup ";
      docBlock += current_module->name.data();
      docBlock += text;
      docBlock += " \n@{ \n";
   }

  }

  static Entry *newModule( QCString modnamep )
  {
    const char *name = modnamep.data();
    return newModule( name, (name[1] == '$' ? Private : Private ) );
  }

  static Entry *newModule( const char *modname, Protection prot )
  {
    Entry * newm;
    if (!modname)
      modname = "user";
    QCString mname = modname;
    if (! strcmp(modname, ":") ) {
      newm = g_moduleNameCache.find(mname); 
      if (prot == Public)
	newm->protection = Public;
      return newm;
    }
    mname = mname.stripWhiteSpace();
    mname = stripQuotes( mname );
    if (!(newm = g_moduleNameCache.find(mname))) {
      // add a new module
      newm  = new Entry;
      initEntry( newm );
      g_moduleNameCache.insert(mname, newm);
      newm->section = Entry::NAMESPACE_SEC;
      newm->type = "module" ;
      newm->fileName  = yyFileName;
      newm->startLine  = yyLineNo;
      newm->bodyLine  = yyLineNo;
      newm->name = mname.copy();
      newm->protection = prot;
      newm->setParent( current_root );
      if (newm != current)
	newm->parent()->addSubEntry(newm);
    } 
    if (prot == Public)
      newm->protection = Public;
    return newm;
  }
			  

  static bool firstClause( Entry * p )
  {
    // search a group decl from initial comment
    EntryListIterator eli(*p->children());
    Entry *ce;
    for (;(ce=eli.current());++eli)
      {
	if (ce->section == Entry::CLAUSE_SEC)
	  return FALSE;
      }
    return TRUE;
  }


  static void searchFoundDef(){
    current->fileName  = yyFileName;
    current->startLine = yyLineNo;
    current->bodyLine  = yyLineNo;
    current->section = Entry::CLAUSE_SEC;
    current->protection = protection;
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
    g_call->argList->clear();
    g_call->bodyLine  = yyLineNo;
  }

  static Entry *
    buildPredEntry(  QCString pname, uint arity, Protection protection, Entry *parent )
  {
    Entry *newp;
   if ( (newp = g_predNameCache.find(pname.data()) ) ) {
     if (parent && !strcmp(parent->name.data() , "prolog") &&
	 newp->parent() != parent ) {
       // Prolog rulez
       newp->parent()->removeSubEntry( newp );
       newp->setParent( parent );
       parent->addSubEntry( newp ); 
     }
     if (protection == Public)
       newp->protection = Public;
     return newp;
   }
   newp = new Entry;
   g_predNameCache.insert(pname, newp);
   initEntry( newp );
   newp->section = Entry::CLASS_SEC;
   newp->type = "predicate" ;
   newp->fileName  = yyFileName;
   newp->startLine  = yyLineNo;
   newp->bodyLine  = yyLineNo;
   newp->name = pname.copy();
   for (uint i=0; i<arity; i++) {
     char buf[16];
    Argument *a = new Argument;
    snprintf( buf, sizeof(buf), "A%u\n", i+1);
    a->name = buf;
    a->type = "Term";
    //current->argList->append(a);
  }
  if (!newp->name.isEmpty() && newp->name.at(0)=='$') // mark as private
    {
      newp->protection = Private;
    }
  else 
    {
      newp->protection = protection;
    }
  newp->setParent( parent );
  if (parent && newp != current)
    newp->parent()->addSubEntry(newp); // the circle of life
  
  return newp;
 }

  Entry  *predBind(Entry *cur, Entry *module, uint arity)
  {
    Entry *parent;
    parent = normalizePredName(cur, arity, module );
    QCString pname = cur->name;
    return buildPredEntry( pname, arity, protection, parent );
  }



  static void newClause(  ) {
    
    Entry *newp = predBind( current, current_module, current->argList->count()  );
    if (firstClause( current )) {
      current->bodyLine = current->endBodyLine = yyLineNo;
      newp->bodyLine = newp->endBodyLine = yyLineNo;
      }
    current->setParent( newp );
    current->protection = newp->protection;
    current_predicate = newp;
    //   size_t i = current->name.findRev( '_', -1 );
    // current->name.truncate( i );
    current_clause = current;
  }

  static void addPredDecl(  )
  {
    Entry *newp = predBind( current, current_module, current->argList->count() );
    current->explicitExternal = true;
    current->setParent( newp );
    current->protection = newp->protection;
    current_predicate = newp;
    docBlockInBody = FALSE;

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


SOLO		  [;!,]

ATOM		   ({IDENTIFIER}|{SQSTRING}|{SYMBOL}|{SOLO})

ATOMIC             ({ATOM}|{VAR}|{NUMBER}|{DQSTRING})


INDICATOR          (({ATOM}":"|"(")?{ATOM}(")")?("/"|"//"){DECNUMBER})

OPDEC		   {IDENTIFIER}"("{BNS}{INTNUMBER}{BNS}","{BNS}{IDENTIFIER}{BNS}","{BNS}("("{BNS})?{ATOM}({BNS}")")?{BNS}")"

META		   {ATOM}"("{BNS}[0-9:?\-+]{BNS}(","{BNS}[0-9:?\-+]{BNS})*{BNS}")"

PATH		   (("/")?{ATOM}("/"{ATOM})*)

LIBRARY		   (({ATOM}"("{BNS}{PATH}{BNS}")")|({PATH}))

FLOWKW             ("spy"|"nospy"|"same"|"block"|"^"|"**"|"\\"|"rem"|"mod"|">>"|"<<"|"//"|"/"|"*"|"xor"|"div"|"rdiv"|"#"|"><"|"\\/"|"/\\"|"-"|"-"|"+"|"+"|":"|"as"|">="|"=<"|">"|"<"|"=\\="|"=:="|"\\=@="|"=@="|"@>="|"@=<"|"@>"|"@<"|"\\=="|"=="|"=.."|"is"|"\\="|"="|"not"|"\\+"|"uncutable"|"table"|"discontiguous"|"module_transparent"|"meta_predicate"|"multifile"|"public"|"mode"|"volatile"|"initialization"|"thread_local"|"dynamic")

STARTSPECIALLINE      ("%"[%!])([ \t]+("\n")?|"\n")
STARTSPECIALSLASHDOT      ("/*"[*!]([ \t]("\n")?|"\n"))

STARTSPECIAL           ({STARTSPECIALLINE}|{STARTSPECIALSLASHDOT})


PERCCOMMENT      ("%"([%!][^ \n\t]|[^%!])[^\n]*\n)


CMD      ("\\"|"@")[A-Za-z0-9_]*

SLASHSTARSTARTCOMMENT "/*"([^\*\!]|"*"[^ \t\n]|"!"[^ \t\n])
SLASHSTAREMPTYCOMMENT "/*/"
SLASHSTARENDCOMMENT   "*/"

PREDTAG               ("det"|"semidet"|"failure"|"nondet"|"multi"|"iso"|"deprecated"|"dynamic"|"directive"|"meta")

PARAMETERDESCRIPTOR   ([+\-?:@!]?{BNS}(({VAR}":"{IDENTIFIER})|{VAR}|{IDENTIFIER}|({BNS}"."+{BNS})+)){BNS}

        /* [+\-?:@!]?{VAR}{BNS}(":"{BNS}{IDENTIFIER})?{BNS} */
VARPARAMETERDESCRIPTOR   [+\-?:@!]?{VAR}{BNS}(":"{BNS}{IDENTIFIER})?{BNS}

PREDINFO              (".")?({BB}"is"{BB}{PREDTAG}({B}","{BB}{PREDTAG})*)?{B}

COMPOUND	      {ATOM}"("

%option noyywrap
%option nounput
%option yyLineNo			    

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

			    /* import */
%x Directive
%x ImportList
%x ExportList
%x Import
%x Metas

%x DocBlockShortMsg

%%

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


  {SLASHSTARSTARTCOMMENT}    { // normal comment 
    savedDocBlockOuter = YY_START;
    increaseLines( );
    g_packageCommentAllowed = FALSE;
    BEGIN(SkipComment);
  }
 

  {NEWLINE}   {
      increaseLine( );
}

 
  ({ATOM}":")?{COMPOUND}{B}	{
    // must be start of a function/clause definition
    increaseLines( );
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
    g_argLevel = 1;
    g_callLevel = 0;
    g_defVal = "";
    g_headDone = FALSE;
    g_call = current;
    BEGIN( FunctionParams );
  }      


  ({NUMBER}|{VAR})"::"{COMPOUND}{B}     {
    // must be start of a function/clause definition
    increaseLines( );
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
    g_argLevel = 1;
    g_callLevel = 0;
    g_defVal = "";
    g_headDone = FALSE;
    g_call = current;
    BEGIN( FunctionParams );
  }      



  ({ATOM}":")?{ATOM}{B}":-"  {

    {
      current->type = "method";
    }
    increaseLines( );
    g_callLevel = 0;
    current->program = yytext;
    current->name = QCString( yytext );
    current->name.remove(current->name.length()-2,2);
    current->name = current->name.stripWhiteSpace();
    newClause(  );
    g_defVal = "";
    g_headDone = TRUE;
    current->bodyLine  = yyLineNo;
    BEGIN( FunctionBody ); 
  }

  ({ATOM}":")?{ATOM}{B}"-->"  {

    {
      current->type = "method";
    }
    g_callLevel = 0;
    g_grammar = TRUE;
    current->program = yytext;
    current->name = QCString( yytext );
    current->name.remove(current->name.length()-2,2);
    current->name = current->name.stripWhiteSpace();
    newClause(  );
    g_defVal = "";
    g_headDone = TRUE;
    current->bodyLine  = yyLineNo;
    increaseLines( );
    BEGIN( FunctionBody ); 
  }

  ({ATOM}":")?{ATOM}  {
    //found function name, but no arity
    {
      current->type = "method";
    }
    increaseLines( );
    current->program = yytext;
    current->name = QCString( yytext );
    current->name = current->name.stripWhiteSpace();
    current_clause = current;
    g_callLevel = 0;
    g_defVal = "";
    g_headDone = TRUE;
    BEGIN( HeadOperator );
  }

 ({NUMBER}|{VAR})"::"{ATOM}  {
    //found function name, but no arity
    {
      current->type = "method";
    }
    increaseLines( );
    current->program = yytext;
    QCString s = yytext;
    s = s.stripWhiteSpace();
    int i = s.find("::");
    s=s.remove(0,i+2);
    current->name = s;
    current_clause = current;
    g_callLevel = 0;
    g_defVal = "";
    g_headDone = TRUE;
    BEGIN( HeadOperator );
 }

  {EOT}         {
    g_grammar = FALSE;
  }

 
{STARTSPECIAL}({ATOM}":")?{ATOM}"("{B}	{
  increaseLines( );
  lineComments();
  current->section = Entry::CLASSDOC_SEC;
  g_packageCommentAllowed = TRUE;
  g_slashStarComment = ( yytext[0] == '/' && yytext[1] == '*' );
  initSpecialBlock(  );
  const char *s = skipSpecialStart( yytext );
  savedDocBlockOuter = YY_START;
  initSWIComment( 0 );
  current->program = s;
  current->name = s;
  current->name =
    current->name.stripWhiteSpace();
  uint l = current->name.length();
  current->name.truncate(l-1);
  g_argLevel = 1;
  if (g_slashStarComment)
    savedDocBlockInner = SWISpecialComment;
  else
    savedDocBlockInner = SWISpecialLineComment ;
  BEGIN( ExtraCommentArgs );
					}

{STARTSPECIAL}({ATOM}":")?{ATOM}[. \t]{B}	{
  increaseLines( );
  lineComments();
  g_packageCommentAllowed = TRUE;
  g_slashStarComment = ( yytext[0] == '/' && yytext[1] == '*' );
  initSpecialBlock(  );
  const char *s = skipSpecialStart( yytext );
  initSWIComment( 0 );
  current->name = current->program = s;
  current->name =
    current->name.stripWhiteSpace();
  uint l = current->name.length();
  if (current->name.data()[l-1] == '.')
    current->name.truncate(l-1);
  current->setParent(predBind(current, current_module, 0));
  current->name = current->parent()->name.copy();
  if (current->briefLine == yyLineNo) {
    addPredDecl( );
  }
  if (current->briefLine < yyLineNo) {
    current->briefLine = yyLineNo;
  }
  current->section = Entry::CLASSDOC_SEC;
  addToDocBlock( " \\brief <b>" );
  addToDocBlock( current->program );
  addToDocBlock( "</b> " );
  savedDocBlockOuter = YY_START;
 if (g_slashStarComment)
    BEGIN( SWISpecialComment );
  else
    BEGIN( SWISpecialLineComment );

		      }


  {STARTSPECIAL}	{
  g_slashStarComment = ( yytext[0] == '/' && yytext[1] == '*' );
  savedDocBlockOuter = YY_START;
  increaseLines( );
  g_packageCommentAllowed = TRUE;
  initSpecialBlock(  );
  if ( g_SWIStyle) {
    initSWIComment( 0 );
    if (g_slashStarComment)
      BEGIN( SWISpecialComment );
    else
      BEGIN( SWISpecialLineComment );
  } else {
    if (g_slashStarComment)
      BEGIN( SpecialComment );
    else
      BEGIN( SpecialLineComment );
  }
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
    current->bodyLine  = yyLineNo;
    BEGIN( FunctionBody ); 
  }

  {B}"-->"    {
    if (!g_headDone) {
      current->name = QCString( "op" );
      g_headDone= TRUE;
    }
    g_grammar = TRUE;
    current->program+=yytext;
    current->bodyLine  = yyLineNo;
    BEGIN( FunctionBody ); 
  }

  {B}{EOT}         {
     increaseLines( );
   // facts
    current->program+=yytext;

    //printf("\nDONE\n %s \n*******\n", current->program.data());
    endOfDef();
    BEGIN(Search);

  }

  \n       {
    increaseLine( );
   current->program+=yytext;
  }

  [^\n]       {
    current->program+=yytext;
    g_defVal += yytext;

  }
 }


<FunctionParams>{

  {COMPOUND}{B}	{
    increaseLines( );
    current->program += yytext;
    g_argLevel++;
    g_defVal += yytext;
  }

  {ATOM} { //
    increaseLines( );
   g_defVal += yytext;
    current->program+=yytext;
  }

  {VAR}|{NUMBER} { //
    increaseLines( );
    g_defVal += yytext;
    current->program+=yytext;
  }

  ","|"|"        {
    current->program+=yytext;
    if (g_argLevel == 1) {
      Argument *a = new Argument;

      a->name = g_defVal.copy().stripWhiteSpace();
      a->type = "Term";
      a->docs = "";
      g_call->argList->append(a);
      g_defVal = "";
    }
}

 \n       {
     increaseLine( );
    current->program+=yytext;
  }

  "("|"["|"{" {
    current->program+=yytext;
    g_argLevel++;
  }

  "]"|"}" {
    current->program+=yytext;
    if (--g_argLevel == 0) {
      if (g_callLevel) {
	foundTerm();
	BEGIN( FunctionBody );
      } else
	if (g_headDone) {
	  BEGIN( FunctionBody );
	} else {
	  g_headDone = TRUE;
	  BEGIN( HeadOperator );
	}
    }
  }

  ")"   { // end of parameter list
    current->program+=yytext;
    if (--g_argLevel== 0) {
      //unsigned int arity = g_call->argList->count();
      Argument *a = new Argument;

      a->name = g_defVal.copy().stripWhiteSpace();
      a->type = "Term";
      a->docs = "";
      g_call->argList->append(a);
      g_defVal = "";
      if (g_callLevel) {
	foundTerm();
	BEGIN( FunctionBody );
      } else
	if (g_headDone) {
          newFunction();
	  BEGIN( FunctionBody );
	} else {
	  newClause(  );
	  g_headDone = TRUE;
	  BEGIN( HeadOperator );
	}

    }
    
  }
 }



<FunctionBody>{

  {EOT}         {
     increaseLines( );
    // end of a rule
    if (current) {
      current->program+=yytext;
      if (current->section == Entry::CLAUSE_SEC) {
	endOfDef();
      }	
      BEGIN(Search);
    }
  }

  <<EOF>>         {
    // end of a rule
    if (current->section == Entry::CLAUSE_SEC) {
      endOfDef();
    }	
    if (g_SWIStyle) {
     initSpecialBlock();
     char s[] = "@}\n";
     savedDocBlockOuter = YY_START;
     initSWIComment( 0 );
     current->program = s;
     current->name = s;
     current->name =
       current->name.stripWhiteSpace();
     uint l = current->name.length();
     current->name.truncate(l-1);
     docBlock += " \n@} \n";
     handleCommentBlock(docBlock, docBrief);
    }
    yyterminate();
  }

  {BB}(^{BB}\n)*	      {   // skip spaces
     increaseLines( );
    current->program+=yytext;
  }

  {BB}*(","|";"|"->"|"->*"){BB}* { //
    current->program+=yytext;
    // printf( "%p %d %s\n",current, g_headDone,current->program.data());
  }

   ({ATOM}":")?{ATOM}"(" { // call
     increaseLines( );
    current->program+=yytext;
    ++g_argLevel;
    g_pName = yytext;
    g_pName.truncate(g_pName.length()-1);
    foundCall(  );
    BEGIN( FunctionParams );
  }

  ({ATOM}":")?{ATOM} { // call
     increaseLines( );
    g_pName = yytext;
    foundCall(  );
    if (strcmp(yytext, "=:=")) 
      doneCall();
    current->program+=yytext;
  }

  "[" {
    current->program+=yytext;
    g_argLevel ++;
    BEGIN( FunctionParams);
  }

   ("("|"{") { //
    current->program+=yytext;
    if (g_argLevel)
      g_argLevel++;
    else
      g_callLevel++;
  }

 (")"|"}") { 
    //
    current->program+=yytext;
    if (g_argLevel) {
      g_argLevel--;
      if (!g_argLevel)
        doneCall();
   } else
      g_callLevel--;
  }

 \n       {
   increaseLine( );
   current->program+=yytext;
  }

 }	


<Directive>{
  ("system_")?"module("{B}{ATOM}{B}"," { // define module  ATOM 
    increaseLines( );
    QCString modn = strrchr( yytext, '(')+1;
    modn = modn.remove(modn.length()-1,1);
    modn = modn.stripWhiteSpace();
    g_packageName=modn;
    if (yytext[0] == 's') 
      current_module = newModule("prolog", Public);
    else
      current_module = newModule(modn.data(), Public);
    BEGIN(ExportList);
  }

  "multifile("{B} { // define module  ATOM 
    BEGIN(ExportList);
  }

  "multifile"{B} { // define module  ATOM 
    BEGIN(ExportList);
  }

  "meta_predicate"{B} { // define module  ATOM 
    BEGIN(Metas);
  }

  "use_module("{B}{LIBRARY}{B}")"{B}{EOT} {
    increaseLines( );
    g_packageName=yytext;
    QCString item=g_packageName;
    item = removeRedundantWhiteSpace(sliceArgument(item.data(), ')' ));
    if (item.find("library(") == 0) item = item.mid(8,item.length()-9).stripWhiteSpace();
    current->name = item;
    current->setParent( newModule( current->name ) );
    current->section=Entry::USINGDECL_SEC;
    BEGIN(Search);
  }


  ("use_module("|"reexport("){B}{LIBRARY}{B}","{B} {
    increaseLines( );
    g_packageName=yytext;
    QCString item=g_packageName;
    item = removeRedundantWhiteSpace(sliceArgument(item.data(), ',' ));
    if (item.find("library(") == 0) item = item.mid(8,item.length()-9).stripWhiteSpace();
    current->name = item;
    current->setParent( newModule( current->name ) );
    current->section=Entry::USINGDECL_SEC;
    BEGIN(Search);
  }

  ("system_")?"module("{B}{ATOM}{B}"," { // define module  ATOM 
    increaseLines( );
    QCString modn = strrchr( yytext, '(')+1;
    modn = modn.remove(modn.length()-1,1);
    modn = modn.stripWhiteSpace();
    g_packageName=modn;
    if (yytext[0] == '$') {
      // newModule(modn.data(), Private);
      current_module = newModule("prolog", Public);
    } else
      current_module = newModule(modn.data(), Public);
    BEGIN(ExportList);
  }

 "foreign_predicate( "{ATOM}":"{INDICATOR}" , "{ATOM}" , "{ATOM}" , "{NUMBER}" )"{EOT} {
    increaseLines( );
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
    int line=pname.mid(comma2+3, end-(comma2+3)).toInt();
    current->reset();
    current->name = predName;
    current->fileName = fileName; 
    current->section=Entry::USINGDECL_SEC;
    current->startLine = line;
    current->bodyLine  = line;
    current->artificial  = true;
    Entry *p = current;
    uint arity = predName.left(slash-(colomn+1)).toUInt();
    current->setParent( predBind( current, newModule( modName.data(), Public), arity ) );
    newEntry(); 
    current->reset();
    current->setParent( p );
    current->name = funcName;
    current->fileName = fileName; 
    current->section=Entry::FUNCTION_SEC;
    current->startLine = line;
    current->bodyLine  = line;
    current->protection = Public;

    newEntry(); 
    BEGIN(Search);
  }

  "export( "{ATOM}":"{INDICATOR}" , "{ATOM}":"{INDICATOR}" )." {
    increaseLines( );
    QCString pname=yytext;
    pname = pname.stripWhiteSpace();
    pname = pname.remove(0, strlen("export("));
    pname = pname.stripWhiteSpace();
    int comma = pname.find(":");
    int comma2 = pname.find(" , ", comma);
    int colomn = pname.find(":", comma2);
    QCString target = pname.left(comma) + "::" + pname.mid(comma+1, comma2-(comma+1) );
    QCString s = pname.mid(comma2+3,colomn-(comma2+3)) + "::" + pname.right(colomn+1);
    QCString* src = new QCString( s );
    g_exportNameCache.insert( target, src );
    BEGIN(Search);
  }


  "use_system_module("{B}{LIBRARY}{B}","{B} {
    increaseLines( );
    g_packageName=yytext;
    QCString item=g_packageName;
    current->name =removeRedundantWhiteSpace(sliceArgument(item.data(), ',' ));
    current->setParent( newModule( current->name ) );
    current->section=Entry::USINGDECL_SEC;
    BEGIN(ImportList);

  }

  \n		      {
     increaseLine( );
 }
	
  {EOT}	      {
    increaseLines( );
    BEGIN(Search);
  }
	
  [^\n]		      {
  }

 }

<Metas>{

  {META} {
  }

  \n		      {
     increaseLine( );
 }
	
  ("("|")"|",") {
  }

  {EOT} {
    BEGIN(Search);   
      increaseLines( );
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
      current_root->removeSubEntry(current);
      current_root->addSubEntry(current);
      current->startLine = yyLineNo;
      current->bodyLine  = yyLineNo;
      current = new Entry ;
      initEntry(current);
    */
    if (g_argLevel > 0) exit(1);
  }

  {INDICATOR}  {
     increaseLines( );
   /* current->name=yytext;
       current->name = current->name.stripWhiteSpace();
       current->fileName = yyFileName; 
       current->section=Entry::USINGDECL_SEC;
       current_root->addSubEntry(current);
       current->startLine = yyLineNo;
       current->bodyLine  = yyLineNo;
       newEntry(); */
  }

  \n		{
  }

  {OPDEC}  {
      increaseLines( );
}

  {B}")"{B}{EOT}		{
    increaseLines( );
    g_grammar = FALSE;
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
      QCString pname = yytext;
      current->reset();
      current->name = pname.simplifyWhiteSpace();
      current->fileName = yyFileName; 
      current->section=Entry::USINGDECL_SEC;
      current->startLine = yyLineNo;
      current->bodyLine  = yyLineNo;
      uint arity = pname.left(pname.findRev('/')+1).toUInt();
      Entry *p = predBind( current, current_module, arity );
      p->protection = current->protection;
      current->setParent( p );
  }


  {OPDEC}  {
     increaseLines( );
 }

  \n		{
     increaseLine( );
 }
	
  {B}")"{EOT}		{
    increaseLines( );

    BEGIN(Search);
  }

  {B}{EOT}		{
    increaseLines( );
    g_grammar = FALSE;
    BEGIN(Search);
  }

 }

<SkipComment>{
  \n					{  lineComments();  }

  "*"+/[^/]	{ 
  }

  "*/"		{ BEGIN(savedDocBlockOuter);
  }

  [^*\n]+ {
  }

  . {
  }

 }

<SWISpecialComment,SpecialComment,SWISpecialLineComment,SpecialLineComment>{

  ("@module"|"<module>")[^\n]+	{
  g_packageCommentAllowed = TRUE;
  initSpecialBlock( );
  if (yytext[0] == '@')
    initSWIComment(  yytext + 7 );
  else
    initSWIComment(  yytext + 8 );
 if (g_slashStarComment)
    BEGIN( SWISpecialComment );
  else
    BEGIN( SWISpecialLineComment );
				}

  "\n~~~"		{
    increaseLine( );
    addToDocBlock( yytext );
    savedDocBlockInner   = YY_START; // enter Inline
    BEGIN(Inline);
  }



  {B}{VAR}|{NUMBER} { //
    addToDocBlock( yytext );
  }


  {B}("@"|"\\")"pred"{B}({ATOM}":")?{ATOM}"("{B}	{
    increaseLines( );
     g_argLevel = 1;
    current->name = strstr(yytext, "pred")+4;
    current->name = current->name.stripWhiteSpace();
    current->program = current->name;
    uint l = current->name.length();
    current->name.remove( l-1, 1 );
    current->section = Entry::CLASSDOC_SEC;
    current->argList->clear();
    addToDocBlock( yytext );
    savedDocBlockInner   = YY_START; // enter Inline
    if ( g_SWIStyle) {
      initSWIComment( 0 );
    }
    BEGIN( ExtraCommentArgs );
					}

  {B}("@"|"\\")"pred"{B}({ATOM}":")?{ATOM}(". ")?{PREDINFO}/{BN}	{
     increaseLines( );
     current->name = strstr(yytext, "pred")+4;
     current->name = current->name.stripWhiteSpace();
    current->name = skipToBlanks( current->name );
     uint l = current->name.length();
     if (current->name.data()[l-1] == '.')
       current->name.truncate( l-1 );
     QCString q = current->name.copy();
     current->setParent(predBind(current, current_module, 0));
     current->section = Entry::CLASSDOC_SEC;
     current->name = current->parent()->name.copy();
     current->protection = current->parent()->protection = Public;
     addPredDecl(  );
     initSpecialBlock( );
     addToDocBlock( " \\brief <b>" );
     addToDocBlock( q.data());
     addToDocBlock( "</b> " );

					}

  {B}("@"|"\\")"pred"{B}{ATOM}{B}{VARPARAMETERDESCRIPTOR}{PREDINFO}/{BN} {
    // prefix operator 
   current->program = yytext;
    increaseLines( );

    QCString s = yytext+5;
    current->name = skipToBlanks(  s );
    Argument *arg = new Argument;
    QCString s1 = skipToBlanks(  s );
    getParameter( s1, arg, current );
     current->setParent(predBind(current, current_module, 1));
     current->section = Entry::CLASSDOC_SEC;
     current->protection = current->parent()->protection = Public;
     addPredDecl(  );
     initSpecialBlock( );
     addToDocBlock( " \\brief <b>" );
     addToDocBlock( yytext );
     addToDocBlock( "</b> " );
    
    
    }

   {B}("@"|"\\")"pred"{B}{VARPARAMETERDESCRIPTOR}{B}{ATOM}{PREDINFO}/{BN} {
    // posfix operator 
   current->program += yytext;
    increaseLines( );

    QCString s = strstr(yytext, "pred")+4;
    s = current->name.stripWhiteSpace();
    Argument *arg = new Argument;
    QCString s1 = skipToBlanks( s  );
    getParameter( s1, arg, current );
    current->name = skipToBlanks(  s );    
     current->setParent(predBind(current, current_module, 2));
     current->section = Entry::CLASSDOC_SEC;
     current->protection = current->parent()->protection = Public;
     addPredDecl(  );
     initSpecialBlock( );
     addToDocBlock( " \\brief <b>" );
     addToDocBlock( yytext );
     addToDocBlock( "</b> " );
    
    }

   {B}("@"|"\\")"pred"{B}{VARPARAMETERDESCRIPTOR}{B}{ATOM}{B}{VARPARAMETERDESCRIPTOR}{PREDINFO}/{BN} {
    // infix operator 
   current->program += yytext;
    increaseLines( );

    QCString s = strstr(yytext, "pred")+4;
    s = s.stripWhiteSpace();
    Argument *arg1 = new Argument;
    QCString s1 = skipToBlanks(  s );
    getParameter( s1, arg1, current );
    current->name = skipToBlanks(  s  );
    QCString s2 = skipToBlanks(  s );
    Argument *arg2 = new Argument;
    getParameter( s2, arg2, current );
     current->setParent(predBind(current, current_module, 1));
     current->section = Entry::CLASSDOC_SEC;
     current->protection = current->parent()->protection = Public;
     addPredDecl(  );
     initSpecialBlock( );
     addToDocBlock( " \\brief <b>" );
     addToDocBlock( yytext );
     addToDocBlock( "</b> " );
    }

  {B}*{CMD}{B}*        {
    increaseLines( );
    addToDocBlock( yytext );
  }

 }

<SWISpecialComment,SWISpecialLineComment>{
  "=|"  {
    addToDocBlock( "`" );
    savedDocBlockInner   = YY_START;
    BEGIN( SWIQuoted );
  }

  "\n---+ " {
    addToDocBlock( "## " );
  }

  "\n---++ " {
    addToDocBlock( "### " );
  }

  "\n---+++ " {
    addToDocBlock( "#### " );
  }

  "\n---++++ " {
    addToDocBlock( "##### " );
  }

  "\n==\n" {
    addToDocBlock( "~~~~" );
  }

 "*|"  {
   addToDocBlock("*" );
    savedDocBlockInner   = YY_START;
    BEGIN( SWIBold );
  }

 "="[a-zA-Z0-9]([a-zA-Z0-9:/_.]*[a-zA-Z0-9])?("=")? {
   if (yytext[strlen(yytext)-1] == '=')
     yytext[strlen(yytext)-1] = '\0';
   addToDocBlock( "<code>" );
   addToDocBlock( yytext+1 );
   addToDocBlock( "</code>" );
 }

  {SQSTRING} {
    increaseLines( );
    addToDocBlock( yytext );
  }

  "\n==\n"		{
     increaseLine( );
    increaseLine( );
   addToDocBlock( "~~~~~~~~~~{.prolog}\n" );
    savedDocBlockInner   = YY_START;
    BEGIN(SWIInline);

  }


 }

<SWISpecialComment,SpecialComment>{
  [^*\n]     { addToDocBlock( yytext ); } 
  
  "*"/[^/]    { addToDocBlock( yytext ); }

  "\n"        {     increaseLines( );
    addToDocBlock( yytext ); }

  "\n"/{B}("*")?{B}\n        {  // empty line
    increaseLines( );
    docBlock+='\n';
    docBrief = FALSE;
    startCommentBlock( FALSE );
  }

  ^{B}"*"/{BB} {  }

  "*/"		{
    handleCommentBlock(docBlock, docBrief);
    BEGIN( savedDocBlockOuter );
  }
 }

<SWISpecialLineComment,SpecialLineComment>{

  \n{B}("%")+/[ \t]     { docBlock+='\n'; } 

  \n{B}("%")+{B}/"\n"   { // empty line
     increaseLines( );
     if (!docBlock.isEmpty()) {
       docBlock+='\n';
       if (docBrief) {
	 docBrief = FALSE;
	 startCommentBlock( FALSE );
       }
     }
  }
  

  [^\n]     { addToDocBlock( yytext ); } 
  
  "\n" {  
     increaseLine( );
     handleCommentBlock(docBlock, docBrief);
     BEGIN(savedDocBlockOuter); }
 }


<SWIQuoted>{
  [^|\n]*     { addToDocBlock( yytext ); }   
  "|"+[^=]*   { addToDocBlock( yytext ); }
  "\n"        { addToDocBlock( yytext );     increaseLine( ); }
  "|="       {  addToDocBlock( "`" ); BEGIN(savedDocBlockInner); }

 }

<SWIBold>{
  [^|\n]*     { addToDocBlock( yytext ); }   
  "|"+[^*]*   { addToDocBlock( yytext ); }
  "\n"        { addToDocBlock( yytext );     increaseLine( ); }
  "|*"       {  addToDocBlock( "</b>" ); BEGIN(savedDocBlockInner); }

 }

<SWIInline>{
  "\n==\n"       {  addToDocBlock( "~~~~~~~~~~\n" );    increaseLines( ); BEGIN(savedDocBlockInner); }
  [^\n]+      { addToDocBlock( yytext ); }   

 }

<Inline>{
  "~~~"("~")*"\n"       { 
    increaseLine( );
    addToDocBlock( yytext ); 
    BEGIN(savedDocBlockInner);
  }
  [^\n]+       { addToDocBlock( yytext ); }   

  \n           { addToDocBlock( yytext );    increaseLine( );
 }
 }

<ExtraCommentArgs>{

  {PARAMETERDESCRIPTOR} {
    current->program += yytext;
    increaseLines( );

    Argument *arg = new Argument;
    getParameter( yytext, arg, current );
  }

  {ATOMIC} {
     increaseLines( );
   current->program += yytext;
  }

  ("("|"["|"{") {
    current->program += yytext;
    g_argLevel++;
  }

  ("]"|"}") {
    current->program += yytext;
    g_argLevel--;
  }

  ")"{PREDINFO}/{BN} {
     increaseLines( );
     current->program += yytext;
     if (--g_argLevel == 0) {

       if (current->name.isNull())
	 current->name = "op";
       current->setParent(predBind(current, current_module, current->argList->count()));
       current->protection = current->parent()->protection = Public;
       current->name = current->parent()->name.copy();
       fillArgs();
       initSpecialBlock( );
       if (current->briefLine == yyLineNo) {
	 addPredDecl( );
       }
       if (current->briefLine < yyLineNo) {
	 current->briefLine = yyLineNo;
       }
       addToDocBlock( "\\brief <b>" );
       addToDocBlock( current->program.data());
       addToDocBlock( "</b> " );
       BEGIN(savedDocBlockInner);
     } else {
       g_argLevel--;
     }
  }

  {NEWLINE} {
    // terminate after a nl
    increaseLine( );
    current->program += yytext;
  } 
	
  [^\n] {
    // just in case the user wrote strange stuff.
    current->program += yytext;
  } 
	
  {B}","{B} {
    current->program += yytext;
  }

  }
                                        /* ------------ Default rules -------------- */

<*>{UONLY} {
  if (    g_specialBlock  ) {
    addToDocBlock( yytext );
  } else if (current) {
    current->program+=yytext;
    g_defVal += yytext;
  }
   }

<FunctionParams,FunctionBody,TakeList>{ATOMIC}	{ 
    increaseLines( );
  if (current) {
    current->program+=yytext;
    g_defVal += yytext;
  }
 }    	  

<Search,FunctionParams,FunctionDec,FunctionBody,CallArgs,HeadOperator,Directive,ImportList,ExportList,Import>{PERCCOMMENT} {
  lineComments();			    
}

<Search,FunctionParams,HeadOperator,TakeList,Directive,ImportList,ExportList,SkipComment,ExtraCommentArgs,SpecialComment><<EOF>>	      {
  yyterminate();
 }

<Search,FunctionParams,FunctionBody,HeadOperator,TakeList,Directive,ImportList,ExportList>{BB}	      {   // skip spaces quickly
  if (current) {
    current->program+=yytext;
    g_defVal += yytext;
  }
 }

<*>[\x00]/([^\n]|"\n") { /* yes, it happens */ }

%%


											     //----------------------------------------------------------------------------

   static void fillArgs()
   {
     return;
    ArgumentListIterator ali(*current->argList);
    Argument *a;
    addToDocBlock( "\\n" );
    for (ali.toFirst();(a=ali.current());++ali)
      {
	QCString attb = a->attrib;
	int attc;

	if (!attb.isNull()) {
      attc = attb.data()[0];
	switch (attc) {
	case '+':
	  addToDocBlock( "\\param[in] " );
	break;
	case '-':
	  addToDocBlock( "\\param[out] " );
	break;
	case '?':
	  addToDocBlock( "\\param[in,out] " );
	break;
	case ':':
	case '/':
	case '!':
	case '^':
	case '0':
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	case '8':
	case '9':
	  addToDocBlock( "\\param meta " );
	  char s[3];
	  s[0] = attc;
	  s[1] = ' ';
	  s[2] = '\0';
	  addToDocBlock( s );
	  break;
	default:
	  addToDocBlock( "\\param " );
	}
	} else {
	  addToDocBlock( "\\param " );
	}
	addToDocBlock( a->name.data() );
	addToDocBlock( " " );
	if (!a->type.isEmpty()) {
	  addToDocBlock( "of type `" );
	  addToDocBlock( a->type.data() );
	  addToDocBlock( "`\n" );
	} else
	  addToDocBlock( "\n" );
      }
    addToDocBlock( "\n" );
   }

static void parsePrototype(const QCString &text)
{
  //printf("**** parsePrototype(%s) begin\n",text.data());
  if (text.isEmpty()) 
    {
      warn(yyFileName,yyLineNo,"Empty prototype found!");
      return;
    }

  g_specialBlock = FALSE;
  g_packageCommentAllowed = FALSE;

  const char *orgInputString;
  int orgInputPosition;
  YY_BUFFER_STATE orgState;
  
  // save scanner state<
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
    s = "CLASS_SEC";
    break;
  case Entry::NAMESPACE_SEC:
    s = "NAMESPACE_SEC";
    break;
  case Entry::CLASSDOC_SEC:
    s = "CLASSDOC_SEC";
    break;
  case Entry::PREDDOC_SEC:
    s = "PREDDOC_SEC";
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
  if ( ! ce->parent() ) 
    printf("%*s (%d) -> %s\n",off+20, s, (ce->protection == Public ? 1 : 0), ce->name.data() /*, ce->program.data() */);
  else
    printf("%*s (%d) -> %s\n",off+20, s, (ce->protection == Public ? 1 : 0), ce->name.data() /*, ce->program.data() */);
}

void      
showScannerTree(uint off, Entry *current) {
  showScannerNode( off, current, FALSE );
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
   showScannerTree(0, root);
#endif
  printlex(yy_flex_debug, FALSE, __FILE__, fileName);

  //      delete current_module; 
  current_module=0;
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

static void parseMain(const char *fileName,const char *fileBuf,Entry *rt)
{
  initParser();

  inputString = fileBuf;
  inputPosition = 0;

  protection    = Private;
  mtype         = Method;
  gstat         = FALSE;
  virt          = Normal;
  current_root  = g_root = rt;
  g_specialBlock = FALSE;
  g_SWIStyle = FALSE;

  inputFile.setName(fileName);
  if (inputFile.open(IO_ReadOnly))
    {
      yyLineNo= 1 ; 
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
      initEntry( current );

      groupEnterFile(yyFileName,yyLineNo);

      // make user default module
      prologscannerYYrestart( prologscannerYYin );
      BEGIN( Search );
      prologscannerYYlex();
      g_lexInit=TRUE;

      groupLeaveFile(yyFileName,yyLineNo);

      current_root->program.resize(0);
      delete current; current=0;
//      delete current_module; current_module=0;

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


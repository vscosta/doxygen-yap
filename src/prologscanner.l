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
  static QCString	yyFileName;
  static Entry   	       *current_module = 0;
  static Entry   	       *current_clause = 0;
  static MethodTypes 	mtype;
  static bool    		gstat;
  static Specifier 	virt;
  static bool                     g_system_module;
  static bool                     g_new_module;

  static int              savedDocBlockOuter;
  static int              savedDocBlockInner;
  static QCString         docBlock;
  static QCString         docBlockName;
  static bool             docBlockInBody;
  static bool             docBlockJavaStyle;
  static bool             docBrief;

  static bool             g_specialBlock;
  static bool             g_grammar;

  static uint		 g_arity;
  
  static QDict<char>  g_prologFileCache(257);
  static QDict<char>   g_systemPredTable(257);
  static QDict<char>  g_callHashTable(257);
  static QDict<Entry>     g_predNameCache(257);
  static QDict<Entry>     g_moduleNameCache(257);
  static QDict<Entry>     g_varNameCache(257);
  static QDict<char>      g_exportNameCache(257);

  QDict<char>  g_foreignCache(257);

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
  static unsigned int     g_callLevel = 0;
  static unsigned int     g_argLevel = 0;  

  static Entry *     g_call = 0;
  static Entry *     g_callStore = 0;

  
  static Entry *newModule(const char *modname);

  static bool				g_headDone, g_atCall;
  static bool                           g_firstCall = true;


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

  static QCString
  baseNormalizePredName(QCString rc, uint arity, Entry * curModule )
  {
    QCString tmp, ar = "/";
    ar += QCString().setNum(arity);
    
    if (!curModule)
      curModule = current_module;
    if (!current_root)
        current_root = curModule;
                
    while(true) {
      if (rc.isNull() || rc[rc.length()-1]=='/')
	return 0;
      rc = rc.copy().stripWhiteSpace();
      // keep the arity separate
      int j;
      // right now, ar has the arity and rc the name
      if (rc.data()[0] == '(' && rc.data()[rc.length()-1] == ')') {
	rc = rc.mid(1, rc.length()-2);
	continue;
      }
      while ((j = rc.findRev("//", -1 , TRUE)) >= 0) {
	ar = QCString().setNum(rc.right(rc.length()-(j+1)).toUInt()+2).prepend("/");
	rc = rc.left( j );
      }
      while ((j = rc.findRev('/', -1)) >= 0) {
	ar = rc.right( rc.length()-j ).copy();
	rc = rc.left( j );             
      }
      // right now, ar has the arity and rc the name
      if (rc.data()[0] == '(' && rc.data()[rc.length()-1] == ')') {
	rc = rc.mid(1, rc.length()-2);
	continue;
      }
      if (rc.data()[0] == '\'' && rc.data()[rc.length()-1] == '\'') {
	rc = rc.remove(rc.length()-1,1);
	rc = rc.remove(0,1);
	continue;
      }
      int i;
      if (!strcmp(rc.data(), "=:=")) {
	rc = "prolog::=:=/2";
	break;
      } else if (!strcmp(rc.data(), "::")) {
	rc = "problog::::/2";
	break;
      }
      while ((i = rc.find("::")) > 0) {
	curModule = newModule(rc.left(i));
        rc = rc.right(rc.length()-(i+2));       
      }
      while ((i = rc.find(":")) > 0) {
	curModule = newModule(rc.left(i));
        rc = rc.right(rc.length()-(i+1));       
      }
		 
      if (rc.findRev("=:=", 0, TRUE) == 0 ||
	  rc.findRev("::", rc.length(), TRUE) == 0) {
        curModule = newModule("prolog") ;
      }
      break;
    }
    char *imp;
    rc += ar;
    if (g_systemPredTable[rc]) {
      rc = rc.prepend("prolog::");
      curModule = newModule("prolog") ;
      //printf("Y %s\n", rc.data());
      return rc;
    }
    rc = rc.prepend(curModule->name+"::");
    while ( (imp = g_exportNameCache[rc])) {
      // follow import chain
      rc = imp;
      int i = rc.find( "::" );
      if (i > 0)
        curModule = newModule(rc.left(i).data());
    }
    return rc;
  }

  static Entry *
normalizePredName(Entry *e, uint arity, Entry * curModule )
{
  QCString rc = e->name;
    rc = baseNormalizePredName( rc, arity, curModule );
    if (rc) {
      e->name = qstrdup(rc);
      return newModule( rc.left( rc.find("::") ) );
      }
    else {
    return 0;
    }
}

const char *
    normalizeIndicator( const char *link )
 {
    Entry *curModule = current_module;
    if (!curModule)
        curModule = newModule("user");
   QCString rc = baseNormalizePredName( link, 0, curModule );
   if (rc.isEmpty()) return 0;
   return qstrdup( rc );
 }
 
// This one actually returns the original string,
// not the module.
QCString
normalizePredName(QCString rc, uint arity, QCString curMod ) {
    Entry *curModule = newModule(curMod);
    rc = baseNormalizePredName( rc, arity, curModule);
    return rc;
}

static QCString mkKey(QCString file, uint line )
{
  static uint last = 0;
  static uint id = 0;
  QCString key =  file;
  key += " ";
  key += QCString().setNum(line);
  if (last == line)
    id ++;
  else
    id = 0;
  key += " ";
  key += QCString().setNum(id);   
  last = line;
  return key;
}

 char *getPredCallArity( QCString clName, QCString  file, uint line )
{
    // use an hash table to store all predicate calls,
    // so that we can track down arity;
    //
    
    // we assume at most one call to procedures
    // with the same name per line.
  if (clName.isEmpty())
    return 0;
  QCString key = mkKey( file, line);  
  return g_callHashTable[ key ];
}
 
 static void storePredCall( QCString clName, QCString file, uint line, uint arity )
 {
 if (g_specialBlock)
     return;
       // use an hash table to store all predicate calls,
    // so that we can track down arity;
   QCString key = mkKey( file, line);
   
   QCString n = normalizePredName( clName, arity, current_module->name );
   printf("%s -> %s\n", key.data(),n.data() );
   g_callHashTable.insert( key, qstrdup(n) );
    
}

static void initParser( void )
  {
    protection = Private;
    mtype = Method;
    gstat = FALSE;
    virt = Normal;
    previous = 0;
    g_packageCommentAllowed = TRUE;
    if (g_firstCall) {
      g_callHashTable.clear();
      g_exportNameCache.clear();
      g_callHashTable.setAutoDelete(FALSE);  // this is just a cache      
      g_exportNameCache.setAutoDelete(FALSE);  
    }
    g_predNameCache.setAutoDelete(FALSE);  // this is just a cache    
    g_moduleNameCache.setAutoDelete(FALSE);  // this is just a cache
    g_varNameCache.setAutoDelete(FALSE); // just another cache
  }

  static void initEntry( Entry * current )
  {
    //current->prolog = TRUE;
    current->protection = Private ;
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
    current->fileName = yyFileName;
    current->startLine = yylineno;    
    current->briefFile = yyFileName;
    current->briefLine = yylineno;
    current->docFile = yyFileName;
    current->docLine = yylineno;
    initEntry( current );
  }

  static void foundCall( QCString pname  )
  {
  if (!g_callStore)
      g_callStore = new Entry;
    g_call = g_callStore;
    g_arity = 0;
    Entry *n = g_call;
    
    //n->prolog = TRUE;
    n->mtype      = mtype;
    n->virt       = virt;
    n->stat       = gstat;
    n->lang       = SrcLangExt_Prolog;
    initGroupInfo(n);
    gstat = FALSE;
    n->section = Entry::CLASS_SEC;
    n->argList->clear();
    n->type  = "predicate" ;
    n->fileName  = yyFileName;
    n->startLine  = yylineno;
    n->name = pname.copy();
    // n->setParent(current);
    //current->addSubEntry(n);

  }

  static void doneCall( )
  {
    g_atCall = false;
    if (g_arity) {
      QCString n = g_call->name;
      storePredCall( n, yyFileName, yylineno, g_arity );
    }
    g_call = current;
  }

  static void getParameter( QCString s, Argument *arg, Entry *current )
  {
    char *v;
    const char *p = s.data();
    int ch;
    if (s.isNull() || s.isEmpty()) {
      arg->type = "term" ;
      arg->name = "A";
      arg->name += current->argList->count() ;
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
        {
            char cs[2];
            cs[0] = ch;
            cs[1] = '\0';
            arg->attrib = cs;
            arg->name = yytext + 1;
        }
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
          arg->name = "A";
          arg->name += current->argList->count() ;
       }
    } else if (arg->attrib) {
        arg->type = "term_t" ;
        arg->name = "A";
        arg->name += current->argList->count() ;
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
    if ( !strncmp(yytext , "_", 1 ) ) {
      n ->protection=Private;
    } else {
      n ->protection=current->protection;
    }
    //	    g_moduleNameCache.insert(mname, n );
    n ->section   = Entry::VARIABLE_SEC;
    n ->type = "variable" ;
    n ->fileName  = yyFileName;
    n ->startLine  = yylineno;
    n ->bodyLine  = yylineno;
    n ->setParent( current );
    current->addSubEntry(n);
  }

  static char *
    sliceArgument(const char *inp, int c)
  {
    size_t sz0 = strlen(inp);
    char *ptr;
    const char *tmp = inp, *end = inp+sz0;
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

  void brk() {printf("broken\n");}

  
  static void
    lineComments(  )
  {
    //  DBG_CTX((stderr,"yylineno=%d\n",yylineno));
    for (const char	*p = yytext; *p; ++p)
      {
	//     if (*p == '\n')
	//      printf("CM yylineno=%d\n", yylineno);
	if (*p == '\n') {
	  yyLineCms ++;
	}
      }
  }

  //-----------------------------------------------------------------

  //-----------------------------------------------------------------
  static void
    startCommentBlock(bool brief )
  {
    g_specialBlock = true;
    if (brief) {
      current->briefFile = yyFileName;
      current->briefLine = yylineno;
    } else {
      current->docFile = yyFileName;
      current->docLine = yylineno;
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

  static void initDocBlock(const char * s) {
    docBlock = s;
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
    } else if (current->section == Entry::EMPTY_SEC ||
	       current->section == Entry::CLAUSE_SEC) {
      return;
    } else {
      fprintf( stderr, "Unexpected item type 0x%x in Comment %s at line %d\n", current->section, yyFileName.data(), yylineno );
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
    g_specialBlock = false;
  }

  static void endOfDef(int correction=0)
  {
    // printf("endOfDef at=%d\n",yylineno);
    //printf("endOfDef %s\n", current->name.data());
    if (bodyEntry)
      {
	bodyEntry->endBodyLine = bodyEntry->parent()->endBodyLine = yylineno-correction;
	bodyEntry = 0;
      }
    newEntry(  );
    // reset depth of term.
    g_callLevel = g_argLevel = 0;
    current_clause = 0;
    //g_insideConstructor = FALSE;
  }

  static void initSpecialBlock(  )
  {
    docBlockInBody    = FALSE;
    docBlockJavaStyle = FALSE;
    docBrief = TRUE;
    // I don't know what I am;
    docBlock.resize(0);
    g_specialBlock = true;
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
    current->briefLine = yylineno;
    current->briefFile = yyFileName;
    g_SWIStyle = TRUE;
    if ( text )  {
      docBlock = "@defgroup ";
      docBlock += current_module->name.data() ;
      docBlock += " " ;
      docBlock += text;
      docBlock += " \n@{ \n";
    }

  }

  static void finalSWI( )
  {
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

  static Entry *newModule( QCString modnamep )
  {
    const char *name = modnamep.data();
    return newModule( name );
  }

  static Entry *newModule( const char *modname )
  {
    Entry * newm;
    if (!modname)
      modname = "user";
    QCString mname = modname;
    if (! strcmp(modname, ":") ) {
      newm = g_moduleNameCache.find(mname);
      return newm;
    }
    mname = mname.stripWhiteSpace();
    mname = stripQuotes( mname );
    if (!(newm = g_moduleNameCache[mname])) {
      // add a new module
      newm  = new Entry;
      initEntry( newm );
      if (current_root) {
          g_moduleNameCache.insert(mname, newm);
          newm->setParent( current_root );
          if (newm->parent() && newm != current)
            newm->parent()->addSubEntry(newm);
      }
      newm->section = Entry::NAMESPACE_SEC;
      newm->type = "module" ;
      newm->fileName  = yyFileName;
      newm->startLine  = yylineno;
      newm->bodyLine  = yylineno;
      newm->name = mname.copy();
    }
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
    current->startLine = yylineno;
    current->bodyLine  = yylineno;
    current->section = Entry::CLAUSE_SEC;
    current->protection = Private;
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

  static Entry *
    buildPredEntry(  QCString pname, uint arity, Entry *parent )
  {
    Entry *newp;
    if ( false && (newp = g_predNameCache.find(pname.data()) ) ) {
      if (parent && !strcmp(parent->name.data() , "prolog") &&
	  newp->parent() != parent ) {
	// Prolog rulez
	newp->parent()->removeSubEntry( newp );
	newp->setParent( parent );
	parent->addSubEntry( newp );
      }
      return newp;
    }
    newp = new Entry;
    g_predNameCache.insert(pname, newp);
    initEntry( newp );
    newp->section = Entry::CLASS_SEC;
    newp->type = "predicate" ;
    newp->fileName  = yyFileName;
    newp->startLine = yylineno;    
    newp->name = pname.copy();
    newp->bodyLine = yylineno;
    newp->protection = Private;
    for (uint i=0; i<arity; i++) {
      char buf[16];
      Argument *a = new Argument;
      snprintf( buf, sizeof(buf), "A%u", i+1);
      a->name = buf;
      a->type = "Term";
      //current->argList->append(a);
    }
    newp->setParent( parent );
    if (parent && newp != current)
      newp->parent()->addSubEntry(newp); // the circle of life

    return newp;
  }

  Entry  *predBind(Entry *cur, Entry *module, uint arity)
  {
    Entry *parent;
    if (arity) {
      QCString n = cur->name;
      storePredCall( n, yyFileName, yylineno, arity );
    }
    parent = normalizePredName(cur, arity, module );
    QCString pname = cur->name;
    return buildPredEntry( pname, arity, parent );
  }



  static void newClause(  ) {

    Entry *newp = predBind( current, current_module, current->argList->count()  );
    if (firstClause( current )) {
      newp->bodyLine = newp->endBodyLine = yylineno;    
      current->bodyLine = current->endBodyLine = yylineno;
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
    current->protection = current->parent()->protection = Public;
    current_predicate = newp;
    docBlockInBody = FALSE;

  }

  static void
  startSpecialBlock( void )
  {
    current->reset();
    g_slashStarComment = ( yytext[0] == '/' && yytext[1] == '*' );
    savedDocBlockOuter = YY_START;
    current->name = "";
    current->program = "";
    g_packageCommentAllowed = TRUE;
    initSpecialBlock(  );
  }

  QString getPrologFile(QDir dir, QString file);

  QString  checkFile( QFileInfo *finfo, QString file )
  {
    QString item = finfo->absFilePath(), xabs;
    if ( QDir(item).exists()) item = item;
    else if ( QDir(item + ".yap").exists() )
      item = item+".yap";
    else if ( QDir(item + ".pl").exists())
      item = item+".pl";
    else if ((xabs = getPrologFile(QDir(item), file ) ) != 0)
      item = xabs;
    else
      item = "";
    return item;
  }

  QString getPrologFile(QDir dir, QString file)
  {
    size_t dabs = dir.canonicalPath().length();
    dir.setFilter( QDir::Dirs );
    const QFileInfoList *list = dir.entryInfoList();
    QFileInfoListIterator it( *list );      // create list iterator
    QFileInfo *finfo;                          // pointer for traversing

    while ( (finfo=it.current()) ) {	//foreach(QFileInfo finfo, list) {

      QString abs =  finfo->absFilePath() ;
      if (abs.length() > dabs) {
	QString xabs;
	if (( xabs = checkFile( finfo, file ) ).isEmpty()) {
	  return xabs;
	}
      }
      ++it;
    }
    return 0;
  }

  const char *fileToModule(QString item) {
    if (item.find("library(") == 0) {
      item = item.mid(8,item.length()-9).stripWhiteSpace();
      item = getPrologFile(QDir(), item);
      if (item == "0") item = "user";
    } else {
      item = item.stripWhiteSpace();
      if ( QDir("./"+item).exists()) item = "./"+item;
      else if ( QDir("./"+item + ".yap").exists() )
	item = "./"+item+".yap";
      else if ( QDir("./"+item + ".pl").exists())
	item = "./"+item+".pl";
      else
	return "user";
      QDir d = QDir( item );
      d.convertToAbs();
      return d.dirName().data();
    }
    if ( QFileInfo( item ).exists() ) {
      return g_prologFileCache[ item.data() ];
    }
    return "user";
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

STARTSPECIALLINE      ("%"[%!])[ \t]*("\n"[ \t]*"%"[ \t])*
STARTSPECIALSLASHDOT      ("/*"[*!])[ \t]*("\n"[ \t]*("*")*[ \t]*)*

STARTSPECIAL           ({STARTSPECIALLINE}|{STARTSPECIALSLASHDOT})


PERCCOMMENT      "%"([^%!\n][^\n]*"\n"|"\n"|[%!][%!][^\n]*"\n")



SLASHSTARSTARTCOMMENT "/*"([^\*\!]|"*"[^ \t\n]|"!"[^ \t\n])
SLASHSTAREMPTYCOMMENT "/*/"
SLASHSTARENDCOMMENT   "*/"

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
    g_packageCommentAllowed = FALSE;
    BEGIN(SkipComment);
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
    current->name.remove(current->name.length()-2,2);
    current->name = current->name.stripWhiteSpace();
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
    current_clause = current;
    g_defVal = "";
    g_headDone = TRUE;
    BEGIN( HeadOperator );
 }

  {EOT}         {
    g_grammar = FALSE;
  }


  {STARTSPECIAL}	{
    startSpecialBlock();
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

  {STARTSPECIAL}{B}({NOC}":")?{NOC}"("{B}	{
    startSpecialBlock();
    current->section = Entry::CLASSDOC_SEC;
    const char *s = skipSpecialStart( yytext );
    current->program = s;
    current->name = s;
    current->name =
      current->name.stripWhiteSpace();
    uint l = current->name.length();
    current->name.truncate(l-1);
    g_argLevel = g_callLevel = 1;
    g_atCall = true;
    BEGIN( ExtraCommentArgs );
}

{STARTSPECIAL}{B}({NOC}":")?{NOC}[. \t]{B}	{
  startSpecialBlock();
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
    QCString s;
   s = current->program  = skipSpecialStart( yytext );
  	current->name =
      s.stripWhiteSpace();
	initDocBlock( "<b> ");
        addToDocBlock(current->program  );
        addToDocBlock( " </b> " );
    uint l = current->name.length();
  if (l && current->name.data()[l-1] == '.')
    current->name.truncate(l-1);
    current->setParent(predBind(current, current_module, 0));
   current->section = Entry::CLASSDOC_SEC;
  current->name = current->parent()->name.copy();
    addPredDecl( );
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
   QCString predName = pname.left( fg );
   int fge = fg + strlen(" foreign ");
   QCString func = pname.right( end - fge );
   g_foreignCache.insert( predName, qstrdup( func ) );
 }

 "sys "{INDICATOR}{EOT} {
   // connect imports
   QCString pname=yytext;
   int fg = strlen("sys ");
   int lim = pname.findRev(".");
   pname = pname.mid(fg,lim-fg );
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
	  g_headDone = TRUE;
	  BEGIN( HeadOperator );
	}
      }
    } else {
      g_argLevel--;
      foundTerm();
    }
  }

")"{B}/[,;\])}] {
  current->program+=yytext;
  if (current_clause && current_clause != current)
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
      current->program+=yytext;
      if (current_clause && current_clause != current)
        current_clause->program+=yytext;
    }

 }

  <FunctionBody>{

  {EOT}         {
    // end of a rule
    if (current_clause) {
      current_clause->program+=yytext;
      if (current_clause->section == Entry::CLAUSE_SEC) {
	endOfDef();
      }
      BEGIN(Search);
    }
  }

  <<EOF>>         {
    // end of a rule
    if (current_clause) {
      endOfDef();
    }
    if (g_SWIStyle) {
      finalSWI();
    }
    yyterminate();
  }

  {BB}(^{BB}\n)*	      {   // skip spaces
    current_clause->program+=yytext;
  }

  "->"|";"              {  
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
     current->name = g_pName;     
     foundCall( g_pName  );
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
    g_argLevel ++;
  }

   ("("|"{") { //
    current_clause->program+=yytext;
    if (g_argLevel == g_callLevel)
      g_callLevel++;      
    g_argLevel++;
   }

   (")"|"}"|"]") {
    //
    current_clause->program+=yytext;
    if (g_argLevel == g_callLevel) {
      g_callLevel--;
      if (g_atCall) {
	g_arity++;
	doneCall();
      }
    }
    g_argLevel--;
 }

 \n       {
   current_clause->program+=yytext;
  }

 .       {
   current_clause->program+=yytext;
 }

 }


<Directive>{
  ("system_")?"module("{B}("("{B}*)*{ATOM}{B}"," { // define module  ATOM
    QCString modn = strrchr( yytext, '(')+1;
    modn = modn.remove(modn.length()-1,1);
    modn = modn.stripWhiteSpace();
    g_packageName=modn;
    g_new_module = true;
    if (yytext[0] == 's') {
      current_module = newModule("prolog");
      BEGIN(Search);
    } else {
      current_module = newModule(modn.data());
      BEGIN(ExportList);
    }
  }

   "multifile"{B} { // define module  ATOM
    BEGIN(ExportList);
  }

  "meta_predicate"{B} { // define module  ATOM
    BEGIN(Metas);
  }

  "use_module("{BNS}{LIBRARY}{BNS}")"{BNS}{EOT} {
    g_packageName=yytext;
    QCString item=g_packageName;
    item = removeRedundantWhiteSpace(sliceArgument(item.data(), ')' ));
    current->name = fileToModule(item);
    current->setParent( newModule( current->name ) );
    current->section=Entry::USINGDECL_SEC;
    BEGIN(Search);
  }


  ("use_module("|"reexport("){BNS}{LIBRARY}{BNS}","{BNS} {
    g_packageName=yytext;
    QCString item=g_packageName;
    item = removeRedundantWhiteSpace(sliceArgument(item.data(), ',' ));
    if (item.find("library(") == 0) item = item.mid(8,item.length()-9).stripWhiteSpace();
    current->name = fileToModule(item);
    current->setParent( newModule( current->name ) );
    current->section=Entry::USINGDECL_SEC;
    BEGIN(Search);
  }

  ("system_")?"module("{BNS}{ATOM}{BNS}"," { // define module  ATOM
    QCString modn = strrchr( yytext, '(')+1;
    modn = modn.remove(modn.length()-1,1);
    modn = modn.stripWhiteSpace();
    g_packageName=modn;
    g_new_module = true;
    if (modn[0] == '$') {
      // newModule(modn.data(), Private);
      current_module = newModule("prolog");
      protection = Public;
    } else {
      current_module = newModule(modn.data());
    }
    if (yytext[0] == 's') {
      g_system_module = true;
    }
    BEGIN(ExportList);
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
    current->setParent( predBind( current, newModule( modName.data()), arity ) );
    newEntry();
    current->reset();
    current->setParent( p );
    current->name = funcName;
    current->fileName = fileName;
    current->section=Entry::FUNCTION_SEC;
    current->startLine = line;
    current->bodyLine  = line;
    newEntry();
    BEGIN(Search);
  }


  "use_system_module("{B}{LIBRARY}{B}","{B} {
    g_packageName=yytext;
    QCString item=g_packageName;
    current->name =removeRedundantWhiteSpace(sliceArgument(item.data(), ',' ));
    current->setParent( newModule( "prolog" ) );
    protection = Private;
    current->section=Entry::USINGDECL_SEC;
    BEGIN(ImportList);

  }

  \n		      {
  }

  {EOT}	      {
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
      current_root->removeSubEntry(current);
      current_root->addSubEntry(current);
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
       current_root->addSubEntry(current);
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

  {BNS}"["{BNS}  {
    g_argLevel = 1;
  }

  {BNS}"]"{BNS}  {
    g_argLevel--;
  }

  {BNS}","{BNS}  {
    /* skip to next entry */
  }

  {INDICATOR}  {
    QCString pname = yytext;
      current->reset();
      current->name = pname.simplifyWhiteSpace();
      current->fileName = yyFileName;
      current->section=Entry::USINGDECL_SEC;
      uint arity = pname.left(pname.findRev('/', pname.length())+1).toUInt();
      Entry *p = predBind( current, current_module, arity );
      p->protection = Public;
      g_predNameCache.insert( current->name, current );
      current->setParent( p );
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
  lineComments( );
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
    addToDocBlock( yytext );
    savedDocBlockInner   = YY_START; // enter Inline
    BEGIN(Inline);
  }



  {B}{VAR}|{NUMBER} { //
    addToDocBlock( yytext );
  }


  {B}("@"|"\\")("pred"|"predicate"){BB}({ATOM}":")?{ATOM}"("{B}	{
    g_argLevel = 1;
    current->program = current->name = (current->name = yytext).copy();
    int s = current->name.find( "pred", 0);
    current->name.remove( 0, s+4 );
    current->program = current->name;
    current->name = current->name.simplifyWhiteSpace ();
    uint l = current->name.length();
    current->name.remove( l-1, 1 );
    current->section = Entry::CLASSDOC_SEC;
    current->argList->clear();
    if ( g_SWIStyle) {
      initSWIComment( 0 );
    }
    BEGIN( ExtraCommentArgs );
					}

  {B}("@"|"\\")("pred"|"predicate"){BB}({ATOM}":")?{ATOM}("."|{PREDINFO})?{BN}	{
    // 0 arity
    current->name = yytext;   
    current->program = yytext;
    current->name = current->name.copy();
    current->name.remove( 0, current->name.find( "pred", 0)+4 );
    current->name = current->name.simplifyWhiteSpace ();
      // discard predinfo
      int i;
      if ((i = current->name.find( ' ', 0)) > 0)
      current->name.truncate(i);
     uint l = current->name.length();
     if (current->name.data()[l-1] == '.')
       current->name.truncate( l-1 );
     QCString q = current->name.copy();
     current->setParent(predBind(current, current_module, 0));
     current->section = Entry::CLASSDOC_SEC;
     current->name = current->parent()->name.copy();
  if (!current->name.isEmpty() && current->name.at(0)=='$') // mark as private
    {
      current->protection = Private;
      current->parent()->protection = Public;
    }
  else
    {
     current->protection = current->parent()->protection = Public;
}
     addPredDecl(  );
     initSpecialBlock( );
     initDocBlock( " <b> " );
     addToDocBlock( yytext );
     addToDocBlock( " </b> " );
}

  {B}("@"|"\\")("pred"|"predicate"){BB}{ATOM}{BB}{VARPARAMETERDESCRIPTOR}{PREDINFO}{BN} {
    // prefix operator
    current->name = (current->name = yytext).copy();
    current->name.remove( 0, current->name.find( "pred", 0)+4 );
    current->program = current->name;
    current->name = current->name.simplifyWhiteSpace ();
    uint sp = current->name.find( ' ', 0);
    uint len = current->name.length();
    QCString s1 = current->name.right( len- sp);
     current->name.truncate( sp );
     Argument *arg = new Argument;
    getParameter( s1, arg, current );
     current->setParent(predBind(current, current_module, 1));
     current->section = Entry::CLASSDOC_SEC;
  if (!current->name.isEmpty() && current->name.at(0)=='$') // mark as private
    {
      current->protection = Private;
current->parent()->protection = Public;
    }
  else
    {
     current->protection = current->parent()->protection = Public;
    }
     addPredDecl(  );
     initSpecialBlock( );
     initDocBlock("  <b> " );
     addToDocBlock( current->program );
     addToDocBlock( " </b> " );

    }

   {B}("@"|"\\")("pred"|"predicate"){BB}{VARPARAMETERDESCRIPTOR}{BB}{ATOM}{PREDINFO}{BN} {
    // posfix operator
     QCString s1;
     s1 = (s1 =yytext).copy();
    s1.remove( 0, s1.find( "pred", 0)+4 );
    s1 = s1.simplifyWhiteSpace ();
    current->program = s1;
    int sp = s1.find( ' ', 0);
    current->name = s1.right( s1.length()- (sp+1));
     s1.truncate( sp );
     Argument *arg = new Argument;
     getParameter( s1, arg, current );
      current->setParent(predBind(current, current_module, 2));
     current->section = Entry::CLASSDOC_SEC;
  if (!current->name.isEmpty() && current->name.at(0)=='$') // mark as private
    {
      current->protection = Private;
    }
  else
    {
current->protection = current->parent()->protection = Public;
}
     addPredDecl(  );
     initSpecialBlock();
     initDocBlock("<b> " );
     addToDocBlock( yytext );
     addToDocBlock( " </b> " );

    }

   {B}("@"|"\\")("pred"|"predicate"){BB}{VARPARAMETERDESCRIPTOR}{BB}({ATOM}|";"|","){BB}{VARPARAMETERDESCRIPTOR}{PREDINFO}{BN} {
     // infix operator
     QCString s1, s2;
     s1 = yytext;
     s1 = s1.copy();
   int sp = s1.find( "pred", 0);
    s1.remove( 0, sp+4 );
    current->program = s1;
     s1 = s1.simplifyWhiteSpace ();
    int sp1 = s1.find( ' ',  0);      // op1
    int sp2 = s1.find( ' ', sp1+1);   // op
    int sp3 = s1.find( ' ', sp2+1);   // op3
    if (sp3 > 0) s1.truncate(sp3);
    current->name = s1.mid( sp1+1, sp2 - (sp1+1));
    s2 = s1.right( sp3 - (sp2+1));
    s1.truncate(  sp1 );

    Argument *arg1 = new Argument;
    getParameter( s1, arg1, current );
    Argument *arg2 = new Argument;
    getParameter( s2, arg2, current );
     current->setParent(predBind(current, current_module, 2));
     current->section = Entry::CLASSDOC_SEC;
     addPredDecl(  );
     initSpecialBlock( );
    initDocBlock( "<b> " );
     addToDocBlock( yytext );
     addToDocBlock( " </b> " );
    }

  {B}*{CMD}{B}*        {
    addToDocBlock( yytext );
  }

 }

<SWISpecialComment,SWISpecialLineComment>{
  "=|"  {
    addToDocBlock( "`" );
    savedDocBlockInner   = YY_START;
    BEGIN( SWIQuoted );
  }

  ^"---+"[ \t] {
    addToDocBlock( "## " );
  }

  ^"---++"[ \t] {
    addToDocBlock( "### " );
  }

  ^"---+++"[ \t] {
    addToDocBlock( "#### " );
  }

  ^"---++++"[ \t] {
    addToDocBlock( "##### " );
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
    addToDocBlock( yytext );
  }

  \n[ \t]*"=="[ \t]*\n		{
    addToDocBlock( "~~~~{.prolog}\n" );
    savedDocBlockInner   = YY_START;
    BEGIN(SWIInline);

  }

  ^[ \t]*"=="[ \t]*\n		{
    addToDocBlock( "~~~~{.prolog}\n" );
    savedDocBlockInner   = YY_START;
    BEGIN(SWIInline);

  }

 }

<SWISpecialComment,SpecialComment>{

  "\n"        {     
    addToDocBlock( yytext ); }

  ^{B}("*")?{B}\n        {  // empty line
    docBlock+='\n';
    docBrief = FALSE;
    startCommentBlock( FALSE );
  }

  ^{B}"*"{B} {       
 }

  "*"/[^/]    {       
addToDocBlock( yytext ); }

  "*/"		{
    handleCommentBlock(docBlock, docBrief);
    BEGIN( savedDocBlockOuter );
  }

  .  {       
    addToDocBlock( yytext ); }
 }

<SWISpecialLineComment,SpecialLineComment>{

  \n{B}("%")+/[ \t]     {   
docBlock+='\n'; }

  \n{B}("%")+{B}"\n"   { // empty line
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
    handleCommentBlock(docBlock, docBrief);
    BEGIN(savedDocBlockOuter);
  }
 }


<SWIQuoted>{
  [^|\n]*     {       
addToDocBlock( yytext ); }
  "|"+[^=]*   {       
addToDocBlock( yytext ); }
  "\n"        { addToDocBlock( yytext );  }
  "|="       {  addToDocBlock( "`" ); BEGIN(savedDocBlockInner); }

 }

<SWIBold>{
  [^|\n]*     {     
addToDocBlock( yytext ); }
  "|"+[^*]*   {     
addToDocBlock( yytext ); }
  "\n"        { addToDocBlock( yytext );    }
  "|*"       {  addToDocBlock( "</b>" ); BEGIN(savedDocBlockInner); }

 }

<SWIInline>{
  \n[ \t]*"=="[ \t]*"\n" {
    addToDocBlock( "~~~~\n" );
    BEGIN(savedDocBlockInner);
  }
    
    \n[^\n]*      {
      addToDocBlock( yytext );
    }
  }

<Inline>{
    "~~~"("~")*"\n"       {
      addToDocBlock( yytext );
      BEGIN(savedDocBlockInner);
    }
    
    [^\n]+       {
      addToDocBlock( yytext );
    }
    
    \n           {
      addToDocBlock( yytext );
    }
  }

<ExtraCommentArgs>{

    {PARAMETERDESCRIPTOR} {
      current->program += yytext;
      Argument *arg = new Argument;
      getParameter( yytext, arg, current );
    }

    {ATOMIC} {
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

    ")"("//")?{PREDINFO}{BN} {
      current->program += yytext;
      if (--g_argLevel == 0) {
       
	if (current->name.isNull())
	  current->name = "op";
	if (yytext[1] == '/') {
	  current->setParent(predBind(current, current_module, current->argList->count()+2));
	} else
	  current->setParent(predBind(current, current_module, current->argList->count()));
	current->protection = current->parent()->protection = Public;
	current->name = current->parent()->name.copy();
	fillArgs();
	initSpecialBlock( );
	if (current->briefLine == yylineno) {
	  addPredDecl( );
	}
	if (current->briefLine < yylineno) {
	  current->briefLine = yylineno;
	}
        initDocBlock( "<b> " );
	addToDocBlock(  current->program );
	addToDocBlock( " </b>" );
	if (g_slashStarComment)
	  BEGIN( SWISpecialComment );
	else
	  BEGIN( SWISpecialLineComment );
      } else {
	g_argLevel--;
      }
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
    if (current) {
      current->program+=yytext;
      g_defVal += yytext;
    }
  }

<Search,FunctionParams,FunctionDec,FunctionBody,CallArgs,HeadOperator,Directive,ImportList,ExportList,Import>{PERCCOMMENT} {
  lineComments();
}

<<EOF>>	      {
  if (g_SWIStyle) {
    finalSWI();
  }
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
      warn(yyFileName,yylineno,"Empty prototype found!");
      return;
    }

  g_specialBlock = false;
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
  return;
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
#if DEBUG_ALL||1
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
  gstat         = false;
  virt          = Normal;
  current_root  = g_root = rt;
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
      current = rt ;
      initParser();
      g_predNameCache.clear();
      g_moduleNameCache.clear();
      current_module = newModule( "user" );
      current            = new Entry;
      current->reset();
      initEntry( current );

      groupEnterFile(yyFileName,yylineno);

      // make user default module
      prologscannerYYrestart( prologscannerYYin );
      BEGIN( Search );
      prologscannerYYlex();
      g_lexInit=TRUE;

      groupLeaveFile(yyFileName,yylineno);

      current_root->program.resize(0);
      delete current; current=0;
      current_root = 0;
      g_firstCall = false;
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

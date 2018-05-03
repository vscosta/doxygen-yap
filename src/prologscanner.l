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

  /* -----------------------------------------------------------------
   *
   *	statics
   */

  static ParserInterface *g_thisParser;
  static const char *inputString;
  static int inputPosition;
  int g_ignore;
  static QFile inputFile;

static Entry * createModuleEntry( QCString mname );

  static Protection protection;

  static Entry *current_root = 0;
  static Entry *current_group = 0;
  static Entry *current_predicate = 0;
  static Entry *current_comment = 0;
  static Entry *current = 0;
  static Entry *previous = 0;
  static Entry *bodyEntry = 0;
  static int yyLineCms = 0;
  static QCString yyFileName;
  static Entry *current_module = 0;
  static Entry *current_clause = 0;
  static MethodTypes mtype;
  static bool gstat;
  static Specifier virt;
  static bool g_system_module;
  static bool g_new_module;

  static int savedDocBlockOuter;
  static int savedDocBlockInner;
  static QCString docBlock;
  static QCString docBlockName;
  static bool docBlockInBody;
  static bool docBlockJavaStyle;
  static bool docBrief;

  static QCString docComment;


  static bool g_specialBlock;
  static bool g_grammar;

  static uint g_arity;

  static QDict<char> g_prologFileCache(257);
  static QDict<char> g_systemPredTable(257);
  static QDict<Entry> g_predNameCache(257);
  static QDict<Entry> g_moduleEntryCache(257);
  static QDict<Entry> g_varNameCache(257);
 static QDict<char> g_exportNameCache(257);
 static QDict<char> g_groupEntryCache(257);

  QDict<char> g_foreignCache(257);

  static QCString g_packageScope;
  static QCString g_pName;

  // static bool             g_insideConstructor;

  static QCString g_moduleScope;
  static QCString g_packageName;

  // static bool             g_hideClassDocs;

  static QCString g_defVal;

  static bool g_lexInit = FALSE;
  static bool g_packageCommentAllowed;
  static bool g_slashStarComment;
  static bool g_SWIStyle;

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
  static unsigned int g_callLevel = 0;
  static unsigned int g_argLevel = 0;

  static Entry *g_call = 0;
  static Entry *g_callStore = 0;

  static QCString newModule(const char *modname);
  static Entry *buildPredEntry(QCString pname, QCString mod);

  static bool g_headDone, g_atCall;
  static bool g_firstCall = true;

  static void parseMain(const char *fileName, const char *fileBuf, Entry *rt);

  static void fillArgs();

  static QRegExp ra("/[0-9]+$");
  static QRegExp rm("^[a-z][a-zA-Z_0-9]*:");
  static QRegExp rmq("^'[^']+':");

#define DEBUG_ALL 1

#if DEBUG_ALL
  void showScannerTree(uint off, Entry * current);
  static void showScannerNode(uint off, Entry * current, bool show);
#endif
  //-----------------------------------------------------------------------------

  static QCString stripQuotes(QCString item) {
    if (item.isEmpty())
      return item;
    const char *s = item.data();
    size_t last = strlen(s) - 1;
    if (s[0] == '\'' && s[last] == '\'') {
      item.remove(last, 1);
      item.remove(0, 1);
    }
    return item;
  }

  static QCString ind_name, ind_arity, ind_mod;

  // We should accept ({atom}":")*{atom}("/"{nat})?
  // in this case, as no grouping operators are available
  //  we step backwards
  //
  //

  static bool normalizePredName__(QCString curMod, const char *input,
                                     uint n, QCString &omod, QCString &oname, uint &arity);

  bool normalizePredName(QCString inp, uint arity, QCString curMod,
                         QCString & o, QCString &om) {
      QCString on;
      bool rc;
      if  ((rc = normalizePredName__(curMod, inp.data(), arity, om, on, arity))) {

          o =  ( //om + "::" +
                on + "/" + QCString().setNum(arity));
          }
      return rc;
  }

  bool normalizeIndicator(const char *link, QCString &om,  QCString &on, uint &arity ) {

      QCString l = link, m = "";
      if (link == 0)
          return false;

     return normalizePredName__(m, l, 0,  om, on, arity );
  }

  bool normalizeIndicator(const char *link, QCString &namr, QCString &om ) {
    QCString on = "", m = "";
     uint arity;


    if ( normalizePredName__( m, link, 0, om, on, arity) ) {
        namr =
            on + "/" + QCString().setNum(arity);
       return true;
    }
   return false;
  }


  static QCString mkKey(QCString file, uint line) {
    static uint last = 0;
    static uint id = 0;
    QCString key = file;
    key += " ";
    key += QCString().setNum(line);
    if (last == line)
      id++;
    else
      id = 0;
    key += " ";
    key += QCString().setNum(id);
    last = line;
    return key;
  }

  static void initParser(void) {
    protection = Private;
    mtype = Method;
    gstat = FALSE;
    virt = Normal;
    previous = 0;
    g_packageCommentAllowed = TRUE;
    if (g_firstCall) {
      g_exportNameCache.clear();
      g_exportNameCache.setAutoDelete(FALSE);
    }
    g_predNameCache.setAutoDelete(FALSE);   // this is just a cache
    g_moduleEntryCache.setAutoDelete(FALSE); // this is just a cache
    g_varNameCache.setAutoDelete(FALSE);    // just another cache
  }

  static void initEntry(Entry * current) {
    // current->prolog = TRUE;
    current->protection = Private;
    current->mtype = mtype;
    current->virt = virt;
    current->stat = gstat;
    current->lang = SrcLangExt_Prolog;
    initGroupInfo(current);
    gstat = FALSE;
  }

  static void newEntry() {
    //        if (current && current->parent())
    //     printf("||%p %s -< %p %s||\n", current->parent(),
    //     current->parent()->name.data() , current, current->name.data() /*,
    //     current->program.data() */);

    // if (current->section!=Entry::PREDDOC_SEC)
    current = new Entry;
    current->fileName = yyFileName;
    current->startLine = yylineno;
    current->briefFile = yyFileName;
    current->briefLine = yylineno;
    current->docFile = yyFileName;
    current->docLine = yylineno;
    initEntry(current);
  }

  static Entry *newFreeEntry(void) {
    //        if (current && current->parent())
    //     printf("||%p %s -< %p %s||\n", current->parent(),
    //     current->parent()->name.data() , current, current->name.data() /*,
    //     current->program.data() */);

    //  else   if (current->section!=Entry::PREDDOC_SEC)
    Entry *e = new Entry;
    e->fileName = yyFileName;
    e->startLine = yylineno;
    e->briefFile = yyFileName;
    e->briefLine = yylineno;
    e->docFile = yyFileName;
    e->docLine = yylineno;
    initEntry(e);
    return e;
  }

  static void foundCall(QCString pname)
  {
    g_arity = 0;
    Entry *n = newFreeEntry();
    g_call = n;

    // n->prolog = TRUE;
    n->mtype = mtype;
    n->virt = virt;
    n->stat = gstat;
    n->lang = SrcLangExt_Prolog;
    initGroupInfo(n);
    gstat = FALSE;
    n->section = Entry::CLASS_SEC;
    n->spec = ClassDef::Predicate;
    n->argList->clear();
    n->type = "predicate";
    n->fileName = yyFileName;
    n->startLine = yylineno;
    n->name = pname.copy();
    g_exportNameCache.insert( pname, n->type);
 }

  static void doneCall() {
    g_atCall = false;
    QCString n = g_call->name;
   // predBind(n, current_module->name, g_call->argList->count());
  }

  static void getParameter(QCString s, Argument * arg, Entry * current) {
    char *v;
    const char *p = s.data();
    int ch;
    if (s.isNull() || s.isEmpty()) {
      arg->type = "term";
      arg->name = "A";
      arg->name += current->argList->count();
      current->argList->append(arg);
      return;
    }
    while ((ch = *p) && !isblank((ch)))
      p++;
    QCString r = s.left(p - s.data());
    ch = s.data()[0];
    p = s.data();
    arg->docs += s.data();
    switch (ch) {
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
    case '9': {
      char cs[2];
      cs[0] = ch;
      cs[1] = '\0';
      arg->attrib = cs;
      arg->name = yytext + 1;
    } break;
    default:
      arg->attrib = 0;
      arg->name = p;
    }
    arg->name = arg->name.stripWhiteSpace();
    if (arg->attrib && !arg->name.isNull()) {
      ch = arg->name.data()[0];
      if ((ch >= 'A' && ch <= 'Z') || ch == '_') {
      v = strchr( ( char *)(arg->name.data()), ':');
	if (v) {
	  // got a name and type;
	  // skip :
	  v += 1;
	  arg->type = arg->name.data()+(v - arg->name.data()) ;
	  //arg->name.truncate((v-1) - arg->name.data());
	}
      } else {
        arg->type = arg->name;
        arg->name = "A";
        arg->name += current->argList->count();
      }
    } else if (arg->attrib) {
      arg->type = "term_t";
      arg->name = "A";
      arg->name += current->argList->count();
    }
    current->argList->append(arg);
  }

  static void foundTerm() {}

  void foundVariable() {
    return;
    Entry *n = new Entry;
    n->name = QCString(yytext);
    if (!strncmp(yytext, "_", 1)) {
      n->protection = Private;
    } else {
      n->protection = current->protection;
    }
    //	    g_moduleNameCache.insert(mname, n );
    n->section = Entry::VARIABLE_SEC;
    n->type = "variable";
    n->fileName = yyFileName;
    n->startLine = yylineno;
    n->bodyLine = yylineno;
assert(n->name);
     current_clause->addSubEntry(n);
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

  void brk() { printf("broken\n"); }

  static void lineComments() {
    //  DBG_CTX((stderr,"yylineno=%d\n",yylineno));
    for (const char *p = yytext; *p; ++p) {
      //     if (*p == '\n')
      //      printf("CM yylineno=%d\n", yylineno);
      if (*p == '\n') {
        yyLineCms++;
      }
    }
  }

  //-----------------------------------------------------------------

  //-----------------------------------------------------------------
  static void startCommentBlock(bool brief) {
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

  static uint prepLine(const char *text, bool slashStarComment) {
    int nch, ch;
    uint i = 0;
    int marker = ( slashStarComment ? '*' : '%' );

while (true) {
  ch =text[i++];
  if ((ch = text[i]) == ' ') {  continue; }
  if (ch == marker) {
    i++;
    int nch = text[i];
    if (isblank(nch) && nch != '\n') return i+1;
    if (nch == '\0') return i;
      return i;
    if (nch == marker)
      continue;
  }
  return 0;
}
  }

  typedef enum { BRIEF, BRIEF_EMPTY, BLANK_LINE, DOC } state_t;

  static bool prepComment(const char *text, bool & brief,
                          bool slash_star) {

    int follow = (slash_star ? 3 : 2);
    int n, n0 = 0, m;

    docBlock = text + follow;
    if (slash_star)
    docBlock.truncate(docBlock.size()-2);
    if (docBlock.isEmpty()) return false;
    docBlock = docBlock.stripWhiteSpace();
    if (docBlock.isEmpty()) return false;
    n0 = docBlock.size();
   while ((n=docBlock.findRev('\n', n0))>0) {
     if ((m = prepLine(docBlock.data()+(n+1), slash_star))) {
         docBlock = docBlock.remove(n+1, (m));
     }
        n0 = n-1;
 }
    brief = (
        docBlock.findRev("@pred", 0) == 0 ||
        docBlock.findRev("\\pred", 0) == 0 ||
        docBlock.findRev("@brief", 0) == 0 ||
        docBlock.findRev("\\brief", 0) == 0 );
     return true;
}

static void linkComment(bool needsEntry  ) {
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
      current->setParent( predBind(  current->name ) );
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
    }

  static void handleCommentBlock(const QCString &doc, bool brief) {
    // printf("handleCommentBlock(doc=[%s] brief=%d docBlockInBody=%d
    // docBlockJavaStyle=%d\n",
    //	   doc.data(),brief,docBlockInBody,docBlockJavaStyle);

    if (doc.isNull() || doc.isEmpty())
      return;
    docBlockInBody = FALSE;

    int position = 0;
    bool needsEntry;
    // this is a name for  anonymous documents.
    int lineNr = brief ? current->briefLine : current->docLine;
    while (parseCommentBlock(g_thisParser, current,
                             doc,        // text
                             yyFileName, // file
                             lineNr, docBlockInBody ? FALSE : brief,
                             docBlockJavaStyle, // javadoc style // or FALSE,
                             docBlockInBody, protection, position,
                             needsEntry)) // need to start a new entry
    {
      linkComment(needsEntry);
    }
    linkComment(needsEntry);
    g_specialBlock = false;
  }

  static void endOfDef(int correction = 0) {
    // printf("endOfDef at=%d\n",yylineno);
    if (bodyEntry) {
      bodyEntry->endBodyLine = bodyEntry->parent()->endBodyLine =
          yylineno - correction;
      bodyEntry = 0;
    }
      current->reset();
      initEntry( current );
    // reset depth of term.
    g_callLevel = g_argLevel = 0;
    current_clause = 0;
    // g_insideConstructor = FALSE;
  }

  static void initSpecialBlock() {
    docBlockInBody = FALSE;
    docBlockJavaStyle = FALSE;
    docBrief = TRUE;
    // I don't know what I am;
    docBlock.resize(0);
    g_specialBlock = true;
    current_comment = current;
    startCommentBlock(TRUE);
  }

  static QCString newModule(QCString modnamep) {
    const char *name = modnamep.data();

    return newModule(name);
  }

  static QCString newModule(const char *modname) {
  QCString mname = modname;
  mname = mname.stripWhiteSpace();
  mname = stripQuotes(mname);
  int p = mname.findRev(':');
  if (p >= 0 && mname[p-1] != ':') {
     mname = mname.data()+(p+1);
  }
    if (mname.isEmpty() && current_module) {
        mname = current_module->name;
	}
    if (mname.isEmpty() && current_module_name) {
        mname = current_module_name;
	}

  if (mname.isEmpty()) {
    mname = "prolog";
  }
  return mname.copy();
}

static Entry * createModuleEntry( QCString mname )
{
Entry *newm;
    mname = newModule(mname);
    if (current_root != NULL) {
     if ((newm = g_moduleEntryCache[mname])) {
     return newm;
     }
     }
      // current_root = current;
      newm = newFreeEntry();
       newm->section = Entry::NAMESPACE_SEC;
      newm->type = "module";
      newm->name = mname;
      if (mname[0] == '$')
      newm->protection = Private;
      else
      newm->protection = Public;
    if (current_root != NULL) {
      g_moduleEntryCache.insert(newm->name.copy(), newm);
      current_root->addSubEntry( newm );
      } else {
      current_root = newm;
      }
      assert(newm->name);
      return newm;
}


 static void searchFoundDef() {
    current->fileName = yyFileName;
    current->startLine = yylineno;
    current->bodyLine = yylineno;
    current->section = Entry::CLAUSE_SEC;
    current->protection = Private;
    current->lang = SrcLangExt_Prolog;
    current->virt = Normal;
    current->stat = gstat;
    current->mtype = mtype = Method;
    current->type.resize(0);
    current->name="";
    current->args="";
    current->argList->clear();
    g_packageCommentAllowed = TRUE;
    gstat = FALSE;
  }

  static Entry *buildPredEntry(QCString pname, QCString mod) {
    Entry *newp;
    //  fprintf(stderr,"|| ************* %p %s:\n", parent,
    //  parent->name.data());
    if (current_predicate &&
        mod+"::"+pname == current_predicate->name) {
        return current_predicate;
    }
    if (current_comment) {
      newp = current_comment;
      current_comment = 0;
      return newp;
    } else {
      newp = newFreeEntry();
    }
    newp->argList->clear();
    g_predNameCache.insert(pname, newp);
    newp->section = Entry::CLASS_SEC;
    newp->spec = ClassDef::Predicate;
    newp->type = "predicate";
    newp->name = mod + "::" + pname;
    if (mod == "user" ||
    (mod == "prolog" && pname[0] != '$') )
            newp->protection = Public;
    else
      newp->protection = Private;
    for (uint i = 0; i < ind_arity; i++) {

      char buf[16];
      Argument *a = new Argument;
      snprintf(buf, sizeof(buf), "A%u", i + 1);
      a->name = buf;
      a->type = "Term";
      newp->argList->append(a);
    }
assert(newp->name);
    createModuleEntry(ind_mod)->addSubEntry(newp);
    current_predicate = newp;
//     fprintf(stderr,"|| *************                    <- %p %s||\n" , newp,x newp->name.data());
    return newp;
  }
// normalize
  Entry *predBind(const char * n, const char * module_name, uint arity) {
    // use an hash table to store all predicate calls,
    // so that we can track down arity;
    QCString o, omod;
    uint ar;
    normalizePredName__(module_name, n, arity, omod, o, ar);
    // if we have comments available, it's our chance....
    Entry *e;
    e = buildPredEntry(o+"/"+QCString().setNum(ar), omod);
     current_comment = 0;
    //if (g_specialBlock)
    //  return NULL;
 return e;

  }

  Entry *predBind(const char * key) {
    // use an hash table to store all predicate calls,
    // so that we can track down arity;
    QCString o, omod;
    // if we have comments available, it's our chance....
    Entry *e;
    QCString moa = QCString(key);
    int i = moa.find("::");
    e = buildPredEntry( moa.right(moa.length()-(i+2)), moa.left(i));
     current_comment = 0;
    //if (g_specialBlock)
    //  return NULL;
 return e;

  }

  static void newClause() {
      Entry *op = current_predicate;
      Entry *newp = predBind(current->name, current_module->name,
                           (uint)current->argList->count());
      current_clause = current;
      if (!op || op->name != newp->name ) {
          //          fprintf(stderr, "new %s\n", newp->name.data());
    //   size_t i = current->name.findRev( '_', -1 );
    // current->name.truncate( i );
        newp->bodyLine = newp->endBodyLine = yylineno;
       current_predicate = newp;
    }
#if 0
    current_predicate->addSubEntry(current);
     current->protection = current_predicate->protection;
    newEntry();
       current->bodyLine = current->endBodyLine = yylineno;
#endif
     newp->bodyLine = newp->endBodyLine = yylineno;
 }

  static bool addPredDecl(QCString name) {
    if (current_module== 0) createModuleEntry("user");
    Entry *e = predBind( name, current_module->name, 0);
    e->protection = Public;
    e->section = Entry::CLASS_SEC;
    e->spec = ClassDef::Predicate;
    g_exportNameCache.insert( e->name, e->name.data());
    if (e == current)
        newEntry();
    return true;
  }

    QString getPrologFile(QDir dir, QString file);

  QString checkFile(QFileInfo * finfo, QString file) {
    QString item = finfo->absFilePath(), xabs;
    if (QDir(item).exists())
      item = item;
    else if (QDir(item + ".yap").exists())
      item = item + ".yap";
    else if (QDir(item + ".pl").exists())
      item = item + ".pl";
    else if ((xabs = getPrologFile(QDir(item), file)) != 0)
      item = xabs;
    else
      item = "";
    return item;
  }

  QString getPrologFile(QDir dir, QString file) {
    size_t dabs = dir.canonicalPath().length();
    dir.setFilter(QDir::Dirs);
    const QFileInfoList *list = dir.entryInfoList();
    QFileInfoListIterator it(*list); // create list iterator
    QFileInfo *finfo;                // pointer for traversing

    while ((finfo = it.current())) { // foreach(QFileInfo finfo, list) {

      QString abs = finfo->absFilePath();
      if (abs.length() > dabs) {
        QString xabs;
        if ((xabs = checkFile(finfo, file)).isEmpty()) {
          return xabs;
        }
      }
      ++it;
    }
    return 0;
  }

  const char *fileToModule(QString item) {
    if (item.find("library(") == 0) {
      item = item.mid(8, item.length() - 9).stripWhiteSpace();
      item = getPrologFile(QDir(), item);
      if (item == "0") {
        if (g_system_module)
          item = "prolog";
        else
          item = "user";
      }
    } else {
      item = item.stripWhiteSpace();
      if (QDir("./" + item).exists())
        item = "./" + item;
      else if (QDir("./" + item + ".yap").exists())
        item = "./" + item + ".yap";
      else if (QDir("./" + item + ".pl").exists())
        item = "./" + item + ".pl";
      else
        return "user";
      QDir d = QDir(item);
      d.convertToAbs();
      return d.dirName().data();
    }
    if (QFileInfo(item).exists()) {
      return g_prologFileCache[item.data()];
    }
    if (g_system_module)
      return "prolog";
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
%x Predinfo

			    /* import */
%x Directive
%x ImportList
%x ExportList
%x Import
%x Metas

%x DocBlockShortMsg

%x Indicator

%%

			    /* ------------ Indicator recognition rules -------------- */


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

vvv

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
    current->name.remove(current->name.length()-3,3);
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

    {B}{EOT} {
    current->program+=yytext;
    if (current_clause) {

     if ( current_clause != current)
      current_clause->program+=yytext;
    if (current_clause->section == Entry::CLAUSE_SEC) {
	endOfDef();
}
 g_argLevel = g_callLevel = 0;
 g_arity = 0;
      BEGIN(Search);
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
	  g_headDone = true;
	  BEGIN( HeadOperator );
	}
}
    } else {
      g_argLevel--;
      foundTerm();
    }
  }

")"{B}/[,;\])}] {
  assert ( current_clause );
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
           assert (current_clause );
        current_clause->program+=yytext;
    }

 }

  <FunctionBody>{

  {EOT}         {
    // end of a rule
    assert (current_clause);
 {
      current_clause->program+=yytext;
      if (current_clause->section == Entry::CLAUSE_SEC) {
	endOfDef();
      }
  g_argLevel = g_callLevel = 0;
 g_arity = 0;
     BEGIN(Search);
    }
  }

  <<EOF>>         {
    // end of a rule
    if (current_clause) {
      endOfDef();
    }
    yyterminate();
  }

  {BB}(^{BB}\n)*	      {   // skip spaces
    current_clause->program+=yytext;
  }

  "->"|"*->"|[{};[\]()]             {
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
      foundCall( g_pName  );
     current->name = g_pName;
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
  }

   ("("|"{") { //
    current_clause->program+=yytext;

   }

   (")"|"}"|"]") {
    //
    current_clause->program+=yytext;
 }

 \n       {
   current_clause->program+=yytext;
  }

 .       {
   current_clause->program+=yytext;
 }

 }


<Directive>{

  "module("{B}{ATOM}{B}"," {
      // define/ module  ATOM
    QCString modn = strrchr( yytext, '(')+1;
    modn = modn.remove(modn.length()-1,1);
    g_packageName=modn;
    g_new_module = true;
   current_module = createModuleEntry(modn);
current_module_name = current_module->name;
   g_argLevel = 0;
      BEGIN(ExportList);
  }

 "system_module("{B}{ATOM}{B}"," {
      // define/ module  ATOM
    QCString modn = strrchr( yytext, '(')+1;
    modn = modn.remove(modn.length()-1,1);
    modn = modn.stripWhiteSpace();
    g_packageName=modn;
    g_system_module = true;
    modn = "prolog";
    current_module = createModuleEntry(modn);
current_module_name = current_module->name;

    //BEGIN(ExportList);
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
    createModuleEntry( current->name );
    current_root->addSubEntry( current  );
    current->section=Entry::USINGDECL_SEC;
    newEntry();
    BEGIN(Search);
  }


  ("use_module("|"reexport("){BNS}{LIBRARY}{BNS}","{BNS} {
    g_packageName=yytext;
    QCString item=g_packageName;
    item = removeRedundantWhiteSpace(sliceArgument(item.data(), ',' ));
    if (item.find("library(") == 0) item = item.mid(8,item.length()-9).stripWhiteSpace();
    current->name = fileToModule(item);
    current_root->addSubEntry( current  );
     current->section=Entry::USINGDECL_SEC;
     newEntry();
   BEGIN(Search);
  }

  ("system_")?"module("{BNS}{ATOM}{BNS}"," { // define module  ATOM
     QCString l = yytext;
   if (l.find("system_module") == 0) {
      // newModule(modn.data(), Private);
      QCString modn = "prolog";
      current_module = createModuleEntry(modn);
      current_module_name = current_module->name;
      g_system_module = true;
 BEGIN(ImportList);
    } else {
    QCString modn = l.mid( l.find('('),l.find(')'));
    modn = modn.stripWhiteSpace();
    modn = modn.remove(modn.length()-1,1);
    g_packageName=modn;
    current_module = createModuleEntry(modn);
    current_module_name = current_module->name;
      g_new_module = true;
 BEGIN(ExportList);
    }
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
    current->section=Entry::GROUPDOC_SEC;
    current->startLine = line;
    current->bodyLine  = line;
    current->artificial  = true;
    uint arity = predName.left(slash-(colomn+1)).toUInt();
    Entry *e = predBind( current->name.data(), modName.data(), arity );
    createModuleEntry(ind_mod)->addSubEntry( e  );
    newEntry();
    current->name = funcName;
    current->fileName = fileName;
    current->section=Entry::FUNCTION_SEC;
    current->startLine = line;
    current->bodyLine  = line;
     e->addSubEntry( current  );
   newEntry();
    BEGIN(Search);
  }


  "use_system_module("{B}{LIBRARY}{B}","{B} {
    g_packageName=yytext;
    QCString item=g_packageName;
    current->name =removeRedundantWhiteSpace(sliceArgument(item.data(), ',' ));
      createModuleEntry( current->name );
    current->section=Entry::USINGDECL_SEC;
    newEntry();
    createModuleEntry("prolog");
    BEGIN(ImportList);

  }

  \n		      {
  }

  {EOT}	      {
 g_argLevel = g_callLevel = 0;
 g_arity = 0;
    BEGIN(Search);
  }
"]"?{B}*")"?{B}*{EOT}	      {
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

  {BNS}"]"{BNS}","{BNS}"["{BNS}  {
    if(g_argLevel== 1) {
      g_argLevel = 0;
      BEGIN(Search);
    } else {
      g_argLevel--;
    }
  }

  {BNS}"["{BNS}  {
    g_argLevel += 1;
  }

  {BNS}"]"{BNS}  {
    g_argLevel--;
  }

  {BNS}","{BNS}  {
    /* skip to next entry */
  }

  {INDICATOR}  {
      QCString om, on, key;
      uint arity;
      QCString l = yytext;
      // never trust yytext
           addPredDecl( l );
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



<Indicator>{

    {B}{ATOM}{B}":" {
    // notice that the first rule may match
    // several times.
        ind_mod = QCString(yytext, strlen(yytext)-1);
        ind_mod.stripWhiteSpace();
    }

    {B}{ATOM} {
        ind_name = yytext;
        ind_name.stripWhiteSpace();
        if (ind_name[0] == '\'' &&
            ind_name[ind_name.length()-1] == '\'')
            ind_name = ind_name.mid(1, ind_name.length()-2);
    }

    {B}"/"{B}{INTNUMBER} {
        ind_arity = yytext;
        ind_arity.stripWhiteSpace();
            ind_arity.remove(0,1);
        ind_arity.stripWhiteSpace();
    }

{B} {
     }
<<EOF>>   { yyterminate(); }
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
}

<*>{UONLY} {
    if (current) {
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


<<EOF>>	      {
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

static char symbs[] = "#&*+-./:<=>?@\\^~";

int quoted_end( QCString text, int begin )
{int ch;
    int i = begin+1;
    if (text[begin] != '\'')
      return -1;
    while((ch = text[i++])) {
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

int get_atom(QCString text)
{
  int i = 0, ch = text[i++];
  if (ch == '\0')
    return -1;
  if (ch == '\'') {
    int o = quoted_end( text, 0);
    text = text.mid(1, o-2)+text.left(text.length()-o);
    return o;
  } else if (ch == '(') {
    int o = get_atom(text.data()+(i+1));
    if (o < 0)
      return -1;
    while (isblank(text[o])) o++;
    if(text[o] == ')')
      return o+1;
    return -1;
  } else if (isalpha(ch) || ch == '_' || ch == '$') {
    while (isalnum((ch = text[i++])) || ch == '_');
    return i-1;
  } else if (strchr(symbs, ch)) {
    while ( (ch = text[i++])  != '\0') {
      if (strchr(symbs, ch) == 0)
	break;
    }
    return i-1;
  } else {
    return -1;
  }
 }

static const char * get_module(QCString curMod) {
    const char *s;
  if (curMod.isEmpty()) {
      if (current_module == 0 || current_module->name.isEmpty()) {
	  if (current_module_name.isEmpty()) {
	       current_module->name = current_module_name = QCString( "prolog" );
	  } else {
	      current_module = createModuleEntry(current_module_name);
	      return current_module_name;
	  }
      } else {
	  return current_module_name = current_module->name;
      }
  } else {
     return curMod;
  }
}

extern void mymsg(const char *input);
void mymsg(const char *input) { printf("Got you %s", input ); }

static bool normalizePredName__(QCString curMod, const char *input,
  uint n, QCString &omod, QCString &oname, uint &arity)
  {
    QCString text  = input, txts[2];
    text = text.copy().stripWhiteSpace();
    QCString newE;
    int state = 0, j = 0, i=0;
    bool moreText = true;
    omod = get_module(curMod);
    if (text=="!" || text == "|"||
  text=="prolog:!" || text == "prolog:|")
      { omod = "prolog"; oname = input; arity =0; return true;}
    while (moreText) {
      i = get_atom(text);
      if (i<0) {
        mymsg(input);
        fprintf(stderr,"While scanning %s: needed an atom but got %s \n", input, text.data());
        return false;
      }
      if (i == text.length()) {
        moreText = false;
      } else {
        newE = text.left(i);
        text = text.right(text.length()-i);
        if (newE == ":") {
          if (j==1) {
            omod = txts[0];
            j = 0;
          } else if (j>1) {
            fprintf(stderr,"While scanning %s: needed to do \':\' but had >1 word before %s\n", input, text.data());
            return false;
          }
          state = 1;
        } else if (newE == "//" ||  newE == "/") {
          moreText = false;
        } else {
          txts[j++] = newE;
        }
      }
    }
      if (i == text.length()) {
        oname = text.copy();
        arity = n;
        return true;
      } else {
        if (j == 1) {
          oname = txts[0];
        } else if (j>1) {
          fprintf(stderr,"While scanning %s: needed to do %s but had >1 word after :\n", input, text.data());
          return false;
        }
        arity = text.toUInt();
        if ((int)arity < 0) {
          fprintf(stderr,"While scanning %s: needed a number in %s\n", input, text.data());
          return false;
        }
        if (newE == "//") {
          arity += 2;
          return true;
        }
      }
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
  if (ce->spec == ClassDef::Predicate) s = "PREDICATE_SEC";
  else
    s = "CLASS_SEC";
    break;
   case Entry::PREDICATE_SEC:
      s = "PREDICATE_SEC";
      break;
  case Entry::NAMESPACE_SEC:
    s = "NAMESPACE_SEC";
    break;
  case Entry::CLASSDOC_SEC:
    s = "CLASSDOC_SEC";
    break;
  case Entry::PREDDOC_SEC:
    s = "PREDDOC_SEC";
    ce->protection = Public;
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
v    break;
*/
  case Entry::INCLUDED_SERVICE_SEC:
    s = "INCLUDED_SERVICE";
    break;
  case Entry::CLAUSE_SEC:
    s = "CLAUSE_SEC";
    break;
  }
  if ( ! ce->parent() )
    fprintf(stderr,"%*s (%d) -> %s\n",off+20, s, (ce->protection == Public ? 1 : 0), ce->name.data() /*, ce->program.data() */);
  else
    fprintf(stderr,"%*s (%d) -> %s\n",off+20, s, (ce->protection == Public ? 1 : 0), ce->name.data() /*, ce->program.data() */);
}
#endif

void
showScannerTree(uint off, Entry *current) {
#if DEBUG_ALL
  //return;
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
  g_predNameCache.clear();
  g_moduleEntryCache.clear();
  Entry *oc = current_module;
 printlex(yy_flex_debug, TRUE, __FILE__, fileName);
  ::parseMain(fileName,fileBuf,root);
   showScannerTree(0, root);
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
 Entry *e;
  initParser();

  inputString = fileBuf;
  inputPosition = 0;

  protection    = Private;
  mtype         = Method;
  gstat         = false;
  virt          = Normal;
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

         initParser();
    groupEnterFile(yyFileName,yylineno);

    current_root  = rt;
  current       = new Entry;
    e = current_module;
      current_module = createModuleEntry("prolog");
current_module_name = current_module->name;
  current_predicate = 0;
  current_clause=0;
   {
      current->name    = yyFileName;
      current->section =Entry::SOURCE_SEC;
      current_root->addSubEntry(current);
      current          = new Entry;
    }
       current->reset();
    initEntry( current );

       prologscannerYYrestart( prologscannerYYin );
      BEGIN( Search );
      prologscannerYYlex();
      g_lexInit=TRUE;

current_module = e;
 if (current_module)
 current_module_name =  current_module->name;
      groupLeaveFile(yyFileName,yylineno);

      current_root->program.resize(0);
      current = 0;
      current_root = 0;
      g_firstCall = false;

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

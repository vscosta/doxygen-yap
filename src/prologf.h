/* -----------------------------------------------------------------
 *
 * static
 */

#include "entry.h"
#include "groupdef.h"
#include "membergroup.h"
#include "qfile.h"
#include "qregexp.h"

static ParserInterface *g_thisParser;
static const char *inputString;
static int inputPosition;
int g_ignore;
static QFile inputFile;

static Protection protection;


static Entry *current = 0;
static Entry *current_root = 0;
 Entry *current_predicate = 0;
static Entry *current_comment = 0;
static Entry *previous = 0;
static Entry *bodyEntry = 0;
static int yyLineCms = 0;
static QCString yyFileName;
QCString current_module = 0;
static Entry *current_clause = 0;
static EntryList *g_entries = 0;
static MethodTypes mtype;
static bool gstat;
static Specifier virt;
static bool g_system_module;
static bool g_new_module;
static QCString g_source_module;

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

static bool g_headDone, g_atCall;
static bool g_firstCall = true;

static void parseMain(const char *fileName, const char *fileBuf, Entry *rt);

static void fillArgs();

static QRegExp ra("/[0-9]+$");
static QRegExp rm("^[a-z][a-zA-Z_0-9]*:");
static QRegExp rmq("^'[^']+':");

#define DEBUG_ALL 0

void showScannerTree(uint off, Entry *current);
static void showScannerNode(uint off, Entry *current, bool show);

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

static QCString ind_name, ind_arity;

// We should accept ({atom}":")*{atom}("/"{nat})?
// in this case, as no grouping operators are available
//  we step backwards
//
//

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
  g_predNameCache.setAutoDelete(FALSE);    // this is just a cache
  g_moduleEntryCache.setAutoDelete(FALSE); // this is just a cache
  g_varNameCache.setAutoDelete(FALSE);     // just another cache
}

static void initEntry(Entry *current) {
  // current->prolog = TRUE;
  current->reset();

  current->protection = protection ;
  current->mtype      = mtype;
  current->virt       = virt;
  current->stat       = gstat;
  current->lang       = SrcLangExt_Prolog; 
 g_packageCommentAllowed = TRUE;
  gstat = FALSE;
}

static void newEntry() {
  //        if (current && current->parent())
  //     printf("||%p %s -< %p %s||\n", current->parent(),
  //     current->parent()->name.data() , current, current->name.data() /*,
  //     current->program.data() */);

  // if (current->section!=Entry::PREDDOC_SEC)
  //  current->setParent(current_root);
  // while (current_root->removeSubEntry(current));
  previous = new Entry(*current); 
  previous->setParent(current_root);
  current_root->addSubEntry(previous);
  current->reset();
}


static void foundCall(QCString pname) {
  g_arity = 0;
    Doxygen::docGroup.enterCompound(yyFileName,yylineno,pname);


}

static void doneCall() {

  // current->prolog = TRUE;
  current->mtype = mtype;
  current->virt = virt;
  current->stat = gstat;
  current->lang = SrcLangExt_Prolog;
    gstat = FALSE;
  current->section = Entry::CLASS_SEC;
  current->spec = ClassDef::Predicate;
  current->argList->clear();
  current->type = "predicate";
  current->fileName = yyFileName;
  current->startLine = yylineno;
  //  current->name = Pred(g_source_module, g_name, g_arity);                                                                  
  //g_exportNameCache.insert(current->name, current->type);
  //    current_predicate = current;
}

static void getParameter(QCString s, Argument *arg, Entry *current) {
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
      v = strchr((char *)(arg->name.data()), ':');
      if (v) {
        // got a name and type;
        // skip :
        v += 1;
        arg->type = arg->name.data() + (v - arg->name.data());
        // arg->name.truncate((v-1) - arg->name.data());
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
  int marker = (slashStarComment ? '*' : '%');

  while (true) {
    ch = text[i++];
    if ((ch = text[i]) == ' ') {
      continue;
    }
    if (ch == marker) {
      i++;
      int nch = text[i];
      if (isblank(nch) && nch != '\n')
        return i + 1;
      if (nch == '\0')
        return i;
      return i;
      if (nch == marker)
        continue;
    }
    return 0;
  }
}

typedef enum { BRIEF, BRIEF_EMPTY, BLANK_LINE, DOC } state_t;

static bool prepComment(const char *text, bool &brief, bool slash_star) {

  int follow = (slash_star ? 3 : 2);
  int n, n0 = 0, m;

  docBlock = text + follow;
  if (slash_star)
    docBlock.truncate(docBlock.size() - 2);
  if (docBlock.isEmpty())
    return false;
  docBlock = docBlock.stripWhiteSpace();
  if (docBlock.isEmpty())
    return false;
  n0 = docBlock.size();
  while ((n = docBlock.findRev('\n', n0)) > 0) {
    if ((m = prepLine(docBlock.data() + (n + 1), slash_star))) {
      docBlock = docBlock.remove(n + 1, (m));
    }
    n0 = n - 1;
  }
  return true;
}

static void handleCommentBlock(const QCString &doc, bool brief) {
  // printf("handleCommentBlock(doc=[%s] brief=%d docBlockInBody=%d
  // docBlockJavaStyle=%d\n",
  //	   doc.data(),brief,docBlockInBody,docBlockJavaStyle);
  // newEntry();
  if (doc.isNull() || doc.isEmpty())
    return;
  docBlockInBody = FALSE;
  bool needsEntry = false;
  // this is a name for  anonymous documents.
  int lineNr = brief ? current->briefLine : current->docLine;
  int position = 0;
  QCString preprocessedDoc = preprocessCommentBlock(doc,yyFileName,lineNr);
  while (parseCommentBlock(g_thisParser,
			   (docBlockInBody && previous) ? previous : current,
                           preprocessedDoc,        // text
                           yyFileName, // file
                           lineNr, docBlockInBody ? FALSE : brief,
                           docBlockJavaStyle, // javadoc style // or FALSE,
                           docBlockInBody, protection, position,
                           needsEntry)) // need to start a new entry
    {
      if(needsEntry||true) {
	current->protection = Public;
  Doxygen::docGroup.initGroupInfo(current);
	newEntry();
      }
    }
  if(needsEntry||true) {
    current->protection = Public;
  Doxygen::docGroup.initGroupInfo(current);
    newEntry();
  }
	g_specialBlock = false;
}

static void endOfDef(int correction = 0) {
  // printf("endOfDef at=%d\n",yylineno);
  if (bodyEntry) {
    bodyEntry->endBodyLine = bodyEntry->parent()->endBodyLine =
      yylineno - correction;
    bodyEntry = 0;
  }
  newEntry();
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
  int p = mname.find("::");
  if (p > 0 && mname[p-1]!='(' && mname[p-1]!='\'' )
    mname = mname.left(p-1);
  else {
    int p = mname.find(':');
    if (p > 0 && mname[p - 1] != '(') {
      mname = mname.left(p-1);
    }
  }
  if (mname.isEmpty() && current_module) {
    mname = current_module.stripWhiteSpace().copy();
  }
  return mname.copy();
}

static void createModuleEntry(QCString mname) {
  Entry *newm;
  mname = newModule(mname);
  current->section = Entry::NAMESPACE_SEC;
  current->type = "module";
  current->name = mname;
  if (mname[0] == '$')
    current->protection = Private;
  else
    current->protection = Public;
 newEntry();
  }

static void searchFoundDef() {
  current->fileName = yyFileName;
  current->startLine = yylineno;
  current->bodyLine = yylineno;
  current->spec = ClassDef::Predicate;
  current->type = "predicate";
  current->section = Entry::CLASS_SEC;
  current->protection = Public;
  current->lang = SrcLangExt_Prolog;
  current->virt = Normal;
  current->stat = gstat;
  current->mtype = mtype = Method;
  current->type.resize(0);
  current->name = "";
  current->args = "";
  current->argList->clear();
  //  current_root->addSubEntry(current);
  gstat = FALSE;
}

static void buildPredEntry(Pred p) {
  Entry *newp=current, *ind_mod;
  //  fprintf(stderr,"|| ************* %p %s:\n", parent,
  //  parent->name.data());
  QCString pname = p.predName(),
  mname = p.m;


  //  if ((newp = g_predNameCache[pname])!= 0){
  //    return newp;
  //} else
    
  //newp->argList->clear();
  if (mname == "user" || (mname == "prolog" && pname.find("\'") < 0)) {
    //groupEnterCompound(yyFileName,yylineno,p.predName());
    // groupLeaveCompound(yyFileName,yylineno,p.predName());
    newp->protection = Public;
  }// else
   // newp->protection = Private;
  for (uint i = 0; i < p.a;  i++) {

    char buf[16];
    Argument *a = new Argument;
    snprintf(buf, sizeof(buf), "A%u", i + 1);
    a->name = buf;
    a->type = "Term";
    newp->argList->append(a);
  }
    current_predicate = current;
  newEntry();
}

// normalize

static void newClause() {
    Pred *p = new Pred(g_source_module, current->name,current->argList->count());
      Doxygen::docGroup.leaveCompound(yyFileName,yylineno,current->name);
      current_clause = current;
      g_source_module = current_module;
      // if (!op || op->name != newp->name ) {
      //          fprintf(stderr, "new %s\n", newp->name.data());
      //   size_t i = current->name.findRev( ';
      current->bodyLine = current->endBodyLine = yylineno;
       Doxygen::docGroup.enterCompound(yyFileName,yylineno,current->name);
 
}

static bool addPredDecl(QCString name) {
  int l;
  Entry *e;
  QCString s;
  bool ok;

  Pred p = Pred(name);
  current->protection = Public;
  current->section = Entry::USINGDECL_SEC;
  current->spec = ClassDef::Predicate;
      current->name = p.link();
  g_exportNameCache.insert(current->name, current->name.data());
  newEntry();
  return true;
}


QString getPrologFile(QDir dir, QString file);

QString checkFile(QFileInfo *finfo, QString file) {
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

static QCString symbs = "#&*+;-./:<=>?@\\^~";

int quoted_end(QCString text, int begin) {
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

int get_atom(QCString text) {
  int i = 0, ch, level = 0;
 restart:
  ch = text[i++];
  if (ch == '\0')
    return -1;
  if (ch == '\'') {
    int o = quoted_end(text, i - 1);
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


inline QCString get_module(QCString curMod) {
  const char *s;
  if (curMod.isEmpty()) {
    if (current_module == 0) {
      return QCString("prolog"); 
    } else {
       return  current_module;
    }
  } else {
      return  curMod;
    }
  }

extern void mymsg(const char *input);
void mymsg(const char *input) { /* printf("Got you %s", input );*/
}

bool normalizePredName__(QCString curMod, const char *input, QCString &omod,
                         QCString &oname, uint &arity) {
    QCString text = input, txt;
    text = text.copy().stripWhiteSpace();
    QCString newE;
    int state = 0, j = 0, i = 0;
    bool moreText = true;
    {
        bool ok;
        int p;
        bool underscore_ok = true;

        do {
            if ((p = text.findRev("/")) > 0 && (arity = (text.right(text.length() - p - 2)
                    .toUInt(&ok))) >= 0 && ok) {
                text = text.left(p).stripWhiteSpace();
                underscore_ok = false;
            }
            break;
        } while (false);
    }
    omod = get_module(curMod);
    while (true) {
        i = get_atom(text);
        if (i < 0) {
            i = text.find("::");
            if (i > 0) {
                bool ok;
                QCString left = text.left(i - 1);
                unsigned int p = left.toUInt(&ok);
                if (ok) text = text.right(text.length() - i - 2).stripWhiteSpace();
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
                while ((i = get_atom(text)) > 0) {
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


Pred::Pred(QCString s)
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
 m = g_source_module;
while ((nm=name.find(":"))>=0) {
if (name[nm] == ':' && name[nm+1] != ':' && (nm==0||name[nm-1] != ':')) {
m = name.left(nm-1);
 
name = name.right(name.length()-nm-1);
} else {
break;
}
}
n = name;
//fprintf(stderr, "+++ %s %s/%u\n", m.data(), n.data(), a);

foreign = nullptr;
}

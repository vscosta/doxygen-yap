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
  static Entry *predBind(const char * mod, const char * key);
static Entry *predBind( char const* current, char const* parent, uint arity);

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

  static bool normalizePredName__(QCString curMod, const char *input, QCString &omod, QCString &oname, uint &arity);



QCString normalizePredName(const char *link ) {
  const char *m = "";
  QCString  om, namr, rc;
  uint arity;
    normalizePredName__( m, link, om, namr, arity);
    if (om == "prolog") {
      rc = *new QCString(om);
      rc += "::";
    } else {
      rc = *new QCString("::");

    }
    rc +=  namr + "_" + QCString().setNum(arity);
      return rc;
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
   // predBind( current_module->name,n, g_call->argList->count());
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

  static void linkComment(bool needsNre) {
      if (needsNre) {
      current_root->addSubEntry(current);
      newEntry();
      current_comment = current;
    } else {
      current_comment = current;
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
    if (current_comment &&
	(current_comment->name.isEmpty() || current_comment->name == mod+"::"+pname)) {
      current_comment->name = mod+"::"+pname ;
      newp = current_comment;
      return newp;
    } else {
      newp = newFreeEntry();
    }
    newp->argList->clear();
    newp->section = Entry::CLASS_SEC;
    newp->spec = ClassDef::Predicate;
    newp->type = "predicate";
    newp->name = mod + "::" + pname;
    g_predNameCache.insert(newp->name, newp);
    if (mod == "user" ||
	(mod == "prolog" && pname.find("\'") != 0) )
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
  static Entry *predBind(const char * module_name, const char * n,  uint arity) {
    // use an hash table to store all predicate calls,
    // so that we can track down arity;
      QCString o, omod, l = n;
    uint ar;
      l += "/";
      l += QCString().setNum(arity);
      normalizePredName__(module_name, l, omod, o, ar);
      // if we have comments available, it's our chance....
      Entry *e;
      e = buildPredEntry(o+"_"+QCString().setNum(ar), omod);
      current_comment = 0;
      //if (g_specialBlock)
      //  return NULL;
      return e;

  }

  static Entry *predBind(const char *cmod, const char * key) {
    // use an hash table to store all predicate calls,
    // so that we can track down arity;
    QCString o, omod;
    // if we have comments available, it's our chance....
    Entry *e;
    e = buildPredEntry( cmod, key);
    //if (g_specialBlock)
    //  return NULL;
 return e;

  }

  static void newClause() {
      Entry *op = current_predicate;
      Entry *newp = predBind(current_module->name,current->name,
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
    int l;
    Entry *e;
    QCString s;

    if (current_module== 0) createModuleEntry("user");
    if ((l = name.findRev("//")) > 0 &&
	!(( s = name.right(name.length()-(l+2))).isEmpty()) &&
	s.toUInt() >= 0)
      e = predBind( current_module->name, name.left(l),	s.toUInt()+2);
    else if ((l = name.findRev("/")) > 0 &&
	     !((s = name.right(name.length()-l-1)).isEmpty()) &&
	s.toUInt() >= 0)
      e = predBind( current_module->name, name.left(l),	s.toUInt());
    else
      return false;
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

static QCString symbs = "#&*+;-./:<=>?@\\^~";

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

int get_atom(QCString text, int level)
{
  int i = 0, ch = text[i++];
  if (ch == '\0')
    return -1;
  if (ch == '\'') {
    int o = quoted_end( text, 0);
    return o;
  } else if (ch == '(') {
    int o = get_atom(text.data()+(i+1), level+1);
    if (o < 0)
      return -1;
    while (isblank(text[o])) o++;
    if(text[o] == ')')
      return o+1;
    return -1;
  } else if (isalpha(ch) || ch == '_' || ch == '$') {
    while (isalnum((ch = text[i++])) || ch == '_');
    return i-1;
  }
  if (text[0] == '/' && text[1] == '/')
    return 2;
  if (text[0] == '/')
    return 1;
  i = 0;
  do {
    if (level > 0 && ch == ')')
      return i;
    if (symbs.find( ch) < 0)
      break;
    i++;
    ch = text[i];
  } while (true);
  return i == 0 ? -1 : i;
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
void mymsg(const char *input) {/* printf("Got you %s", input );*/ }

static bool normalizePredName__(QCString curMod, const char *input,
  QCString &omod, QCString &oname, uint &arity)
  {
    QCString text  = input, txts[2];
    text = text.copy().stripWhiteSpace();
    QCString newE;
    int state = 0, j = 0, i=0;
    bool moreText = true;
    omod = get_module(curMod);
    if (text.find("!") == 0 | text.find("prolog:!") == 0)
           { omod = "prolog"; oname = "!"; arity =0; return true;}
    if (text.find(",") == 0 | text.find("prolog:,") == 0)
      { omod = "prolog"; oname = ","; arity =0; return true;}
    if (text.find("::") == 0 | text.find("problog:::") == 0)
      { omod = "problog"; oname = "'::'"; arity =0; return true;}
    while (true) {
      i = get_atom(text, 0);
      if (i<0) {
        mymsg(input);
        fprintf(stderr,"While scanning %s: needed an atom but got %s \n", input, text.data());
        return false;
      }
      newE = (text.left(i));
      text = text.remove(0,i);
      text = text.stripWhiteSpace();
      if (newE == ":") {
          if (j==1) {
	      omod = txts[0];
	      j = 0;
          } else if (j>1) {
	      fprintf(stderr,"While scanning %s: needed to do \':\' but had >1 word before %s\n", input, text.data());
	      return false;
          }

      } else if (newE == "//" ||  newE == "/") {
          moreText = false;
	  oname = txts[0];
	  arity = text.stripWhiteSpace().toUInt();
	  if ((int)arity < 0) {
	     fprintf(stderr,"While scanning %s: %s left-over\n", input,  text.data());
	     return false;
	  }
	  if (newE == "//") {
	      arity += 2;
	  }
	  return true;
      } else {
          txts[j++] = newE;
      }
    }
  }

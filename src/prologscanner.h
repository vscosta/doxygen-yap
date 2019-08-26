/******************************************************************************
 *
 *
 *
 * copyright (C) 1997-2014 by Dimitri van Heesch.
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

#ifndef PROLOGSCANNER_H
#define PROLOGSCANNER_H

#include <iostream>
#include <vector>
#include <string.h>
#include <entry.h>
#include "parserintf.h"

extern bool normalizePredName__(QCString curMod, const char *input,
                                QCString &omod, QCString &oname, uint &arity);

extern Entry *current_predicate;
extern QCString current_module;
extern Entry *current_comment;

extern QDict<QCString> g_predCache;

static void dbg() {}

extern QCString  g_source_module;


class Literal {
public:
typedef  enum {
	       PL_NONE = 0x0,
	       PL_ATOMIC = 0x1,
	       PL_ATOM = 0x2,
	       PL_GOAL = 0x4,
	       PL_ENTER_BRA = 0x8,
	       PL_ENTER_SQB = 0x10,
	       PL_ENTER_CRB = 0x20,
	       PL_ENTER_GOAL = 0x40,
	       PL_ENTER_COMPOUND = 0x80,
	       PL_INNER_BRA = 0x100,
	       PL_INNER_SQB = 0x200,
	       PL_INNER_CRB = 0x400,
	       PL_COMPOUND = 0x800,
	       PL_ENTER_MODULE = 0x1000
} token_t ;

  QCString n, m;
  uint a;
  token_t t;
  
Literal() {
    t = Literal::PL_NONE;
    n = "";
    m =  g_source_module;
    a = 0;
};
  
Literal(token_t t0, QCString m0, QCString n0, uint a0) {
    t = t0;
    n = n0;
    m = m0;
    a = a0;
  }

};

class Clause {
public:
 typedef enum {
	       CLI_NONE,
	       CLI_DIRECTIVE,
	       CLI_HEAD,
	       CLI_NECK,
	       CLI_BODY,
	       FLIT_COMPLETED
  } state_t;
  state_t state;
  QCString text;
  QCString n;
  QCString m;
  uint a;
  std::vector<Literal> q;

    Clause() {
      init();
    };
  
  void init() {
    q = {};
    state = CLI_NONE;
    m = current_module;
    text = n = "";
    a = 0;
      };

    void reset()
    {
      state = CLI_NONE;
      q = {};
      m = current_module;
      text = n = "";
      a = 0;
    };

  int eval();    
};


class Pred
{
  public:
  QCString n, foreign;
  QCString m;
  uint a;

Pred(QCString s);


  Pred(QCString m0, QCString n0, uint a0, QCString *foreign = nullptr)
  {
    valid(n0, "predef");
    n = *new QCString(n0);
        m = *new QCString(m0);
	if (n[0] == '(' && n[m.length()-1] == ')') {
	  n = n.mid(1,n.length()-2);
	  if (n.isEmpty()) n = "''";
	}
	if (n[0] == '\'' && n[m.length()-1] == '\'') {
	  n = n.mid(1,n.length()-2);
	  if (n.isEmpty()) n = "''";
	}
        a = a0;
   }

  bool  valid(QCString &n, QCString s);

  QCString protect(QCString s)
  {
    QCString rc = QCString();
    const char *p = s.data();
    int ch;
    while((ch = *p++)) {
	switch(ch) {
	case '$':
	  rc += "_d";
	case '-':
	  rc += "_y";
	case '\\':
	  rc += "_b";
	case '^':
	  rc += "_a";
	case ':':
	  rc += "_o";
	  break;
	case '_':
	  rc += "_u";
	  break;
	case '.':
	  rc += "_c";
	  break;
	case '?':
	  rc += "_q";
	  break;
	case '!':
	  rc += "_e";
	  break;
	case ' ':
	  rc += "_s";
	  break;
	case ';':
	  rc += "_m";
	  break;
	case '*':
	  rc += "_r";
	  break;
	case '[':
	  rc += "_sqopen";
	  break;
	case ']':
	  rc += "_sqclose";
	  break;
	case '(':
	  rc += "_bopen";
	  break;
	case ')':
	  rc += "_bclose";
	  break;
	case '{':
	  rc += "_clyopen";
	  break;
	case '}':
	  rc += "_clyclose";
	  break;
	case '\'':
	  rc += "_q";
	  break;
	case '`':
	  rc += "_bq";
	  break;
	case '"':
	  rc += "_dq";
	  break;
	case '~':
	  rc += "_t";
	  break;
	case '#':
	  rc += "_C";
	  break;
	case '&':
	  rc += "_m";
	  break;
	case '%':
	  rc += "_p";
	  break;
	case '=':
	  rc += "_eq";
	  break;
	case '>':
	  rc += "_gt";
	  break;
	case '<':
	  rc += "_lt";
	  break;
	default:
	  rc += ch;
	}
    }
    return rc;
  }



  QCString link()
  {
//      if (m == current_module || m->name == "prolog")
    return (n+"/"+QCString().setNum(a) );
//      else
//          return n+QCString().setNum(a);
  }

QCString title()
  {
    return link();

    }

QCString predName()
  {

    //      if (m == current_module || "prolog")
    //return n+"/"+QCString().setNum(a);
	  //  else
          //return m+":"+n+"/"+QCString().setNum(a);
    return link();
  }


  QCString label() {
      return link();
  }
};

extern void parsePrologCode(CodeOutputInterface &od,const char *className,
                     const QCString &s,bool exBlock, const char *exName,
                      FileDef *fd,int startLine,int endLine,bool inlineFragment,
                     const MemberDef *,bool,const Definition *searchCtx,bool collectXrefs);

/** \brief Prolog Language parser using state-based lexical scanning.
 *
 * This is the Prolog language parser for doxygen.
 */
class PrologLanguageScanner : public ParserInterface
{
public:
  virtual ~PrologLanguageScanner() {}
  void startTranslationUnit(const char *) {}
  void finishTranslationUnit() {}
  void parseInput(const char *fileName, const char *fileBuf, Entry *root,
                  bool sameTranslationUnit,
                  QStrList &filesInSameTranslationUnit);
  bool needsPreprocessing(const QCString &extension);
    void parseCode(CodeOutputInterface &codeOutIntf,
                   const char *scopeName,
                   const QCString &input,
		    SrcLangExt lang,
                   bool isExampleBlock,
                   const char *exampleName=0,
                    FileDef *fileDef=0,
                   int startLine=-1,
                   int endLine=-1,
                   bool inlineFragment=FALSE,
                   const MemberDef *memberDef=0,
                   bool showLineNumbers=TRUE,
                   const Definition *searchCtx=0,
                   bool collectXrefs=TRUE
    );
  void resetCodeParserState() {};
  void parsePrototype(const char *text);
  bool valid();
};

extern void plscanFreeScanner();
extern Entry *predBind(Pred);

extern QDict<char> g_foreignCache;

inline bool isIndicator(QCString src) {
    if (src.isEmpty())
    return false;
  int i, l = src.length();
  int ch;
  if ((i = src.findRev('/')) < 0)
        return false;
  bool ok = false;
  uint a = src.right(src.length()-i-1).toUInt(&ok);
  return ok && a< 32;
}

#endif

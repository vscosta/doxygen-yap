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
#include <string.h>
#include "parserintf.h"

extern bool normalizePredName__(QCString curMod, const char *input,
                                QCString &omod, QCString &oname, uint &arity);

  extern QCString current_module_name;

static void dbg() {}

class Pred
{
  public:
  QCString m, n, foreign;
  uint a;

Pred(QCString s);


  Pred(QCString m0, QCString n0, uint a0, QCString *foreign = nullptr)
  {
        n = *new QCString(n0);
        m = *new QCString(m0);
        a = a0;
   }


  QCString link()
  {
      if (m == current_module_name || m == "prolog")
          return n+"/"+QCString().setNum(a);
      else
          return m+":"+n+"/"+QCString().setNum(a);
  }

QCString title()
  {
      if (m == current_module_name || m == "prolog")
      return n+"/"+QCString().setNum(a);
          else
             return m+":"+n+"/"+QCString().setNum(a);
    }

QCString predName()
  {
      if (m == current_module_name || m == "prolog")
          return n+"/"+QCString().setNum(a);
      else
          return m+":"+n+"/"+QCString().setNum(a);
  }


  QCString label() {
      return title();
  }
};


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
  void parseCode(CodeOutputInterface &codeOutIntf, const char *scopeName,
                 const QCString &input, SrcLangExt lang, bool isExampleBlock,
                 const char *exampleName = 0, FileDef *fileDef = 0,
                 int startLine = -1, int endLine = -1,
                 bool inlineFragment = FALSE, MemberDef *memberDef = 0,
                 bool showLineNumbers = TRUE, Definition *searchCtx = 0,
                 bool collectXrefs = TRUE);
  void resetCodeParserState();
  void parsePrototype(const char *text);
};

void plscanFreeScanner();

extern QDict<char> g_foreignCache;
extern QCString source_module;

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

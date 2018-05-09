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

#ifndef PROLOGSCANNER_H
#define PROLOGSCANNER_H

#include "parserintf.h"

/** \brief Prolog Language parser using state-based lexical scanning.
 *
 * This is the Prolog language parser for doxygen.
 */
class PrologLanguageScanner : public ParserInterface {
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
extern QCString source_module ;

inline QCString mkPrologLink(QCString source, QCString m, QCString n, uint a)
{
  QCString out = "", content, title;
 out = "[" + source + "](" + m +"::" + n + "/" + QCString().setNum(a) +")";
 return out;
}


inline int left_scan( const char *text )
{
  int i = 0; int ch;
  while ((ch = text[i++]) == ' ' || ch == '\t');
  if (text[i] == '(') {
    i ++;
    while (text[i++] != ')');
  } else   if (text[i] == '"') {
    i ++;
    while (text[i++] != '"');
  }
  return i;
}

inline int right_scan( const char *text )
{
  int i = strlen( text ); int ch;
  while ((ch = text[--i]) == ' ' || ch == '\t');
  /* brackets */
  if (text[i] == '(') {
    while (text[--i] != ')');
    return i;
  } else   if (text[i] == '"') {
    i ++;
    while ( text[--i] != '"');
    return i;
  } else
    return i+1;
}



extern QCString current_module_name;
extern bool g_insideProlog;

extern bool normalizeAndSplitIndicator( const char *link,QCString &om,   QCString &on, uint &arity);
extern bool normalizeAndSplitIndicator( const char *link,QCString &om,   QCString &on);
extern bool normalizeIndicator(const char *link, QCString &out);

extern char *getPredLineCallArity(QCString clName, QCString file, uint lin, QCString &om);

inline bool
isPrologLink(QCString link, QCString &m, QCString &n, uint &a)
{
  uint len = link.length();

  if ( link[len - 1] >= '0' &&
       link[len - 1] <= '9' &&
       (
	link[len - 2] == '/' || (link[len - 2] >= '0' &&
				 link[len - 2] <= '9' &&
				 link[len - 3] == '/')
	)
       )
      {
	int ms = link.find("::");
	QCString o = link.copy();
	  
	if (ms < 0)
	  return false;
	int ns = o.findRev("/");
	if (ns < 0)
	  return false;	
	m = o.left(ms);
	n = o.mid(ms + 2, ns-ms-2);
	a = o.right(o.length()-ns-1).toUInt();
	return (int)a > 0;
      }
}

#endif

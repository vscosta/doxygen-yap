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

#include <qcstring.h>

#include <iostream>
#include <string.h>
#include "parserintf.h"

/** \brief Prolog Language parser using state§  1-based lexical scanning.
 *
 * This is the Prolog language parser for doxygen.
 */
class PrologOutlineParser : public OutlineParserInterface
{
  public:
    PrologOutlineParser();
    virtual ~PrologOutlineParser();
    void parseInput(const QCString & fileName,
                    const char *fileBuf,
                    const std::shared_ptr<Entry> &root,
                    ClangTUParser *clangParser);
    bool needsPreprocessing(const QCString &extension) const;
    void parsePrototype(const QCString &text);
  private:
    struct Private;
    std::unique_ptr<Private> p;
};

#endif

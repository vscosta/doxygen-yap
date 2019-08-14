/******************************************************************************
 *
 * 
 *
 * Copyright (C) 1997-2015 by Dimitri van Heesch.
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

#ifndef PAGEDEF_H
#define PAGEDEF_H

#include "definition.h"
#include "sortdict.h"

class PageSDict;
class OutputList;
class FTextStream;

/** @brief A model of a page symbol. */
class PageDef : virtual public Definition
{
  public:
    virtual ~PageDef() {}

    // setters
    virtual void setFileName(const char *name) = 0;
    virtual void setLocalToc(const LocalToc &tl) = 0;
    virtual void setShowLineNo(bool) = 0;

    // getters
    virtual DefType definitionType() const = 0;
    virtual bool isLinkableInProject() const = 0;
    virtual bool isLinkable() const = 0;
    virtual QCString getOutputFileBase() const = 0;
    virtual QCString anchor() const = 0;
    virtual void findSectionsInDocumentation() = 0;
    virtual QCString title() const = 0;
    virtual GroupDef *  getGroupDef() const = 0;
    virtual PageSDict * getSubPages() const = 0;
    virtual void addInnerCompound(Definition *d) = 0;
    virtual bool visibleInIndex() const = 0;
    virtual bool documentedPage() const = 0;
    virtual bool hasSubPages() const = 0;
    virtual bool hasParentPage() const = 0;
    virtual bool hasTitle() const = 0;
    virtual LocalToc localToc() const = 0;
    virtual void setPageScope(Definition *d) = 0;
    virtual Definition *getPageScope() const = 0;
    virtual QCString displayName(bool=TRUE) const = 0;
    virtual bool showLineNo() const = 0;

    virtual void writeDocumentation(OutputList &ol) = 0;
    virtual void writeTagFile(FTextStream &) = 0;
    virtual void setNestingLevel(int l) = 0;
    virtual void writePageDocumentation(OutputList &ol) = 0;

};

PageDef *createPageDef(const char *f,int l,const char *n,const char *d,const char *t);

class PageSDict : public SDict<PageDef>
{
  public:
    PageSDict(int size) : SDict<PageDef>(size) {}
    virtual ~PageSDict() {}
  private:
    int compareValues(const PageDef *i1,const PageDef *i2) const
    {
      return qstricmp(i1->name(),i2->name());
    }
};

#endif


/******************************************************************************
*
* Copyright (C) 1997-2019 by Dimitri van Heesch.
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

#ifndef DOTNODE_H
#define DOTNODE_H

#include "sortdict.h"

#include "dotgraph.h"

class ClassDef;
class DotNodeList;
class FTextStream;

/** Attributes of an edge of a dot graph */
class EdgeInfo
{
  public:
    enum Colors { Blue=0, Green=1, Red=2, Purple=3, Grey=4, Orange=5, Orange2=6 };
    enum Styles { Solid=0, Dashed=1 };
    EdgeInfo(int color,int style,const QCString &lab,const QCString &url,int labColor) 
        : m_color(color), m_style(style), m_label(lab), m_url(url), m_labColor(labColor) {}
    ~EdgeInfo() {}
    int color() const      { return m_color; }
    int style() const      { return m_style; }
    QCString label() const { return m_label; }
    QCString url() const   { return m_url; }
    int labelColor() const { return m_labColor; }
  private:
    int m_color;
    int m_style;
    QCString m_label;
    QCString m_url;
    int m_labColor;
};

/** A node in a dot graph */
class DotNode
{
  public:
    static void deleteNodes(DotNode* node, SDict<DotNode>* skipNodes = 0);
    static QCString convertLabel(const QCString& l);
    DotNode(int n,const char *lab,const char *tip,const char *url,
        bool rootNode=FALSE,const ClassDef *cd=0);
    ~DotNode();

    enum TruncState { Unknown, Truncated, Untruncated };

    void addChild(DotNode *n,
                  int edgeColor=EdgeInfo::Purple,
                  int edgeStyle=EdgeInfo::Solid,
                  const char *edgeLab=0,
                  const char *edgeURL=0,
                  int edgeLabCol=-1);
    void addParent(DotNode *n);
    void deleteNode(DotNodeList &deletedList,SDict<DotNode> *skipNodes=0);
    void removeChild(DotNode *n);
    void removeParent(DotNode *n);
    int  findParent( DotNode *n );

    void write(FTextStream &t,GraphType gt,GraphOutputFormat f,
               bool topDown,bool toChildren,bool backArrows) const;
    void writeXML(FTextStream &t,bool isClassGraph) const;
    void writeDocbook(FTextStream &t,bool isClassGraph) const;
    void writeDEF(FTextStream &t) const;
    void writeBox(FTextStream &t,GraphType gt,GraphOutputFormat f,
                  bool hasNonReachableChildren) const;
    void writeArrow(FTextStream &t,GraphType gt,GraphOutputFormat f,const DotNode *cn,
                    const EdgeInfo *ei,bool topDown, bool pointBack=TRUE) const;

    QCString label() const         { return m_label; }
    int  number() const            { return m_number; }
    bool isVisible() const         { return m_visible; }
    TruncState isTruncated() const { return m_truncated; }
    int distance() const           { return m_distance; }
    int subgraphId() const         { return m_subgraphId; }
    bool isRenumbered() const      { return m_renumbered; }
    bool hasDocumentation() const  { return m_hasDoc; }
    bool isWritten() const         { return m_written; }

    void clearWriteFlag();
    void renumberNodes(int &number);
    void markRenumbered()          { m_renumbered = true; }
    void markHasDocumentation()    { m_hasDoc = true; }
    void setSubgraphId(int id)     { m_subgraphId = id; }

    void colorConnectedNodes(int curColor);
    void setDistance(int distance);
    const DotNode *findDocNode() const; // only works for acyclic graphs!
    void markAsVisible(bool b=TRUE) { m_visible=b; }
    void markAsTruncated(bool b=TRUE) { m_truncated=b ? Truncated : Untruncated; }
    const QList<DotNode> *children() const { return m_children; }
    const QList<DotNode> *parents() const { return m_parents; }
    const QList<EdgeInfo> *edgeInfo() const { return m_edgeInfo; }

  private:
    int              m_number;
    QCString         m_label;     //!< label text
    QCString         m_tooltip;   //!< node's tooltip
    QCString         m_url;       //!< url of the node (format: remote$local)
    QList<DotNode>  *m_parents;   //!< list of parent nodes (incoming arrows)
    QList<DotNode>  *m_children;  //!< list of child nodes (outgoing arrows)
    QList<EdgeInfo> *m_edgeInfo;  //!< edge info for each child
    bool             m_deleted;   //!< used to mark a node as deleted
    mutable bool     m_written;   //!< used to mark a node as written
    bool             m_hasDoc;    //!< used to mark a node as documented
    bool             m_isRoot;    //!< indicates if this is a root node
    const ClassDef * m_classDef;  //!< class representing this node (can be 0)
    bool             m_visible;   //!< is the node visible in the output
    TruncState       m_truncated; //!< does the node have non-visible children/parents
    int              m_distance;  //!< shortest path to the root node
    bool             m_renumbered;//!< indicates if the node has been renumbered (to prevent endless loops)
    int              m_subgraphId;
};

/** Class representing a list of DotNode objects. */
class DotNodeList : public QList<DotNode>
{
  public:
    DotNodeList() : QList<DotNode>() {}
    ~DotNodeList() {}
  private:
    int compareValues(const DotNode *n1,const DotNode *n2) const;
};

#endif

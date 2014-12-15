/* Generated By:JavaCC: Do not edit this line. TokenManager.h Version 6.2 */
/* JavaCCOptions:STATIC=false,SUPPORT_CLASS_VISIBILITY_PUBLIC=true */
#ifndef TOKENMANAGER_H
#define TOKENMANAGER_H
#include "JavaCC.h"
#include "Token.h"

using namespace std;

namespace vhdl {
namespace parser {
/**
 * An implementation for this interface is generated by
 * JavaCCParser.  The user is free to use any implementation
 * of their choice.
 */

class TokenManager {
public:
  /** This gets the next token from the input stream.
   *  A token of kind 0 (<EOF>) should be returned on EOF.
   */
  virtual       ~TokenManager() { }
  virtual Token *getNextToken() = 0;
  virtual void   lexicalError() {
  }

};

}
}
#endif
/* JavaCC - OriginalChecksum=918e2eba53e028d6c4142283ce3f498f (do not edit this line) */

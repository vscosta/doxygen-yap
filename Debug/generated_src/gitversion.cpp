#include <string.h>
#include <version.h>

/* - On some systems git is not installed or
 *   installed on a place where FindGit.cmake cannot find it
 * - No git information is present (no .git directory)
 * in those cases clear the gitVersionString (would have string GIT-NOTFOUND).
 */
const char *getGitVersion(void)
{
#define BUF_SIZE 100
  static char gitVersionString[BUF_SIZE];
  static bool init = false;
  if (!init)
  {
    strncpy(gitVersionString,"f2098cbbd5f0d80f5e20f4c08c4df447dd9c6cdc",BUF_SIZE-1);
    strncat(gitVersionString,!strcmp("true","true")?"*":"",BUF_SIZE-1);
    if (!strcmp("f2098cbbd5f0d80f5e20f4c08c4df447dd9c6cdc", "GIT-NOTFOUND")) gitVersionString[0] = '\0';
    gitVersionString[BUF_SIZE-1]='\0';
    init = true;
  }
  return gitVersionString;
}

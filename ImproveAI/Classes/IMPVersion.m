#import "IMPVersion.h"

#define STR(x) STR_EXPAND(x)
#define STR_EXPAND(x) #x

NSString* IMPImproveAIVersion(void) {
  return @STR(ImproveAI_VERSION);
}

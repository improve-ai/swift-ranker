//
//  improve_ai_version.c
//  
//
//  Created by Hongxi Pan on 2023/5/5.
//

#include <stdio.h>

#define STR(x) STR_EXPAND(x)
#define STR_EXPAND(x) #x

const char* improve_ai_version() {
    return STR(ImproveAI_VERSION);
}


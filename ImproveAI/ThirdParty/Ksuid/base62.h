//
//  base62.h
//  ImproveUnitTests
//
//  Created by PanHongxi on 11/4/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#ifndef base62_h
#define base62_h

#include <stdint.h>

int ksuid_b62_encode(char *dst, size_t dst_size, const unsigned char *src, size_t src_size);

#endif /* base62_h */

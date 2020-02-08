//
//  TestUtils.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/2/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

// Helper utilities for testing.

#include <math.h>

#ifndef TestUtils_h
#define TestUtils_h

NS_INLINE BOOL __attribute__((overloadable)) isEqualRough(double fl1, double fl2) {
    const double precision = 0.001;
    if (fl1 == fl2) {
        return YES;
    } if (fl1 == 0. || fl2 == 0.) {
        return ABS(fl1 - fl2) < precision;
    } else if (fl1 > fl2) {
        return (ABS(fl1 / fl2) - 1.) < precision;
    } else {
        return (ABS(fl2 / fl1) - 1.) < precision;
    }
}

NS_INLINE BOOL __attribute__((overloadable)) isEqualRough(int count, double *buf1, double *buf2) {
    for (int i = 0; i < count; i++) {
        if (!isEqualRough(*(buf1 + i), *(buf2 + i))) {
            return NO;
        }
    }
    return YES;
}

#endif /* TestUtils_h */

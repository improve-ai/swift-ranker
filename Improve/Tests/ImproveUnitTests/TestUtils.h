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

NS_INLINE BOOL isEqualRough(double fl1, double fl2) {
    const double precision = 0.001;
    if (fl1 == fl2) {
        return YES;
    } if (fl1 == 0 || fl2 == 0) {
        return ABS(fl1 - fl2) < precision;
    } else if (fl1 >= fl2) {
        return (ABS(fl1 / fl2) - 1) < precision;
    } else {
        return (ABS(fl2 / fl1) - 1) < precision;
    }
}

/**
 A combination of subtractiong a constant and sigmoid. Intended to fix incorrect output from MLModel in order to make it the same
 as output form XGBoost Booster.
 */
NS_INLINE double sigmfix(double x) {
  return 1. / (1. + exp(0.5 - x));
}

#endif /* TestUtils_h */

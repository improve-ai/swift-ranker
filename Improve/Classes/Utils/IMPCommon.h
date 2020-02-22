//
//  IMPCommon.h
//  Tests
//
//  Created by Vladimir on 2/7/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef IMPCommon_h
#define IMPCommon_h

/**
 @param object An Objective-C object.
 @param cl Objective-C class. Call [Type class] to get it.
 @param caller A caller function for logging.
 @return Returns `obj` if it is kind of `cl` otherwise logs error and returns nil.
 */
NS_INLINE id insureClass(id object, Class cl, SEL caller) {
    if ([object isKindOfClass:cl]) {
        return object;
    } else {
        NSLog(@"%@ wrong object in variants dictionary: %@ /nExpected %@", NSStringFromSelector(caller), object, NSStringFromSelector(caller));
        return nil;
    }
}

// Next macros are useful for logging.
// In a format like (@"-[%@ %@]: ...", CLASS_S, CMD_S)
#define CLASS_S NSStringFromClass(self.class)
#define CMD_S NSStringFromSelector(_cmd)


#define INSURE_CLASS(obj, cl) insureClass(obj, cl, _cmd)

#endif /* IMPCommon_h */

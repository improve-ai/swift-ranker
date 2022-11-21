//
//  ksuid.h
//  ImproveUnitTests
//
//  Created by PanHongxi on 11/4/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#ifndef ksuid_h
#define ksuid_h

#include <stdio.h>

// Base62 representation is always of length 27
#define KSUID_STRING_LENGTH 27

#define EPOCH_TIME 1400000000

#define KSUID_TIME_STAMP_LENGTH 4

#define KSUID_PAYLOAD_LENGTH 16

#define KSUID_BYTES_LENGTH (KSUID_TIME_STAMP_LENGTH+KSUID_PAYLOAD_LENGTH)

int ksuid(unsigned char buf[KSUID_BYTES_LENGTH+1]);

int ksuid_with_ts_and_payload(int64_t ts, uint8_t payload[KSUID_PAYLOAD_LENGTH],
                               char data[KSUID_STRING_LENGTH+1]);

#endif /* ksuid_h */

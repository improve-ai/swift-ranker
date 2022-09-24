//
//  ksuid.c
//  ImproveUnitTests
//
//  Created by PanHongxi on 11/4/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//
#include <stdlib.h>
#include <time.h>
#include <string.h>

#import <Security/SecRandom.h>

#include "ksuid.h"
#include "base62.h"

// big endian
void encode_timestamp(time_t t, uint8_t *buf) {
    buf[0] = (t >> 24) & 0xff;
    buf[1] = (t >> 16) & 0xff;
    buf[2] = (t >> 8) & 0xff;
    buf[3] = t & 0xff;
}

int ksuid_with_ts_and_payload(int64_t ts, uint8_t payload[KSUID_PAYLOAD_LENGTH],
                              char data[KSUID_STRING_LENGTH+1]) {
    uint8_t buf[KSUID_BYTES_LENGTH];
    
    // encode timestamp
    uint64_t corrected_ts = (uint64_t)(ts - EPOCH_TIME);
    encode_timestamp(corrected_ts, buf);
    
    // copy payload
    memcpy(buf+KSUID_TIME_STAMP_LENGTH, payload, KSUID_PAYLOAD_LENGTH);
    
    // base62 representation
    ksuid_b62_encode(data, KSUID_STRING_LENGTH, buf, KSUID_BYTES_LENGTH);
    
    return 0;
}

int ksuid(char data[KSUID_STRING_LENGTH+1]) {
    uint8_t payloadBuf[KSUID_PAYLOAD_LENGTH];
    
    int status = SecRandomCopyBytes(kSecRandomDefault, KSUID_PAYLOAD_LENGTH, payloadBuf);
    if(status != errSecSuccess) {
        return -2;
    }
    
    return ksuid_with_ts_and_payload(time(0), payloadBuf, data);
}

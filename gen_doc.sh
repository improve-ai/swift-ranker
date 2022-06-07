#!/bin/bash
sourcekitten doc --objc ImproveAI/include/ImproveAI/ImproveAI.h -- -x objective-c -isysroot $(xcrun --show-sdk-path) -I$(pwd) > core.json
sourcekitten doc --single-file ImproveAISwift/ImproveAI.swift -- -j4 ImproveAISwift/ImproveAI.swift > swift.json
jazzy \
    --sdk iphoneos \
    --author ImproveAI \
    --author_url https://improve.ai \
    --source-host github \
    --source-host-url https://github.com/improve-ai/ios-sdk \
    --theme apple \
    --sourcekitten-sourcefile core.json,swift.json

rm core.json swift.json

#!/bin/bash

# Run Swift tests
xcodebuild test -scheme ImproveAI -sdk iphonesimulator -destination "platform=iOS Simulator,OS=15.5,name=iPhone 12"


#!/bin/bash

# Run Swift tests
xcodebuild test -scheme ImproveAI -sdk iphonesimulator -destination "name=iPhone 12"

read -p "Press enter to continue"

# Run Objective C tests
xcodebuild test -project ImproveAI/Tests/Tests.xcodeproj -scheme ImproveUnitTests -destination 'name=iPhone 12'

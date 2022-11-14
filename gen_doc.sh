#!/bin/bash
build_docs_objc() {
    mv .jazzy.yaml tmp
    jazzy \
        --objc \
        --sdk iphoneos \
        --clean \
        --author ImproveAI \
        --author_url https://improve.ai \
        --github_url https://github.com/improve-ai/ios-sdk \
        --module-version 7.1 \
        --umbrella-header ImproveAI/include/ImproveAI/ImproveAI.h \
        --framework-root . \
        --module ImproveAI \
        --title "Improve AI iOS SDK(7.2.0)" \
        --output docs/objc
    mv tmp .jazzy.yaml
}

# The arguments used to generate doc for Swift contains a comma("platform=iOS Simulator,OS=15.5,name=iPhone 12")
# which seems can not be properly parsed when run in command line. So arguments
# used to generate Swift doc are placed in the default config file .jazzy.yaml.
# https://github.com/realm/jazzy/issues/651
build_docs_swift() {
    jazzy
}

build_docs_objc
build_docs_swift

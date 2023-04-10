
# The arguments used to generate doc for Swift contains a comma("platform=iOS Simulator,OS=15.5,name=iPhone 12")
# which seems can not be properly parsed when run in command line. So arguments
# used to generate Swift doc are placed in the default config file .jazzy.yaml.
# https://github.com/realm/jazzy/issues/651
build_docs_swift() {
    jazzy
}

build_docs_swift

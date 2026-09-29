APP := build/Doit.app
# The default swift-build system fails without Xcode; native works with Command Line Tools
SWIFT_FLAGS := --build-system native

# Command Line Tools ship swift-testing outside the default framework search path, and the
# macOS 27 SDK implements @State as a macro whose plugin only ships with Xcode
ifeq ($(shell xcode-select -p),/Library/Developer/CommandLineTools)
FW := /Library/Developer/CommandLineTools/Library/Developer/Frameworks
TEST_FLAGS := -Xswiftc -F$(FW) -Xlinker -F$(FW) -Xlinker -rpath -Xlinker $(FW)
SDK26 := $(wildcard /Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk)
ifneq ($(SDK26),)
export SDKROOT := $(SDK26)
endif
endif

.PHONY: app run test install clean

app:
	swift build $(SWIFT_FLAGS) -c release
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp .build/release/Doit $(APP)/Contents/MacOS/
	cp Resources/Info.plist $(APP)/Contents/
	codesign --force --sign - $(APP)

run: app
	open $(APP)

test:
	swift test $(SWIFT_FLAGS) $(TEST_FLAGS)

install: app
	rm -rf /Applications/Doit.app
	cp -R $(APP) /Applications/

clean:
	rm -rf .build build

help: ##@Helper Display all commands and descriptions
	@printf "\n"
	@awk 'BEGIN {FS = ":.*##@"} \
	/^[.a-zA-Z_-]+:.*?##@/ { \
		split($$2, parts, " "); \
		section = parts[1]; \
		description = substr($$2, length(section) + 2); \
		sections[section] = sections[section] sprintf("\033[36m%-15s\033[0m %s\n", $$1, description); \
	} \
	END { \
		for (section in sections) { \
			printf "\033[1m%s\033[0m\n", section; \
			printf "%s\n", sections[section]; \
		} \
	}' $(MAKEFILE_LIST)

build: ##@App Build the app (Release)
	./build.sh build

build-release: build ##@App Build the app (Release - alias)

build-debug: ##@App Build the app (Debug)
	@echo "Building AltTab (Debug)..."
	cd AltTab && xcodebuild -project AltTab.xcodeproj -scheme AltTab -configuration Debug -derivedDataPath build clean build 2>&1 | grep -E 'error:|SUCCEEDED' || true
	@echo "Debug build complete: AltTab/build/Build/Products/Debug/AltTab.app"

test: ##@Testing Run unit tests
	@echo "Running unit tests..."
	cd AltTab && xcodebuild test -project AltTab.xcodeproj -scheme AltTab -configuration Debug -destination 'platform=macOS' -enableCodeCoverage YES 2>&1 | grep -E 'Test Suite|Test Case|error:|FAILED|SUCCEEDED' || true

test-coverage: ##@Testing Run tests with code coverage report
	@echo "Running tests with coverage..."
	@rm -rf AltTab/build/coverage.xcresult
	cd AltTab && xcodebuild test -project AltTab.xcodeproj -scheme AltTab -configuration Debug -destination 'platform=macOS' -enableCodeCoverage YES -resultBundlePath build/coverage.xcresult 2>&1 | grep -E 'Test Suite|Test Case|error:|FAILED|SUCCEEDED' || true
	@echo ""
	@echo "Coverage report:"
	@xcrun xccov view --report AltTab/build/coverage.xcresult 2>/dev/null || echo "No coverage data found"

lint: ##@Quality Run SwiftLint
	@echo "Running SwiftLint..."
	swiftlint lint --config .swiftlint.yml --strict 2>&1

install: ##@App Install the app
	./build.sh install

run: ##@App Run the app (Release)
	@echo "Launching AltTab..."
	open "AltTab/build/Build/Products/Release/AltTab.app"

run-release: run ##@App Run the app (Release - alias)

run-debug: build-debug ##@App Run in debug mode with logging
	@echo "Stopping any running instances..."
	@pkill -9 AltTab 2>/dev/null || true
	@sleep 0.5
	@rm -f /tmp/alttab-debug.log
	@echo "Starting AltTab in debug mode (logging to /tmp/alttab-debug.log)..."
	@echo "Press Ctrl+C to stop tailing (app will keep running)"
	@AltTab/build/Build/Products/Debug/AltTab.app/Contents/MacOS/AltTab > /tmp/alttab-debug.log 2>&1 &
	@echo "AltTab started (PID: $$!). Logs: /tmp/alttab-debug.log"
	@sleep 1
	@tail -f /tmp/alttab-debug.log

logs: ##@Debug Show debug logs
	@tail -f /tmp/alttab-debug.log

clean: ##@App Clean build artifacts
	./build.sh clean

reset-perms: ##@Debug Deep clean TCC cache and build artifacts
	@echo "Killing AltTab..."
	@pkill -9 AltTab 2>/dev/null || true
	@sleep 0.5
	@echo "Resetting TCC permissions..."
	tccutil reset ScreenCapture com.alttab.app 2>/dev/null || echo "  (not in TCC database yet)"
	tccutil reset Accessibility com.alttab.app 2>/dev/null || echo "  (not in TCC database yet)"
	@sleep 1
	@echo "Cleaning build directory..."
	@rm -rf AltTab/build
	@echo "Done. Run 'make run-debug' next."

reset-perms-deep: ##@Debug Deep clean TCC cache and build artifacts
	@echo "Killing AltTab..."
	@pkill -9 AltTab 2>/dev/null || true
	@sleep 0.5
	@echo "Resetting TCC permissions..."
	@tccutil reset ScreenCapture com.alttab.app 2>/dev/null || echo "  (not in TCC database yet)"
	@tccutil reset Accessibility com.alttab.app 2>/dev/null || echo "  (not in TCC database yet)"
	@echo "Clearing TCC ad-hoc signature cache..."
	@rm -rf ~/Library/Application\ Support/com.apple.TCC/AdhocSignatureCache/* 2>/dev/null || true
	@echo "Restarting TCC daemon..."
	@sudo killall -9 tccd 2>/dev/null || true
	@sleep 1
	@echo "Cleaning build directory..."
	@rm -rf AltTab/build
	@rm -rf ~/Library/Developer/Xcode/DerivedData/AltTab-* 2>/dev/null || true
	@echo "Done. Run 'make run-debug' next."

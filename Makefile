RELEASE_BUILD=./.build/apple/Products/Release
EXECUTABLE=stack-cli
ARCHIVE=$(EXECUTABLE).tar.gz

.PHONY: clean build-release package

build-release:
	swift build --configuration release --arch arm64 --arch x86_64

package: build-release
	$(RELEASE_BUILD)/$(EXECUTABLE) --generate-completion-script zsh > _reminders
	tar -pvczf $(ARCHIVE) _reminders -C $(RELEASE_BUILD) $(EXECUTABLE)
	tar -zxvf $(ARCHIVE)
	@shasum -a 256 $(ARCHIVE)
	@shasum -a 256 $(EXECUTABLE)

clean:
	rm -f $(EXECUTABLE) $(ARCHIVE) 
	swift package clean

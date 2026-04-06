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

build: ##@App Build the app
	./build.sh run

install: ##@App install the app
	./build.sh install

run: ##@App Run the app
	@echo "Launching ${APP_NAME}..."
	open "AltTab/build/Build/Products/Release/AltTab.app"
	#./build.sh run

clean: ##@App clean the app
	./build.sh clean



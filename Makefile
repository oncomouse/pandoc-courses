.PHONY: md docx html open clean clean-all get-ref help
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:

FILTER_DIR   := $(realpath filters)
SYLLABUS_DIR := $(realpath classes)
OUTPUT_DIR   := $(realpath output)
DOCX_REF     := $(realpath reference/syllabus-reference.docx)

ifdef CONFIG
    CONFIG_FILE := $(SYLLABUS_DIR)/$(CONFIG).md
    MD_OUTPUT   := $(OUTPUT_DIR)/md/$(CONFIG).md
    DOCX_OUTPUT := $(OUTPUT_DIR)/docx/$(CONFIG).docx
    HTML_OUTPUT := $(OUTPUT_DIR)/html/$(CONFIG).html
    LAST_OPENED := $(OUTPUT_DIR)/.last-opened.$(CONFIG)
endif

define require-config
	@test -n "$(CONFIG_FILE)" || { echo "CONFIG is required. Usage: make $(1) CONFIG=<name>"; exit 1; }
endef

define check-docx-ref
	@test -f "$(DOCX_REF)" || { echo "Missing reference docx: $(DOCX_REF). Run: make get-ref" >&2; exit 1; }
endef

$(CONFIG_FILE):
	cp template.md $(CONFIG_FILE)

$(OUTPUT_DIR)/docx $(OUTPUT_DIR)/html:
	@mkdir -p $@

$(DOCX_OUTPUT): $(CONFIG_FILE) | $(OUTPUT_DIR)/docx
	$(call check-docx-ref)
	@pandoc -s $(CONFIG_FILE) \
		-f markdown -t docx \
		--reference-doc=$(DOCX_REF) \
		--lua-filter=$(FILTER_DIR)/fix-title.lua \
		--lua-filter=$(FILTER_DIR)/fix-includes.lua \
		--lua-filter=include-files/include-files.lua \
		--lua-filter=$(FILTER_DIR)/schedule-filter.lua \
		--lua-filter=$(FILTER_DIR)/syllabus-header.lua \
		--lua-filter=syllabus_factory/filters/tables.lua \
		--lua-filter=syllabus_factory/filters/linebreaks.lua \
		-o $(DOCX_OUTPUT)

$(HTML_OUTPUT): $(CONFIG_FILE) | $(OUTPUT_DIR)/html
	@pandoc -s $(CONFIG_FILE) \
		-f markdown -t html \
		--lua-filter=$(FILTER_DIR)/fix-title.lua \
		--lua-filter=$(FILTER_DIR)/fix-includes.lua \
		--lua-filter=include-files/include-files.lua \
		--lua-filter=$(FILTER_DIR)/schedule-filter.lua \
		--lua-filter=$(FILTER_DIR)/syllabus-header.lua \
		--lua-filter=syllabus_factory/filters/tables.lua \
		--lua-filter=syllabus_factory/filters/linebreaks.lua \
		-o $(HTML_OUTPUT)

docx: $(DOCX_OUTPUT)
	$(call require-config,$@)
	@echo "docx" > $(LAST_OPENED)

html: $(HTML_OUTPUT)
	$(call require-config,$@)
	@echo "html" > $(LAST_OPENED)

# State tracking enables dynamic file opening based on the filetype. Each of
# the above aliases records its associated filetype, which open draws from when
# called
open:
	$(call require-config,$@)
	@if [ -f "$(LAST_OPENED)" ]; then \
		format=$$(cat "$(LAST_OPENED)"); \
		case $$format in \
			docx) f="$(DOCX_OUTPUT)" ;; \
			html) f="$(HTML_OUTPUT)" ;; \
			*) echo "Unknown format recorded: $$format" >&2; exit 1 ;; \
		esac; \
		[ -f "$$f" ] || { echo "File does not exist: $$f" >&2; exit 1; }; \
		open "$$f"; \
	else \
		echo "No recorded format for $(CONFIG_NAME). Run: make <md|docx|html> CONFIG=..." >&2; \
		exit 1; \
	fi

clean:
	$(call require-config,$@)
	rm -f $(DOCX_OUTPUT) $(HTML_OUTPUT) $(LAST_OPENED)

clean-all:
	@echo "Removing all files from syllabi/"
	rm -rf $(OUTPUT_DIR)/md/* $(OUTPUT_DIR)/docx/* $(OUTPUT_DIR)/html/* $(SYLLABUS_DIR)/.last-opened.*

help:
	@echo "Available targets:"
	@echo "  schedule CONFIG=<name>  - Make a schedule"
	@echo "  md CONFIG=<name>        - Compile markdown"
	@echo "  docx CONFIG=<name>      - Render to docx"
	@echo "  html CONFIG=<name>      - Render to html"
	@echo "  open CONFIG=<name>      - Open the last rendered file"
	@echo "  clean CONFIG=<name>     - Clean a config's generated files"
	@echo "  clean-all               - Clean all generated files"

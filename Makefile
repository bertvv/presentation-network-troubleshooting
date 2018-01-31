## reveal.js presentation makefile
#
# This Makefile will generate a reveal.js presentation from a Markdown file
# using Pandoc. The resulting presentation can be easily exported with Github
# Pages.

##---------- Preliminaries ----------------------------------------------------

.POSIX:     # Get relible POSIX behaviour
.SUFFIXES:  # Clear built-in inference rules

##---------- Variables --------------------------------------------------------

# Markdown file containing presentation source
SOURCE_FILE := troubleshooting-network-services.md

# Target directory for the reveal.js presentation
# `docs/' is the standard directory for Github pages
OUTPUT := docs

# Directory for reveal.js
REVEAL_JS_DIR := $(OUTPUT)/reveal.js

# File name of the reveal.js tarball
REVEAL_JS_TAR := 3.6.0.tar.gz

# Download URL
REVEAL_JS_URL := https://github.com/hakimel/reveal.js/archive/$(REVEAL_JS_TAR)

# reveal.js style file
STYLE := hogent
STYLE_FILE := $(REVEAL_JS_DIR)/css/theme/$(STYLE).css

##---------- User build targets -----------------------------------------------

help: ## Show this help message (default)
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all: $(STYLE_FILE) $(OUTPUT)/index.html ## Build the presentation (but not the handouts)

handouts: $(OUTPUT)/handouts.pdf ## Generate PDF handouts

clean: ## Deletes the presentation and handouts (not reveal.js)
	rm -f $(OUTPUT)/*.html
	rm -f $(OUTPUT)/*.pdf

mrproper: clean ## Thorough cleanup (also removes reveal.js)
	rm -rf $(REVEAL_JS_DIR)

##---------- Actual build targets ---------------------------------------------

## Generate the reveal.js presentation
$(OUTPUT)/index.html: $(SOURCE_FILE) $(REVEAL_JS_DIR) $(STYLE_FILE)
	pandoc \
		--standalone \
		--to=revealjs \
		--template=default.revealjs \
		--variable=theme:hogent \
		--highlight-style=haddock \
		--output $@ $<

## Generate PDF handouts
$(OUTPUT)/handouts.pdf: $(SOURCE_FILE)
	pandoc --variable mainfont="DejaVu Sans" \
		--variable monofont="DejaVu Sans Mono" \
		--variable fontsize=11pt \
		--variable geometry:margin=1.5cm \
		-f markdown  $< \
		--latex-engine=lualatex \
		-o $@

## Ensure the style file is put into the right place
$(STYLE_FILE): $(STYLE).css
	cp $(STYLE).css $(STYLE_FILE)

## Download and install reveal.js locally
$(REVEAL_JS_DIR):
	wget $(REVEAL_JS_URL)
	tar xzf $(REVEAL_JS_TAR)
	rm $(REVEAL_JS_TAR)
	mv -T reveal.js* $(REVEAL_JS_DIR)


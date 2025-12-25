# Makefile for Single Cycle CPU Project

# Configuration
TOP_VERILOG_FILE := top_sim_testbench
INST_ASM_FILE := test/inst.asm

# Tools
IVERILOG := iverilog
VVP := vvp
NODE := node
RM := rm -rf

# Flags
ifeq ($(DEBIAN_FRONTEND),noninteractive)
VVP_FLAGS := -n
else
VVP_FLAGS :=
endif

# Color output
BLUE := \033[34m
CYAN := \033[36m
RED := \033[31m
RESET := \033[0m

# Special targets
.PHONY: all inst test clean help
.SECONDARY:

# Default target: transform and test
all: inst $(TOP_VERILOG_FILE)

# Transform instruction file only
inst:
	@echo "$(BLUE)Analyzing and Transforming $(CYAN)$(INST_ASM_FILE)$(BLUE) ...$(RESET)"
	@$(NODE) transform.js $(INST_ASM_FILE)

# Run test only
test: $(TOP_VERILOG_FILE)

# Clean build artifacts
clean:
	@echo "$(CYAN)Cleaning...$(RESET)"
	@find . \( -name "*.vvp" -o -name "*.vcd" -o -name "*.out" \) -exec $(RM) {} +

# Help target
help:
	@echo "Usage:"
	@echo "  make              - Transform instruction file and run test"
	@echo "  make help         - Show this help message"
	@echo "  make inst         - Analyze and transform instruction file only"
	@echo "  make test         - Run test only"
	@echo "  make clean        - Remove build artifacts (*.vvp, *.vcd, *.out)"
	@echo "  make <file>       - Simulate specified verilog file"
	@echo "       <file>.vvp"

%.vvp:
	@FILE="$@"; \
	DIR=$$(dirname "$$FILE"); \
	BASE=$$(basename "$$FILE"); \
	SOURCE="$$DIR/$${BASE%.vvp}.v"; \
	if [ -f "$$SOURCE" ]; then \
		echo "$(BLUE)Generating $(CYAN)$$FILE$(BLUE) via $(CYAN)$${SOURCE}$(BLUE) ...$(RESET)"; \
		$(IVERILOG) -o "$$FILE" "$$SOURCE"; \
		$(VVP) $(VVP_FLAGS) "$$FILE"; \
	else \
		echo "$(RED)Error: File \"$$SOURCE\" not found.$(RESET)"; \
		exit 1; \
	fi

# Catch-all: redirect to .vvp target
%: %.vvp
	@:
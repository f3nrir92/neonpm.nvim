.PHONY: test lint fmt fmt-check

test:
	busted

lint:
	luacheck lua tests

fmt:
	stylua lua tests

fmt-check:
	stylua --check lua tests

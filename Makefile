.PHONY: test lint fmt fmt-check

test:
	eval "$$(luarocks --lua-version=5.1 path)" && busted

lint:
	luacheck lua tests

fmt:
	stylua lua tests

fmt-check:
	stylua --check lua tests

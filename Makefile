.PHONY: all test clean

default: test lint spec

test:
	forge test -vvv

lint:
	forge fmt

spec:
	npx --quiet --yes @defi-wonderland/natspec-smells@1.1.3 --enforceInheritdoc=false --include='src/**/*.sol'

run:
	mix phx.server

build:
	mix compile

test:
	mix test

check-formatting:
	mix format --check-formatted

iex:
	iex -S mix

clean:
	mix clean

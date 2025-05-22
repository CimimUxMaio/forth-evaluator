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

db:
	docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres

setup_db:
	mix ecto.reset

dev:
	mix phx.server

deps:
	mix local.hex --force
	mix local.rebar --force
	mix do deps.get, deps.compile
	mix deps.get

start_db:
	docker compose up -d

stop_db:
	docker compose down

setup_db:
	mix ecto.drop
	mix ecto.create
	mix ecto.migrate

setup_all: deps start_db setup_db

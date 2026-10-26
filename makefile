# run mix commands inside the app container, both from the host and from inside it
ifeq ($(wildcard /.dockerenv),)
RUN = docker compose exec app_service
else
RUN =
endif

ARGS = $(filter-out $@,$(MAKECMDGOALS))

# host only
up:
	docker compose up -d

down:
	docker compose down

shell:
	docker compose exec app_service sh

# host or container
app:
	$(RUN) iex -S mix phx.server

app.setup:
	$(RUN) mix setup

app.migrate:
	$(RUN) mix ecto.migrate

app.test:
	$(RUN) sh -c "MIX_ENV=test mix test $(ARGS) && mix format"

app.test.watch:
	$(RUN) sh -c "MIX_ENV=test mix test.watch $(ARGS)"

app.precommit:
	$(RUN) mix precommit

app.credo:
	$(RUN) mix credo --strict

%:
	@:

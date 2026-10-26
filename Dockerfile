FROM elixir:1.19-alpine

# git for third party dependencies
# bash for mix test.watch
# make and build-base for bcrypt_elixir
# inotify-tools for live reload
RUN apk add --no-cache openssl inotify-tools git bash make build-base

# create a user with the same UID/GID as the host user,
# so files generated in the container are owned by you
ARG HOST_UID=1000
ARG HOST_GID=1000
RUN addgroup -g $HOST_GID app && adduser -D -u $HOST_UID -G app app

ENV APP_HOME=/app
RUN mkdir -p $APP_HOME && chown app:app $APP_HOME
WORKDIR $APP_HOME

USER app

# IEx history folder (mounted as a volume); created here so it is owned by the app user
RUN mkdir -p /home/app/.cache/erlang-history

ARG PHX_VERSION=1.8.16
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix archive.install hex phx_new $PHX_VERSION --force

ARG APP_PORT=4000
EXPOSE $APP_PORT

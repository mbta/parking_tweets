ARG ELIXIR_VERSION=1.14.2
ARG ERLANG_VERSION=25.2
ARG ALPINE_VERSION=3.17.0
FROM hexpm/elixir:$ELIXIR_VERSION-erlang-$ERLANG_VERSION-alpine-$ALPINE_VERSION AS builder

WORKDIR /root

# Install Hex+Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Install git
RUN apk --update add git make

ENV MIX_ENV=prod

WORKDIR /root

ADD mix.* /root/
ADD config /root/config

RUN mix do deps.get --only prod, deps.compile

ADD lib /root/lib

RUN mix release

FROM alpine:$ALPINE_VERSION

RUN apk add --no-cache bash dumb-init libstdc++ libgcc libssl1.1 && \
    adduser -D parking_tweets && \
    mkdir /parking_tweets && \
    chmod a+r /parking_tweets

# Set environment
ENV MIX_ENV=prod TERM=xterm LANG=C.UTF-8 REPLACE_OS_VARS=true

COPY --from=builder /root/_build/prod/rel/parking_tweets /parking_tweets

# ensure the application can run
RUN /parking_tweets/bin/parking_tweets eval ":crypto.supports()"

HEALTHCHECK CMD ["/parking_tweets/bin/parking_tweets", "rpc", "1 + 1"]

CMD ["dumb-init", "/parking_tweets/bin/parking_tweets", "start"]

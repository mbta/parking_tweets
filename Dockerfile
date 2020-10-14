FROM hexpm/elixir:1.11.0-erlang-23.1.1-alpine-3.12.0 AS builder

WORKDIR /root

# Install Hex+Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Install git
RUN apk --update add git make

ENV MIX_ENV=prod

WORKDIR /root

ADD mix.* /root/

RUN mix do deps.get --only prod, deps.compile

ADD lib /root/lib
ADD config /root/config

RUN mix release

FROM alpine:3.12.0

RUN apk add --update bash dumb-init \
	&& rm -rf /var/cache/apk

# Set environment
ENV MIX_ENV=prod TERM=xterm LANG=C.UTF-8 REPLACE_OS_VARS=true

COPY --from=builder /root/_build/prod/rel/ /root/rel

CMD ["dumb-init", "/root/rel/parking_tweets/bin/parking_tweets", "start"]
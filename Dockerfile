FROM hexpm/elixir:1.12.3-erlang-24.0.6-alpine-3.13.5 AS builder

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

FROM alpine:3.13.5

RUN apk add --update bash dumb-init libstdc++ libgcc libssl1.1 \
	&& rm -rf /var/cache/apk

# Set environment
ENV MIX_ENV=prod TERM=xterm LANG=C.UTF-8 REPLACE_OS_VARS=true

COPY --from=builder /root/_build/prod/rel/ /root/rel

# ensure the application can run
RUN /root/rel/parking_tweets/bin/parking_tweets eval ":crypto.supports()"

HEALTHCHECK CMD ["/root/rel/parking_tweets/bin/parking_tweets", "rpc", "1 + 1"]

CMD ["dumb-init", "/root/rel/parking_tweets/bin/parking_tweets", "start"]
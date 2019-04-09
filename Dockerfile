FROM elixir:1.8.1-alpine AS builder

WORKDIR /root

# Install Hex+Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Install git
RUN apk --update add git make

ENV MIX_ENV=prod

ADD . .

WORKDIR /root

RUN elixir --erl "-smp enable" /usr/local/bin/mix do deps.get --only prod, compile, release --verbose

FROM alpine:3.9

RUN apk add --update bash \
	&& rm -rf /var/cache/apk

# Set environment
ENV MIX_ENV=prod TERM=xterm LANG=C.UTF-8 REPLACE_OS_VARS=true

COPY --from=builder /root/_build/prod/rel/ /root/rel

CMD ["/root/rel/parking_tweets/bin/parking_tweets", "foreground"]
# ParkingTweets

Tweets about parking garage availability.

[![Elixir CI](https://github.com/mbta/parking_tweets/actions/workflows/elixir.yml/badge.svg)](https://github.com/mbta/parking_tweets/actions/workflows/elixir.yml)

## Configuration

ParkingTweets requires 5 environment variables:

- `API_KEY`: a [V3 API](https://api-v3.mbta.com/) key
- `CONSUMER_KEY`
- `CONSUMER_SECRET`
- `ACCESS_TOKEN`
- `ACCESS_TOKEN_SECRET` - configuration variables from [Twitter](https://developer.twitter.com/)

## Running the applicaion

You can run the application on your local machine:

```
mix run --no-halt
```

Or with Docker:

```bash
docker build . -t parking_tweets
docker run parking_tweets
```

## Development Setup

```
# after installing asdf from https://github.com/asdf-vm/asdf..
asdf install

# get Elixir dependencies
mix deps.get

# add pre-commit hook to verify formatting & tests
ln -s ../../hooks/pre-commit .git/hooks/pre-commit

# make sure everything passes! (slowest to fastest)
mix format --check-formatted
mix credo
mix test

# you can also run them in Docker
docker build -f Dockerfile.test .
```

## License

ParkingTweets is licensed under the [MIT license](LICENSE).

## Code of Conduct

Parking Tweets is governed by the [Contributor Covenant](CODE_OF_CONDUCT.md), version 1.4.

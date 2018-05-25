# ParkingTweets

Tweets about parking garage availability.

## Configuration

ParkingTweets requires 5 environment variables:

- `API_KEY`: a [V3 API][https://api-v3.mbta.com/] key
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

## License

ParkingTweets is licensed under the [MIT license](LICENSE).

defmodule ParkingTweetsTest do
  use ExUnit.Case, async: true
  import ParkingTweets

  describe "url/0" do
    test "returns a valid URL" do
      actual = url()
      assert actual =~ "https://test.example/path/live-facilities/"
      assert actual =~ "api_key=test_api_key"
      assert actual =~ "filter[id]="
    end
  end
end

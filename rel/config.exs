use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: :prod

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"${ERLANG_COOKIE}"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :parking_tweets do
  set version: current_version(:parking_tweets)
  set applications: [
    :runtime_tools,
    :oauther,
    :poison,
    :extwitter
  ]
end

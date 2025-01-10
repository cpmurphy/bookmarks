# README

This is a vanilla Rails application (yes, I know), so expect it to work
like one of those.  It is currently pre-alpha, missing lots of features
and not too smooth.

## Development

To run unit tests, use `rake`.

## Deployment

It doesn't use Kamal, instead there is bin/deploy.sh, which expects to find
config/deploy-env.sh which defines environment variables on here to ssh
and deploy.

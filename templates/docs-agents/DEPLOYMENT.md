# Deployment

How this project is built, released, and run in each environment. Keep it
current — this is the doc someone follows to ship a release or roll one back.

## Environments

- **<name>** — <url / purpose> · <how to access>.

## Release process

1. <step — e.g. tag a version, trigger CI, build the artifact>
2. <step — e.g. deploy to environment, run migrations>
3. <step — e.g. smoke-check, announce>

## Configuration & secrets

- <where config lives; how secrets are provided at runtime — never commit secrets>

## Rollback

- <how to revert a bad release, and any data/migration caveats>

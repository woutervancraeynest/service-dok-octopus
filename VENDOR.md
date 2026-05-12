# Vendored dependencies

## octopus_client

The `octopus_client` gem is vendored in `vendor/octopus_client/` instead of
fetched from GitHub at build time. This is because the Docker build runs on
a server without GitHub credentials, so `bundle install` cannot clone private
repositories.

**Source repo:** https://github.com/by2-be/octopus_client (private)

### Updating the vendored gem

When `octopus_client` is updated, copy the new version into this repo:

```bash
# From the service-dok-octopus project root:
rm -rf vendor/octopus_client
mkdir -p vendor/octopus_client
cp -r /path/to/octopus_client/lib vendor/octopus_client/
cp /path/to/octopus_client/octopus_client.gemspec vendor/octopus_client/
cp /path/to/octopus_client/LICENSE vendor/octopus_client/

# Regenerate lockfile
bundle install

# Commit everything
git add vendor/octopus_client Gemfile.lock
git commit -m "chore: update vendored octopus_client to vX.Y.Z"
git push
```

Then rebuild the service from the Dok admin panel.

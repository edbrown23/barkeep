# Barkeep

`barkeep` is a home bartending application that tracks your liquor cabinet and recommends
cocktail recipes for you.

You can view the running application at [barkeep.website](https://barkeep.website).

I am blogging about my work on this app here: [https://edbrown23.github.io/blog/](https://edbrown23.github.io/blog/)

## Development setup

Barkeep uses Ruby 3.2.2 and PostgreSQL 14 with the pgvector extension. Copy the sample
database settings, adjust them for your local PostgreSQL user, and run the setup script:

```sh
cp .env.example .env
bin/setup
```

The database user must be able to create the `barkeep_development` and `barkeep_test`
databases. PostgreSQL must provide the `vector` extension used by the application schema.

Run the same database preparation and test commands used by CI with:

```sh
RAILS_ENV=test bin/rails db:test:prepare
RAILS_ENV=test bundle exec rspec
```

Check Rails autoloading after dependency or application structure changes:

```sh
RAILS_ENV=test bin/rails zeitwerk:check
```

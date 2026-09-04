# Barkeep

`barkeep` is a home bartending application that tracks your liquor cabinet and recommends
cocktail recipes for you.

You can view the running application at [barkeep.website](https://barkeep.website).

I am blogging about my work on this app here: [https://edbrown23.github.io/blog/](https://edbrown23.github.io/blog/)

## Development setup

Barkeep uses Ruby 3.2.2, Node.js 24 LTS, and PostgreSQL 14 with the pgvector extension.
Volta reads the Node version from `package.json`. Copy the sample database settings,
adjust them for your local PostgreSQL user, and install the dependencies:

```sh
cp .env.example .env
bin/setup
```

For local development, run the Homebrew PostgreSQL 14 service on port `5433`.
This project intentionally avoids the standard PostgreSQL port (`5432`) so it
does not conflict with another local database setup. Set `port = 5433` in the
Homebrew cluster's `postgresql.conf` (typically
`$(brew --prefix)/var/postgresql@14/postgresql.conf`), set `DB_USER` in `.env`
to your local PostgreSQL role, then restart the service before running the
setup commands above:

```sh
brew services restart postgresql@14
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

Build the browser assets with:

```sh
npm run build
npm run build:css
```

[![Clippy check](https://github.com/ChicoState/archenemy/actions/workflows/ci.yml/badge.svg)](https://github.com/ChicoState/archenemy/actions/workflows/ci.yml)


> [!WARNING]
> To fix authentication, run 
>
> `keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore`
>
> Under the `android` directory, then send me (discord: WERDXZ) or max the SHA1 hash

> [!WARNING]
> I just made a major api change!
> Basically everything is prefixed with `/api/v1`
>

# Archenemy 

A matching platform that helps you find your nemesis!

## Development Environment Setup

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Port Requirements

The following ports need to be available on your system:

- `3000`: API Server
- `5432`: PostgreSQL Database

Ensure these ports are not already in use by other services on your system.

### Configuration

- Dm me (WERDXZ) on discord for a copy of environment variable, put it at root directory (it should be `Secrets.toml`) (Only needed if you want bucket access).
- Else, just create an empty `Secrets.toml` file.


### Running with Docker Compose

Start the development environment:

```bash
docker compose up
```

To run in detached mode:

```bash
docker compose up -d # It wouldn't block your terminal!
```

To stop the containers:

```bash
docker-compose -f docker-compose.dev.yaml down
```

### Seeding

To initialize your database with sample data:

```bash
# Basic usage (seed from a file)
./scripts/seed seed/0x01.seed

# Import from a remote database
./scripts/seed --remote REMOTE_DB_URL

# Additional options
./scripts/seed --help  # Show all available options
./scripts/seed seed/0x01.seed --no-clear  # Seed without clearing existing data
./scripts/seed seed/0x01.seed --yes  # Skip confirmation prompts
```

## Api Docs

It will be in the uri: `/swagger-ui`, make sure to prefix with the correct domain. In our case, the remote server is: `archenemy-zusg.shuttle.app`.

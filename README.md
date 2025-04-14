[![Clippy check](https://github.com/ChicoState/archenemy/actions/workflows/ci.yml/badge.svg)](https://github.com/ChicoState/archenemy/actions/workflows/ci.yml)

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

- Local development:
    - You don't need any configuration! I did my best to make everything work out of box

- Production:
    - Dm me (WERDXZ) on discord for a copy of environment variable, put it at root directory (it should be `Secrets.toml`)

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

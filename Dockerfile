FROM lukemathwalker/cargo-chef:latest-rust-1 AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder 
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json

COPY . .
# Create a script to load environment variables from Secrets.toml and start the application
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Load variables from Secrets.toml\n\
if [ -f /usr/local/share/archenemy/Secrets.toml ]; then\n\
  echo "Loading environment variables from Secrets.toml..."\n\
  while IFS="=" read -r key value; do\n\
    # Skip comments and empty lines\n\
    [[ "$key" =~ ^[[:space:]]*# ]] && continue\n\
    [[ -z "$key" ]] && continue\n\
    # Extract the key and value\n\
    key=$(echo "$key" | tr -d "[:space:]")\n\
    # Remove quotes around values if they exist\n\
    value=$(echo "$value" | sed -E "s/^[\"'\''](.*)[\"\'']$/\\1/")\n\
    # Only set environment variable if it doesn'\''t already exist\n\
    if [ -z "${!key}" ]; then\n\
      export "$key"="$value"\n\
      echo "Exported: $key"\n\
    else\n\
      echo "Keeping existing value for: $key"\n\
    fi\n\
  done < <(grep "=" /usr/local/share/archenemy/Secrets.toml)\n\
  echo "Environment variables loaded."\n\
else\n\
  echo "Warning: Secrets.toml not found!"\n\
fi\n\
\n\
exec /usr/local/bin/archenemy\n\
' > entrypoint.sh

# Make the script executable
RUN chmod +x entrypoint.sh

# Build application
RUN cargo build --release --bin archenemy --features local

FROM debian:bookworm-slim AS runtime
WORKDIR /app

RUN apt-get update && apt-get install -y ca-certificates libssl3 libpq5 libsqlite3-0 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/archenemy /usr/local/bin/archenemy
COPY --from=builder /app/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY Secrets.toml /usr/local/share/archenemy/Secrets.toml

# Expose the port the application will run on
EXPOSE 3000

# Use the entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

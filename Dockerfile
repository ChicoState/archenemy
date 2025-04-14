FROM rust:1.86-slim AS builder

WORKDIR /usr/src/app

# Install dependencies for building
RUN apt-get update && \
    apt-get install -y pkg-config libssl-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the project files
COPY . .

# Build the project (using release mode for optimization)
RUN cargo build --release --features local

FROM debian:12-slim as runtime

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates libssl-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the binary from the builder stage
COPY --from=builder /usr/src/app/target/release/archenemy /app/archenemy

# Copy the Secrets.toml file
COPY Secrets.toml /app/Secrets.toml

# Create a script to load environment variables from Secrets.toml and start the application
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Load variables from Secrets.toml\n\
if [ -f /app/Secrets.toml ]; then\n\
  echo "Loading environment variables from Secrets.toml..."\n\
  while IFS="=" read -r key value; do\n\
    # Skip comments and empty lines\n\
    [[ "$key" =~ ^[[:space:]]*# ]] && continue\n\
    [[ -z "$key" ]] && continue\n\
    # Extract the key and value\n\
    key=$(echo "$key" | tr -d "[:space:]")\n\
    # Remove quotes around values if they exist\n\
    value=$(echo "$value" | sed -E "s/^[\"'\''](.*)[\"\'']$/\\1/")\n\
    # Export as environment variable\n\
    export "$key"="$value"\n\
    echo "Exported: $key"\n\
  done < <(grep "=" /app/Secrets.toml)\n\
  echo "Environment variables loaded."\n\
else\n\
  echo "Warning: Secrets.toml not found!"\n\
fi\n\
\n\
exec /app/archenemy\n\
' > /app/entrypoint.sh

# Make the script executable
RUN chmod +x /app/entrypoint.sh

# Expose the port the application will run on
EXPOSE 3000

# Use the entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]


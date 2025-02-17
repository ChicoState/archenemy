[![Clippy check](https://github.com/ChicoState/archenemy/actions/workflows/ci.yml/badge.svg)](https://github.com/ChicoState/archenemy/actions/workflows/ci.yml)

# Hatingapp

A developer matching platform that helps you find your coding nemesis!

## Database Setup

### Seeding the Database

To populate the database with initial test data:

1. First, get the database URL:
   - DM [werdxz on Discord](https://discord.com/) for the database credentials
   - The URL format will be: `postgres://<user>:<password>@<host>:<port>/<database>`

2. Run the seed script:
   ```bash
   # Basic usage (will prompt for database URL)
   ./seed/seed seed/0x01.seed

   # Or with environment variable
   DATABASE_URL=<your-database-url> ./seed/seed seed/0x01.seed
   ```

Options:
- Use `-y` flag to skip confirmation prompts
- Use `--no-clear` to keep existing data
- Use `-h` or `--help` for more options

⚠️ Note: The seed script will clear all existing data by default. Use `--no-clear` if you want to preserve existing data.

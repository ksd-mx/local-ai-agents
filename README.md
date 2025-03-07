# n8n + Supabase Local Development Environment

This project provides a simple setup for running [n8n](https://n8n.io/) workflow automation platform alongside [Supabase](https://supabase.com/) database on your local computer, completely free.

## 📋 Overview

This setup provides:

- **n8n**: A powerful workflow automation tool (like Zapier or Make.com)
- **Supabase**: A reliable database and backend service
- **Docker**: Runs everything in containers without affecting your computer

## 🚀 Getting Started

### First Time Setup

1. **Make the scripts executable** (one-time setup):

```bash
chmod +x *.sh
```

This command gives permission to run the scripts. Your computer requires this for security reasons.

2. **Install prerequisites** based on your operating system:

```bash
# For Mac users
./install-prereqs-mac.sh

# For Linux users
./install-prereqs-linux.sh
```

3. **Run the setup script**:

```bash
./setup.sh
```

4. **Start all services**:

```bash
./start.sh
```

### Regular Usage

After the initial setup, you only need to:

- **Start services**: `./start.sh`
- **Stop services**: `./stop.sh`

## ⭐ Accessing Your Services

Once everything is running:

- **n8n**: Visit http://localhost:5678 in your browser
- **Supabase Dashboard**: Visit http://localhost:8000
- **Supabase Studio**: Visit http://localhost:3000

### Supabase Login Credentials

When you first visit the Supabase Dashboard, you'll need to log in with these default credentials:

- **Username**: `supabase`
- **Password**: `this_password_is_insecure_and_should_be_updated`

These credentials will be shown in the terminal after running `./start.sh`. If you ever need to find them:
1. Check the terminal output after running `./start.sh`
2. Or look in the file `supabase-docker/.env` under the DASHBOARD_USERNAME and DASHBOARD_PASSWORD fields

## 🔌 Connecting n8n to Supabase

After starting the services:

1. In n8n, create a new workflow
2. Add a **PostgreSQL** node
3. Use these connection details:
   - Host: `supabase-db`
   - Database: `postgres`
   - Port: `5432`
   - User: `postgres`
   - Password: `postgres`

## ⚠️ Troubleshooting

### KONG Unauthorized Error

If you see a "KONG unauthorized" screen when trying to access Supabase (this often happens if you've run the setup before):

1. **Open an incognito/private browser window** and try accessing Supabase again

OR

2. **Clear browser data for localhost**:
   - In Chrome: Go to Settings → Privacy and Security → Clear browsing data
   - Select "Cookies and site data" 
   - Enter "localhost" in the search bar
   - Click "Clear data"

   > ⚠️ **Note**: This will remove any saved login information for other development projects using localhost.

After clearing the data, try logging in with the credentials:
- Username: `supabase`
- Password: `this_password_is_insecure_and_should_be_updated`

(Or the new credentials shown in the terminal if they were updated during setup)

### Starting Fresh

If you want to start completely fresh:

```bash
./cleanup.sh
./setup.sh
./start.sh
```

## 🛡️ Security Note

This setup is for local development only and not meant for production use.

## 📚 For More Information

- [n8n Documentation](https://docs.n8n.io/)
- [Supabase Documentation](https://supabase.com/docs)
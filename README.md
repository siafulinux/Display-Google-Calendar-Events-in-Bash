````markdown
# Google Calendar CLI

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)

A lightweight Bash CLI for viewing Google Calendar events directly from the terminal.

It displays today's events first, followed by the complete Monday-Sunday calendar week.

## Features

- 📅 Today's events
- 🗓️ Current Monday-Sunday week
- ⏰ Timed events
- 📌 All-day events
- 🎨 Colorized terminal output
- 🔐 API credentials stored outside the repository
- ⚡ Single Google Calendar API request
- 📦 Minimal dependencies
- 🐧 Designed for Linux
- 🧩 Uses the Google Calendar API
- 📄 Simple Bash configuration

## Example

```text
Google Calendar
Wednesday, September 9, 2026
────────────────────────────────────────────────────────────

TODAY

  09:00 - 10:00  Morning Meeting
  14:30 - 15:30  Project Work
  All Day        Submit Application

────────────────────────────────────────────────────────────

THIS WEEK
September 07, 2026 - September 13, 2026

Wednesday, September 09
────────────────────────────────────────
  09:00 - 10:00  Morning Meeting
  14:30 - 15:30  Project Work

Thursday, September 10
────────────────────────────────────────
  All Day        Pay Bills

Saturday, September 12
────────────────────────────────────────
  18:00 - 20:00  Dinner

────────────────────────────────────────────────────────────
```

## Requirements

- Bash
- `curl`
- `jq`
- GNU `date`

On Debian, Ubuntu, Parrot OS, and other Debian-based distributions:

```bash
sudo apt install curl jq
```

## Google Calendar API Setup

This script uses the Google Calendar API with an API key.

### 1. Create a Google Cloud project

Create or select a project in Google Cloud Console.

### 2. Enable the Google Calendar API

Enable:

```text
Google Calendar API
```

### 3. Create an API key

Create an API key under:

```text
APIs & Services → Credentials
```

For better security, restrict the API key to the Google Calendar API and, where practical, restrict its use to the environment where this script will run.

### 4. Obtain your Calendar ID

In Google Calendar:

```text
Settings → Settings for my calendars → Select your calendar
```

Look for:

```text
Calendar ID
```

For a primary calendar, this is commonly your Google account email address.

Shared calendars generally have IDs similar to:

```text
abc123456789@group.calendar.google.com
```

## Configuration

The repository includes an `example.config` file.

Copy it to `config`:

```bash
cp example.config config
```

Edit the configuration:

```bash
nano config
```

Enter your Google Calendar API key and Calendar ID.

The resulting configuration file should look similar to:

```bash
GOOGLE_API_KEY="your-google-api-key"
CALENDAR_ID="your-calendar-id"
```

The actual `config` file is excluded from Git so that your API key does not get committed to the repository.

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/google-calendar-cli.git
cd google-calendar-cli
```

Make the script executable:

```bash
chmod +x calendar.sh
```

Create your private configuration:

```bash
cp example.config config
```

Edit the configuration:

```bash
nano config
```

Enter your API key and Calendar ID.

## Run

Run the script from the project directory:

```bash
./calendar.sh
```

## Security

Never commit your actual `config` file.

The repository contains:

```text
example.config
```

which provides a safe configuration template.

Your actual configuration is stored in:

```text
config
```

The `config` file is intentionally excluded by `.gitignore`.

This keeps your Google Calendar API key out of the Git repository.

You should also restrict your Google API key in Google Cloud Console whenever possible.

If an API key has accidentally been committed to a public repository, revoke or rotate the key immediately.

## Project Structure

```text
google-calendar-cli/
├── calendar.sh
├── example.config
├── .gitignore
└── README.md
```

## How It Works

The script requests the current Monday-Sunday week from the Google Calendar API.

The returned events are then processed locally with `jq`.

The terminal output is divided into two sections:

1. **TODAY**
2. **THIS WEEK**

Today's events are displayed first, followed by the remaining events grouped by day.

The script makes a single Google Calendar API request for each execution.

## License

This project is licensed under the **GNU General Public License v3.0**.

See the [GNU GPL v3.0](https://www.gnu.org/licenses/gpl-3.0.html) for the full license text.
````

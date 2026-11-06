# Alyss Cinema

A database-course project for cinema ticket booking, implemented with Flask and MySQL.

**Stack:** Python · Flask · MySQL 8 · Bootstrap 5

## Engineering focus

- Relational modeling for users, films, screenings, seats, bookings, and payments.
- Booking operations implemented with stored procedures.
- Business rules enforced through constraints and triggers.
- Seat selection, booking management, revenue reports, and a demo wallet.

## Run locally

Requires MySQL 8+ and Python. From the repository root:

```bash
git clone https://github.com/alyss1801/Alyss_Cinema.git
cd Alyss_Cinema
python -m pip install -r cinema_app/requirements.txt
```

Initialize a disposable local database using the SQL files in this order. **`schema.sql` drops and recreates the `railway` database**, so review it before running.

```sql
SOURCE schema.sql;
SOURCE data.sql;
SOURCE triggers.sql;
SOURCE procedures_crud.sql;
SOURCE procedures_query.sql;
SOURCE functions.sql;
```

Set these environment variables in the terminal that starts Flask:

| Variable | Local configuration |
| :--- | :--- |
| `MYSQL_HOST` | `localhost` |
| `MYSQL_PORT` | `3306` |
| `MYSQL_USER` | Your MySQL user |
| `MYSQL_PASSWORD` | Your MySQL password |
| `MYSQL_DATABASE` | `railway` |
| `SECRET_KEY` | A local session-signing secret |

```bash
cd cinema_app
python app.py
```

Open <http://localhost:5000>.

## Reference

| File | Responsibility |
| :--- | :--- |
| [schema.sql](schema.sql) | Tables, keys, and constraints |
| [triggers.sql](triggers.sql) | Booking and data-integrity rules |
| [procedures_crud.sql](procedures_crud.sql) | Booking mutations |
| [procedures_query.sql](procedures_query.sql) | Filtered queries and reporting |
| [functions.sql](functions.sql) | Loyalty points and seat pricing |
| [cinema_app/](cinema_app/) | Flask routes, templates, and database access |

This is an academic demo. The wallet represents simulated funds, and the demo authentication and session defaults require hardening before production use.

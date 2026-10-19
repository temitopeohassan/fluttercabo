#!/usr/bin/env bash
# Regenerates database/cabo.sql from a freshly seeded database.
#
#   php artisan migrate:fresh --seed
#   database/dump.sh            # uses DB_* values from .env
#
# Dumps every table's structure, and the data of all tables except sessions,
# cache, queues, one-time codes and API tokens.
set -euo pipefail
cd "$(dirname "$0")/.."

env_value() { grep -E "^$1=" .env | tail -1 | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//'; }
DB_HOST=${DB_HOST:-$(env_value DB_HOST)}
DB_PORT=${DB_PORT:-$(env_value DB_PORT)}
DB_DATABASE=${DB_DATABASE:-$(env_value DB_DATABASE)}
DB_USERNAME=${DB_USERNAME:-$(env_value DB_USERNAME)}
DB_PASSWORD=${DB_PASSWORD:-$(env_value DB_PASSWORD)}
OUT=database/cabo.sql

export MYSQL_PWD="$DB_PASSWORD"
COMMON=(-h "$DB_HOST" -P "${DB_PORT:-3306}" -u "$DB_USERNAME" --single-transaction --skip-dump-date --skip-comments
        --no-tablespaces --default-character-set=utf8mb4 --skip-extended-insert)
IGNORE=()
for t in sessions cache cache_locks jobs job_batches failed_jobs personal_access_tokens otp_codes password_reset_tokens; do
    IGNORE+=("--ignore-table=$DB_DATABASE.$t")
done

{
cat <<EOF
-- Cabo: tables and sample data for the admin control panel and the rider and driver APIs.
--
-- Import into an empty MySQL 8 or MariaDB 10.6+ database:
--   mysql -u root -p -e "CREATE DATABASE cabo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
--   mysql -u root -p cabo < database/cabo.sql
-- Importing again replaces every table.
--
-- Admin sign-in: admin@caboapp.online / password123!  (change it before going live)
-- Regenerate with: php artisan migrate:fresh --seed && database/dump.sh
-- Money is stored in whole naira. Times are UTC; sample dates are relative to $(date -u +%Y-%m-%d), when this file was made.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';
SET time_zone = '+00:00';

EOF
mysqldump "${COMMON[@]}" --no-data --add-drop-table "$DB_DATABASE"
echo
mysqldump "${COMMON[@]}" --no-create-info "${IGNORE[@]}" "$DB_DATABASE"
echo
echo "SET FOREIGN_KEY_CHECKS = 1;"
echo "SET UNIQUE_CHECKS = 1;"
} \
  | grep -v -E '^/\*M!999999' \
  | grep -v -E '^/\*!40[0-9]{3} SET (@OLD_|NAMES|TIME_ZONE|SQL_MODE=@OLD|FOREIGN_KEY_CHECKS=@OLD|UNIQUE_CHECKS=@OLD|CHARACTER_SET_CLIENT=@OLD|CHARACTER_SET_RESULTS=@OLD|COLLATION_CONNECTION=@OLD|SQL_NOTES)' \
  > "$OUT"

echo "Wrote $OUT ($(grep -c '^CREATE TABLE' "$OUT") tables, $(grep -c '^INSERT INTO' "$OUT") rows)"

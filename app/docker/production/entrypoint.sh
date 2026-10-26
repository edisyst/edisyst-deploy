#!/bin/sh
set -e

# Attende che MySQL accetti connessioni prima di qualsiasi comando artisan.
# A ogni tentativo fallito stampa l'ultima riga dell'errore: distingue l'attesa
# normale (Connection refused) da un problema vero (password errata, host sbagliato)
until OUT=$(php artisan db:monitor --max=1 2>&1); do
    echo "In attesa del database..."
    echo "$OUT" | grep -v '^[[:space:]]*$' | tail -n 1
    sleep 2
done

# Solo il container app esegue le migration: worker e scheduler partono con RUN_MIGRATIONS=false
if [ "${RUN_MIGRATIONS}" = "true" ]; then
    php artisan migrate --force
    php artisan storage:link || true
fi

# Le variabili d'ambiente arrivano da Coolify all'avvio: le cache si generano qui, non in build
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

exec "$@"

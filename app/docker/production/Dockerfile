# Immagine unica dell'applicazione: la usano app, worker e scheduler,
# cambia solo il comando con cui parte il container

# Stage 1 — build degli asset front-end (Vite)
FROM node:22-alpine AS assets
WORKDIR /app
# Prima solo i manifest npm: se non cambiano, Docker riusa la cache di npm ci
COPY package*.json ./
RUN npm ci
# Poi tutto il progetto: Vite legge la sua config e le view Blade
COPY . .
RUN npm run build

# Stage 2 — dipendenze PHP
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
# --ignore-platform-reqs: questa immagine non ha le estensioni PHP del progetto,
# che sono installate nello stage finale
# --no-scripts: niente artisan qui, Laravel genera la cache dei package all'avvio
# Ambiente demo: dipendenze dev incluse (i seeder usano Faker)
RUN composer install --no-scripts --no-autoloader --prefer-dist \
    --no-interaction --ignore-platform-reqs
COPY . .
RUN composer dump-autoload --optimize --no-scripts

# Stage 3 — runtime
FROM dunglas/frankenphp:1-php8.3-bookworm

# Estensioni PHP richieste dallo stack
RUN install-php-extensions \
    pdo_mysql redis gd intl zip bcmath exif pcntl opcache

WORKDIR /app
COPY --from=vendor /app /app
COPY --from=assets /app/public/build /app/public/build
COPY docker/production/entrypoint.sh /usr/local/bin/entrypoint
COPY docker/production/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

RUN chmod +x /usr/local/bin/entrypoint \
    && chown -R www-data:www-data storage bootstrap/cache

ENV SERVER_NAME=:80
# Worker mode di FrankenPHP: da attivare solo dopo aver verificato che
# l'applicazione non conservi stato tra una richiesta e l'altra
# ENV FRANKENPHP_CONFIG="worker ./public/index.php"

EXPOSE 80
ENTRYPOINT ["entrypoint"]
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]

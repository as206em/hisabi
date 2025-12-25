FROM php:8.4-cli-bookworm AS build
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    libonig-dev \
    unzip \
  && docker-php-ext-install bcmath mbstring pdo pdo_mysql \
  && rm -rf /var/lib/apt/lists/*
COPY --from=composer:2.2 /usr/bin/composer /usr/bin/composer
COPY . /app/
RUN composer install --prefer-dist --no-dev --optimize-autoloader --no-interaction

FROM php:8.4-apache-bookworm AS production

ENV APP_ENV=production
ENV APP_DEBUG=false

RUN apt-get update && apt-get install -y --no-install-recommends \
    libonig-dev \
  && docker-php-ext-configure opcache --enable-opcache \
  && docker-php-ext-install bcmath mbstring pdo pdo_mysql \
  && rm -rf /var/lib/apt/lists/*
COPY docker/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

COPY --from=build /app /var/www/html
COPY docker/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY .env.prod.example /var/www/html/.env

RUN php artisan key:generate && \
    php artisan route:cache && \
    chmod 777 -R /var/www/html/storage/ && \
    chown -R www-data:www-data /var/www/ && \
    a2enmod rewrite

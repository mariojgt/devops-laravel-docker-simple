FROM php:8.3-apache

# Install Node.js and npm
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install bun globally
RUN npm install -g bun

RUN apt-get update

# Install development packages
RUN apt-get install -y \
    nano \
    git \
    zip \
    curl \
    sudo \
    unzip \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    g++ \
    libonig-dev \
    libzip-dev \
    libwebp-dev \
    libjpeg62-turbo-dev \
    libxpm-dev \
    libgd-dev

# Set apache document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Enable apache modules
RUN a2enmod rewrite headers

# Start with base php config, then add extensions
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Install PHP extensions
RUN docker-php-ext-configure gd --with-jpeg --with-freetype --with-webp \
    && docker-php-ext-install gd

RUN docker-php-ext-install \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar \
    mbstring \
    pdo_mysql \
    zip \
    exif \
    pcntl

# Enable additional extensions
RUN docker-php-ext-enable \
    gd \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar \
    mbstring \
    pdo_mysql \
    zip \
    exif \
    pcntl

# Install Redis extension
RUN pecl install redis \
    && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy and set up the start script
COPY ./start.sh /scripts/start.sh
WORKDIR /scripts
RUN chmod +x start.sh

# Create a user with the same UID/GID as the host user
ARG uid
RUN useradd -G www-data,root -u $uid -d /home/devuser devuser
RUN mkdir -p /home/devuser/.composer && \
    chown -R devuser:devuser /home/devuser

# Set permissions for Laravel storage and cache directories if they exist
RUN if [ -d /var/www/html/storage ]; then chown -R www-data:www-data /var/www/html/storage; fi \
    && if [ -d /var/www/html/public ]; then chown -R www-data:www-data /var/www/html/public; fi \
    && if [ -d /var/www/html/bootstrap/cache ]; then chown -R www-data:www-data /var/www/html/bootstrap/cache; fi

RUN if [ -d /var/www/html/storage ]; then chmod -R 775 /var/www/html/storage; fi \
    && if [ -d /var/www/html/public ]; then chmod -R 775 /var/www/html/public; fi \
    && if [ -d /var/www/html/bootstrap/cache ]; then chmod -R 775 /var/www/html/bootstrap/cache; fi

# Set the entrypoint to the start script
# ENTRYPOINT ["/scripts/start.sh"]

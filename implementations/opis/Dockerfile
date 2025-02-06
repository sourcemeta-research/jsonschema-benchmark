FROM composer:2.8.5

COPY . /app
RUN composer install
ENTRYPOINT ["composer", "-d", "/app", "benchmark"]
CMD []

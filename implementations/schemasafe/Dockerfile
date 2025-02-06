FROM node:23.7.0-alpine3.21

COPY . /app
RUN npm ci --prefix /app
ENTRYPOINT ["node", "--disable-warning=ExperimentalWarning", "/app/main.mjs"]
CMD []

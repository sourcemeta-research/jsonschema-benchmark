FROM node:22-alpine

COPY . /app
RUN npm ci --prefix /app
ENTRYPOINT ["node", "--disable-warning=ExperimentalWarning", "/app/main.mjs"]
CMD []

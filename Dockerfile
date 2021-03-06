
FROM alpine:latest

ENV GITHUB_REPOSITORY=
ENV GITHUB_REPOSITORY_OWNER=
ENV GITHUB_API_URL=

ENV INPUT_VERSION=
ENV INPUT_FOLDER=
ENV INPUT_TOKEN=
ENV INPUT_REPONAME=

RUN apk add jq curl zip unzip sed bash

RUN mkdir -p /app

COPY app/* /app/

RUN chmod +x /app/entrypoint.sh; \
  chmod +x /app/gh-dl-release; \
  chmod +x /app/build.sh;

ENTRYPOINT ["/app/entrypoint.sh"]
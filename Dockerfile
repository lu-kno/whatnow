FROM golang:alpine AS builder
RUN apk add npm git just nodejs bash
WORKDIR /src

# install npm dependencies to populate cache
COPY ./web/package.json ./web/package-lock.json ./web/.npmrc web/
RUN --mount=type=cache,target=/root/.npm \
    cd web; npm ci --only=production --no-audit --no-fund
RUN --mount=type=cache,target=/root/.npm \
    cd web; npm ci --no-audit --no-fund

# download go dependencies
COPY ./go.mod ./go.sum ./
RUN go mod download

# build linux binary
COPY . /src/
RUN --mount=type=cache,target=/root/.npm \
    just build-linux

FROM alpine AS final

COPY --from=builder /src/dist/whatnow-linux-amd64 /bin/
EXPOSE 7777
WORKDIR /app
VOLUME /app/data
LABEL org.opencontainer.image.name="whatnow"
CMD [ "whatnow", "serve", "--addr", "0.0.0.0:7777", "-db", "/app/data/whatnow.db" ]

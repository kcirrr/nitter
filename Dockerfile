FROM nimlang/nim:alpine as builder

RUN apk --no-cache add libsass-dev libffi-dev openssl-dev redis openssh-client

COPY . /src/nitter
WORKDIR /src/nitter

RUN nimble build -y -d:release --passC:"-flto" --passL:"-flto" \
    && strip -s nitter \
    && nimble scss


FROM alpine:3.14
EXPOSE 8080

ENV USER nitter
ENV UID 32784
ENV GID 32784

WORKDIR /src/

RUN groupadd -r "${USER}" --gid="${GID}" \
    && useradd --no-log-init -r -g "${GID}" --uid="${UID}" "${USER}" \
    && apk --no-cache add pcre-dev sqlite-dev
COPY --chown="${USER}" --from=builder /src/nitter/nitter /src/nitter/nitter.conf ./
COPY --chown="${USER}" --from=builder /src/nitter/public ./public

USER "${USER}"

CMD ["./nitter"]

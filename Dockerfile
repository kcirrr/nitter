FROM zedeus/nitter:latest as builder


FROM alpine:3.14
EXPOSE 8080

ENV USER nitter
ENV UID 32784
ENV GID 32784

WORKDIR /src/

RUN addgroup \
    --gid "$GID" \
    "$USER" \
    && adduser \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --ingroup "$USER" \
    --no-create-home \
    --uid "$UID" \
    "$USER" \
    && apk --no-cache add pcre-dev sqlite-dev

COPY --chown="${USER}" --from=builder /src/nitter /src/nitter.conf ./
COPY --chown="${USER}" --from=builder /src/public ./public

USER "${USER}"

CMD ["./nitter"]

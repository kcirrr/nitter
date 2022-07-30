FROM ubuntu:22.04 as builder

ENV PATH=~/.nimble/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
    g++ \
    curl \
    ca-certificates \
    tar \
    xz-utils \
    nodejs \
    libsass-dev \
    libffi-dev \
    libssl-dev \
    redis \
    openssh-client \
    git \
    mercurial \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && c_rehash

WORKDIR /nim/

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p /nim /src/nitter/ \
    && curl -sL https://github.com/zedeus/nitter/archive/master.tar.gz \
    | tar -xzC /src/nitter/ --strip-components=1 \
    && curl -sL "https://nim-lang.org/download/nim-1.4.8.tar.xz" \
    | tar xJ --strip-components=1 -C /nim \
    && sh build.sh \
    && rm -r c_code tests \
    && ln -s /nim/bin/nim /bin/nim \
    && nim c koch \
    && ./koch tools \
    && ln -s /nim/bin/nimble /bin/nimble \
    && ln -s /nim/bin/nimsuggest /bin/nimsuggest \
    && ln -s /nim/bin/testament /bin/testament

WORKDIR /src/nitter/

RUN nimble build -y -d:release --passC:"-flto" --passL:"-flto" \
    && strip -s nitter \
    && nimble scss


FROM redis:6.2-buster

ENV USER nitter
ENV UID 32784
ENV GID 32784

WORKDIR /src/

RUN mkdir -p /src \
    && groupadd -r "${USER}" --gid="${GID}" \
    && useradd --no-log-init -r -g "${GID}" --uid="${UID}" "${USER}" \
    && apt-get update \
    && apt-get install --no-install-recommends --yes \
    libsqlite3-dev \
    libpcre3 \
    libpcre3-dev \
    libssl-dev \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --chown="${USER}" --from=builder /src/nitter/nitter /src/nitter/start.sh /src/nitter/nitter.conf ./
COPY --chown="${USER}" --from=builder /src/nitter/public ./public

USER "${USER}"
EXPOSE 8080

CMD ["./start.sh"]

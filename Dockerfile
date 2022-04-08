# syntax=docker/dockerfile:1
FROM ubuntu:bionic-20220401
ENV LD_LIBRARY_PATH=/usr/local/lib PREFIX=/usr/local HOST_OS=Linux
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -qqy --no-install-recommends \
    gcc \
    libssl-dev \
    build-essential \
    dpkg-sig \
    libcap-dev \
    libc6-dev \
    sudo \
    git \
    cmake \
    curl \
    libgmp-dev \
    libssl-dev \
    libbz2-dev \
    libreadline-dev \
    software-properties-common \
    libsecp256k1-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

RUN curl -sSL https://get.haskellstack.org/ | sh
COPY . /echidna/
WORKDIR /echidna
RUN .github/scripts/install-libff.sh
RUN stack upgrade && stack setup && stack install --extra-include-dirs=/usr/local/include --extra-lib-dirs=/usr/local/lib

FROM ubuntu:bionic-20220401 AS final
ENV PREFIX=/usr/local HOST_OS=Linux
WORKDIR /root

COPY --from=builder /root/.local/bin/echidna-test /root/.local/bin/echidna-test
COPY .github/scripts/install-crytic-compile.sh .github/scripts/install-crytic-compile.sh
#RUN curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -

RUN apt-get update && apt-get install -qqy --no-install-recommends \
    wget \
    locales-all \
    locales \
    dpkg-sig \
    libcap-dev \
    libc6-dev \
    ca-certificates \
    python3.7 \
    python3-pip \
    python3-setuptools \
    libsecp256k1-0 \
    npm \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7.10

RUN wget https://github.com/ethereum/solidity/releases/download/v0.8.13/solc-static-linux && chmod +x solc-static-linux && mv solc-static-linux /usr/bin/solc
RUN .github/scripts/install-crytic-compile.sh
RUN update-locale LANG=en_US.UTF-8 && locale-gen en_US.UTF-8

RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
RUN locale-gen C.UTF-8 || true
ENV LANG=C.UTF-8

RUN npm install -g npx
ENV PATH=$PATH:/root/.local/bin LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /src
CMD ["/bin/bash"]

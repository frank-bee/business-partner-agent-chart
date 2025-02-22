# Copyright (c) 2020 Gitpod GmbH. All rights reserved.
# Licensed under the GNU Affero General Public License (AGPL).
# See License-AGPL.txt in the project root for license information.

FROM gitpod/workspace-full-vnc:latest

ENV TRIGGER_REBUILD 12

USER root

### QEMU (x86) and workspace kernel development tools
RUN install-packages qemu qemu-system-x86 linux-image-$(uname -r) libguestfs-tools sshpass

### Clang and LLVM
RUN install-packages clang-7 llvm-7

### cloud_sql_proxy ###
#ARG CLOUD_SQL_PROXY=/usr/local/bin/cloud_sql_proxy
#RUN curl -fsSL https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 > $CLOUD_SQL_PROXY \
#    && chmod +x $CLOUD_SQL_PROXY

### Azure CLI ###
RUN curl -sL https://aka.ms/InstallAzureCLIDeb

### Helm3 ###
RUN mkdir -p /tmp/helm/ \
    && curl -fsSL https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz | tar -xzvC /tmp/helm/ --strip-components=1 \
    && cp /tmp/helm/helm /usr/local/bin/helm \
    && cp /tmp/helm/helm /usr/local/bin/helm3 \
    && rm -rf /tmp/helm/ \
    && helm completion bash > /usr/share/bash-completion/completions/helm

### kubernetes ###
#RUN mkdir -p /usr/local/kubernetes/ && \
#   curl -fsSL https://github.com/kubernetes/kubernetes/releases/download/v1.17.16/kubernetes.tar.gz \
#    | tar -xzvC /usr/local/kubernetes/ --strip-components=1 \
#    && KUBERNETES_SKIP_CONFIRM=true /usr/local/kubernetes/cluster/get-kube-binaries.sh \
#    && chown gitpod:gitpod -R /usr/local/kubernetes
#
#ENV PATH=$PATH:/usr/local/kubernetes/cluster/:/usr/local/kubernetes/client/bin/

### kubectl ###
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    # really 'xenial'
    && add-apt-repository -yu "deb https://apt.kubernetes.io/ kubernetes-xenial main" \
    && install-packages kubectl=1.20.0-00 \
    && kubectl completion bash > /usr/share/bash-completion/completions/kubectl

RUN curl -fsSL -o /usr/bin/kubectx https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx && chmod +x /usr/bin/kubectx \
    && curl -fsSL -o /usr/bin/kubens  https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens  && chmod +x /usr/bin/kubens

RUN curl -fsSL https://go.kubebuilder.io/dl/2.3.2/linux/amd64 | tar -xz -C /tmp/ \
    && sudo mkdir -p /usr/local/kubebuilder \
    && sudo mv /tmp/kubebuilder_2.3.2_linux_amd64/* /usr/local/kubebuilder \
    && rm -rf /tmp/*

### MySQL client ###
#RUN install-packages mysql-client

# golangci-lint
#RUN cd /usr/local && curl -fsSL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s v1.39.0

# leeway
#ENV LEEWAY_NESTED_WORKSPACE=true
#RUN cd /usr/bin && curl -fsSL https://github.com/TypeFox/leeway/releases/download/v0.2.2/leeway_0.2.2_Linux_x86_64.tar.gz | tar xz

# dazzle
#RUN cd /usr/bin && curl -fsSL https://github.com/32leaves/dazzle/releases/download/v0.0.3/dazzle_0.0.3_Linux_x86_64.tar.gz | tar xz

# werft CLI
#ENV WERFT_K8S_NAMESPACE=werft
#ENV WERFT_DIAL_MODE=kubernetes
#RUN cd /usr/bin && curl -fsSL https://github.com/csweichel/werft/releases/download/v0.0.5rc/werft-client-linux-amd64.tar.gz | tar xz && mv werft-client-linux-amd64 werft

# yq - jq for YAML files
# Note: we rely on version 3.x.x in various places, 4.x breaks this!
RUN cd /usr/bin && curl -fsSL https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 > yq && chmod +x yq

# release helper
RUN cd /usr/bin && curl -fsSL https://github.com/c4milo/github-release/releases/download/v1.1.0/github-release_v1.1.0_linux_amd64.tar.gz | tar xz

### Protobuf
RUN set -ex \
    && tmpdir=$(mktemp -d) \
    && curl -fsSL -o $tmpdir/protoc.zip https://github.com/protocolbuffers/protobuf/releases/download/v3.15.5/protoc-3.15.5-linux-x86_64.zip \
    && mkdir -p /usr/lib/protoc && cd /usr/lib/protoc && unzip $tmpdir/protoc.zip \
    && chmod -R o+r+x /usr/lib/protoc/include \
    && chmod -R +x /usr/lib/protoc/bin \
    && ln -s /usr/lib/protoc/bin/* /usr/bin \
    && rm -rf $tmpdir

### Telepresence ###
#RUN curl -fsSL https://packagecloud.io/datawireio/telepresence/gpgkey | apt-key add - \
#    # 'cosmic' not supported
#    && add-apt-repository -yu "deb https://packagecloud.io/datawireio/telepresence/ubuntu/ bionic main" \
#    # 0.95 (current at the time of this commit) is broken
#    && install-packages \
#    iproute2 \
#    iptables \
#    net-tools \
#    socat \
#    telepresence=0.109

### Toxiproxy CLI
#RUN curl -fsSL -o /usr/bin/toxiproxy https://github.com/Shopify/toxiproxy/releases/download/v2.1.4/toxiproxy-cli-linux-amd64 \
#    && chmod +x /usr/bin/toxiproxy

### libseccomp > 2.5.0
RUN install-packages gperf \
    && cd $(mktemp -d) \
    && curl -fsSL https://github.com/seccomp/libseccomp/releases/download/v2.5.1/libseccomp-2.5.1.tar.gz | tar xz \
    && cd libseccomp-2.5.1 && ./configure && make && make install

USER gitpod

# Fix node version we develop against
ARG GITPOD_NODE_VERSION=12.22.1
RUN bash -c ". .nvm/nvm.sh \
    && nvm install $GITPOD_NODE_VERSION \
    && npm install -g typescript yarn"
ENV PATH=/home/gitpod/.nvm/versions/node/v${GITPOD_NODE_VERSION}/bin:$PATH

# Go
ENV GOFLAGS="-mod=readonly"

## Register leeway autocompletion in bashrc
#RUN bash -c "echo . \<\(leeway bash-completion\) >> ~/.bashrc"

# Install tools for gsutil
RUN sudo install-packages \
    gcc \
    python-dev \
    python-setuptools

RUN bash -c "pip uninstall crcmod; pip install --no-cache-dir -U crcmod"

# Set k8s user config for dev cluster
RUN echo ". /workspace/business-partner-agent-chart/scripts/setup-kubeconfig.sh" >> ~/.bashrc

#ENV LEEWAY_WORKSPACE_ROOT=/workspace/gitpod
#ENV LEEWAY_REMOTE_CACHE_BUCKET=gitpod-core-leeway-cache-branch

# Install Terraform
#ARG RELEASE_URL="https://releases.hashicorp.com/terraform/0.15.4/terraform_0.15.4_linux_amd64.zip"
#RUN mkdir -p ~/.terraform \
#    && cd ~/.terraform \
#    && curl -fsSL -o terraform_linux_amd64.zip ${RELEASE_URL} \
#    && unzip *.zip \
#    && rm -f *.zip \
#    && printf "terraform -install-autocomplete\n" >>~/.bashrc

# Install GraphViz to help debug terraform scripts
#RUN sudo install-packages graphviz

#ENV PATH=$PATH:$HOME/.aws-iam:$HOME/.terraform

# brew : helm-docs, pre-commit, chart-testing
RUN brew install norwoodj/tap/helm-docs pre-commit chart-testing
FROM ubuntu:22.04

# install base
RUN apt-get update \
    && apt-get install -y \
        software-properties-common \
        gnupg2 \
        curl \
        unzip \
        gpg \
        wget \
        less \
        git \
        vim \
        jq

# install terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt update \
    && apt install terraform

# install azure-cli
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash 

# add kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# latest terraform
RUN mkdir -p /workspace/terraform
COPY modules /workspace/terraform/modules
COPY build.sh /workspace/terraform
COPY *.tf /workspace/terraform


ENTRYPOINT [ "/bin/bash" ]
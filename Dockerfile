FROM alpine:latest

ARG CLOUD_SDK_VERSION=245.0.0
ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION
ENV TERRAFORM_VERSION=0.11.8
ENV TF_DEV=true
ENV TF_RELEASE=true

ADD settings/bashrc /etc/bash.bashrc
ADD settings/bashrc /etc/skel/.bashrc
ADD settings/vimrc /etc/vim/vimrc
ADD settings/profile /etc/profile

RUN echo http://nl.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories && \
    echo http://nl.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories && \
    echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    apk update && \
    apk --no-cache add \
    git \
    openssl \
    ca-certificates \
    bash \
    vim \ 
    curl \
    gcc \
    netcat-openbsd \
    perl-net-telnet \
    grep \
    openssh-client \
    nmap \
    drill \
    python3 \
    sudo && \
    pip3 install awscli && \
    pip3 install boto3 && \
    ln -s /usr/bin/drill /usr/bin/dig

ENV PATH /google-cloud-sdk/bin:$PATH
RUN apk --no-cache add \
    curl \
    python \
    py-crcmod \
    bash \
    libc6-compat \
    openssh-client \
    git \
    gnupg \
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    ln -s /lib /lib64 && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version

VOLUME ["/root/.config"]

# Adding the package path to local
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin

ADD settings/motd /etc/motd
# Set Root to bash not ash and overwrite .bashrc
RUN sed -i 's/root:\/bin\/ash/root:\/bin\/bash/' /etc/passwd && \
    cp /etc/skel/.bashrc /root/.bashrc

# Link vi to vim (otherwise ric no happy)
RUN ln -sf vim /usr/bin/vi ; ln -s /usr/bin/pip3 /usr/bin/pip

# Link python to python3
RUN cd /usr/local/bin && ln -sf pydoc3 pydoc && ln -sf python3 python && ln -sf python3-config python-config

# Installing Terraform
RUN cd /usr/local/bin && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    terraform -v

# Installing Ansible
RUN apk add ansible ; ansible --version

# Customizing Ansible
RUN mkdir /etc/ansible ; echo 'localhost' > /etc/ansible/hosts

# Setup user a regular user
RUN /usr/sbin/adduser -D -G wheel -k /etc/skel -s /bin/bash user && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers


WORKDIR /root

CMD ["/bin/bash"]



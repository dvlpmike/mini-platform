FROM mcr.microsoft.com/azure-cli

WORKDIR /mini-platform

COPY mini-platform.yaml .
COPY hosts .
COPY group_vars/ group_vars/

RUN apk update \
    && apk upgrade \
    && apk add ansible \
    && rm -rf /var/cache/apk/* \
    && mkdir ssh_keys

LABEL maintainer="dvlpmike" \
      description="Docker image for provisioning mini platform with Azure CLI and Ansible. Image source https://hub.docker.com/_/microsoft-azure-cli?tab=description"

FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_MAJOR=20

RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://us-east1.gce.archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list && \
    apt-get update

# 1. 系统核心工具 & 开发必需品
# 保留缓存，不执行清理命令
RUN apt-get install -y \
    curl \
    bash \
    ca-certificates \
    git \
    sudo \
    vim \
    wget \
    gnupg \
    iputils-ping \
    net-tools \
    dnsutils \
    htop \
    unzip \
    jq \
    build-essential \
    pkg-config \
    python3 \
    python3-pip

    

# 3. 安装 OpenCode & oh-my-opencode
# 使用构建参数传入代理，确保在 Docker Build 阶段能连上安装服务器

# ARG http_proxy
# ARG https_proxy

RUN curl -fsSL https://opencode.ai/install | bash

# RUN opencode -v
# 4. 配置开发环境与别名
WORKDIR /projects
RUN echo 'alias ls="ls --color=auto"' >> /root/.bashrc \
    && echo 'alias ll="ls -la"' >> /root/.bashrc \
    && echo 'alias oc="opencode"' >> /root/.bashrc \
    && echo 'alias vi="vim"' >> /root/.bashrc

# 保持容器运行
CMD ["bash"]
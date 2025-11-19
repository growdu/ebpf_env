# 基于 Ubuntu 24.04
FROM ubuntu:24.04

# 设置环境变量，避免交互式安装
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV USER=ebpf
ENV PASSWORD=ebpf
ENV CODE_SERVER_VERSION=4.23.0

# 设置工作目录
WORKDIR /workspace

# 更新系统并安装基础工具
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    sudo \
    locales \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# 设置语言环境
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 创建非root用户
RUN useradd -m -s /bin/bash $USER && \
    echo "$USER:$PASSWORD" | chpasswd && \
    usermod -aG sudo $USER && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 安装 SSH 服务器
RUN apt-get update && apt-get install -y \
    openssh-server \
    && mkdir /var/run/sshd \
    && rm -rf /var/lib/apt/lists/*

# 配置 SSH
RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "X11Forwarding yes" >> /etc/ssh/sshd_config && \
    echo "X11DisplayOffset 10" >> /etc/ssh/sshd_config && \
    echo "PrintMotd no" >> /etc/ssh/sshd_config

# 安装所有开发工具（直接安装，不下载deb包）
RUN apt-get update && apt-get install -y \
    # 基础开发工具
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    pkg-config \
    gdb \
    clang \
    llvm \
    # 开发库
    libelf-dev \
    zlib1g-dev \
    libssl-dev \
    libcap-dev \
    libmnl-dev \
    binutils-dev \
    python3-dev \
    python3-venv \
    python3-pip \
    git \
    ca-certificates \
    # eBPF 相关
    libbpf-dev \
    elfutils \
    bpfcc-tools \
    python3-bpfcc \
    # 语言环境
    golang-go \
    rustc \
    cargo \
    nodejs \
    npm \
    # 其他工具
    vim \
    htop \
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# 安装 code-server
COPY code-server.deb /tmp/
RUN dpkg -i /tmp/code-server.deb || true && \
    # 修复依赖
    apt-get update && \
    apt-get install -f -y && \
    # 清理
    rm -rf /var/lib/apt/lists/*

# 设置 Rust 国内镜像
ENV RUSTUP_DIST_SERVER=https://rsproxy.cn
ENV RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup

# 安装 Rust 工具链
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# 配置 code-server
RUN mkdir -p /home/$USER/.config/code-server && \
    echo "bind-addr: 0.0.0.0:8080" > /home/$USER/.config/code-server/config.yaml && \
    echo "auth: password" >> /home/$USER/.config/code-server/config.yaml && \
    echo "password: $PASSWORD" >> /home/$USER/.config/code-server/config.yaml && \
    echo "cert: false" >> /home/$USER/.config/code-server/config.yaml && \
    chown -R $USER:$USER /home/$USER/.config

# 创建工作区目录
RUN mkdir -p /workspace/projects && \
    chown -R $USER:$USER /workspace

# 安装 code-server 扩展
# 复制启动脚本
COPY start-services.sh /usr/local/bin/start-services.sh
RUN chmod +x /usr/local/bin/start-services.sh

# 暴露端口
EXPOSE 22 8080 8888

# 切换到工作用户
USER $USER
WORKDIR /workspace

# 设置启动命令
CMD ["/usr/local/bin/start-services.sh"]

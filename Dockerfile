FROM centos:8

# Fix CentOS 8 repo (official mirrors are offline)
RUN sed -e 's|^mirrorlist=|#mirrorlist=|g' \
        -e 's|^#baseurl=http://mirror.centos.org|baseurl=http://mirrors.aliyun.com|g' \
        -i /etc/yum.repos.d/CentOS-*.repo && \
    dnf clean all && dnf makecache


ENV LANG=C.UTF-8
ENV GO_VERSION=1.21.7
ENV PATH=/usr/local/go/bin:$PATH

RUN dnf -y update &&     dnf -y install epel-release &&     dnf -y groupinstall "Development Tools" &&     dnf -y install       cmake make wget git unzip tar vim which       python3 python3-pip       clang llvm llvm-devel clang-devel       elfutils-libelf-devel libbpf-devel libbpf       kernel-headers kernel-devel       cmake3 pkgconfig       iproute iproute-doc       sudo curl jq openssh-server which &&     dnf clean all

# Install bpftool from kernel tools if not present
RUN if ! command -v bpftool >/dev/null 2>&1 ; then       mkdir -p /tmp/build && cd /tmp/build &&       git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/shemminger/bpf.git bpf-tools || true &&       cd bpf-tools/tools/bpftool && make && cp bpftool /usr/local/bin/ && cd / && rm -rf /tmp/build ;     fi

# Install libbpf if system package missing
RUN if [ ! -f /usr/lib64/libbpf.a ] ; then       mkdir -p /opt/libbpf && cd /opt &&       git clone --depth 1 https://github.com/libbpf/libbpf.git &&       cd libbpf/src && make && make install || true ;     fi

# Install Go
RUN curl -fsSL https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz -o /tmp/go.tar.gz &&     tar -C /usr/local -xzf /tmp/go.tar.gz && rm -f /tmp/go.tar.gz

# Python packages commonly used for eBPF tooling
RUN python3 -m pip install --upgrade pip setuptools wheel &&     python3 -m pip install bcc bpfcc prometheus-client

# Create developer user
RUN useradd -m dev && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev &&     mkdir -p /home/dev/workdir && chown -R dev:dev /home/dev

WORKDIR /home/dev
USER dev

ENV GOPATH=/home/dev/go
RUN mkdir -p /home/dev/go /home/dev/src /home/dev/bin

CMD ["/bin/bash"]

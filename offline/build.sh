#!/bin/bash
set -e

IMAGE_NAME="ebpf-dev"
IMAGE_TAG="latest"

echo "=== 构建 eBPF 开发环境 Docker 镜像 ==="


# 构建镜像
docker build -t $IMAGE_NAME:$IMAGE_TAG .

# 清理临时文件
rm -f start-services.sh

echo "=== 镜像构建完成 ==="
echo "运行命令: docker run -it -p 2222:22 -p 8080:8080 -p 8888:8888 $IMAGE_NAME:$IMAGE_TAG"

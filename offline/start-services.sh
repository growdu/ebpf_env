#!/bin/bash
#!/bin/bash
set -e

echo "=== 启动 eBPF 开发环境 ==="

# 启动 SSH 服务
echo "启动 SSH 服务..."
sudo /usr/sbin/sshd -D &

# 启动 code-server
echo "启动 code-server..."
code-server --auth password --bind-addr 0.0.0.0:8080 /workspace &

# 启动 Jupyter notebook（可选）
echo "启动 Jupyter notebook..."
jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password='' &

echo "=== 服务启动完成 ==="
echo "SSH 访问: ssh $USER@<container-ip> -p 22"
echo "密码: $PASSWORD"
echo "Code-Server: http://<container-ip>:8080"
echo "Jupyter: http://<container-ip>:8888"
echo "=== 环境信息 ==="
echo "GCC: $(gcc --version | head -1)"
echo "Clang: $(clang --version | head -1)"
echo "Go: $(go version)"
echo "Rust: $(rustc --version)"
echo "Python: $(python3 --version)"
echo "Node: $(node --version)"

# 保持容器运行
wait


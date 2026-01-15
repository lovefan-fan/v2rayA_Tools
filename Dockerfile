# 多阶段构建 - 构建阶段
FROM python:3.12-slim as builder

# 设置工作目录
WORKDIR /app

# 只复制依赖文件
COPY requirements.txt .

# 安装依赖
RUN pip install --no-cache-dir --user -r requirements.txt

# 最终阶段 - 使用最小的基础镜像
FROM python:3.12-slim

# 设置工作目录
WORKDIR /app

# 从构建阶段复制已安装的依赖
COPY --from=builder /root/.local /root/.local

# 设置环境变量
ENV PATH=/root/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# 创建非root用户以提高安全性
RUN useradd -m -u 1000 v2raya_tools && \
    chown -R v2raya_tools:v2raya_tools /app

# 切换到非root用户
USER v2raya_tools

# 复制应用代码（这一步会在docker-compose中通过volume映射覆盖）
COPY --chown=v2raya_tools:v2raya_tools *.py ./
COPY --chown=v2raya_tools:v2raya_tools config.json ./

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)" || exit 1

# 默认命令（会被docker-compose覆盖）
CMD ["python", "main.py"]

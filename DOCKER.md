# Docker 部署指南

本文档介绍如何使用 Docker 和 docker-compose 部署 v2rayA_Tools。

## 前置条件

1. 已安装 Docker 和 docker-compose
2. 已部署 v2rayA 容器
3. Python 版本 >= 3.7

## 配置说明

### 1. 配置 v2rayA 容器

确保你的 v2rayA 容器已经正确配置并运行。你需要知道：

- v2rayA 容器的名称（默认：`v2rayA`）
- v2rayA WebUI 的端口（默认：`2017`）
- v2rayA 的用户名和密码
- v2rayA 配置文件在宿主机上的映射路径

### 2. 修改 config.json

编辑 `config.json` 文件，填入你的 v2rayA 配置：

```json
{
    "v2raya_container_name": "v2rayA",
    "webui_port": 2017,
    "forced_reset_proxy": true,
    "username": "你的v2rayA用户名",
    "password": "你的v2rayA密码",
    "apply_subscription_ids": [1],
    "number_of_node_group_members": 110,
    "random_selected_node": true,
    "node_name_blacklist":[],
    "node_protocol_blacklist":[],
    "node_delay_limit": 1000,
    "v2raya_config": "/home/v2raya/config.json"
}
```

**重要配置项说明：**

- `v2raya_config`: 这是 v2rayA 配置文件在**宿主机**上的路径
  - 如果你的 v2rayA 容器启动命令是：`-v /etc/v2raya:/etc/v2raya`
  - 那么这里应该填：`/etc/v2raya/config.json`
  - 如果是：`-v /home/v2raya:/etc/v2raya`
  - 那么这里应该填：`/home/v2raya/config.json`

### 3. 修改 docker-compose.yml

根据你的 v2rayA 配置修改 `docker-compose.yml` 中的卷映射：

```yaml
volumes:
  # 映射当前目录的所有代码文件到容器
  - .:/app
  # 映射 Docker socket
  - /var/run/docker.sock:/var/run/docker.sock
  # 映射 v2rayA 配置文件目录（根据你的实际情况修改）
  - /home/v2raya:/home/v2raya:ro
```

**注意：** 
- 左边的路径是宿主机的路径
- 右边的路径是容器内的路径
- 必须与 `config.json` 中的 `v2raya_config` 路径匹配

## 使用方法

### 构建镜像

首次使用需要构建镜像：

```bash
docker-compose build
```

### 运行主程序（测试节点并择优绑定）

```bash
docker-compose run v2raya-tools python main.py
```

### 更新单个订阅

```bash
docker-compose run v2raya-tools python updateSub_one_sub.py
```

### 更新所有订阅

```bash
docker-compose run v2raya-tools python updateSub.py
```

### 停用代理并解除绑定

```bash
docker-compose run v2raya-tools python shutdownProxy.py
```

## 代码热重载

由于所有代码文件都通过卷映射到容器中，你可以在宿主机上直接修改代码：

1. 在宿主机上编辑 `.py` 文件
2. 无需重新构建镜像
3. 直接运行对应的脚本即可使用修改后的代码

## 镜像大小优化

本 Dockerfile 采用了以下优化措施：

1. **多阶段构建**：分离构建环境和运行环境
2. **最小基础镜像**：使用 `python:3.12-slim` 而非完整的 python 镜像
3. **依赖分离**：将依赖安装到 `/root/.local` 而非系统目录
4. **清理缓存**：使用 `--no-cache-dir` 减少 pip 缓存
5. **.dockerignore**：排除不必要的文件

最终镜像大小约为 **80-100 MB**（比标准 python 镜像小约 700 MB）

## 网络配置

默认使用 `network_mode: host`，这样可以：

- 直接访问宿主机网络
- 访问 v2rayA 的 WebUI 端口
- 执行 docker 命令管理其他容器

如果你的 v2rayA 在自定义网络中，可以修改为：

```yaml
network_mode: service:v2raya
```

或者使用外部网络：

```yaml
networks:
  default:
    name: v2raya-network
    external: true
```

## 常见问题

### Q: 提示找不到 v2rayA 容器？
A: 检查 `config.json` 中的 `v2raya_container_name` 是否与实际容器名一致。

### Q: 无法访问 v2rayA 配置文件？
A: 确保：
1. `docker-compose.yml` 中的卷映射路径正确
2. `config.json` 中的 `v2raya_config` 路径与映射匹配
3. 文件有读取权限

### Q: 如何查看容器日志？
A: 
```bash
docker-compose logs v2raya-tools
```

### Q: 如何进入容器调试？
A:
```bash
docker-compose run v2raya-tools /bin/bash
```

## 安全建议

1. 不要将包含敏感信息的 `config.json` 提交到版本控制
2. 确保 v2rayA 的用户名密码安全
3. 考虑使用 Docker secrets 管理敏感信息
4. 仅在受信任的网络环境中使用

## 维护和更新

### 更新代码后

由于代码已映射到容器，只需重新运行命令即可：

```bash
docker-compose run v2raya-tools python main.py
```

### 更新依赖

如果修改了 `requirements.txt`，需要重新构建：

```bash
docker-compose build --no-cache
```

### 清理容器

```bash
# 停止并删除容器
docker-compose down

# 删除镜像
docker rmi v2raya_tools
```

## 许可证

本项目遵循原项目的许可证。

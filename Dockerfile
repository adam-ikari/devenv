# 基于webtop:debian-xfce镜像
FROM lscr.io/linuxserver/webtop:debian-xfce

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 更新包列表并安装基础软件包
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    git \
    tree \
    build-essential \
    btop \
    neovim \
    ripgrep \
    fd-find \
    zsh \
    fonts-powerline \
    && rm -rf /var/lib/apt/lists/*

# 安装vscode-server
RUN curl -fsSL https://code-server.dev/install.sh | sh && \
    mkdir -p /root/.local/share/code-server/User && \
    echo '{"workbench.startupEditor":"none"}' > /root/.local/share/code-server/User/settings.json

# 安装nvm和Node.js
ENV NVM_DIR=/usr/local/nvm
ENV NODE_VERSION=22.10.0

RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install 16 && \
    nvm install 22 && \
    nvm alias default 22 && \
    nvm use default && \
    npm install -g yarn

ENV PATH=$NVM_DIR/versions/node/v${NODE_VERSION}/bin:$PATH

# 安装uv和Python环境
ENV UV_INSTALL_DIR=/usr/local/bin
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# 安装Python 3.5到最新版本
RUN $UV_INSTALL_DIR/uv python install 3.5 && \
    $UV_INSTALL_DIR/uv python install 3.12 && \
    $UV_INSTALL_DIR/uv python install 3.13

# 设置默认Python版本
RUN $UV_INSTALL_DIR/uv python pin 3.13

# 安装C++开发环境
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    g++ \
    clang \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# 安装Oh My Zsh和相关插件
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.oh-my-zsh/custom/themes/powerlevel10k && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# 配置.zshrc
RUN echo 'export ZSH="/root/.oh-my-zsh"' > /root/.zshrc && \
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> /root/.zshrc && \
    echo 'plugins=(git docker docker-compose npm yarn zsh-syntax-highlighting zsh-autosuggestions)' >> /root/.zshrc && \
    echo 'source $ZSH/oh-my-zsh.sh' >> /root/.zshrc && \
    echo 'export NVM_DIR="/usr/local/nvm"' >> /root/.zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"' >> /root/.zshrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"' >> /root/.zshrc && \
    echo 'export PATH="/usr/local/bin:$PATH"' >> /root/.zshrc && \
    echo 'eval "$(uv gen-shell-completion zsh)"' >> /root/.zshrc

# 设置默认shell为zsh
RUN chsh -s $(which zsh)

# 清理apt缓存
RUN apt-get clean

# 创建工作目录
WORKDIR /workspace

# 暴露code-server端口
EXPOSE 8080

# 启动命令
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "."]
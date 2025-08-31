FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    nodejs \
    npm \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Neovim
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage \
    && chmod u+x nvim.appimage \
    && mv nvim.appimage /usr/local/bin/nvim

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install security tools
RUN pip3 install bandit requests

# Install Trivy
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Create app user
RUN useradd -m -s /bin/bash appuser
USER appuser
WORKDIR /home/appuser

# Copy nvim-secscan
COPY --chown=appuser:appuser . /home/appuser/nvim-secscan

# Install nvim-secscan
RUN cd nvim-secscan && chmod +x install.sh && ./install.sh

# Create Neovim config directory
RUN mkdir -p /home/appuser/.config/nvim

# Copy Neovim configuration
COPY --chown=appuser:appuser deploy/docker/init.lua /home/appuser/.config/nvim/init.lua

# Set PATH
ENV PATH="/home/appuser/.local/bin:$PATH"

# Expose any ports if needed (none for CLI tool)
# EXPOSE 8080

# Default command
CMD ["/bin/bash"]
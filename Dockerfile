# ============================================================================
# Multi-stage Dockerfile for NS-3.42 on Alpine Linux
# Optimized for performance and minimal image size
# ============================================================================

# ============================================================================
# Stage 1: Builder - Compile NS-3 with all dependencies
# ============================================================================
FROM alpine:3.19 AS builder

# Metadata
LABEL maintainer="NS-3 Docker <ns3@example.com>"
LABEL description="NS-3.42 Network Simulator - Builder Stage"
LABEL version="3.42"

# Build arguments
ARG NS3_VERSION=3.42
ARG NS3_BUILD_PROFILE=optimized
ARG JOBS=4

# Set working directory
WORKDIR /tmp

# Install build dependencies
RUN apk add --no-cache \
    # Core build tools
    build-base \
    cmake \
    ninja \
    ccache \
    git \
    wget \
    tar \
    # NS-3 dependencies
    python3 \
    python3-dev \
    py3-pip \
    py3-setuptools \
    # C++ libraries
    boost-dev \
    gsl-dev \
    sqlite-dev \
    libxml2-dev \
    # Additional tools
    bash \
    && rm -rf /var/cache/apk/*

# Configure ccache for faster rebuilds
ENV CCACHE_DIR=/ccache
ENV PATH="/usr/lib/ccache/bin:${PATH}"
RUN mkdir -p ${CCACHE_DIR} && ccache --max-size=2G

# Download and extract NS-3
RUN echo "==> Downloading NS-3 ${NS3_VERSION}..." && \
    wget -q https://www.nsnam.org/releases/ns-allinone-${NS3_VERSION}.tar.bz2 && \
    echo "==> Extracting NS-3..." && \
    tar -xjf ns-allinone-${NS3_VERSION}.tar.bz2 && \
    rm ns-allinone-${NS3_VERSION}.tar.bz2 && \
    mv ns-allinone-${NS3_VERSION}/ns-${NS3_VERSION} /ns3 && \
    rm -rf ns-allinone-${NS3_VERSION}

# Set NS-3 working directory
WORKDIR /ns3

# Configure NS-3 with optimizations
RUN echo "==> Configuring NS-3..." && \
    ./ns3 configure \
    --build-profile=${NS3_BUILD_PROFILE} \
    --enable-examples \
    --enable-tests \
    --out=/ns3/build \
    --disable-gtk \
    --disable-python

# Build NS-3 core
RUN echo "==> Building NS-3 (this may take 10-15 minutes)..." && \
    ./ns3 build -j${JOBS}

# Run tests to verify build (optional but recommended)
RUN echo "==> Running basic tests..." && \
    ./test.py --nowaf || true

# ============================================================================
# Stage 2: Runtime - Minimal image with only runtime dependencies
# ============================================================================
FROM alpine:3.19 AS runtime

# Metadata
LABEL maintainer="NS-3 Docker <ns3@example.com>"
LABEL description="NS-3.42 Network Simulator - Runtime"
LABEL version="3.42"

# Runtime arguments
ARG NS3_USER=ns3user
ARG NS3_UID=1000
ARG NS3_GID=1000

# Install only runtime dependencies (much smaller than builder)
RUN apk add --no-cache \
    # Runtime essentials
    bash \
    python3 \
    py3-pip \
    # Build tools for scratch simulations
    build-base \
    cmake \
    ninja \
    ccache \
    # Required libraries
    libstdc++ \
    libgcc \
    gsl-dev \
    sqlite-dev \
    libxml2-dev \
    boost-dev \
    # Utilities
    coreutils \
    findutils \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g ${NS3_GID} ${NS3_USER} && \
    adduser -D -u ${NS3_UID} -G ${NS3_USER} -h /home/${NS3_USER} -s /bin/bash ${NS3_USER}

# Copy compiled NS-3 from builder
COPY --from=builder --chown=${NS3_USER}:${NS3_USER} /ns3 /ns3

# Create volume mount points
RUN mkdir -p /ns3/scratch /ns3/results /ns3/contrib && \
    chown -R ${NS3_USER}:${NS3_USER} /ns3

# Set working directory
WORKDIR /ns3

# Switch to non-root user
USER ${NS3_USER}

# Environment variables
ENV PATH="/ns3:${PATH}"
ENV NS3_HOME="/ns3"
ENV RESULTS_DIR="/ns3/results"

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ./ns3 --version || exit 1

# Default command: show help
CMD ["./ns3", "--help"]

# ============================================================================
# Stage 3: Development - Full image with dev tools (optional)
# ============================================================================
FROM runtime AS development

USER root

# Install development tools
RUN apk add --no-cache \
    build-base \
    cmake \
    ninja \
    git \
    vim \
    nano \
    tmux \
    gdb \
    valgrind \
    strace \
    htop \
    python3-dev \
    linux-headers \
    && rm -rf /var/cache/apk/*

# Install Python packages for analysis
RUN pip3 install --no-cache-dir --break-system-packages \
    numpy \
    pandas \
    matplotlib \
    scipy \
    jupyter

# Copy build artifacts for rebuilding
COPY --from=builder /ns3/cmake-cache /ns3/cmake-cache

# Switch back to user
USER ${NS3_USER}

# Expose Jupyter port (if needed)
EXPOSE 8888

CMD ["/bin/bash"]

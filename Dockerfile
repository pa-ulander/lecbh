FROM ubuntu:22.04

# Set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Apache, Nginx, and support tools
RUN apt-get update && apt-get install -y \
    apache2 \
    nginx \
    netcat-openbsd \
    iputils-ping \
    dnsutils \
    snapd \
    python3-pip \
    python3-dev \
    lsb-release \
    curl \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up directory for the script
WORKDIR /app

# Copy the script into the container
COPY lecbh.sh /app/
COPY test.sh /app/
RUN chmod +x /app/lecbh.sh
RUN chmod +x /app/test.sh

# Create a startup script that properly starts services
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo '# Start Apache on port 80' >> /app/start.sh && \
    echo 'echo "Starting Apache..."' >> /app/start.sh && \
    echo 'service apache2 start || echo "Failed to start Apache"' >> /app/start.sh && \
    echo '# Configure Nginx to use port 8080 to avoid conflict with Apache' >> /app/start.sh && \
    echo 'echo "Configuring Nginx for port 8080..."' >> /app/start.sh && \
    echo 'sed -i "s/listen 80/listen 8080/g" /etc/nginx/sites-available/default' >> /app/start.sh && \
    echo 'echo "Starting Nginx..."' >> /app/start.sh && \
    echo 'service nginx start || echo "Failed to start Nginx"' >> /app/start.sh && \
    echo '# Install certbot pip version for testing' >> /app/start.sh && \
    echo 'echo "Installing pip certbot for testing..."' >> /app/start.sh && \
    echo 'pip3 install --no-input certbot certbot-apache certbot-nginx > /dev/null' >> /app/start.sh && \
    echo 'echo "Services started. Container is ready for testing lecbh.sh."' >> /app/start.sh && \
    echo 'echo "Apache status:" && service apache2 status || echo "Apache status check failed"' >> /app/start.sh && \
    echo 'echo "Nginx status:" && service nginx status || echo "Nginx status check failed"' >> /app/start.sh && \
    echo '# Keep the container running' >> /app/start.sh && \
    echo 'tail -f /dev/null' >> /app/start.sh && \
    chmod +x /app/start.sh

EXPOSE 80 443 8080

CMD ["/app/start.sh"]

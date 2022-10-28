FROM podman-in-podman:latest

RUN dnf -y update && \
    dnf install -y \
        java-17-openjdk.x86_64 \
        socat && \
        zip && \
    dnf clean all && \
    rm -rf /var/cache /var/log/dnf* /var/log/yum.*


RUN curl -s https://get.nextflow.io | bash && \
    chmod +rx nextflow && \
    mv nextflow /usr/local/bin

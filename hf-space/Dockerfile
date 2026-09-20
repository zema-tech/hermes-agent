# Hugging Face Space (Docker SDK) running Hermes from the prebuilt image published by
# .github/workflows/docker-publish-ghcr.yml. The package must be public on ghcr.io.
FROM ghcr.io/zema-tech/hermes-agent:latest

USER root
RUN useradd -m -u 1000 user 2>/dev/null || true \
 && mkdir -p /home/user/data \
 && chown -R 1000:1000 /home/user

ENV HOME=/home/user \
    HERMES_HOME=/home/user/data \
    HERMES_WRITE_SAFE_ROOT=/home/user/data \
    HERMES_LAZY_INSTALL_TARGET=/home/user/data/lazy-packages \
    PORT=7860

USER 1000
WORKDIR /home/user
EXPOSE 7860

ENTRYPOINT ["/bin/sh", "/opt/hermes/docker/hf-start.sh"]
CMD []

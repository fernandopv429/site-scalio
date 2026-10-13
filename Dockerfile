# Site da Scalio: arquivos estáticos servidos por nginx, com configuração por variáveis de ambiente.
FROM nginx:stable-alpine
ENV TZ=America/Sao_Paulo
RUN rm -rf /usr/share/nginx/html/* /etc/nginx/conf.d/default.conf
COPY docker/40-scalio.sh /docker-entrypoint.d/40-scalio.sh
RUN chmod +x /docker-entrypoint.d/40-scalio.sh
COPY site/ /usr/share/nginx/html/
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD wget -qO- http://127.0.0.1/healthz >/dev/null 2>&1 || exit 1

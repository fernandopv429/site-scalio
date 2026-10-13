#!/bin/sh
# Roda na inicialização do contêiner (a imagem do nginx executa os scripts de /docker-entrypoint.d).
# Define o domínio, gera o config.js a partir das variáveis de ambiente, trata as páginas legais e escreve a configuração do nginx.
set -eu
ROOT="${WEBROOT:-/usr/share/nginx/html}"
CONF="${NGINX_CONF_OUT:-/etc/nginx/conf.d/default.conf}"
SNIP="${SNIPPET_OUT:-/etc/nginx/scalio-seguranca.conf}"
log() { echo "[scalio] $*"; }
erro() { echo "[scalio] ERRO: $*" >&2; exit 1; }
js() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\r\n'; }

SITE_URL="${SITE_URL:-}"; SITE_URL="${SITE_URL%/}"
LEADS_WEBHOOK_URL="${LEADS_WEBHOOK_URL:-https://n8n.nexusdevhub.com/webhook/096735fb-68ba-4376-b005-d03d3977982c}"; LEADS_WEBHOOK_URL="${LEADS_WEBHOOK_URL%/}"
NOINDEX=0

if [ -n "$SITE_URL" ]; then
  echo "$SITE_URL" | grep -Eq '^https://[A-Za-z0-9.-]+(:[0-9]+)?$' || erro "SITE_URL inválido. Use o formato https://www.seudominio.com.br"
fi
if [ -n "$LEADS_WEBHOOK_URL" ]; then
  echo "$LEADS_WEBHOOK_URL" | grep -Eq '^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/[A-Za-z0-9._~/-]*)?$' || erro "LEADS_WEBHOOK_URL inválido. Use o formato https://n8n.seudominio.com.br/webhook/..."
fi

# 1) domínio nos arquivos (canonical, imagens de compartilhamento, robots e sitemap)
if [ -n "$SITE_URL" ]; then
  find "$ROOT" -type f \( -name '*.html' -o -name 'robots.txt' -o -name 'sitemap.xml' \) -exec sed -i "s|https://SEUSITE.com.br|$SITE_URL|g" {} +
  log "domínio definido: $SITE_URL"
else
  NOINDEX=1
  log "AVISO: SITE_URL não definido. O site será servido com noindex até você definir o domínio."
fi

# 2) páginas legais: só saem do rascunho quando você confirma a revisão jurídica
if [ "${POLITICAS_REVISADAS:-false}" = "true" ]; then
  for f in privacidade.html termos.html; do
    [ -f "$ROOT/$f" ] && sed -i -E 's|<!--REV-->.*<!--/REV-->||g' "$ROOT/$f"
  done
  log "política e termos marcados como revisados (aviso e noindex removidos)"
else
  log "política e termos em rascunho (aviso e noindex mantidos)"
fi

# 3) config.js a partir das variáveis de ambiente (só quando alguma estiver definida)
if [ -n "${LEADS_WEBHOOK_URL}${SITE_WHATSAPP:-}${SITE_EMAIL:-}${EMPRESA_RAZAO:-}${EMPRESA_CNPJ:-}${EMPRESA_CIDADE:-}${EMPRESA_ENDERECO:-}${EMPRESA_DPO:-}${EMPRESA_FORO:-}${EMPRESA_DATA_POLITICAS:-}" ]; then
  cat > "$ROOT/config.js" <<JS
window.SCALIO_CONFIG = Object.assign({
  webhookUrl: "$(js "$LEADS_WEBHOOK_URL")",
  whatsapp: "$(js "${SITE_WHATSAPP:-}")",
  email: "$(js "${SITE_EMAIL:-}")",
  instagram: "$(js "${SITE_INSTAGRAM:-scalio.consultoria}")",
  empresa: { razao: "$(js "${EMPRESA_RAZAO:-}")", cnpj: "$(js "${EMPRESA_CNPJ:-}")", cidade: "$(js "${EMPRESA_CIDADE:-}")", endereco: "$(js "${EMPRESA_ENDERECO:-}")", dpo: "$(js "${EMPRESA_DPO:-}")", foro: "$(js "${EMPRESA_FORO:-}")", data: "$(js "${EMPRESA_DATA_POLITICAS:-}")" }
}, window.SCALIO_CONFIG || {});
JS
  log "config.js gerado a partir das variáveis de ambiente"
else
  log "AVISO: nenhuma variável de configuração definida (LEADS_WEBHOOK_URL, SITE_WHATSAPP...). Os formulários mostrarão que o envio não está conectado."
fi

# 4) cabeçalhos de segurança e configuração do nginx
WEBHOOK_ORIGIN=""
[ -n "$LEADS_WEBHOOK_URL" ] && WEBHOOK_ORIGIN=$(echo "$LEADS_WEBHOOK_URL" | sed -E 's|^(https?://[^/]+).*|\1|')
mkdir -p "$(dirname "$SNIP")" "$(dirname "$CONF")"
{
  echo 'add_header X-Content-Type-Options "nosniff" always;'
  echo 'add_header X-Frame-Options "SAMEORIGIN" always;'
  echo 'add_header Referrer-Policy "strict-origin-when-cross-origin" always;'
  echo 'add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;'
  echo "add_header Content-Security-Policy \"default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'self' $WEBHOOK_ORIGIN; frame-ancestors 'self'; base-uri 'self'; form-action 'self'; object-src 'none'\" always;"
  [ "$NOINDEX" = "1" ] && echo 'add_header X-Robots-Tag "noindex, nofollow" always;'
  [ "${HSTS:-false}" = "true" ] && echo 'add_header Strict-Transport-Security "max-age=31536000" always;'
  true
} > "$SNIP"

cat > "$CONF" <<'NGINX'
server {
  listen 80;
  server_name _;
  root __ROOT__;
  index index.html;
  charset utf-8;
  absolute_redirect off;
  server_tokens off;
  gzip on;
  gzip_min_length 1024;
  gzip_types text/plain text/css application/javascript application/json application/xml image/svg+xml;
  include __SNIP__;
  error_page 404 /404.html;

  location = /healthz { access_log off; default_type text/plain; include __SNIP__; return 200 "ok\n"; }
  location = /config.js { include __SNIP__; add_header Cache-Control "no-store" always; }
  location = /404.html { internal; include __SNIP__; add_header Cache-Control "no-store" always; }
  location ~ /\. { return 404; }
  location ~* \.(png|jpe?g|webp|svg|ico|pdf)$ { include __SNIP__; add_header Cache-Control "public, max-age=604800" always; try_files $uri =404; }
  location ~* \.(txt|xml)$ { include __SNIP__; add_header Cache-Control "public, max-age=3600" always; try_files $uri =404; }
  location / { include __SNIP__; add_header Cache-Control "no-cache" always; try_files $uri $uri.html $uri/ =404; }
}
NGINX
sed -i "s|__ROOT__|$ROOT|g; s|__SNIP__|$SNIP|g" "$CONF"
log "nginx configurado"

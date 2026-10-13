#!/usr/bin/env python3
"""Define o domínio do site nos arquivos (canonical, imagens de compartilhamento, robots e sitemap).
Uso:   python3 definir_dominio.py https://www.seudominio.com.br
Depois que um advogado revisar a política e os termos:
       python3 definir_dominio.py https://www.seudominio.com.br --politicas-revisadas
(remove o aviso de rascunho e o noindex de privacidade.html e termos.html)
"""
import os, re, sys
AQUI = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "site")
ARQ = ["index.html", "clinicas/index.html", "advocacia/index.html", "privacidade.html", "termos.html", "robots.txt", "sitemap.xml"]
def main():
    if len(sys.argv) < 2 or not sys.argv[1].startswith("https://"): sys.exit("Informe o domínio começando com https://, por exemplo: https://www.seudominio.com.br")
    dom = sys.argv[1].rstrip("/"); revisadas = "--politicas-revisadas" in sys.argv
    for a in ARQ:
        p = os.path.join(AQUI, a)
        if not os.path.exists(p): print("não encontrado:", a); continue
        s = open(p, encoding="utf-8").read(); n = s.count("https://SEUSITE.com.br")
        s = s.replace("https://SEUSITE.com.br", dom)
        if revisadas and a in ("privacidade.html", "termos.html"): s = re.sub(r"<!--REV-->.*?<!--/REV-->", "", s, flags=re.S)
        open(p, "w", encoding="utf-8").write(s); print(f"{a}: {n} ocorrência(s) trocada(s)" + (" e aviso de rascunho removido" if revisadas and a in ("privacidade.html", "termos.html") else ""))
    print("Pronto. Se ainda houver campos em destaque na política e nos termos, preencha-os em SCALIO_CONFIG.empresa (veja o README) ou no texto.")
main()

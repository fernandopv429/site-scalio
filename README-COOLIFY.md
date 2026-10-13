# Publicar o site da Scalio no Coolify

Esta pasta é a **raiz de um repositório Git**. Ela traz só o que vai ao ar: o site em `site/`, um `Dockerfile` (nginx) e um script que configura o contêiner pelas variáveis de ambiente. Os arquivos internos (kit do PocketBase, planilhas, README) ficam de fora de propósito.

```
Dockerfile              imagem nginx
docker/40-scalio.sh     configura domínio, config.js, políticas e nginx ao iniciar
site/                   páginas, imagens de compartilhamento, guia em PDF, robots e sitemap
ferramentas/            só para o modo Static (definir_dominio.py)
```

## Antes de começar
1. **Repositório Git** (GitHub, GitLab etc., de preferência privado) com o conteúdo desta pasta na raiz. O Coolify precisa do repositório para ter acesso aos arquivos do site: segundo a documentação, um Dockerfile digitado direto no Coolify, sem Git, não tem os arquivos do repositório para construir a imagem.
2. **Domínio** apontando para o servidor do Coolify (registro DNS do tipo A, ou o que o seu provedor pedir).
3. **PocketBase** no ar, com a coleção `leads` criada (`./enviar.sh setup-leads --update` no kit). Anote o endereço público, por exemplo `https://db.seudominio.com.br`.

## Passo a passo (Dockerfile, o recomendado)
1. No Coolify, crie um novo recurso do tipo **Application** e escolha o repositório.
2. Em **Build Pack**, escolha **Dockerfile** (o caminho padrão é `/Dockerfile`).
3. Em **Ports Exposes**, informe **80**.
4. Em **Domains**, informe `https://www.seudominio.com.br`. O HTTPS fica por conta do proxy do Coolify.
5. Em **Environment Variables**, cadastre as variáveis da tabela abaixo.
6. Clique em **Deploy** e acompanhe o log. A saída do script aparece com o prefixo `[scalio]`.

O Dockerfile já define um healthcheck em `/healthz`. Se preferir, também dá para configurá-lo em Configuration > Healthcheck.

## Variáveis de ambiente
| Variável | Obrigatória | O que faz |
|---|---|---|
| `SITE_URL` | **Sim** | Domínio final, com `https://` e sem barra no fim. Define canonical, imagens de compartilhamento, robots e sitemap. **Sem ela, o site sai com `noindex`** (proteção para não indexar uma versão incompleta) |
| `PB_URL` | **Sim** | Endereço do PocketBase. Sem ela, os formulários avisam que o envio não está conectado |
| `SITE_WHATSAPP` | Recomendada | Com DDI e DDD, por exemplo `5511999999999`. Habilita o botão e o link do rodapé |
| `SITE_EMAIL` | Recomendada | E-mail comercial, mostrado no rodapé |
| `EMPRESA_RAZAO`, `EMPRESA_CNPJ`, `EMPRESA_CIDADE` | Recomendadas | Aparecem no rodapé e preenchem a política e os termos |
| `EMPRESA_ENDERECO`, `EMPRESA_DPO`, `EMPRESA_FORO`, `EMPRESA_DATA_POLITICAS` | Para as páginas legais | Endereço, encarregado de dados, comarca e data da última atualização |
| `SITE_INSTAGRAM` | Não | Padrão `scalio.consultoria` |
| `POLITICAS_REVISADAS` | Não | `true` **somente depois** de um advogado revisar `privacidade.html` e `termos.html`: remove o aviso de rascunho e o `noindex` delas |
| `HSTS` | Não | `true` para enviar o cabeçalho HSTS. Só ative quando o HTTPS estiver estável |

Se `SITE_URL` ou `PB_URL` vierem em formato inválido, o contêiner **não sobe** e o log explica o erro. Isso é intencional. Para mudar uma variável, reimplante ou reinicie o recurso, porque o script roda na inicialização.

## Alternativa mais simples: build pack Static
Serve para colocar no ar rápido, com menos recursos. O Coolify serve os arquivos com Nginx.
1. Build Pack **Static**, com o diretório de publicação **`/site`**.
2. Antes de enviar ao Git, edite `site/config.js` e rode `python3 ferramentas/definir_dominio.py https://www.seudominio.com.br`.
3. O que você perde: os cabeçalhos de segurança, o `noindex` automático, o `/healthz` e a configuração por variáveis.

## Depois do deploy, confira
- `https://seudominio/healthz` responde `ok`.
- A home, `/clinicas/` e `/advocacia/` abrem, e `/pagina-que-nao-existe` mostra a página 404 da marca.
- Envie **um formulário de teste** em cada página e confirme o registro na coleção `leads`. Depois apague os registros de teste.
- Peça o guia em PDF e baixe.
- No PocketBase: leitura da coleção só para superusuário e criação pública só com consentimento (o `setup-leads` já configura isso). Confira também o limite de requisições do PocketBase e o backup.
- Se você restringiu as origens permitidas (CORS) no PocketBase, acrescente o domínio do site.

## Antes de abrir ao público
- **Revisão jurídica** da política de privacidade e dos termos, e dos textos de clínicas (conselhos) e de advocacia (OAB).
- **Dados reais** da empresa e contatos nas variáveis.
- Só então: `POLITICAS_REVISADAS=true`, envie o `sitemap.xml` ao Google Search Console e meça a velocidade no PageSpeed Insights.
- Se for instalar Google Analytics ou Meta Pixel, implante antes o aviso e o consentimento de cookies e atualize a seção 9 da política. A política de segurança do site (CSP) bloqueia scripts de terceiros, então esses domínios precisam ser liberados em `docker/40-scalio.sh`.

## O que foi testado e o que não foi
**Testado, em ambiente local:**
- O script `40-scalio.sh` em 6 cenários: sem variáveis, com domínio e política revisada, domínio inválido, tentativa de injeção, aspas e barras no nome da empresa, e segunda execução.
- O nginx 1.24 com a configuração gerada: sintaxe, rotas (`/`, `/clinicas`, `/clinicas/`, `/privacidade`, `/healthz`), redirecionamento relativo, página 404 da marca, bloqueio de arquivos ocultos, tipos de arquivo, cache e compressão.
- Os formulários das três páginas e o download do guia, servidos por esse nginx com a CSP ativa, gravando em um PocketBase local (4 registros). Nenhuma violação de CSP.

**Não testado (não havia Docker aqui):**
- A construção da imagem e a execução dentro do Coolify.
- A compatibilidade com o `nginx:stable-alpine`: testei com o nginx 1.24 do Ubuntu e usei só comandos POSIX, mas o primeiro deploy é o teste real.
- DNS, HTTPS, o seu PocketBase de produção e a velocidade real do site.

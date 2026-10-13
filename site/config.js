// Configuração do site. Em produção com Docker, este arquivo é gerado a partir das variáveis de ambiente (veja README-COOLIFY.md).
// Quando editado à mão, preencha os valores entre aspas.
window.SCALIO_CONFIG = Object.assign({
  pbUrl: "",          // endereço público do PocketBase, por exemplo https://db.seudominio.com.br
  whatsapp: "",       // com DDI e DDD, por exemplo 5511999999999
  email: "",          // e-mail comercial
  instagram: "scalio.consultoria",
  empresa: { razao: "", cnpj: "", cidade: "", endereco: "", dpo: "", foro: "", data: "" }
}, window.SCALIO_CONFIG || {});

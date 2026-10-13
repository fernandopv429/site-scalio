// Configuração do site. Em produção com Docker, este arquivo é gerado a partir das variáveis de ambiente (veja README-COOLIFY.md).
// Quando editado à mão, preencha os valores entre aspas.
window.SCALIO_CONFIG = Object.assign({
  webhookUrl: "https://n8n.nexusdevhub.com/webhook/096735fb-68ba-4376-b005-d03d3977982c", // URL do webhook do n8n que recebe os leads
  whatsapp: "",       // com DDI e DDD, por exemplo 5511999999999
  email: "",          // e-mail comercial
  instagram: "scalio.consultoria",
  empresa: { razao: "", cnpj: "", cidade: "", endereco: "", dpo: "", foro: "", data: "" }
}, window.SCALIO_CONFIG || {});

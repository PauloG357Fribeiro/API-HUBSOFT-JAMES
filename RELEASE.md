# Ciclo de release da extensao HubAuto

Este arquivo e so para uso interno (nao vai para `dist/`).

## Passo a passo para publicar uma nova versao

1. Editar os arquivos em `src/` (`content.js`, `hubsoft_auto.js`,
   `background.js`, `manifest.json`, etc.).
2. Subir o numero de versao em `src/manifest.json` (campo `"version"`).
   Isso e o que dispara a atualizacao no `atualizador.bat` dos atendentes
   e a trava de versao no n8n. Se esquecer, ninguem recebe a nova versao.
3. Rodar `npm run build`.
   - Isso gera `dist/` do zero, ofuscando os `.js` de `src/` e copiando
     `manifest.json`, `content.css`, icones, `atualizador.bat` e
     `LEIA-ME.txt` sem ofuscar.
   - O build falha com erro claro se algum arquivo ofuscado nao passar
     em `node --check` (sintaxe invalida).
4. Conferir a arvore de `dist/` e, se quiser, testar carregando essa
   pasta em `chrome://extensions` antes de publicar.
5. Commitar e dar push SO da pasta `dist/` (a `src/` esta no `.gitignore`,
   entao `git status` nao deve mostrar nada dela).
6. Avisar os atendentes para rodar o `atualizador.bat`.

## Regras importantes

- NUNCA colocar token, apikey, senha ou client_secret em nenhum arquivo
  de `src/`, `dist/` ou no `.bat`. Segredos (HubSoft, Evolution API,
  OpenAI, etc.) ficam SOMENTE no n8n.
- `N8N final.json` (export do workflow) NUNCA deve ser commitado — ele
  contem credenciais em texto puro. Esta no `.gitignore`; mantenha-o
  fora do controle de versao.
- `selfDefending: true` no ofuscador quebra o codigo se alguem
  reindentar/reformatar o arquivo ofuscado — isso e intencional, nao
  "arrumar" o codigo em `dist/`.
- O repositorio e PUBLICO. Antes de commitar, sempre revisar o diff
  (`git status` / `git diff`) para garantir que nenhum segredo entrou.

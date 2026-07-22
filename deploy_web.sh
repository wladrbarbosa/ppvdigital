#!/bin/bash
# Script de Compilação, Empacotamento e Deploy SFTP (Flutter Web)

set -e

# 0. Carrega variáveis de ambiente do arquivo .env se existir
if [ -f ".env" ]; then
    echo -e "\033[0;90mCarregando variáveis do arquivo .env...\033[0m"
    set -a
    source .env
    set +a
fi

echo -e "\033[0;36mIniciando compilação do Flutter Web...\033[0m"

# Detecta se deve usar FVM
FLUTTER_CMD="flutter"
if [ -d ".fvm" ]; then
    echo -e "\033[0;33mFVM detectado. Usando fvm flutter...\033[0m"
    FLUTTER_CMD="fvm flutter"
fi

# 1. Limpa caches e obtém dependências limpas
echo -e "\033[0;90mExecutando: $FLUTTER_CMD clean\033[0m"
$FLUTTER_CMD clean

echo -e "\033[0;90mExecutando: $FLUTTER_CMD pub get\033[0m"
$FLUTTER_CMD pub get

# 2. Compila o Flutter Web como WASM
echo -e "\033[0;90mExecutando: $FLUTTER_CMD build web --wasm\033[0m"
$FLUTTER_CMD build web --wasm

# 3. Processa arquivos de manifest de assets para compatibilidade total Web / Appwrite Sites
echo -e "\033[0;90mGarantindo compatibilidade dos arquivos AssetManifest...\033[0m"
node -e '
const fs = require("fs");
const path = require("path");

const buildWebDir = path.join(__dirname, "build/web");
const assetsDir = path.join(buildWebDir, "assets");

if (fs.existsSync(assetsDir)) {
  const files = fs.readdirSync(assetsDir);
  files.forEach(file => {
    if (file.startsWith("AssetManifest") || file.startsWith("FontManifest")) {
      fs.copyFileSync(path.join(assetsDir, file), path.join(buildWebDir, file));
    }
  });

  const binJsonPath = path.join(assetsDir, "AssetManifest.bin.json");
  if (fs.existsSync(binJsonPath)) {
    try {
      const raw = fs.readFileSync(binJsonPath, "utf8");
      const base64Str = JSON.parse(raw);
      const buf = Buffer.from(base64Str, "base64");
      const str = buf.toString("utf8");
      const assetMatches = str.match(/(assets\/[^\x00-\x1F]+|packages\/[^\x00-\x1F]+)/g) || [];
      const manifest = {};
      assetMatches.forEach(a => {
        manifest[a] = [a];
      });
      const jsonStr = JSON.stringify(manifest, null, 2);
      fs.writeFileSync(path.join(assetsDir, "AssetManifest.json"), jsonStr);
      fs.writeFileSync(path.join(buildWebDir, "AssetManifest.json"), jsonStr);
    } catch (e) {
      console.error("Erro ao gerar AssetManifest.json:", e);
    }
  }
}
'

# 4. Verificação da Build
BUILD_DIR="build/web"

if [ ! -d "$BUILD_DIR" ]; then
    echo -e "\033[0;31mErro: Diretório de compilação $BUILD_DIR não encontrado.\033[0m"
    exit 1
fi

# Remove arquivos de arquivo (.tar.gz) do diretório de build para não enviá-los
rm -f "$BUILD_DIR"/*.tar.gz

echo -e "\033[0;32mCompilação concluída com sucesso!\033[0m"
echo -e "\033[0;32mOs arquivos compilados estão em: $BUILD_DIR\033[0m"

# 5. Envio via SFTP
SFTP_HOST="${SFTP_HOST:-}"
SFTP_PORT="${SFTP_PORT:-22}"
SFTP_USER="${SFTP_USER:-}"
SFTP_REMOTE_DIR="${SFTP_REMOTE_DIR:-.}"
SFTP_KEY="${SFTP_KEY:-}"
SFTP_PASS="${SFTP_PASS:-}"

if [ -n "$SFTP_HOST" ] && [ -n "$SFTP_USER" ]; then
    echo ""
    echo -e "\033[0;36mIniciando envio via SFTP para ${SFTP_USER}@${SFTP_HOST}:${SFTP_REMOTE_DIR} (Porta ${SFTP_PORT})...\033[0m"
    
    # Expande '~' no caminho da chave SSH caso presente
    SFTP_KEY="${SFTP_KEY/#\~/$HOME}"

    SSH_OPTS="-r -P ${SFTP_PORT} -o StrictHostKeyChecking=no"
    if [ -n "$SFTP_KEY" ]; then
        if [ -f "$SFTP_KEY" ]; then
            SSH_OPTS="${SSH_OPTS} -i ${SFTP_KEY}"
        else
            echo -e "\033[0;33mAviso: Arquivo de chave SSH não encontrado em '$SFTP_KEY'.\033[0m"
        fi
    fi

    if [ -n "$SFTP_PASS" ]; then
        if command -v sshpass &> /dev/null; then
            sshpass -p "$SFTP_PASS" scp ${SSH_OPTS} "$BUILD_DIR/." "${SFTP_USER}@${SFTP_HOST}:${SFTP_REMOTE_DIR}/"
        else
            echo -e "\033[0;33mAviso: SFTP_PASS está configurado no .env, mas o utilitário 'sshpass' não está instalado no sistema.\033[0m"
            echo -e "\033[0;33mPara usar a senha do .env automaticamente, instale com: sudo apt install sshpass\033[0m"
            echo -e "\033[0;90mSolicitando senha interativa para o envio...\033[0m"
            scp ${SSH_OPTS} "$BUILD_DIR/." "${SFTP_USER}@${SFTP_HOST}:${SFTP_REMOTE_DIR}/"
        fi
    else
        scp ${SSH_OPTS} "$BUILD_DIR/." "${SFTP_USER}@${SFTP_HOST}:${SFTP_REMOTE_DIR}/"
    fi

    if [ $? -eq 0 ]; then
        echo -e "\033[0;32mUpload via SFTP concluído com sucesso!\033[0m"
    else
        echo -e "\033[0;31mFalha no upload via SFTP. Verifique as credenciais e parâmetros.\033[0m"
        exit 1
    fi
else
    echo ""
    echo -e "\033[0;33mConfigurações de SFTP (SFTP_HOST e SFTP_USER) não encontradas em .env ou variáveis de ambiente.\033[0m"
    echo -e "\033[0;33mPara ativar o upload automático, configure o arquivo .env (consulte .env.example).\033[0m"
fi

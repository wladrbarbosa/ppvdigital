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

# 4. Empacota a build
BUILD_DIR="build/web"
ARCHIVE_NAME="code.tar.gz"

if [ ! -d "$BUILD_DIR" ]; then
    echo -e "\033[0;31mErro: Diretório de compilação $BUILD_DIR não encontrado.\033[0m"
    exit 1
fi

echo -e "\033[0;36mEmpacotando build/web em $ARCHIVE_NAME...\033[0m"

# Remove pacote antigo se existir
rm -f "$BUILD_DIR/$ARCHIVE_NAME"

cd "$BUILD_DIR"
tar -czf "../$ARCHIVE_NAME" .
mv "../$ARCHIVE_NAME" "$ARCHIVE_NAME"
cd - > /dev/null

echo -e "\033[0;32mCompilação e empacotamento concluídos com sucesso!\033[0m"
echo -e "\033[0;32mO pacote pronto está em: $BUILD_DIR/$ARCHIVE_NAME\033[0m"

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
    
    SSH_OPTS="-P ${SFTP_PORT} -o StrictHostKeyChecking=no"
    if [ -n "$SFTP_KEY" ] && [ -f "$SFTP_KEY" ]; then
        SSH_OPTS="${SSH_OPTS} -i ${SFTP_KEY}"
    fi

    if [ -n "$SFTP_PASS" ] && command -v sshpass &> /dev/null; then
        sshpass -p "$SFTP_PASS" scp ${SSH_OPTS} "$BUILD_DIR/$ARCHIVE_NAME" "${SFTP_USER}@${SFTP_HOST}:${SFTP_REMOTE_DIR}/"
    else
        scp ${SSH_OPTS} "$BUILD_DIR/$ARCHIVE_NAME" "${SFTP_USER}@${SFTP_HOST}:${SFTP_REMOTE_DIR}/"
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

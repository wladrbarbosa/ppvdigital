#!/bin/bash
# Script de Compilação e Empacotamento para Appwrite Sites (Flutter Web)

set -e

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
echo -e "\033[0;32mO pacote pronto para o Appwrite Sites está em: $BUILD_DIR/$ARCHIVE_NAME\033[0m"
echo ""
echo -e "\033[0;33mComo fazer o Deploy no console do Appwrite:\033[0m"
echo "1. Acesse o console do Appwrite."
echo "2. Vá em Sites e crie/selecione o site correspondente."
echo "3. Clique em 'Create deployment' -> selecione a aba 'Manual'."
echo "4. Faça o upload do arquivo: $BUILD_DIR/$ARCHIVE_NAME"
echo "5. Escolha o entrypoint (index.html) e ative a compilação."

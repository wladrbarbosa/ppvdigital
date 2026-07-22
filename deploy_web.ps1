# Script de Compilação, Empacotamento e Deploy SFTP (Flutter Web)

$ErrorActionPreference = "Stop"

# 0. Carrega variáveis de ambiente do arquivo .env se existir
if (Test-Path ".env") {
    Write-Host "Carregando variáveis do arquivo .env..." -ForegroundColor Gray
    Get-Content ".env" | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $parts = $line.Split("=", 2)
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
}

Write-Host "Iniciando compilação do Flutter Web..." -ForegroundColor Cyan

# Detecta se deve usar FVM
$flutterCmd = "flutter"
if (Test-Path ".fvm") {
    Write-Host "FVM detectado. Usando fvm flutter..." -ForegroundColor Yellow
    $flutterCmd = "fvm flutter"
}

# 1. Limpa caches e obtém dependências limpas
Write-Host "Executando: $flutterCmd clean" -ForegroundColor Gray
Invoke-Expression "$flutterCmd clean"

Write-Host "Executando: $flutterCmd pub get" -ForegroundColor Gray
Invoke-Expression "$flutterCmd pub get"

# 2. Compila o Flutter Web como WASM
Write-Host "Executando: $flutterCmd build web --wasm" -ForegroundColor Gray
Invoke-Expression "$flutterCmd build web --wasm"

# 3. Processa arquivos de manifest de assets para compatibilidade total Web / Appwrite Sites
Write-Host "Garantindo compatibilidade dos arquivos AssetManifest..." -ForegroundColor Gray
$nodeScript = @'
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
'@
node -e $nodeScript

# 4. Verificação da Build
$buildDir = "build/web"

if (-not (Test-Path $buildDir)) {
    Write-Error "Diretório de compilação $buildDir não encontrado."
}

# Remove arquivos de arquivo (.tar.gz) do diretório de build para não enviá-los
Get-ChildItem -Path $buildDir -Filter "*.tar.gz" | Remove-Item -Force

Write-Host "Compilação concluída com sucesso!" -ForegroundColor Green
Write-Host "Os arquivos compilados estão em: $buildDir" -ForegroundColor Green

# 5. Envio via SFTP
$sftpHost = $env:SFTP_HOST
$sftpPort = if ($env:SFTP_PORT) { $env:SFTP_PORT } else { "22" }
$sftpUser = $env:SFTP_USER
$sftpRemoteDir = if ($env:SFTP_REMOTE_DIR) { $env:SFTP_REMOTE_DIR } else { "." }
$sftpKey = $env:SFTP_KEY
$sftpPass = $env:SFTP_PASS

if ($sftpHost -and $sftpUser) {
    Write-Host ""
    Write-Host "Iniciando envio via SFTP para ${sftpUser}@${sftpHost}:${sftpRemoteDir} (Porta ${sftpPort})..." -ForegroundColor Cyan
    
    # Expande '~' no caminho da chave SSH se necessário
    if ($sftpKey -and $sftpKey.StartsWith("~")) {
        $userHome = if ($HOME) { $HOME } else { $env:USERPROFILE }
        $sftpKey = $sftpKey.Replace("~", $userHome)
    }

    $scpArgs = @("-r", "-P", $sftpPort, "-o", "StrictHostKeyChecking=no")
    if ($sftpKey) {
        if (Test-Path $sftpKey) {
            $scpArgs += @("-i", $sftpKey)
        } else {
            Write-Host "Aviso: Arquivo de chave SSH não encontrado em '$sftpKey'." -ForegroundColor Yellow
        }
    }

    $uploadPath = Join-Path $buildDir "*"
    if ($sftpPass -and (Get-Command sshpass -ErrorAction SilentlyContinue)) {
        & sshpass -p $sftpPass scp @scpArgs $uploadPath "${sftpUser}@${sftpHost}:${sftpRemoteDir}/"
    } else {
        if ($sftpPass) {
            Write-Host "Aviso: SFTP_PASS está configurado no .env, mas o utilitário 'sshpass' não está disponível no PowerShell." -ForegroundColor Yellow
            Write-Host "Para autenticação automática no Windows, recomenda-se configurar uma chave SSH sem senha em SFTP_KEY." -ForegroundColor Yellow
            Write-Host "Solicitando senha interativa para o envio..." -ForegroundColor Gray
        }
        & scp @scpArgs $uploadPath "${sftpUser}@${sftpHost}:${sftpRemoteDir}/"
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Upload via SFTP concluído com sucesso!" -ForegroundColor Green
    } else {
        Write-Error "Falha no envio via SFTP. Verifique as credenciais e parâmetros."
    }
} else {
    Write-Host ""
    Write-Host "Configurações de SFTP (SFTP_HOST e SFTP_USER) não encontradas em .env ou variáveis de ambiente." -ForegroundColor Yellow
    Write-Host "Para ativar o upload automático, configure o arquivo .env (consulte .env.example)." -ForegroundColor Yellow
}

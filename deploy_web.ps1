# Script de Compilação e Empacotamento para Appwrite Sites (Flutter Web)

$ErrorActionPreference = "Stop"

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

# 2. Empacota a build
$buildDir = "build/web"
$archiveName = "code.tar.gz"
$archivePath = Join-Path $buildDir $archiveName

if (-not (Test-Path $buildDir)) {
    Write-Error "Diretório de compilação $buildDir não encontrado."
}

Write-Host "Empacotando build/web em $archiveName..." -ForegroundColor Cyan

# Remove pacote antigo se existir
if (Test-Path $archivePath) {
    Remove-Item $archivePath -Force
}

# Compacta usando tar
Push-Location $buildDir
tar --exclude $archiveName -czf $archiveName .
Pop-Location

Write-Host "Compilação e empacotamento concluídos com sucesso!" -ForegroundColor Green
Write-Host "O pacote pronto para o Appwrite Sites está em: $archivePath" -ForegroundColor Green
Write-Host ""
Write-Host "Como fazer o Deploy no console do Appwrite:" -ForegroundColor Yellow
Write-Host "1. Acesse o console do Appwrite."
Write-Host "2. Vá em Sites e crie/selecione o site correspondente."
Write-Host "3. Clique em 'Create deployment' -> selecione a aba 'Manual'."
Write-Host "4. Faça o upload do arquivo: $archivePath"
Write-Host "5. Escolha o entrypoint (index.html) e ative a compilação."

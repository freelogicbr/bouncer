# PT-BR: Imagem base leve com Python 3.12 / EN: Lightweight base image with Python 3.12
FROM python:3.12-slim

# PT-BR: Criação de usuário não-root por segurança / EN: Non-root user creation for security
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# PT-BR: Diretório de trabalho / EN: Working directory
WORKDIR /app

# PT-BR: Cópia dos arquivos de configuração e código / EN: Copy config files and source code
COPY pyproject.toml README.md ./
COPY src ./src

# PT-BR: Instalação do pacote no ambiente da imagem / EN: Install the package into the image environment
RUN python -m pip install --no-cache-dir .

# PT-BR: Garantia de permissões para o usuário appuser / EN: Ensure permissions for appuser
RUN chown -R appuser:appgroup /app

# PT-BR: Configurações de ambiente Python / EN: Python environment settings
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# PT-BR: Troca para usuário não-root / EN: Switch to non-root user
USER appuser

# PT-BR: Comando de inicialização / EN: Entrypoint command
CMD ["python", "-m", "bouncer"]

# Consolidação Temporária de Decisões

Este arquivo é um rascunho temporário para preservar as decisões discutidas até aqui antes da redação da arquitetura formal.

Ele não substitui a futura documentação final e pode conter lacunas ou pontos que ainda precisem de validação.

## Objetivo deste arquivo

- registrar o que foi decidido
- reduzir risco de perda de contexto
- servir como base de revisão antes de escrever `architecture.md`

## Decisões consolidadas

### 1. Forma de execução

- O Bouncer no MVP será um único serviço MCP em Python.
- O serviço será stateless no processo e usará PostgreSQL com pgvector como persistência externa.
- Docker deixou de ser o caminho principal para o MVP.
- A execução preferencial será nativa no sistema operacional do ambiente de desenvolvimento.

### 2. Escopo de linguagem

- O MVP suportará apenas Python.
- A detecção de linguagem será feita por extensão de arquivo.
- No MVP, o mapeamento relevante é apenas `.py -> python`.
- Linguagens não suportadas devem retornar status explícito de `unsupported_language`.

### 3. Parsing

- A estrutura de parser deve nascer plugável desde o início.
- Haverá uma interface interna de parser, com apenas `PythonParser` implementado no MVP.
- O parser de Python deve usar `ast` da biblioteca padrão.
- AST multi-linguagem continua fora do escopo do MVP.

### 4. Unidades indexadas

- O índice do MVP cobre apenas `function` e `method`.
- Funções aninhadas não serão indexadas como referências independentes.
- Classes, módulos, properties e lambdas ficam fora do escopo do MVP.

### 5. Leitura de arquivos

- O Bouncer lê diretamente os arquivos do workspace.
- Não haverá cliente intermediário responsável por enviar conteúdo de arquivo para o core.
- O fluxo com cliente como ponte foi abandonado.

### 6. Atualização do índice

- O refresh do índice é sempre por arquivo.
- Não haverá operação de refresh em lote no core do Bouncer.
- `refresh_index` recebe `workspace_id` e `file_path`.
- O Bouncer lê o arquivo, detecta a linguagem, parseia, extrai referências e chamadas, gera embeddings e substitui os registros daquele arquivo.
- `refresh_index` assume conteúdo sintaticamente válido.
- Se o parse falhar, a operação retorna erro explícito e não atualiza o índice daquele arquivo.

### 7. Automação de refresh

- A automação de reindexação ficará fora do core do Bouncer.
- Um script externo, acionado por `post-commit`, será responsável por:
- descobrir os arquivos afetados no último commit
- montar a fila
- marcar os arquivos como `dirty`
- chamar `refresh_index` arquivo por arquivo
- chamar `remove_file` para arquivos deletados
- Se `refresh_index` falhar, o arquivo deve permanecer `dirty`.
- Retry, limite de tentativas e alerta são responsabilidade do script, não do Bouncer.
- O alerta do MVP pode ser apenas log claro e exit code não zero ao final.

### 8. Estado dirty

- O estado `dirty` é por arquivo, não por referência.
- `mark_file_dirty` será mantido no MVP.
- Seu uso principal será pelo script de atualização, antes de consumir a fila.
- O `dirty` reduz confiança, mas não remove o arquivo dos resultados.
- Se a atualização falhar, o arquivo permanece `dirty`.

### 9. Remoção

- Haverá uma operação explícita `remove_file`.
- Ela remove referências, relações de chamada e estado `dirty` associados ao arquivo.

### 10. Workspace e configuração

- `workspace_id` será obrigatório em todas as tools.
- `workspace_id` é um alias estável definido em configuração, não o nome automático da pasta.
- O mapeamento `workspace_id -> root_path` ficará em arquivo de configuração local.
- O formato do arquivo de configuração será TOML.
- O caminho padrão será `~/.config/bouncer/config.toml`.
- Deve existir override por variável de ambiente.
- Cada workspace, no MVP, precisa apenas de `root_path`.
- Todo workspace suportado no MVP é assumido como workspace Git.

### 11. Paths

- `file_path` será sempre relativo ao `root_path` do workspace.
- Caminhos absolutos devem ser rejeitados.
- Caminhos que escapem o workspace, como `..`, devem ser rejeitados.
- O Bouncer valida apenas que o `file_path` resolve para dentro do `root_path`.
- A validação de pertencimento ao Git não será feita no core.

### 12. Estrutura lógica de módulos

- O runtime deve continuar simples, mas o código deve nascer mais modular para favorecer desenvolvimento com agentes.
- A modularização precisa evitar arquivos monolíticos.
- A separação lógica discutida inclui, pelo menos:
- interface MCP
- serviços de busca
- serviços de indexação
- módulo de embeddings
- módulo de ranking
- parsers por linguagem
- camada de repositório
- modelos/schemas/configuração

### 13. Texto usado para embedding

- O texto do embedding será montado pelo próprio Bouncer.
- O cliente não monta payload semântico de embedding.
- A composição decidida foi:
- comentário técnico curto opcional imediatamente anterior
- linha de definição da função/método
- corpo da função/método
- Comentários estruturados podem ajudar, mas não são obrigatórios para o funcionamento.
- A recomendação é limitar esse comentário a 1 ou 2 linhas técnicas.
- `qualified_name` e outros metadados podem existir separadamente, mas não foram definidos como parte obrigatória do texto embedado.

### 14. Busca

- `search_code` fará busca híbrida leve.
- A busca híbrida combina similaridade vetorial com sinais estruturais e metadados.
- `find_symbol` continua sendo busca exata/determinística.
- O ranking discutido para `search_code` combina:
- similaridade vetorial
- match no nome do símbolo
- match parcial no caminho do arquivo
- penalidade para arquivos `dirty`

### 15. Filtros

- `search_code` busca no workspace inteiro por padrão.
- `search_code` pode aceitar filtros opcionais:
- `path_prefix`
- `file_path`
- `symbol_kind`

### 16. Resultados de busca

- `search_code` e `find_symbol` devem incluir `reference_id`.
- Os resultados também devem incluir metadados suficientes para localização humana:
- `file_path`
- `symbol_name`
- `start_line`
- `end_line`
- `symbol_kind`
- `qualified_name`, quando existir
- `score` ou `confidence`
- `is_dirty`

### 17. Identificação de referência

- `reference_id` pode ser um inteiro sequencial interno do banco no MVP.
- A identificação humana padrão da referência será:
- `file_path + symbol_name + start_line`
- `qualified_name` permanece como metadado opcional útil, mas não é o centro da identificação prática.

### 18. find_symbol

- `find_symbol` deve exigir linguagem explicitamente no input.
- Consultas para linguagens diferentes devem ser feitas separadamente.
- `find_symbol` deve aceitar nome simples e nome qualificado.
- Se houver múltiplos resultados, ele retorna lista ranqueada, não um único match presumido.

### 19. Relações de chamada

- O grafo será modelado em tabela separada de edges de chamada.
- Uma edge significa apenas `A chama B`.
- Nada além disso foi incluído no escopo do MVP.
- Chamadas não resolvidas não devem virar nós fantasmas no grafo.
- Apenas relações resolvidas para referências conhecidas do workspace entram no índice.

### 20. Resolução de chamadas

- Durante o `refresh_index`, o Bouncer deve:
- extrair primeiro todas as referências do arquivo
- montar um mapa local do próprio arquivo
- resolver primeiro chamadas locais
- tentar depois resolver chamadas externas já conhecidas no workspace
- Para Python no MVP, a detecção de chamadas cobre:
- chamadas diretas a nomes simples, como `foo()`
- chamadas por atributo, como `obj.method()`
- Casos dinâmicos mais complexos ficam fora do MVP.

### 21. Neighbors

- `get_neighbors` deve operar por `reference_id`.
- A profundidade padrão será `1`.
- A profundidade máxima do MVP será `2`.
- A profundidade `1` foi mantida para preservar simplicidade.
- A ordenação dos vizinhos deve priorizar:
- referências no mesmo arquivo
- maior confiança
- desempate estável
- A resposta de vizinhança deve suportar paginação simples.
- A paginação foi preferida a retornar subgrafos grandes em uma única resposta.

### 22. Limites de resposta

- O Bouncer deve manter respostas pequenas por padrão para preservar a vantagem de contexto.
- Foi discutido o uso de limites baixos e paginação para expansão controlada.
- O detalhe exato de `top_k` e limites máximos ainda não foi consolidado de forma final neste rascunho.

### 23. Hash de conteúdo

- O uso de `content_hash` foi discutido em um momento intermediário.
- Depois da decisão de abandonar o cliente intermediário e deixar o Bouncer ler o workspace diretamente, o hash perdeu função clara no MVP.
- A direção mais recente foi remover `content_hash` do escopo inicial.

## Pontos que ainda podem precisar de validação

- detalhes exatos do contrato de resposta de cada tool
- nomes finais das tabelas e colunas
- valores padrão e máximos de paginação e `top_k`
- estrutura exata dos módulos e diretórios do código
- política final de score/ranking na busca híbrida

## Observação final

Este documento existe porque houve perda de confiança na retenção do contexto ao longo da conversa. Ele deve ser tratado como base de conferência, não como documento final já aprovado.

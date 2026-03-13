# Arquitetura - Bouncer MVP

[Read in English](./architecture.md)

Este documento descreve a arquitetura do Bouncer MVP. Ele consolida as decisoes tomadas durante o design e serve como referencia para implementacao.

## 1. Visao Geral

O Bouncer e um servico MCP em Python que indexa funcoes e metodos de um workspace local e oferece busca semantica, busca exata, navegacao por vizinhanca e atualizacao de indice por arquivo.

O servico e stateless no processo. Toda persistencia esta em PostgreSQL com pgvector.

A execucao e nativa no sistema operacional. Docker nao faz parte do caminho principal do MVP.

## 2. Escopo de Linguagem

- O MVP suporta apenas Python.
- Deteccao de linguagem por extensao de arquivo (`.py -> python`).
- Linguagens nao suportadas retornam `unsupported_language`.

## 3. Parsing

- Interface interna plugavel de parser.
- Apenas `PythonParser` implementado no MVP.
- O parser de Python usa `ast` da biblioteca padrao.
- Unidades indexadas: `function` e `method`.
- Fora do escopo: funcoes aninhadas, classes como unidade propria, properties, lambdas, segmentacao textual.

## 4. Leitura de Arquivos

O Bouncer le diretamente os arquivos do workspace. Nao existe cliente intermediario que envie conteudo para o core.

## 5. Workspace e Configuracao

- `workspace_id` e obrigatorio em todas as tools.
- `workspace_id` e um alias estavel definido em configuracao, nao o nome da pasta.
- Mapeamento `workspace_id -> root_path` em arquivo TOML.
- Caminho padrao: `~/.config/bouncer/config.toml`.
- Override por variavel de ambiente.
- Cada workspace no MVP precisa apenas de `root_path`.
- Todo workspace e assumido como workspace Git.

## 6. Paths

- `file_path` e sempre relativo ao `root_path` do workspace.
- Caminhos absolutos sao rejeitados.
- Caminhos que escapem o workspace (`..`) sao rejeitados.
- Validacao: `file_path` resolve para dentro de `root_path`.
- Validacao de pertencimento ao Git nao e feita no core.

## 7. Atualizacao do Indice

### 7.1 refresh_index

- Refresh sempre por arquivo. Sem operacao de refresh em lote.
- Recebe `workspace_id` e `file_path`.
- Fluxo: le arquivo, detecta linguagem, parseia, extrai referencias e chamadas, gera embeddings, substitui registros do arquivo.
- Assume conteudo sintaticamente valido.
- Se o parse falhar, retorna erro explicito e nao atualiza o indice.

### 7.2 Automacao via post-commit

A automacao de reindexacao fica fora do core. Um script externo, acionado por hook `post-commit`:

1. Descobre arquivos afetados no ultimo commit.
2. Marca arquivos como `dirty`.
3. Chama `refresh_index` arquivo por arquivo.
4. Chama `remove_file` para arquivos deletados.
5. Se `refresh_index` falhar, o arquivo permanece `dirty`.

Retry, limite de tentativas e alerta sao responsabilidade do script. O alerta do MVP pode ser log e exit code nao zero.

### 7.3 Estado dirty

- Estado `dirty` e por arquivo, nao por referencia.
- `mark_file_dirty` e mantido no MVP.
- O `dirty` reduz confianca, mas nao remove o arquivo dos resultados.
- Se a atualizacao falhar, o arquivo permanece `dirty`.

### 7.4 Remocao

- Operacao explicita `remove_file`.
- Remove referencias, relacoes de chamada e estado `dirty` do arquivo.

## 8. Texto de Embedding

O texto do embedding e montado pelo Bouncer. Composicao:

1. Comentario tecnico curto opcional imediatamente anterior a definicao.
2. Linha de definicao da funcao/metodo.
3. Corpo da funcao/metodo.

Comentarios estruturados ajudam, mas nao sao obrigatorios. Recomendacao: limitar a 1-2 linhas tecnicas.

`qualified_name` e outros metadados existem separadamente, nao como parte obrigatoria do texto embedado.

## 9. Busca

### 9.1 search_code

Busca hibrida leve combinando:

- Similaridade vetorial
- Match no nome do simbolo
- Match parcial no caminho do arquivo
- Penalidade para arquivos `dirty`

Busca no workspace inteiro por padrao. Filtros opcionais:

- `path_prefix`
- `file_path`
- `symbol_kind`

### 9.2 find_symbol

- Busca exata/deterministica.
- Exige linguagem explicita no input.
- Aceita nome simples, nome qualificado ou caminho de arquivo.
- Multiplos resultados retornam lista ranqueada.

## 10. Resultados de Busca

Campos retornados por `search_code` e `find_symbol`:

- `reference_id`
- `file_path`
- `symbol_name`
- `start_line`
- `end_line`
- `symbol_kind`
- `qualified_name` (quando existir)
- `score` ou `confidence`
- `is_dirty`

### 10.1 Identificacao de Referencia

- `reference_id`: inteiro sequencial interno do banco no MVP.
- Identificacao humana: `file_path + symbol_name + start_line`.
- `qualified_name` e metadado opcional, nao centro da identificacao.

## 11. Relacoes de Chamada

- Grafo modelado em tabela separada de edges.
- Uma edge significa `A chama B`.
- Chamadas nao resolvidas nao viram nos fantasmas.
- Apenas relacoes resolvidas para referencias conhecidas entram no indice.

### 11.1 Resolucao de Chamadas

Durante `refresh_index`:

1. Extrai todas as referencias do arquivo.
2. Monta mapa local do proprio arquivo.
3. Resolve primeiro chamadas locais.
4. Tenta resolver chamadas externas ja conhecidas no workspace.

Cobertura de deteccao para Python no MVP:

- Chamadas diretas a nomes simples: `foo()`
- Chamadas por atributo: `obj.method()`
- Casos dinamicos ficam fora do MVP.

## 12. Vizinhanca (get_neighbors)

- Opera por `reference_id`.
- Profundidade padrao: `1`. Maxima no MVP: `2`.
- Ordenacao: mesmo arquivo primeiro, maior confianca, desempate estavel.
- Paginacao simples para evitar respostas grandes.

## 13. Limites de Resposta

Respostas pequenas por padrao para preservar a vantagem de contexto. Limites baixos com paginacao para expansao controlada.

Defaults sugeridos (a validar durante implementacao):

- `search_code`: `top_k=10`
- `find_symbol`: `top_k=5`
- `get_neighbors`: `page_size=10`

## 14. Estrutura Logica de Modulos

O codigo deve nascer modular para favorecer desenvolvimento com agentes. Separacao logica minima:

- Interface MCP (transporte e roteamento)
- Servicos de busca
- Servicos de indexacao
- Modulo de embeddings
- Modulo de ranking
- Parsers por linguagem
- Camada de repositorio (acesso a dados)
- Modelos, schemas e configuracao

## 15. Ferramentas MCP do MVP

| Tool | Tipo | Descricao |
|---|---|---|
| `search_code` | Busca | Busca semantica hibrida por intencao |
| `find_symbol` | Busca | Localizacao exata por nome, simbolo ou caminho de arquivo |
| `get_neighbors` | Navegacao | Contexto estrutural e relacoes de chamada |
| `refresh_index` | Indexacao | Reconstrucao do indice de um arquivo |
| `mark_file_dirty` | Indexacao | Marca arquivo como potencialmente desatualizado |
| `remove_file` | Indexacao | Remove arquivo e seus dados do indice |

## 16. Pontos Abertos para Implementacao

- Nomes finais de tabelas e colunas.
- Valores exatos de `top_k` e limites de paginacao.
- Estrutura concreta de diretorios do codigo-fonte.
- Schema JSON exato de cada tool MCP.
- Politica final de pesos no ranking hibrido.

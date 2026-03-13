# PRD - Bouncer MVP

[Read in English](./prd.md)

## 1. Visão Geral

O Bouncer é uma ferramenta local-first de busca e navegação de código para agentes via MCP.

Seu objetivo é reduzir o volume de código que precisa ser lido por um LLM antes de localizar o ponto correto de análise ou alteração. Em vez de varrer arquivos inteiros, o agente deve conseguir consultar o Bouncer para encontrar referências relevantes no código e relações diretas de dependência ao redor dessas referências.

O Bouncer não substitui a leitura direta do código. Ele atua como um filtro de contexto e um atalho de navegação.

## 2. Problema

Quando um agente precisa localizar ou alterar um comportamento em uma base de código, ele tende a varrer arquivos inteiros e relações de dependência manualmente. Isso consome contexto e tokens em excesso, especialmente em arquivos longos onde o ponto útil representa apenas uma pequena fração do conteúdo total.

O Bouncer deve reduzir esse desperdício apontando, com baixo custo, onde o agente deve olhar primeiro.

## 3. Objetivo do Produto

Permitir que agentes MCP consultem uma intenção em linguagem natural ou um identificador direto e recebam como resposta:

- as referências indexadas mais prováveis
- a localização dessas referências no workspace
- relações diretas de chamada para ajudar na exploração incremental

O objetivo de negócio do MVP é reduzir consumo desnecessário de contexto e tokens durante tarefas de engenharia assistida por LLM.

## 4. Usuário Principal

O usuário principal do MVP são agentes MCP de desenvolvimento.

Usuários secundários, como assistentes de code review ou humanos via CLI, podem existir no futuro, mas não orientam o escopo inicial.

## 5. Princípios de Escopo

- O Bouncer é um índice local de navegação para agentes.
- O Bouncer não explica o código e não tenta resolver a tarefa pelo agente.
- O Bouncer não substitui a leitura direta dos arquivos no workspace.
- O Bouncer deve priorizar baixo custo operacional e simplicidade.
- O Bouncer não deve evoluir no MVP para um indexador arquitetural profundo ou um sistema de entendimento completo de código.

## 6. Escopo do MVP

O MVP deve operar sobre o estado atual do workspace local.

O piloto inicial será implementado e validado no próprio repositório do Bouncer, em Python.

No MVP, a única linguagem com suporte explicitamente previsto é Python. Suporte a outras linguagens fica para fases posteriores.

No MVP, o Bouncer deve oferecer quatro capacidades principais:

- busca semântica por intenção em linguagem natural
- busca exata por identificadores, símbolos ou arquivo
- consulta de vizinhança estrutural de uma referência indexada
- atualização do índice por arquivo

### 6.1 Premissas Técnicas Básicas

O MVP será um único serviço MCP em Python, executado nativamente no sistema operacional do ambiente de desenvolvimento. Docker não faz parte do caminho principal do MVP.

O MVP utilizará PostgreSQL com pgvector como armazenamento externo de vetores e metadados indexados.

Os embeddings serão gerados localmente, sem uso de APIs externas, por um modelo pequeno o suficiente para execução em CPU em ambiente comum de desenvolvimento.

A implementação inicial adotará o modelo `all-MiniLM-L6-v2`, podendo ser revista após validação do piloto.

## 7. Casos de Uso do MVP

### 7.1 Localização inicial

Um agente faz uma pergunta como:

`onde está a validação deste comportamento?`

O Bouncer retorna as referências mais prováveis para leitura inicial.

### 7.2 Navegação por símbolo

Um agente já conhece o nome de uma função, método ou arquivo e precisa localizar rapidamente sua posição atual no workspace.

### 7.3 Exploração incremental

Após ler um trecho, o agente identifica a necessidade de entender outra função ou chamada relacionada. Em vez de continuar varrendo o arquivo manualmente, ele faz nova consulta ao Bouncer.

### 7.4 Sincronização do índice

Um processo determinístico externo identifica que um arquivo foi alterado e aciona atualização ou marcação de desatualização sem depender de interpretação por LLM.

## 8. Entradas e Saídas

### 8.1 Entrada principal

A entrada principal do sistema no MVP é uma consulta em linguagem natural feita por um agente MCP sobre onde encontrar, entender ou alterar um comportamento na base de código.

### 8.2 Entradas adicionais

O sistema também deve aceitar consultas diretas por:

- nome de função
- nome de método
- símbolo
- caminho de arquivo

### 8.3 Saída mínima obrigatória

Para cada consulta, o Bouncer deve retornar:

- referências relevantes no índice
- caminho do arquivo
- símbolo, quando houver
- linha inicial e final
- score de relevância ou confiança
- quais referências chamam a referência retornada, quando detectável
- quais referências são chamadas por ela, quando detectável

Arquivos marcados como alterados continuam elegíveis para busca, mas devem ser retornados com confiança reduzida e aviso explícito de possível desatualização posicional.

## 9. Unidade de Indexação

No MVP, o trecho indexável principal será função ou método, identificado via parsing AST da biblioteca padrão do Python (`ast`).

A estrutura de parser deve nascer plugável, com interface interna e apenas `PythonParser` implementado no MVP.

Funções aninhadas, classes como unidade própria, properties, lambdas e segmentação textual genérica ficam fora do escopo do MVP. Linguagens não suportadas devem retornar status explícito de `unsupported_language`.

## 10. Dependências e Vizinhança

No MVP, dependência significa relação direta de chamada entre referências indexadas, especialmente funções e métodos.

O sistema deve informar:

- quais referências chamam a referência consultada
- quais referências são chamadas por ela

Casos dinâmicos, ambíguos ou não detectáveis por heurísticas leves podem ser omitidos ou retornados com menor confiança.

## 11. Ferramentas MCP do MVP

O MVP deve expor um conjunto mínimo de ferramentas:

- `search_code`: busca semântica por intenção
- `find_symbol`: localização exata por nome, símbolo ou arquivo
- `get_neighbors`: contexto estrutural e relações diretas de chamada
- `refresh_index`: reconstrução do índice de um arquivo
- `mark_file_dirty`: marca um arquivo como potencialmente desatualizado
- `remove_file`: remove um arquivo e seus dados do indice

## 12. Atualização do Índice

No MVP, a atualização do índice será orientada por arquivo individual.

Um script externo, acionado por hook `post-commit`, será responsável por detectar os arquivos afetados no último commit, montar a fila, marcar arquivos como `dirty`, chamar `refresh_index` arquivo por arquivo e chamar `remove_file` para arquivos deletados.

Se `refresh_index` falhar para um arquivo, esse arquivo deve permanecer `dirty`. Retry, limite de tentativas e alerta são responsabilidade do script, não do Bouncer.

Essa atualização não deve depender de interpretação por LLM.

### 12.1 `refresh_index`

Quando um arquivo mudar, suas referências indexadas e embeddings associados devem ser reconstruídos integralmente para preservar consistência de posição e metadados.

`refresh_index` assume conteúdo sintaticamente válido. Se o parse falhar, a operação retorna erro explícito e não atualiza o índice daquele arquivo.

A resposta mínima por chamada deve incluir:

- arquivo processado
- status
- quantidade de referências geradas
- quantidade de embeddings gerados
- quantidade de dependências extraídas
- erros ou avisos, quando houver

### 12.2 `mark_file_dirty`

O Bouncer deve aceitar marcação de arquivo alterado antes da reindexação.

Enquanto um arquivo estiver marcado como potencialmente desatualizado:

- seus resultados continuam disponíveis
- a confiança posicional deve ser reduzida
- o agente deve receber aviso de que linhas e offsets podem não refletir o estado atual do arquivo

Esse mecanismo existe para ampliar a janela entre indexações sem invalidar totalmente a utilidade do índice.

Arquivos marcados como `dirty` representam um estado degradado aceitável por tempo limitado, mas não um estado operacional desejado como condição persistente.

## 13. Armazenamento

O Bouncer não deve atuar como espelho da base de código.

No MVP, ele armazenará apenas:

- vetores
- metadados de indexação
- relações derivadas necessárias para busca e vizinhança

O conteúdo-fonte permanece no workspace e deve ser lido diretamente quando necessário.

## 14. Metadados Mínimos

Cada referência indexada deve ter, no mínimo:

- identificador de projeto ou workspace
- caminho do arquivo
- linguagem
- nome do símbolo, quando existir
- tipo do símbolo
- linha inicial
- linha final
- flag de estado `dirty`, derivada do estado do arquivo (nao armazenada por referencia)
- referências de chamadas de saída, quando detectáveis
- referências de chamadas de entrada derivadas do índice, quando detectáveis

## 15. Critérios de Sucesso

O principal critério de sucesso do MVP é reduzir em pelo menos 40% as varreduras completas de arquivos pelos agentes.

Em termos operacionais, a meta é que, a cada 10 consultas de localização ou alteração feitas ao Bouncer, pelo menos 4 permitam ao agente localizar o ponto necessário sem precisar varrer o arquivo inteiro.

Para o piloto, essa medição deverá ser feita por instrumentação do workflow de teste, correlacionando o uso das ferramentas MCP do Bouncer com leituras diretas de arquivo observáveis no mesmo cenário de execução.

Métricas quantitativas de latência e reindexação não serão fixadas no PRD inicial. Elas deverão ser observadas no ambiente real do piloto e transformadas em metas após a coleta de baseline.

## 16. Hipótese Principal

Mesmo com embeddings leves, heurísticas simples e indexação sem armazenar o código-fonte, é possível reduzir materialmente a varredura de arquivos por agentes em tarefas reais de desenvolvimento.

## 17. Principal Risco

O maior risco do MVP é manter o índice sincronizado com o workspace sem perder a vantagem de custo e simplicidade.

Em especial, a eficácia do Bouncer depende de acionar reindexação no momento certo, sem exigir leitura excessiva pelo agente e sem gerar processamento desnecessário.

## 18. Fora de Escopo do MVP

- LLM interno para interpretação, síntese ou roteamento
- suporte universal a qualquer linguagem
- parsing profundo por AST para todas as linguagens
- armazenamento completo do código no banco
- atualização incremental ultrafina em nível subarquivo
- análise de histórico Git, branches e diffs
- qualquer tentativa de substituir a leitura direta do código pelo agente

## 19. Resumo Executivo

O MVP do Bouncer é um índice local e minimalista de navegação para agentes MCP.

Ele deve responder duas perguntas fundamentais com baixo custo:

- onde está a referência mais provável que preciso ler agora
- quais chamadas diretas entram e saem dessa referência

Se o produto fizer isso de forma consistente, já terá validado sua proposta principal de valor.

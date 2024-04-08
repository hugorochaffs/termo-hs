# TERMO

## Para instalar dependencias:    
    cabal install --dependencies-only --overwrite-policy=always
## Para fazer a build:    
    cabal build
## Para rodar o jogo:    
    cabal run

## Explicação sobre o código:

    Este código Haskell é um jogo de adivinhação de palavras, similar ao popular jogo "Wordle". O jogo seleciona uma palavra aleatória de um arquivo, e o jogador tem um número limitado de tentativas para adivinhar a palavra, recebendo dicas sobre quão próximas suas tentativas estão da palavra correta. Vamos destrinchar o código parte por parte:

### Bibliotecas e Extensões
- Utiliza várias bibliotecas para controle de estado, entrada/saída (IO), manipulação de arrays e strings, etc.
- A extensão `OverloadedStrings` permite que strings literais sejam interpretadas como diferentes tipos de dados de string, como `Data.Text`.

### Estruturas de Dados Principais
- `GameState`: Mantém o estado do jogo, incluindo o mapa de tentativas de letras (`_attemptMap`), o número de tentativas feitas (`_guesses`), o mapa de palavras (`_wordMap`), a resposta correta (`_answer`) e o número máximo de tentativas (`_maxGuesses`).
- `CharacterStatus`: Representa o estado de uma tentativa de letra, podendo ser `Untested`, `DoesntExist`, `WrongPlace`, ou `RightPlace`.

### Função Principal `main`
- Configura a saída do terminal para não usar buffer.
- Carrega um mapa de palavras a partir de um arquivo chamado "palavras.txt".
- Seleciona aleatoriamente uma palavra desse mapa para ser a resposta do jogo.
- Inicializa o estado do jogo com valores padrão e inicia o loop do jogo.

### Loop do Jogo e Lógica
- O jogo usa um loop (`loop`) que continua pedindo tentativas do jogador até que o jogo termine (vitória, derrota ou saída).
- `game`: Principal função do jogo que processa tentativas, verifica a validade das palavras, e atualiza o estado do jogo baseado no resultado da tentativa.

### Funções Auxiliares
- `getWordMap`: Carrega o mapa de palavras do arquivo, normalizando os acentos para facilitar a comparação.
- `showAttempt`, `renderAttempt`, e `updateAttemptMap`: Funções que, juntas, avaliam a tentativa do jogador, mostram o resultado usando cores e atualizam o mapa de tentativas.
- `displayAttemptNumbers`: Mostra ao jogador o número atual da tentativa e o máximo de tentativas permitidas.
- `printLnS`, `continue`, `makeAttempt`: Funções que auxiliam na interação com o jogador, permitindo continuar o jogo, fazer uma tentativa de adivinhar a palavra, ou imprimir mensagens formatadas.

### Representação Visual e Interação
- Utiliza funções para colorir o texto e fornecer feedback visual ao jogador sobre o estado das suas tentativas (por exemplo, se uma letra está na posição correta, na palavra mas em posição errada, ou não está na palavra).
- Permite ao jogador comandos especiais como `:s` para sair, `:?` para ajuda, e `:l` para listar as tentativas.

Este código demonstra conceitos importantes em Haskell, como manipulação de estado em um contexto IO, programação funcional com uso intenso de mapas e arrays, além de técnicas para interação com o usuário via terminal.

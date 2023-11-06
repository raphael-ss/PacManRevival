#include <stdio.h>
#include <stdlib.h>
#include "tPosicao.h"
#include "tMovimento.h"
#include "tMapa.h"

typedef struct tPacman{
    /* Posição atual do pacman (linha,coluna) */
    tPosicao* posicaoAtual;

    /* Estado de vida do pacman: vivo ou morto */
    int estaVivo;

    /* Estatísticas para quando o pacman se move para baixo */
    int nMovimentosBaixo;
    int nFrutasComidasBaixo;
    int nColisoesParedeBaixo;

    /* Estatísticas para quando o pacman se move para cima */
    int nMovimentosCima;
    int nFrutasComidasCima;
    int nColisoesParedeCima;

    /* Estatísticas para quando o pacman se move para a esquerda */
    int nMovimentosEsquerda;
    int nFrutasComidasEsquerda;
    int nColisoesParedeEsquerda;

    /* Estatísticas para quando o pacman se move para a direita */
    int nMovimentosDireita;
    int nFrutasComidasDireita;
    int nColisoesParedeDireita;

    /* Histórico de movimentos significativos do pacman */
    int nMovimentosSignificativos;
    tMovimento** historicoDeMovimentosSignificativos;

    /* Trilha gerada pelos passos do pacman. */
    int nLinhasTrilha;
    int nColunasTrilha;
    int** trilha;
} tPacman;


/**
 * Cria o pacman dinamicamente. Caso dê erro na alocação da estrutura tPacman, 
 * retorna NULL. 
 * Caso a posição passada como parâmetro seja NULL, retorna NULL.
 * Caso não dê erros, retorna o ponteiro para o tPacman alocado.
 * \param posicao Ponteiro para tPosicao
 */
tPacman* CriaPacman(tPosicao* posicao){
    tPacman* pacman = (tPacman*)malloc(sizeof(tPacman));
    if (pacman == NULL) {
        return NULL;
    }

    pacman->estaVivo = 1;
    pacman->nColisoesParedeBaixo = 0;
    pacman->nColisoesParedeCima = 0;
    pacman->nColisoesParedeDireita = 0;
    pacman->nColisoesParedeEsquerda = 0;

    pacman->nColunasTrilha = 0;
    pacman->nLinhasTrilha = 0;
    pacman->trilha = NULL;

    pacman->nMovimentosSignificativos = 0;
    pacman->historicoDeMovimentosSignificativos = NULL;

    pacman->nMovimentosBaixo = 0;
    pacman->nMovimentosCima = 0;
    pacman->nMovimentosDireita = 0;
    pacman->nMovimentosEsquerda = 0;

    pacman->nFrutasComidasBaixo = 0;
    pacman->nFrutasComidasCima = 0;
    pacman->nFrutasComidasDireita = 0;
    pacman->nFrutasComidasEsquerda = 0;

    if (posicao != NULL) {
        pacman->posicaoAtual = ClonaPosicao(posicao);
        DesalocaPosicao(posicao);
    }
    else {
        return NULL;
    }

    return pacman;
}

/**
 * Clona o pacman dinamicamente, apenas com relação a posição.
 * Aloca outro pacman apenas copiando as informações de linha e coluna do original (passado como parâmetro).
 * \param pacman pacman
 */
tPacman* ClonaPacman(tPacman* pacman){
    if (pacman != NULL) {
        return CriaPacman(ClonaPosicao(pacman->posicaoAtual));
    }
    return NULL;
}

/**
 * Clona a lista historico de movimentos significativos do pacman.
 * Aloca dinamicamente todas as estruturas do histórico de
 * movimentos do pacman original (passado como parâmetro): a lista e os movimentos da lista.
 * E por fim copia as informações do histórico original para o clone.
 * Retorna um ponteiro para o tMovimento** clone.
 * \param pacman pacman
 */
tMovimento** ClonaHistoricoDeMovimentosSignificativosPacman(tPacman* pacman){
    tMovimento** historico = (tMovimento**)malloc(pacman->nMovimentosSignificativos * sizeof(tMovimento*));
    for (int i = 0; i < pacman->nMovimentosSignificativos; i++) {
        tMovimento* mov = pacman->historicoDeMovimentosSignificativos[i];
        historico[i] = CriaMovimento(ObtemNumeroMovimento(mov), ObtemComandoMovimento(mov), ObtemAcaoMovimento(mov));
    }

    return historico;
}

/**
 * Retorna a posição do pacman.
 * 
 * \param pacman pacman
 */
tPosicao* ObtemPosicaoPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->posicaoAtual);
    }
    return NULL;
}

/**
 * Retorna se o pacman está vivo ou morto.
 * 
 * \param pacman pacman
 */
int EstaVivoPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->estaVivo);
    }
    return 0;
}

/**
 * Retorna o número atual de movimentos do pacman
 * 
 * \param pacman pacman
 */
int ObtemNumeroAtualMovimentosPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nMovimentosBaixo + pacman->nMovimentosCima + pacman->nMovimentosDireita + pacman->nMovimentosEsquerda);
    }
    return 0;
}

/**
 * Insere na lista de movimentos um novo movimento significativo.
 * Dado o pacman, o comando do jogador, e a ação significativa,
 * cria um movimento significativo tMovimento com essas informações e
 * insere na lista de movimentos significativos do pacman.
 * 
 * \param pacman pacman
 * \param comando o comando do movimento
 * \param acao a ação do movimento
 */
void InsereNovoMovimentoSignificativoPacman(tPacman* pacman, COMANDO comando, const char* acao){
    if (pacman != NULL) {
        pacman->nMovimentosSignificativos++;
        pacman->historicoDeMovimentosSignificativos = (tMovimento**)realloc(pacman->historicoDeMovimentosSignificativos, (pacman->nMovimentosSignificativos * sizeof(tMovimento*)));

        tMovimento* mov = CriaMovimento(ObtemNumeroAtualMovimentosPacman(pacman), comando, acao);
        pacman->historicoDeMovimentosSignificativos[pacman->nMovimentosSignificativos-1] = mov;
    }

    return;
}

/**
 * Atualiza na trilha a posição por onde passou o pacman.
 * Dado o pacman, com suas informações de posição e trilha na estrutura,
 * atualiza o item da trilha, referente a posição atual do pacman,
 * para o valor int correspondente ao número do movimento atual do pacman.
 * \param pacman pacman
 */
void AtualizaTrilhaPacman(tPacman* pacman){
    if ((pacman != NULL) && (pacman->trilha != NULL) && (pacman->posicaoAtual != NULL)){
        pacman->trilha[ObtemLinhaPosicao(pacman->posicaoAtual)][ObtemColunaPosicao(pacman->posicaoAtual)] = ObtemNumeroAtualMovimentosPacman(pacman);
    }
    return;
}


/**
 * Função que irá mover o pacman no mapa, atualizando sua posição.
 * Dado o pacman, o mapa, e o comando do jogador, a posição do pacman
 * é atualizada. Consultas ao mapa deverão ser feitas para ver se
 * a posição pode ser realmente atualizada ou não, como por exemplo,
 * se o pacman encontrou uma parede ele não se move.
 * 
 * \param pacman pacman
 * \param mapa o mapa que contem o pacman
 * \param comando o comando para onde irá o pacman
 */
void MovePacman(tPacman* pacman, tMapa* mapa, COMANDO comando){  
    if ((mapa != NULL) && (pacman != NULL)) {

        if (comando == MOV_ESQUERDA){
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(pacman->posicaoAtual), ObtemColunaPosicao(pacman->posicaoAtual)-1);
            pacman->nMovimentosEsquerda++;

            if (!EncontrouParedeMapa(mapa, posPretendida)){
                AtualizaPosicao(pacman->posicaoAtual, posPretendida);
            }
            if (PossuiTunelMapa(mapa) && (!EncontrouParedeMapa(mapa, posPretendida))) {
                if (AcessouTunelMapa(mapa, pacman->posicaoAtual)){
                    AtualizaTrilhaPacman(pacman);
                    EntraTunelMapa(mapa, pacman->posicaoAtual);
                }
            }

            else if (EncontrouParedeMapa(mapa, posPretendida)) {
                pacman->nColisoesParedeEsquerda++;
                InsereNovoMovimentoSignificativoPacman(pacman, comando, "colidiu com a parede");
            }


            if (EncontrouComidaMapa(mapa, pacman->posicaoAtual)) {
                AtualizaItemMapa(mapa, posPretendida, ' ');
                pacman->nFrutasComidasEsquerda++;
                InsereNovoMovimentoSignificativoPacman(pacman, comando, "pegou comida");
            }

            AtualizaTrilhaPacman(pacman);
            DesalocaPosicao(posPretendida);
            return;
        }

        else if (comando == MOV_DIREITA){
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(pacman->posicaoAtual), ObtemColunaPosicao(pacman->posicaoAtual)+1);
            pacman->nMovimentosDireita++;

            if (!EncontrouParedeMapa(mapa, posPretendida)){
                AtualizaPosicao(pacman->posicaoAtual, posPretendida);
            }
            if (PossuiTunelMapa(mapa) && (!EncontrouParedeMapa(mapa, posPretendida))) {
                if (AcessouTunelMapa(mapa, pacman->posicaoAtual)){
                    AtualizaTrilhaPacman(pacman);
                    EntraTunelMapa(mapa, pacman->posicaoAtual);
                }
            }

            else if (EncontrouParedeMapa(mapa, posPretendida)) {
                pacman->nColisoesParedeDireita++;
                InsereNovoMovimentoSignificativoPacman(pacman, comando, "colidiu com a parede");
            }

            if (EncontrouComidaMapa(mapa, posPretendida)) {
                AtualizaItemMapa(mapa, posPretendida, ' ');
                pacman->nFrutasComidasDireita++;
                InsereNovoMovimentoSignificativoPacman(pacman, comando, "pegou comida");
            }

            AtualizaTrilhaPacman(pacman);
            DesalocaPosicao(posPretendida);
            return;
        }
        

        else if (comando == MOV_BAIXO){
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(pacman->posicaoAtual)+1, ObtemColunaPosicao(pacman->posicaoAtual));
            pacman->nMovimentosBaixo++;

            if (!EncontrouParedeMapa(mapa, posPretendida)){
                AtualizaPosicao(pacman->posicaoAtual, posPretendida);
            }

            if (PossuiTunelMapa(mapa) && (!EncontrouParedeMapa(mapa, posPretendida))) {
                if (AcessouTunelMapa(mapa, pacman->posicaoAtual)){
                    AtualizaTrilhaPacman(pacman);
                    EntraTunelMapa(mapa, pacman->posicaoAtual);
                }
            }

            else if (EncontrouParedeMapa(mapa, posPretendida)) {
                pacman->nColisoesParedeBaixo++;
                InsereNovoMovimentoSignificativoPacman(pacman, comando, "colidiu com a parede");
            }

            if (EncontrouComidaMapa(mapa, posPretendida)) {
                AtualizaItemMapa(mapa, posPretendida, ' ');
                pacman->nFrutasComidasBaixo++;
                InsereNovoMovimentoSignificativoPacman(pacman, comando, "pegou comida");
            }

            AtualizaTrilhaPacman(pacman);
            DesalocaPosicao(posPretendida);
            return;
        }
        

        else if (comando == MOV_CIMA){
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(pacman->posicaoAtual)-1, ObtemColunaPosicao(pacman->posicaoAtual));
            pacman->nMovimentosCima++;

            if (!EncontrouParedeMapa(mapa, posPretendida)){
                AtualizaPosicao(pacman->posicaoAtual, posPretendida);
            }

            if (PossuiTunelMapa(mapa) && (!EncontrouParedeMapa(mapa, posPretendida))) {
                if (AcessouTunelMapa(mapa, pacman->posicaoAtual)){
                    AtualizaTrilhaPacman(pacman);
                    EntraTunelMapa(mapa, pacman->posicaoAtual);
                }
            }

            else if (EncontrouParedeMapa(mapa, posPretendida)) {
                pacman->nColisoesParedeCima++;
                InsereNovoMovimentoSignificativoPacman(pacman, comando, "colidiu com a parede");
            }

            if (EncontrouComidaMapa(mapa, posPretendida)) {
                AtualizaItemMapa(mapa, posPretendida, ' ');
                pacman->nFrutasComidasCima++;
                InsereNovoMovimentoSignificativoPacman(pacman, comando, "pegou comida");
            }

            AtualizaTrilhaPacman(pacman);
            DesalocaPosicao(posPretendida);
            return;
        }
        
    }
}

/**
 * Aloca a trilha dinamicamente.
 * Caso a trilha seja igual a NULL, a matriz int** deverá ser
 * alocada dinamicamente com os valores de linha e coluna.
 * 
 * \param pacman pacman
 * \param nLinhas número de linhas da trilha
 * \param nColunas número de colunas da trilha
 */
void CriaTrilhaPacman(tPacman* pacman, int nLinhas, int nColunas){
    if (pacman->trilha == NULL) {
        tPosicao* pos_pacman = ObtemPosicaoPacman(pacman);
        pacman->nLinhasTrilha = nLinhas;
        pacman->nColunasTrilha = nColunas;

        pacman->trilha = (int**)malloc(nLinhas * sizeof(int*));
        for (int i = 0; i < nLinhas; i++) {
            pacman->trilha[i] = (int*)malloc(nColunas * sizeof(int));
        }

        for (int i = 0; i < nLinhas; i++) {
            for (int j = 0; j < nColunas; j++) {
                if ((ObtemLinhaPosicao(pos_pacman) == i) && (ObtemColunaPosicao(pos_pacman) == j)) {
                    pacman->trilha[i][j] = 0;    
                }
                else {
                    pacman->trilha[i][j] = -1;    
                }
                //pacman->trilha[i][j] = -1;
            }
        }
        return;
    }
}


/**
 * Salva a trilha em um arquivo na raíz junto com o binário.
 * 
 * \param pacman pacman
 */
void SalvaTrilhaPacman(tPacman* pacman){
    if ((pacman != NULL) && (pacman->trilha != NULL)) {
        FILE * pTrilha = fopen("trilha.txt", "w");
        if (pTrilha == NULL) {
            exit(1);
        }

        for (int i = 0; i < pacman->nLinhasTrilha; i++) {
            for (int j = 0; j < pacman->nColunasTrilha; j++) {
                if (pacman->trilha[i][j] != -1){
                    if (j == pacman->nColunasTrilha-1) {
                        fprintf(pTrilha, "%d", pacman->trilha[i][j]);
                    }
                    else {
                        fprintf(pTrilha, "%d ", pacman->trilha[i][j]);
                    }
                    
                }
                else {
                    if (j == pacman->nColunasTrilha-1) {
                        fprintf(pTrilha, "#");
                    }
                    else {
                        fprintf(pTrilha, "# ");
                    }
                }
            }
            // ESPAÇO
            fprintf(pTrilha, "\n");
        }
        fclose(pTrilha);

        return;
    }
}

/**
 * Seta pacman para morto.
 * 
 * \param pacman pacman
 */
void MataPacman(tPacman* pacman){
    if (pacman != NULL) {
        pacman->estaVivo = 0;
    }
}

/**
 * Caso o pacman seja diferente de NULL, libera o espaço 
 * alocado para a estrutura tPacman.
 * Sempre verificar se é NULL antes de dar free.
 * 
 * \param pacman pacman
 */
void DesalocaPacman(tPacman* pacman){
    if (pacman == NULL) {
        return;
    }

    if (pacman->trilha != NULL) {
        for (int i = 0; i < pacman->nLinhasTrilha; i++) {
            free(pacman->trilha[i]);
            pacman->trilha[i] = NULL;
        }
        free(pacman->trilha);
        pacman->trilha = NULL;
    }

    if (pacman->historicoDeMovimentosSignificativos != NULL) {
        for (int i = 0; i < pacman->nMovimentosSignificativos; i++) {
            DesalocaMovimento(pacman->historicoDeMovimentosSignificativos[i]);
            //pacman->historicoDeMovimentosSignificativos[i] = NULL;
        }
        free(pacman->historicoDeMovimentosSignificativos);
        pacman->historicoDeMovimentosSignificativos = NULL;
    }

    if (pacman->posicaoAtual != NULL){
        DesalocaPosicao(pacman->posicaoAtual);
        pacman->posicaoAtual = NULL;
    }

    free(pacman);
    return;
}

/**
 * Retorna o número de movimentos sem pontuar do pacman
 * 
 * \param pacman pacman
 */
int ObtemNumeroMovimentosSemPontuarPacman(tPacman* pacman){
    if (pacman != NULL) {
        return ((pacman->nMovimentosBaixo + pacman->nMovimentosCima + pacman->nMovimentosDireita + pacman->nMovimentosEsquerda) - 
    ((pacman->nFrutasComidasBaixo + pacman->nFrutasComidasCima + pacman->nFrutasComidasEsquerda + pacman->nFrutasComidasDireita)));
    }
    return 0;
}

/**
 * Retorna o número de colisões com a parede do pacman
 * 
 * \param pacman pacman
 */
int ObtemNumeroColisoesParedePacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nColisoesParedeBaixo + pacman->nColisoesParedeCima + pacman->nColisoesParedeDireita + pacman->nColisoesParedeEsquerda);
    }
    return 0;
}

/**
 * Retorna o número de movimentos para baixo do pacman
 * 
 * \param pacman pacman
 */
int ObtemNumeroMovimentosBaixoPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nMovimentosBaixo);
    }
    return 0;
}

/**
 * Retorna o número de frutas comidas para baixo pelo pacman
 * 
 * \param pacman pacman
 */
int ObtemNumeroFrutasComidasBaixoPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nFrutasComidasBaixo);
    }
    return 0;
}

/**
 * Retorna o número de colisões com a parede para baixo
 * 
 * \param pacman pacman
 */
int ObtemNumeroColisoesParedeBaixoPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nColisoesParedeBaixo);
    }
    return 0;
}

/**
 * Retorna o número de movimentos para baixo do pacman
 * 
 * \param pacman pacman
 */
int ObtemNumeroMovimentosCimaPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nMovimentosCima);
    }
    return 0;
}

/**
 * Retorna o número de frutas comidas para cima pelo pacman
 * 
 * \param pacman pacman
 */
int ObtemNumeroFrutasComidasCimaPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nFrutasComidasCima);
    }
    return 0;
}

/**
 * Retorna o número de colisões com a parede para cima
 * 
 * \param pacman pacman
 */
int ObtemNumeroColisoesParedeCimaPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nColisoesParedeCima);
    }
    return 0;
}

/**
 * Retorna o número de movimentos para a esquerda do pacman
 * 
 * \param pacman pacman
 */
int ObtemNumeroMovimentosEsquerdaPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nMovimentosEsquerda);
    }
    return 0;
}

/**
 * Retorna o número de frutas comidas para a esquerda pelo pacman
 * 
 * \param pacman pacman
 */
int ObtemNumeroFrutasComidasEsquerdaPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nFrutasComidasEsquerda);
    }
    return 0;
}

/**
 * Retorna o número de colisões com a parede para esquerda
 * 
 * \param pacman pacman
 */
int ObtemNumeroColisoesParedeEsquerdaPacman(tPacman* pacman) {
    if (pacman != NULL) {
        return (pacman->nColisoesParedeEsquerda);
    }
    return 0;
}

/**
 * Retorna o número de movimentos para a direita do pacman
 * 
 * \param pacman pacman
 */
int ObtemNumeroMovimentosDireitaPacman(tPacman* pacman) {
    if (pacman != NULL) {
        return (pacman->nMovimentosDireita);
    }
    return 0;
}

/**
 * Retorna o número de frutas comidas para a direita pelo pacman
 * 
 * \param pacman pacman
 */
int ObtemNumeroFrutasComidasDireitaPacman(tPacman* pacman) {
    if (pacman != NULL) {
        return (pacman->nFrutasComidasDireita);
    }
    return 0;
}

/**
 * Retorna o número de colisões com a parede para direita
 * 
 * \param pacman pacman
 */
int ObtemNumeroColisoesParedeDireitaPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nColisoesParedeDireita);
    }
    return 0;
}

/**
 * Retorna o número de movimentos significativos do pacman
 * 
 * \param pacman pacman
 */
int ObtemNumeroMovimentosSignificativosPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nMovimentosSignificativos);
    }
    return 0;
}

/**
 * Retorna a pontuação atual do pacman
 * 
 * \param pacman pacman
 */
int ObtemPontuacaoAtualPacman(tPacman* pacman){
    if (pacman != NULL) {
        return (pacman->nFrutasComidasBaixo + pacman->nFrutasComidasCima + pacman->nFrutasComidasEsquerda + pacman->nFrutasComidasDireita);
    }
    return 0;
}




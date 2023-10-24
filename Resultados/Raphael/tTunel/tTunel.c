#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include "tTunel.h"

/**
 * Cria o tunel dinamicamente
 * \param linhaAcesso1 linha da posição do acesso 1 do túnel
 * \param colunaAcesso1 coluna da posição do acesso 1 do túnel
 * \param linhaAcesso2 linha da posição do acesso 2 do túnel
 * \param colunaAcesso2 coluna da posição do acesso 2 do túnel
 */
tTunel* CriaTunel(int linhaAcesso1, int colunaAcesso1, int linhaAcesso2, int colunaAcesso2){
    tTunel* tunel = (tTunel*) malloc(sizeof(tTunel));
    tunel->acesso1 = CriaPosicao(linhaAcesso1,colunaAcesso1);
    tunel->acesso2 = CriaPosicao(linhaAcesso2, colunaAcesso2);
    return tunel;
}

/**
 * Verifica se entrou no túnel pela posição
 * \param tunel tunel
 * \param posicao posição
 */
bool EntrouTunel(tTunel* tunel, tPosicao* posicao){
    if (SaoIguaisPosicao(tunel->acesso1,posicao) || SaoIguaisPosicao(tunel->acesso2,posicao)){
        return true;
    }
    return false;
}

/**
 * Atualiza a posição para o final do túnel
 * \param tunel tunel
 * \param posicao posição
 */
void LevaFinalTunel(tTunel* tunel, tPosicao* posicao){
    if (SaoIguaisPosicao(tunel->acesso1,posicao)){
        AtualizaPosicao(posicao, tunel->acesso2);
    }
    else if (SaoIguaisPosicao(tunel->acesso2,posicao)) {
        AtualizaPosicao(posicao, tunel->acesso1);
    }
    else {
        printf("mayhem");
    }
    return;
}

/**
 * Libera o espaço alocado para a estrutura tTunel
 * 
 * \param tunel tunel
 */
void DesalocaTunel(tTunel* tunel){
    if (tunel != NULL) {
        DesalocaPosicao(tunel->acesso1);
        DesalocaPosicao(tunel->acesso2);
        free(tunel);
    }
    return;
}


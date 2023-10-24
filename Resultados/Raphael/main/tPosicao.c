#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "tPosicao.h"

/**
 * Cria a posição dinamicamente
 * \param linha linha da posição
 * \param coluna coluna da posição
 */
tPosicao* CriaPosicao(int linha, int coluna) {
    tPosicao* pos = (tPosicao*) malloc(sizeof(tPosicao));
    pos->linha = linha;
    pos->coluna = coluna;
    return pos;
}

/**
 * Clona a posição (construtor de cópia)
 * \param posicao posição
 */
tPosicao* ClonaPosicao(tPosicao* posicao) {
    tPosicao* clone = CriaPosicao(posicao->linha, posicao->coluna);
    return clone;
}

/**
 * Retorna a linha da posição
 * \param posicao posição
 */
int ObtemLinhaPosicao(tPosicao* posicao) {
    return (posicao->linha);
}

/**
 * Retorna a coluna da posição
 * \param posicao posição
 */
int ObtemColunaPosicao(tPosicao* posicao){
    return (posicao->coluna);
}

/**
 * Atualiza a posição a atual por uma nova posição
 * \param posicaoAtual posição atual
 * \param posicaoNova posição nova
 */
void AtualizaPosicao(tPosicao* posicaoAtual, tPosicao* posicaoNova){
    *posicaoAtual = *posicaoNova;
    return;
}

/**
 * Verifica se 2 posição são iguais
 * \param posicao1 posição 1
 * \param posicao2 posição 2
 */
bool SaoIguaisPosicao(tPosicao* posicao1, tPosicao* posicao2) {
    if ((ObtemColunaPosicao(posicao1) == ObtemColunaPosicao(posicao2)) && (ObtemLinhaPosicao(posicao1) == ObtemLinhaPosicao(posicao2))) {
        return true;
    }
    return false;
}

/**
 * Libera o espaço alocado para a estrutura tPosicao
 * 
 * \param posicao posicao
 */
void DesalocaPosicao(tPosicao* posicao) {
    free(posicao);
}




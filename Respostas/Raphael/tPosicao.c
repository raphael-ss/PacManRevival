#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "tPosicao.h"

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
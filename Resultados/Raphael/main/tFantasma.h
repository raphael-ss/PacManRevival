#ifndef TFANTASMA_H_
#define TFANTASMA_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "tPosicao.h"
#include "tMovimento.h"
#include "tMapa.h"
#include "tPacman.h"

typedef struct {
    /*ID DO FANTASMA: B, P, I, C*/
    char nome;

    /*DIREÇÃO NORMAL OU DIREÇÃO INVERSA
    TRUE: NORMAL || FALSE: INVERSA   */
    bool mudouDirecao;

    /*POSICAO*/
    tPosicao* posicaoAtual;

    bool sobreComida;
}tFantasma;


/**
 * Cria 1 fantasma com malloc
 * Retorna um ponteiro para um fantasma
 * \param pos Caso a posicao seja NULL, o fantasma criado é NULL
 */
tFantasma* CriaFantasma(char nome, tPosicao* posicao);

/**
 * Cria o os fantasmas com malloc
 * Retorna um ponteiro para um vetor de fantasmas
 * \param pos Caso alguma posicao seja NULL, o fantasma criado é NULL
 */
tFantasma** CriaFantasmas(tPosicao* pos_B, tPosicao* pos_P, tPosicao* pos_I, tPosicao* pos_C);


/**
 * Move os fantasmas, checando quais existem (if fantasma != NULL)
 * \param fantasmas Vetor de ponteiros para fantasmas
 */
void MoveFantasma(tFantasma* fantasma, tMapa* mapa);

/**
 * Move os fantasmas, checando quais existem (if fantasma != NULL)
 * \param fantasmas Vetor de ponteiros para fantasmas
 */
void MoveFantasmas(tFantasma** fantasmas, tMapa* mapa);

/**
 * Retorna o atributo mudouDirecao
 * \param fantasma
 */
bool ObtemDirecaoFantasma(tFantasma* fantasma);

bool FantasmaSobreComida(tFantasma* fantasma);

/**
 * Muda o atributo mudouDirecao
 * \param fantasma
 */
void MudaDirecaoFantasma(tFantasma* fantasma);

/**
 * Retorna a posicaoAtual
 * \param fantasma
 */
tPosicao* ObtemPosicaoFantasma(tFantasma* fantasma);

/**
 * Retorna true se bateu na parede, e false se não
 * \param fantasma
 */
bool FantasmaBateuParede(tFantasma* fantasma, tMapa* mapa);

/**
 * Desaloca 1 fantasma
 * \param fantasma
 */
void DesalocaFantasma(tFantasma* fantasma);

/**
 * Desaloca todos os fantasmas
 * \param fantasmas
 */
void DesalocaFantasmas(tFantasma** fantasmas);

#endif

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
tFantasma* CriaFantasma(char nome, tPosicao* posicao){
    if (posicao == NULL) {
        return NULL;
    }

    tFantasma* fantasma = (tFantasma*)malloc(sizeof(tFantasma));

    fantasma->mudouDirecao = false;
    fantasma->nome = nome;
    fantasma->posicaoAtual = ClonaPosicao(posicao);
    fantasma->sobreComida = false;

    return fantasma;
}

/**
 * Cria o os fantasmas com malloc
 * Retorna um ponteiro para um vetor de fantasmas
 * \param pos Caso alguma posicao seja NULL, o fantasma criado é NULL
 */
tFantasma** CriaFantasmas(tPosicao* pos_B, tPosicao* pos_P, tPosicao* pos_I, tPosicao* pos_C){
    tFantasma** fantasmas = (tFantasma**)malloc(4 * sizeof(tFantasma*));

    fantasmas[0] = CriaFantasma('B', pos_B);
    fantasmas[1] = CriaFantasma('P', pos_P);
    fantasmas[2] = CriaFantasma('I', pos_I);
    fantasmas[3] = CriaFantasma('C', pos_C);
    
    return fantasmas;
}

/**
 * Retorna o atributo mudouDirecao
 * \param fantasma
 */
bool ObtemDirecaoFantasma(tFantasma* fantasma){
    return (fantasma->mudouDirecao);
}

/**
 * Muda o atributo mudouDirecao
 * \param fantasma
 */
void MudaDirecaoFantasma(tFantasma* fantasma) {
    if (ObtemDirecaoFantasma(fantasma) == true) {
        fantasma->mudouDirecao = false;
    }
    else {
        fantasma->mudouDirecao = true;
    }

    return;
}

/**
 * Retorna a posicaoAtual
 * \param fantasma
 */
tPosicao* ObtemPosicaoFantasma(tFantasma* fantasma) {
    if ((fantasma != NULL) && (fantasma->posicaoAtual != NULL)) {
        return (fantasma->posicaoAtual);
    }
    return NULL;
}

/**
 * Retorna true se bateu na parede, e false se não
 * \param fantasma
 */
bool FantasmaBateuParede(tFantasma* fantasma, tMapa* mapa) {
    if (fantasma == NULL) {
        return false;
    }
    if (fantasma->nome == 'B'){
        if (fantasma->mudouDirecao == false) {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma)), ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma))-1);
            if (ObtemItemMapa(mapa, posPretendida) == '#') {
                DesalocaPosicao(posPretendida);
                return true;
            }
            else {
                DesalocaPosicao(posPretendida);
                return false;
            }
        }
        else if (fantasma->mudouDirecao == true) {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma)), ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma))+1);
            if (ObtemItemMapa(mapa, posPretendida) == '#') {
                DesalocaPosicao(posPretendida);
                return true;
            }
            else {
                DesalocaPosicao(posPretendida);
                return false;
            }

        }
    }
    else if (fantasma->nome == 'P'){
        if (fantasma->mudouDirecao == false) {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma))-1, ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma)));
            if (ObtemItemMapa(mapa, posPretendida) == '#') {
                DesalocaPosicao(posPretendida);
                return true;
            }
            else {
                DesalocaPosicao(posPretendida);
                return false;
            }
        }
        else if (fantasma->mudouDirecao == true) {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma))+1, ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma)));
            if (ObtemItemMapa(mapa, posPretendida) == '#') {
                DesalocaPosicao(posPretendida);
                return true;
            }
            else {
                DesalocaPosicao(posPretendida);
                return false;
            }
        }
    }
    else if (fantasma->nome == 'I'){
        if (fantasma->mudouDirecao == false) {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma))+1, ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma)));
            if (ObtemItemMapa(mapa, posPretendida) == '#') {
                DesalocaPosicao(posPretendida);
                return true;
            }
            else {
                DesalocaPosicao(posPretendida);
                return false;
            }
        }
        else if (fantasma->mudouDirecao == true) {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma))-1, ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma)));
            if (ObtemItemMapa(mapa, posPretendida) == '#') {
                DesalocaPosicao(posPretendida);
                return true;
            }
            else {
                DesalocaPosicao(posPretendida);
                return false;
            }
        }
    }
    else if (fantasma->nome == 'C'){
        if (fantasma->mudouDirecao == false) {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma)), ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma))+1);
            if (ObtemItemMapa(mapa, posPretendida) == '#') {
                DesalocaPosicao(posPretendida);
                return true;
            }
            else {
                DesalocaPosicao(posPretendida);
                return false;
            }
        }
        else if (fantasma->mudouDirecao == true) {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma)), ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma))-1);
            if (ObtemItemMapa(mapa, posPretendida) == '#') {
                DesalocaPosicao(posPretendida);
                return true;
            }
            else {
                DesalocaPosicao(posPretendida);
                return false;
            }

        }
    }
}

bool FantasmaSobreComida(tFantasma* fantasma){
    if (fantasma != NULL) {
        return (fantasma->sobreComida);
    }
    return false;
}

/**
 * Move 1 fantasma, chace se fantasma existe
 * \param fantasmas Vetor de ponteiros para fantasmas
 */
void MoveFantasma(tFantasma* fantasma, tMapa* mapa) {
    if (fantasma == NULL) {
        return;
    }

    if (fantasma->nome == 'B') {
        if (ObtemDirecaoFantasma(fantasma) == false) {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma)), ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma))-1);
            if (FantasmaSobreComida(fantasma)) {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, '*');
            }
            else {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, ' ');
            }
            if (ObtemItemMapa(mapa, posPretendida) == '*') {
                fantasma->sobreComida = true;
            }
            else {
                fantasma->sobreComida = false;
            }
            AtualizaPosicao(fantasma->posicaoAtual, posPretendida);
            DesalocaPosicao(posPretendida);
        }
        else {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma)), ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma))+1);
            if (FantasmaSobreComida(fantasma)) {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, '*');
            }
            else {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, ' ');
            }
            if (ObtemItemMapa(mapa, posPretendida) == '*') {
                fantasma->sobreComida = true;
            }
            else {
                fantasma->sobreComida = false;
            }
            AtualizaPosicao(fantasma->posicaoAtual, posPretendida);
            DesalocaPosicao(posPretendida);
        }
    }

    else if (fantasma->nome == 'P') {
        if (ObtemDirecaoFantasma(fantasma) == false) {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma))-1, ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma)));
            if (FantasmaSobreComida(fantasma)) {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, '*');
            }
            else {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, ' ');
            }
            if (ObtemItemMapa(mapa, posPretendida) == '*') {
                fantasma->sobreComida = true;
            }
            else {
                fantasma->sobreComida = false;
            }
            AtualizaPosicao(fantasma->posicaoAtual, posPretendida);
            DesalocaPosicao(posPretendida);
        }
        else {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma))+1, ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma)));
            if (FantasmaSobreComida(fantasma)) {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, '*');
            }
            else {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, ' ');
            }
            if (ObtemItemMapa(mapa, posPretendida) == '*') {
                fantasma->sobreComida = true;
            }
            else {
                fantasma->sobreComida = false;
            }
            AtualizaPosicao(fantasma->posicaoAtual, posPretendida);
            DesalocaPosicao(posPretendida);
        }
    }

    else if (fantasma->nome == 'I') {
        if (ObtemDirecaoFantasma(fantasma) == false) {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma))+1, ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma)));
            if (FantasmaSobreComida(fantasma)) {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, '*');
            }
            else {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, ' ');
            }
            if (ObtemItemMapa(mapa, posPretendida) == '*') {
                fantasma->sobreComida = true;
            }
            else {
                fantasma->sobreComida = false;
            }
            AtualizaPosicao(fantasma->posicaoAtual, posPretendida);
            DesalocaPosicao(posPretendida);
        }
        else {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma))-1, ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma)));
            if (FantasmaSobreComida(fantasma)) {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, '*');
            }
            else {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, ' ');
            }
            if (ObtemItemMapa(mapa, posPretendida) == '*') {
                fantasma->sobreComida = true;
            }
            else {
                fantasma->sobreComida = false;
            }
            AtualizaPosicao(fantasma->posicaoAtual, posPretendida);
            DesalocaPosicao(posPretendida);
        }
    }

    else if (fantasma->nome == 'C') {
        if (ObtemDirecaoFantasma(fantasma) == false) {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma)), ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma))+1);
            if (FantasmaSobreComida(fantasma)) {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, '*');
            }
            else {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, ' ');
            }
            if (ObtemItemMapa(mapa, posPretendida) == '*') {
                fantasma->sobreComida = true;
            }
            else {
                fantasma->sobreComida = false;
            }
            AtualizaPosicao(fantasma->posicaoAtual, posPretendida);
            DesalocaPosicao(posPretendida);
        }
        else {
            tPosicao* posPretendida = CriaPosicao(ObtemLinhaPosicao(ObtemPosicaoFantasma(fantasma)), ObtemColunaPosicao(ObtemPosicaoFantasma(fantasma))-1);
            if (FantasmaSobreComida(fantasma)) {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, '*');
            }
            else {
                AtualizaItemMapa(mapa, fantasma->posicaoAtual, ' ');
            }
            if (ObtemItemMapa(mapa, posPretendida) == '*') {
                fantasma->sobreComida = true;
            }
            else {
                fantasma->sobreComida = false;
            }
            AtualizaPosicao(fantasma->posicaoAtual, posPretendida);
            DesalocaPosicao(posPretendida);
        }
    }
    return;
}

/**
 * Move os fantasmas, checando quais existem (if fantasma != NULL)
 * \param fantasmas Vetor de ponteiros para fantasmas
 */
void MoveFantasmas(tFantasma** fantasmas, tMapa* mapa) {
    // FANTASMA B EXISTE
    if (fantasmas[0] != NULL) {
        if (FantasmaBateuParede(fantasmas[0], mapa)){
            MudaDirecaoFantasma(fantasmas[0]);
            MoveFantasma(fantasmas[0], mapa);
        }
        else {
            MoveFantasma(fantasmas[0], mapa);
        }
    }
    if (fantasmas[1] != NULL) {
        if (FantasmaBateuParede(fantasmas[1], mapa)){
            MudaDirecaoFantasma(fantasmas[1]);
            MoveFantasma(fantasmas[1], mapa);
        }
        else {
            MoveFantasma(fantasmas[1], mapa);
        }
    }
    if (fantasmas[2] != NULL) {
        if (FantasmaBateuParede(fantasmas[2], mapa)){
            MudaDirecaoFantasma(fantasmas[2]);
            MoveFantasma(fantasmas[2], mapa);
        }
        else {
            MoveFantasma(fantasmas[2], mapa);
        }
    }
    if (fantasmas[3] != NULL) {
        if (FantasmaBateuParede(fantasmas[3], mapa)){
            MudaDirecaoFantasma(fantasmas[3]);
            MoveFantasma(fantasmas[3], mapa);
        }
        else {
            MoveFantasma(fantasmas[3], mapa);
        }
    }
    return;
}

/**
 * Desaloca 1 fantasma
 * \param fantasma
 */
void DesalocaFantasma(tFantasma* fantasma) {
    if (fantasma != NULL) {
        DesalocaPosicao(fantasma->posicaoAtual);
        free(fantasma);
    }
    return;
}

/**
 * Desaloca todos os fantasmas
 * \param fantasmas
 */
void DesalocaFantasmas(tFantasma** fantasmas) {
    for (int i = 0; i < 4; i++) {
        DesalocaFantasma(fantasmas[i]);
    }
    free(fantasmas);
    return;
}
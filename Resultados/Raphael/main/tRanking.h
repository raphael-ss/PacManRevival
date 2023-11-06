#ifndef TRANKING_H_
#define TRANKING_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "tPosicao.h"
#include "tMovimento.h"
#include "tMapa.h"
#include "tPacman.h"
#include "tFantasma.h"
#include "tJogo.h"

typedef struct {
    int numeroFrutasComidas;
    int numeroColisoes;
    int total;

    char movimento;
}tRanking;

/**
 * Cria ranking com malloc
 * \param ranking
 */
tRanking** CriaRanking(tJogo* jogo);

/**
 * Ordena Raking com base nos parametros
 * Sendo #1: n° de comidas pegas com o movimento
 * Sendo #2: n° de colisoes com a parede
 * Sendo #3: n° de movimentos do tipo realizados no total
 * \param ranking
 */
void OrdenaRanking(tRanking** ranking);

/**
 * Cria o arquivo ranking.txt com as informações definidas em ordem de eficiencia:
 * X1,#1,#2,#3
 * X2,#1,#2,#3
 * X3,#1,#2,#3
 * X4,#1,#2,#3
 * Sendo X1,X2,X3,X4 os 4 movimentos (w,a,s,d)
 * Sendo #1: n° de comidas pegas com o movimento
 * Sendo #2: n° de colisoes com a parede
 * Sendo #3: n° de movimentos do tipo realizados no total
 * \param jogo contem todas as informacoes necessarias
 */
void GeraRanking(tRanking** ranking);

/**
 * Desaloca o espaço alocado em CriaRanking
 * \param ranking
 */
void DesalocaRanking(tRanking** ranking);

#endif

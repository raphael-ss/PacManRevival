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
tRanking** CriaRanking(tJogo* jogo) {
    tRanking** ranking = (tRanking**)malloc(4* sizeof(tRanking*));
    for (int i = 0; i < 4; i++) {
        ranking[i] = (tRanking*)malloc(sizeof(tRanking));
    }

    ranking[0]->movimento = 'w';
    ranking[1]->movimento = 'a';
    ranking[2]->movimento = 's';
    ranking[3]->movimento = 'd';

    ranking[0]->total = ObtemNumeroMovimentosCimaPacman(jogo->pacman);
    ranking[1]->total = ObtemNumeroMovimentosEsquerdaPacman(jogo->pacman);
    ranking[2]->total = ObtemNumeroMovimentosBaixoPacman(jogo->pacman);
    ranking[3]->total = ObtemNumeroMovimentosDireitaPacman(jogo->pacman);

    ranking[0]->numeroColisoes = ObtemNumeroColisoesParedeCimaPacman(jogo->pacman);
    ranking[1]->numeroColisoes = ObtemNumeroColisoesParedeEsquerdaPacman(jogo->pacman);
    ranking[2]->numeroColisoes = ObtemNumeroColisoesParedeBaixoPacman(jogo->pacman);
    ranking[3]->numeroColisoes = ObtemNumeroColisoesParedeDireitaPacman(jogo->pacman);

    ranking[0]->numeroFrutasComidas = ObtemNumeroFrutasComidasCimaPacman(jogo->pacman);
    ranking[1]->numeroFrutasComidas = ObtemNumeroFrutasComidasEsquerdaPacman(jogo->pacman);
    ranking[2]->numeroFrutasComidas = ObtemNumeroFrutasComidasBaixoPacman(jogo->pacman);
    ranking[3]->numeroFrutasComidas = ObtemNumeroFrutasComidasDireitaPacman(jogo->pacman);

    return ranking;
}

/**
 * Ordena Raking com base nos parametros
 * Sendo #1: n° de comidas pegas com o movimento
 * Sendo #2: n° de colisoes com a parede
 * Sendo #3: n° de movimentos do tipo realizados no total
 * \param ranking
 */
void OrdenaRanking(tRanking** ranking){
    int i, j;
    tRanking* temp;

    for (i = 1; i < 4; i++) {
        temp = ranking[i];
        j = i - 1;

        // Primeiro critério: Número de comidas pegas (do maior para o menor)
        // Segundo critério: Número de colisões com a parede (do menor para o maior)
        // Terceiro critério: Número de movimentos totais (do maior para o menor)
        while (j >= 0 && (
            (ranking[j]->numeroFrutasComidas < temp->numeroFrutasComidas) ||
            ((ranking[j]->numeroFrutasComidas == temp->numeroFrutasComidas) &&
             (ranking[j]->numeroColisoes > temp->numeroColisoes)) ||
            ((ranking[j]->numeroFrutasComidas == temp->numeroFrutasComidas) &&
             (ranking[j]->numeroColisoes == temp->numeroColisoes) &&
             (ranking[j]->total < temp->total))
        )) {
            ranking[j + 1] = ranking[j];
            j--;
        }

        ranking[j + 1] = temp;
    }
}

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
void GeraRanking(tRanking** ranking){
    OrdenaRanking(ranking);
    FILE * pRanking;
    pRanking = fopen("ranking.txt", "w");
    if (pRanking == NULL) {
        exit(1);
    }

    for (int i = 0; i < 4; i++) {
        fprintf(pRanking, "%c,%d,%d,%d\n", ranking[i]->movimento, ranking[i]->numeroFrutasComidas, ranking[i]->numeroColisoes, ranking[i]->total);
    }

    fclose(pRanking);
    return;
}

/**
 * Desaloca o espaço alocado em CriaRanking
 * \param ranking
 */
void DesalocaRanking(tRanking** ranking){
    for (int i = 0; i < 4; i++) {
        free(ranking[i]);
    }
    free(ranking);
    return;
}


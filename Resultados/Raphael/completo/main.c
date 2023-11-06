#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "tPosicao.h"
#include "tMovimento.h"
#include "tTunel.h"
#include "tMapa.h"
#include "tPacman.h"
#include "tFantasma.h"
#include "tJogo.h"
#include "tRanking.h"

int main(int argc, char** argv){
    if (argc < 2) {
        printf("ERRO: O diretório de arquivos de configuração nao foi informado");
        exit(1);
    }

    char caminho[1000];

    strcpy(caminho, argv[1]);

    tJogo* jogo = CriaJogo(caminho);

    ExecutaJogo(jogo);

    tRanking** ranking = CriaRanking(jogo);
    GeraRanking(ranking);

    DesalocaJogo(jogo);
    DesalocaRanking(ranking);

    return 0;
}


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "tPosicao.h"
#include "tMovimento.h"
#include "tMapa.h"
#include "tPacman.h"
#include "tFantasma.h"

typedef struct {
    /*PACMAN*/
    tPacman* pacman;

    /*MAPA*/
    tMapa* mapa;

    /*VETOR DE FANTASMAS*/
    tFantasma** fantasmas;

}tJogo;

/**
 * Cria o arquivo estatisticas.txt com as informações definidas:
 * ESTADO DO MAPA NO INÍCIO DO JOGO
 * Pac-Man comecara o jogo na linha Y e coluna X
 * \param jogo contem todas as informacoes necessarias
 */
void GeraInicializacao(tJogo* jogo){
    FILE * pInicializacao;
    pInicializacao = fopen("inicializacao.txt", "w");
    if (pInicializacao == NULL) {
        exit(1);
    }

    for (int i = 0; i < ObtemNumeroLinhasMapa(jogo->mapa); i++) {
        for (int j = 0; j < ObtemNumeroColunasMapa(jogo->mapa); j++) {
            tPosicao* pos = CriaPosicao(i, j);
            fprintf(pInicializacao, "%c", ObtemItemMapa(jogo->mapa, pos));
            DesalocaPosicao(pos);
        }
        fprintf(pInicializacao, "\n");
    }
    fprintf(pInicializacao, "Pac-Man comecara o jogo na linha %d e coluna %d", ObtemLinhaPosicao(ObtemPosicaoPacman(jogo->pacman))+1, ObtemColunaPosicao(ObtemPosicaoPacman(jogo->pacman))+1);
    fclose(pInicializacao);
    return;
}

/**
 * Cria o jogo com malloc indireto
 * Chama as funções CriaMapa, CriaPacman e CriaFantasmas
 * \param caminho caminho a ser informado pelo usuário até o diretorio contendo mapa.txt
 */
tJogo* CriaJogo(const char* caminhoConfig){
    tJogo* jogo = (tJogo*)malloc(sizeof(tJogo));

    jogo->mapa = CriaMapa(caminhoConfig);

    tPosicao* pos_pacman = ObtemPosicaoItemMapa(jogo->mapa, '>');

    jogo->pacman = CriaPacman(pos_pacman);

    tPosicao* pos_B = ObtemPosicaoItemMapa(jogo->mapa, 'B');
    tPosicao* pos_P = ObtemPosicaoItemMapa(jogo->mapa, 'P');
    tPosicao* pos_I =  ObtemPosicaoItemMapa(jogo->mapa, 'I');
    tPosicao* pos_C =  ObtemPosicaoItemMapa(jogo->mapa, 'C');

    jogo->fantasmas = CriaFantasmas(pos_B, pos_P, pos_I, pos_C);

    CriaTrilhaPacman(jogo->pacman, ObtemNumeroLinhasMapa(jogo->mapa), ObtemNumeroColunasMapa(jogo->mapa));

    AtualizaTrilhaPacman(jogo->pacman);

    GeraInicializacao(jogo);

    AtualizaItemMapa(jogo->mapa, pos_pacman, ' ');

    if (pos_B != NULL) {
        DesalocaPosicao(pos_B);
    }
    if (pos_C != NULL) {
        DesalocaPosicao(pos_C);
    }
    if (pos_I != NULL) {
        DesalocaPosicao(pos_I);
    }
    if (pos_P != NULL) {
        DesalocaPosicao(pos_P);
    }
    return jogo;
}

/**
 * Exibe estado atual do mapa
 * \param jogo
 */
void ExibeEstadoAtual(tJogo* jogo, COMANDO comando){
    char comando_digitado = '\0';
    if (comando == MOV_BAIXO) {
        comando_digitado = 's';
    }
    else if (comando == MOV_ESQUERDA) {
        comando_digitado = 'a';
    }
    else if (comando == MOV_CIMA) {
        comando_digitado = 'w';
    }
    else if (comando == MOV_DIREITA) {
        comando_digitado = 'd';
    }

    printf("Estado do jogo apos o movimento '%c':\n", comando_digitado);

    tPosicao* pos_B = ObtemPosicaoFantasma(jogo->fantasmas[0]);
    tPosicao* pos_P = ObtemPosicaoFantasma(jogo->fantasmas[1]);
    tPosicao* pos_I = ObtemPosicaoFantasma(jogo->fantasmas[2]);
    tPosicao* pos_C = ObtemPosicaoFantasma(jogo->fantasmas[3]);

    for (int i = 0; i < ObtemNumeroLinhasMapa(jogo->mapa); i++) {
        for (int j = 0; j < ObtemNumeroColunasMapa(jogo->mapa); j++) {
            tPosicao* pos = CriaPosicao(i, j);
            
            if (pos_B != NULL) {
                if ((SaoIguaisPosicao(pos, pos_B))) {
                    printf("B");
                    DesalocaPosicao(pos);
                    continue;
                }
            }
            if (pos_P != NULL) {
                if ((SaoIguaisPosicao(pos, pos_P))) {
                    printf("P");
                    DesalocaPosicao(pos);
                    continue;
                }
            }
            if (pos_I != NULL) {
                if ((SaoIguaisPosicao(pos, pos_I))) {
                    printf("I");
                    DesalocaPosicao(pos);
                    continue;
                }
            }
            if (pos_C != NULL) {
                if ((SaoIguaisPosicao(pos, pos_C))) {
                    printf("C");
                    DesalocaPosicao(pos);
                    continue;
                }
            }

            if (SaoIguaisPosicao(pos, ObtemPosicaoPacman(jogo->pacman))) {
                printf(">");
            }

            else {
                printf("%c", ObtemItemMapa(jogo->mapa, pos));
            }

            DesalocaPosicao(pos);
        }
        printf("\n");
    }

    printf("Pontuacao: %d\n\n", ObtemPontuacaoAtualPacman(jogo->pacman));
    return;
}

/**
 * Exibe estado final com base no acontecimento
 * \param jogo
 */
void ExibeEstadoFinal(tJogo* jogo, COMANDO comando, const char* situacao){
    /*char comando_digitado = '\0';
    if (comando == MOV_BAIXO) {
        comando_digitado = 's';
    }
    else if (comando == MOV_ESQUERDA) {
        comando_digitado = 'a';
    }
    else if (comando == MOV_CIMA) {
        comando_digitado = 'w';
    }
    else if (comando == MOV_DIREITA) {
        comando_digitado = 'd';
    }

    printf("Estado do jogo apos o movimento '%c':\n", comando_digitado);

    tPosicao* pos_B = ObtemPosicaoFantasma(jogo->fantasmas[0]);
    tPosicao* pos_P = ObtemPosicaoFantasma(jogo->fantasmas[1]);
    tPosicao* pos_I = ObtemPosicaoFantasma(jogo->fantasmas[2]);
    tPosicao* pos_C = ObtemPosicaoFantasma(jogo->fantasmas[3]);

    for (int i = 0; i < ObtemNumeroLinhasMapa(jogo->mapa); i++) {
        for (int j = 0; j < ObtemNumeroColunasMapa(jogo->mapa); j++) {
            tPosicao* pos = CriaPosicao(i, j);
            
            if (pos_B != NULL) {
                if ((SaoIguaisPosicao(pos, pos_B))) {
                    printf("B");
                    DesalocaPosicao(pos);
                    continue;
                }
            }
            if (pos_P != NULL) {
                if ((SaoIguaisPosicao(pos, pos_P))) {
                    printf("P");
                    DesalocaPosicao(pos);
                    continue;
                }
            }
            if (pos_I != NULL) {
                if ((SaoIguaisPosicao(pos, pos_I))) {
                    printf("I");
                    DesalocaPosicao(pos);
                    continue;
                }
            }
            if (pos_C != NULL) {
                if ((SaoIguaisPosicao(pos, pos_C))) {
                    printf("C");
                    DesalocaPosicao(pos);
                    continue;
                }
            }

            
            if (SaoIguaisPosicao(pos, ObtemPosicaoPacman(jogo->pacman))) {
                if (situacao == "ganhou") {
                    printf(">");
                }
            }

            else {
                printf("%c", ObtemItemMapa(jogo->mapa, pos));
            }

            DesalocaPosicao(pos);
        }
        printf("\n");
    }*/

    //printf("Pontuacao: %d\n", ObtemPontuacaoAtualPacman(jogo->pacman));
    if (situacao == "ganhou"){
        printf("Voce venceu!\nPontuacao final: %d", ObtemPontuacaoAtualPacman(jogo->pacman));
    }
    else if (situacao == "perdeu") {
        printf("\nGame over!\nPontuacao final: %d", ObtemPontuacaoAtualPacman(jogo->pacman));
    }
    return;
}

/**
 * Retorna true se pacman colidiu, false se não
 * \param jogo checa estado do mapa, pacman e fantasmas
 */
bool ColidiuComFantasma(tJogo* jogo){
    if (jogo->fantasmas[0] != NULL) {
        if (SaoIguaisPosicao(ObtemPosicaoPacman(jogo->pacman), ObtemPosicaoFantasma(jogo->fantasmas[0]))){
            return true;
        }
    }
    if (jogo->fantasmas[1] != NULL) {
        if (SaoIguaisPosicao(ObtemPosicaoPacman(jogo->pacman), ObtemPosicaoFantasma(jogo->fantasmas[1]))){
            return true;
        }
    }
    if (jogo->fantasmas[2] != NULL) {
        if (SaoIguaisPosicao(ObtemPosicaoPacman(jogo->pacman), ObtemPosicaoFantasma(jogo->fantasmas[2]))){
            return true;
        }
    }
    if (jogo->fantasmas[3] != NULL) {
        if (SaoIguaisPosicao(ObtemPosicaoPacman(jogo->pacman), ObtemPosicaoFantasma(jogo->fantasmas[3]))){
            return true;
        }
    }
    
    return false;
}

/**
 * Retorna true se pacman ganhou, false se não
 * \param jogo checa estado do mapa, pacman e fantasmas
 */
bool Ganhou(tJogo* jogo){
    if (ObtemQuantidadeFrutasIniciaisMapa(jogo->mapa) == ObtemPontuacaoAtualPacman(jogo->pacman)) {
        return true;
    }
    return false;
}

/**
 * Retorna true se pacman está sem movimentos, false se não
 * \param jogo checa n de movimentos maximos e movimentos feitos pelo pacman
 */
bool AcabouNumeroMovimentos(tJogo* jogo){
    if ((ObtemNumeroMaximoMovimentosMapa(jogo->mapa) - ObtemNumeroAtualMovimentosPacman(jogo->pacman)) > 0) {
        return false;
    }
    return true;
}

/**
 * Cria o arquivo estatisticas.txt com as informações definidas:
 * Numero de movimentos: X
 * Numero de movimentos sem pontuar: X
 * Numero de colisoes com parede: X
 * Numero de movimentos para baixo: X
 * Numero de movimentos para cima: X
 * Numero de movimentos para esquerda: X
 * Numero de movimentos para direita: X
 * \param jogo contem todas as informacoes necessarias
 */
void GeraEstatisticas(tJogo* jogo) {
    FILE * pEstatisticas;
    pEstatisticas = fopen("estatisticas.txt", "w");
    if (pEstatisticas == NULL) {
        exit(1);
    }

    fprintf(pEstatisticas, "Numero de movimentos: %d\n", ObtemNumeroAtualMovimentosPacman(jogo->pacman));
    fprintf(pEstatisticas, "Numero de movimentos sem pontuar: %d\n", ObtemNumeroMovimentosSemPontuarPacman(jogo->pacman));
    fprintf(pEstatisticas, "Numero de colisoes com parede: %d\n", ObtemNumeroColisoesParedePacman(jogo->pacman));
    fprintf(pEstatisticas, "Numero de movimentos para baixo: %d\n", ObtemNumeroMovimentosBaixoPacman(jogo->pacman));
    fprintf(pEstatisticas, "Numero de movimentos para cima: %d\n", ObtemNumeroMovimentosCimaPacman(jogo->pacman));
    fprintf(pEstatisticas, "Numero de movimentos para esquerda: %d\n", ObtemNumeroMovimentosEsquerdaPacman(jogo->pacman));
    fprintf(pEstatisticas, "Numero de movimentos para direita: %d\n", ObtemNumeroMovimentosDireitaPacman(jogo->pacman));

    fclose(pEstatisticas);
    return;
}


/**
 * Cria uma string explicando o resumo do movimento
 * Movimento x (y) pegou comida
 * \param pacman contem o historico
 * \param mov o movimento em questão
 */
char* CriaMovimentoResumo(tPacman* pacman, tMovimento* mov) {
    char* linha = (char*)malloc(70 * sizeof(char));
    char comando = '\0';
    if (ObtemComandoMovimento(mov) == MOV_BAIXO) {
        comando = 's';
    }
    else if (ObtemComandoMovimento(mov) == MOV_CIMA) {
        comando = 'w';
    }
    else if (ObtemComandoMovimento(mov) == MOV_DIREITA) {
        comando = 'd';
    }
    else if (ObtemComandoMovimento(mov) == MOV_ESQUERDA) {
        comando = 'a';
    }
    sprintf(linha, "Movimento %d (%c) %s\n", ObtemNumeroMovimento(mov), comando,ObtemAcaoMovimento(mov));
    return linha;
}

/**
 * Cria o arquivo resumo.txt com as informações definidas:
 * Movimento x (y) pegou comida
 * Movimento x (y) colidiu na parede
 * Movimento x (y) fim de jogo por enconstar em um fantasma
 * Sendo x: n° do movimento e y:qual o movimento (w, a, s, d)
 * \param jogo contem todas as informacoes necessarias
 */
void GeraResumo(tJogo* jogo){
    FILE * pResumo;
    pResumo = fopen("resumo.txt", "w");
    if (pResumo == NULL) {
        exit(1);
    }

    tMovimento** historico = ClonaHistoricoDeMovimentosSignificativosPacman(jogo->pacman);

    if (historico == NULL) {
        fprintf(pResumo, "F deu ruim\n");
        exit(1);
    }

    for (int i = 0; i < ObtemNumeroMovimentosSignificativosPacman(jogo->pacman); i++) {
        char* resumo = CriaMovimentoResumo(jogo->pacman, historico[i]);
        fprintf(pResumo, "%s", resumo);
        free(resumo);
    }

    if (historico != NULL) {
        for (int i = 0; i < ObtemNumeroMovimentosSignificativosPacman(jogo->pacman); i++) {
            DesalocaMovimento(historico[i]);
        }
        free(historico);
    }

    fclose(pResumo);
    return;
}

/**
 * Faz um loop que executa o jogo inteiramente
 * \param jogo contem todas as informacoes necessarias
 */
void ExecutaJogo(tJogo* jogo){
    COMANDO comando;
    char comando_digitado;
    scanf("%c\n", &comando_digitado);
        if (comando_digitado == 'a') {
            comando = MOV_ESQUERDA;
        }
        if (comando_digitado == 'w') {
            comando = MOV_CIMA;
        }
        if (comando_digitado == 's') {
            comando = MOV_BAIXO;
        }
        if (comando_digitado == 'd') {
            comando = MOV_DIREITA;
        }

    MoveFantasmas(jogo->fantasmas, jogo->mapa);
    MovePacman(jogo->pacman, jogo->mapa, comando);

    ExibeEstadoAtual(jogo, comando);

    while(EstaVivoPacman(jogo->pacman)) {
        if (Ganhou(jogo)){
            ExibeEstadoFinal(jogo, comando, "ganhou");
            break;
        }

        if (ColidiuComFantasma(jogo) || AcabouNumeroMovimentos(jogo)){
            MataPacman(jogo->pacman);
            if ((!Ganhou(jogo)) && (ColidiuComFantasma(jogo))) {
                InsereNovoMovimentoSignificativoPacman(jogo->pacman, comando, "fim de jogo por encostar em um fantasma");
                ExibeEstadoFinal(jogo, comando, "perdeu");
            }
            else if (AcabouNumeroMovimentos(jogo)) {
                ExibeEstadoFinal(jogo, comando, "perdeu");
            }
            break;
        }

        scanf("%c\n", &comando_digitado);

        if (comando_digitado == 'a') {
            comando = MOV_ESQUERDA;
        }
        if (comando_digitado == 'w') {
            comando = MOV_CIMA;
        }
        if (comando_digitado == 's') {
            comando = MOV_BAIXO;
        }
        if (comando_digitado == 'd') {
            comando = MOV_DIREITA;
        }

        MoveFantasmas(jogo->fantasmas, jogo->mapa);
        MovePacman(jogo->pacman, jogo->mapa, comando);

        ExibeEstadoAtual(jogo, comando);
    }

    GeraEstatisticas(jogo);
    GeraResumo(jogo);
    SalvaTrilhaPacman(jogo->pacman);

    return;
}

/**
 * Chama DesalocaMapa, DesalocaPacman e 4xDesalocaFantasma
 * \param jogo contem todas as informacoes necessarias
 */
void DesalocaJogo(tJogo* jogo){
    if (jogo != NULL) {
        DesalocaMapa(jogo->mapa);
        DesalocaPacman(jogo->pacman);
        DesalocaFantasmas(jogo->fantasmas);
        free(jogo);
    }
    return;
}


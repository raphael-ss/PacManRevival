#ifndef TJOGO_H_
#define TJOGO_H_

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
 * Cria o jogo com malloc indireto
 * Chama as funções CriaMapa, CriaPacman e CriaFantasmas
 * \param caminho caminho a ser informado pelo usuário até o diretorio contendo mapa.txt
 */
tJogo* CriaJogo(const char* caminhoConfig);

/**
 * Exibe estado atual do mapa
 * \param jogo
 */
void ExibeEstadoAtual(tJogo* jogo, COMANDO comando);

/**
 * Exibe estado final com base no acontecimento
 * \param jogo
 */
void ExibeEstadoFinal(tJogo* jogo, COMANDO comando, const char* situacao);

/**
 * Retorna true se pacman colidiu, false se não
 * \param jogo checa estado do mapa, pacman e fantasmas
 */
bool ColidiuComFantasma(tJogo* jogo);

/**
 * Retorna true se pacman ganhou, false se não
 * \param jogo checa estado do mapa, pacman e fantasmas
 */
bool Ganhou(tJogo* jogo);

/**
 * Retorna true se pacman está sem movimentos, false se não
 * \param jogo checa n de movimentos maximos e movimentos feitos pelo pacman
 */
bool AcabouNumeroMovimentos(tJogo* jogo);

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
void GeraEstatisticas(tJogo* jogo);

/**
 * Cria o arquivo estatisticas.txt com as informações definidas:
 * ESTADO DO MAPA NO INÍCIO DO JOGO
 * Pac-Man comecara o jogo na linha Y e coluna X
 * \param jogo contem todas as informacoes necessarias
 */
void GeraInicializacao(tJogo* jogo);

/**
 * Cria uma string explicando o resumo do movimento
 * Movimento x (y) pegou comida
 * \param pacman contem o historico
 * \param mov o movimento em questão
 */
char* CriaMovimentoResumo(tPacman* pacman, tMovimento* mov);

/**
 * Cria o arquivo resumo.txt com as informações definidas:
 * Movimento x (y) pegou comida
 * Movimento x (y) colidiu na parede
 * Movimento x (y) fim de jogo por enconstar em um fantasma
 * Sendo x: n° do movimento e y:qual o movimento (w, a, s, d)
 * \param jogo contem todas as informacoes necessarias
 */
void GeraResumo(tJogo* jogo);

/**
 * Faz um loop que executa o jogo inteiramente
 * \param jogo contem todas as informacoes necessarias
 */
void ExecutaJogo(tJogo* jogo);

/**
 * Chama DesalocaMapa, DesalocaPacman e 4xDesalocaFantasma
 * \param jogo contem todas as informacoes necessarias
 */
void DesalocaJogo(tJogo* jogo);

#endif

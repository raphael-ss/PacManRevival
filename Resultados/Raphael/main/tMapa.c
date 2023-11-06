#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "tPosicao.h"
#include "tTunel.h"
#include "tMapa.h"

/*
    Função Auxiliar
    Cria Inicializacao
*/

bool MapaExiste(tMapa* mapa) {
    if (mapa != NULL) {
        return true;
    }
    return false;
}

bool GridExiste(tMapa* mapa) {
    if (mapa->grid != NULL) {
        return true;
    }
    return false;
}

/*void CriaInicializacao(tMapa* mapa, const char* caminhoConfig, tPosicao* pos){
    FILE * pInicializacao;
    char saida[1000];
    sprintf(saida, "%s/saida/inicializacao.txt", caminhoConfig);
    pInicializacao = fopen(saida, "w");
    if (pInicializacao == NULL) {
        exit(1);
    }


    for (int i = 0; i < mapa->nLinhas; i++) {
        for (int j = 0; j < mapa->nColunas; j++) {
            fprintf(pInicializacao, "%c", mapa->grid[i][j]);
        }
        // ESPAÇO
        fprintf(pInicializacao, "\n");
    }

    fprintf(pInicializacao, "Pac-Man comecara o jogo na linha %d e coluna %d", pos->linha+1, pos->coluna+1);
    fclose(pInicializacao);
    DesalocaPosicao(pos);

    return;
}*/

tTunel* ObtemTunelMapa(tMapa* mapa){
    if (mapa->tunel != NULL) {
        return (mapa->tunel);
    }
    return NULL;
}



/**
 * Cria o mapa dinamicamente
 * \param caminho caminho do arquivo com as configurações do mapa
 */

tMapa* CriaMapa(const char* caminhoConfig){
    char caminho_mapa[1000];
    sprintf(caminho_mapa, "%s/mapa.txt", caminhoConfig);

    FILE * pMapa;
    pMapa = fopen(caminho_mapa, "r");
    if (!pMapa) {
        printf("ERRO: nao foi possível ler o arquivo %s ", caminho_mapa);
        return NULL;
    }

    int nMaximoMovimentos = 0;
    fscanf(pMapa, "%d\n", &nMaximoMovimentos);
    int linhas = 0, colunas = 1;
    fscanf(pMapa, "%*c\n");
    char item = '\0';
    while ((fscanf(pMapa, "%c", &item)) == 1) {
        if (item == '\n') {
            linhas++;
        }
        if (linhas == 0) {
            colunas++;
        }
    }

    fseek(pMapa, 0, SEEK_SET);
    fscanf(pMapa, "%*d\n");

    tMapa* mapa = (tMapa*)malloc(sizeof(tMapa));
    mapa->nLinhas = linhas;
    mapa->nColunas = colunas;
    mapa->nFrutasAtual = 0; 
    mapa->nMaximoMovimentos = nMaximoMovimentos;
    mapa->tunel = NULL;

    mapa->grid = (char**)malloc(linhas * sizeof(char*));
    for (int i = 0; i < linhas; i++) {
        mapa->grid[i] = (char*)malloc(colunas * sizeof(char));
    }


    for (int i = 0; i < linhas; i++) {
        for (int j = 0; j < colunas; j++) {
            fscanf(pMapa, "%c", &(mapa->grid[i][j]));

            if (mapa->grid[i][j] == '*') {
                mapa->nFrutasAtual++;
            }
        }
        fscanf(pMapa, "%*c");
    }
    fclose(pMapa);

    //mapa->tunel = ObtemTunelMapa(mapa);

    int n_de_tuneis = 0;
    tTunel* tunel = NULL; 
    tPosicao* acesso1 = NULL;
    tPosicao* acesso2 = NULL;


    for (int i = 0; i < mapa->nLinhas; i++) {
        for (int j = 0; j < mapa->nColunas; j++) {
            if (mapa->grid[i][j] == '@') {
                if (n_de_tuneis == 0) {
                    acesso1 = CriaPosicao(i, j);
                    n_de_tuneis++;
                }
                else if (n_de_tuneis == 1) {
                        acesso2 = CriaPosicao(i, j);
                }
            }
        }
    }
    if (n_de_tuneis == 0){
        mapa->tunel = NULL;
    }
    else {
        mapa->tunel = CriaTunel(ObtemLinhaPosicao(acesso1), ObtemColunaPosicao(acesso1), ObtemLinhaPosicao(acesso2), ObtemColunaPosicao(acesso2));
        DesalocaPosicao(acesso1);
        DesalocaPosicao(acesso2);
    }

    return mapa;
}


/**
 * Obtem a posição de um item do mapa
 * \param mapa mapa
 * \param item item a ser procurado no mapa
 */
tPosicao* ObtemPosicaoItemMapa(tMapa* mapa, char item){
    if (!(MapaExiste(mapa)) || !(GridExiste(mapa))){
        return NULL;
    }
    for (int i = 0; i < mapa->nLinhas; i++) {
        for (int j = 0; j < mapa->nColunas; j++) {
            if (mapa->grid[i][j] == item) {
                tPosicao* pos = CriaPosicao(i, j);
                if (pos == NULL) {
                    return NULL;
                }
                return pos;
            }
        }
    }
    return NULL;
}

/**
 * Retorna o túnel do mapa com os 2 acessos
 * \param mapa mapa
 */


/**
 * Obtem o item do mapa dada a posição
 * \param mapa mapa
 * \param posicao posicao do item a ser retornado
 */
char ObtemItemMapa(tMapa* mapa, tPosicao* posicao){
    if ((MapaExiste(mapa) && GridExiste(mapa))){
        int pos_x = ObtemColunaPosicao(posicao), pos_y = ObtemLinhaPosicao(posicao);
        if ((pos_x < mapa->nColunas) && (pos_y < mapa->nLinhas)) {
            return mapa->grid[pos_y][pos_x];
        }
    }
    return '\0';
}

/**
 * Retorna o número de linhas do mapa
 * \param mapa mapa
 */
int ObtemNumeroLinhasMapa(tMapa* mapa){
    if ((MapaExiste(mapa) && GridExiste(mapa))){
        return (mapa->nLinhas);
    }
    return 0;
}

/**
 * Retorna o número de colunas do mapa
 * \param mapa mapa
 */
int ObtemNumeroColunasMapa(tMapa* mapa){
    if ((MapaExiste(mapa) && GridExiste(mapa))){
        return (mapa->nColunas);
    }
    return 0;
}

/**
 * Retorna a quantidade de frutas iniciais do mapa
 * \param mapa mapa
 */
int ObtemQuantidadeFrutasIniciaisMapa(tMapa* mapa){
    if ((MapaExiste(mapa) && GridExiste(mapa))){
        return (mapa->nFrutasAtual);
    }
    return 0;
}

/**
 * Retorna o número máximo de movimentos permitidos do mapa
 * \param mapa mapa
 */
int ObtemNumeroMaximoMovimentosMapa(tMapa* mapa){
    if ((MapaExiste(mapa) && GridExiste(mapa))){
        return (mapa->nMaximoMovimentos);
    }
    return 0;
}

/**
 * Retorna se a posição passada como parâmetro representa uma comida no mapa
 * \param mapa mapa
 * \param posicao posicao a ser verificada
 */
bool EncontrouComidaMapa(tMapa* mapa, tPosicao* posicao){
    if (ObtemItemMapa(mapa, posicao) == '*') {
        return true;
    }
    return false;
}

/**
 * Retorna se a posição passada como parâmetro representa uma parede no mapa
 * \param mapa mapa
 * \param posicao posicao a ser verificada
 */
bool EncontrouParedeMapa(tMapa* mapa, tPosicao* posicao){
    if (!(MapaExiste(mapa) && GridExiste(mapa))){
        return false;
    }
    if (ObtemItemMapa(mapa, posicao) == '#') {
        return true;
    }
    return false;
}

/**
 * Atualiza um item do mapa
 * \param mapa mapa
 * \param posicao posicao do item
 * \param item posicao item que vai atualizar o mapa
 */
bool AtualizaItemMapa(tMapa* mapa, tPosicao* posicao, char item){
    if (!(MapaExiste(mapa) && GridExiste(mapa))){
        return false;
    }
    int pos_x = ObtemColunaPosicao(posicao), pos_y = ObtemLinhaPosicao(posicao);
    if ((pos_x < mapa->nColunas) && (pos_y < mapa->nLinhas)) {
        mapa->grid[pos_y][pos_x] = item;
        return true;
    }
    return false;
}

/**
 * Verifica se o mapa possui tunel ou não.
 * Caso o campo tunel seja NULL retorna falso.
 * Caso contrário retorna verdadeiro.
 * \param mapa mapa
 */
bool PossuiTunelMapa(tMapa* mapa){
    if (mapa->tunel == NULL) {
        return false;
    }
    return true;
}


/**
 * Retorna se o tunel foi acessado ou não
 * \param mapa mapa
 * \param posicao posicao a ser verificada
 */
bool AcessouTunelMapa(tMapa* mapa, tPosicao* posicao){
    if (EntrouTunel(mapa->tunel, posicao)){
        return true;
    }
    return false;
}

/**
 * Apenas chama a função LevaFinalTunel na estrutura tTunel.h
 * \param mapa mapa
 * \param posicao posicao que vai entrar no túnel
 */
void EntraTunelMapa(tMapa* mapa, tPosicao* posicao){
    if (mapa->tunel != NULL){
        if (EntrouTunel(mapa->tunel, posicao)) {
            LevaFinalTunel(mapa->tunel, posicao);
        }
        
    }
    return;
}

/**
 * Libera o espaço alocado para a estrutura tMapa
 * \param mapa mapa
 */
void DesalocaMapa(tMapa* mapa){
    if (!MapaExiste(mapa)) {
        return;
    }

    if (GridExiste(mapa)) {
        for (int i = 0; i < mapa->nLinhas; i++) {
            free(mapa->grid[i]);
            mapa->grid[i] = NULL;
        }
        free(mapa->grid);
        mapa->grid = NULL;
    }

    if (mapa->tunel != NULL){
        DesalocaTunel(mapa->tunel);
        mapa->tunel = NULL;
    }

    free(mapa);
    return;
}
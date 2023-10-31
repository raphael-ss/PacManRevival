#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "tPosicao.h"
#include "tTunel.h"

typedef struct tMapa{
    /* Número de linhas e de colunas do mapa */
    int nLinhas, nColunas;
    /* Número atual de frutas no mapa */
    int nFrutasAtual;
    /* Número máximo permitido de movimentos do pacman no mapa */
    int nMaximoMovimentos;
    /* O grid (matriz) de informações do mapa */
    char** grid;
    /* O tunel do mapa contendo 2 acessos */
    tTunel* tunel;
} tMapa;


/*
    Função Auxiliar
    Cria Inicializacao
*/

void CriaInicializacao(tMapa* mapa, const char* caminhoConfig, tPosicao* pos){
    FILE * pInicializacao;
    char saida[1000];
    sprintf(saida, "%s/saida1/inicializacao.txt", caminhoConfig);
    pInicializacao = fopen(saida, "w");
    if (pInicializacao == NULL) {
        printf("Erro\n");
        exit(1);
    }


    for (int i = 0; i < mapa->nLinhas; i++) {
        for (int j = 0; j < mapa->nColunas; j++) {
            fprintf(pInicializacao, "%c", mapa->grid[i][j]);
        }
        // ESPAÇO
        fprintf(pInicializacao, "\n");
    }

    fprintf(pInicializacao, "Pac-Man comecara o jogo na linha %d e coluna %d", pos->linha, pos->coluna);
    fclose(pInicializacao);
}


/**
 * Cria o mapa dinamicamente
 * \param caminho caminho do arquivo com as configurações do mapa
 */
tMapa* CriaMapa(const char* caminhoConfig){
    char caminho_mapa[1000];

    tMapa* mapa = (tMapa*)malloc(sizeof(tMapa));
    if (mapa == NULL) {
        printf("Erro");
        exit(1);
    }

    sprintf(caminho_mapa, "%s/mapa.txt", caminhoConfig);
    FILE * pMapa;
    pMapa = fopen(caminho_mapa, "r");
    if (!pMapa) {
        printf("ERRO: nao foi possível ler o arquivo %s ", caminho_mapa);
        exit(1);
    }
    fscanf(pMapa, "%d\n", mapa->nMaximoMovimentos);
    int linhas = 0, colunas = 0, tam_primeira_linha = 0;
    char item = '\0';
    while ((fscanf(pMapa, "%c", &item)) != EOF) {
        // PEGA TAMANHO DA 1° LINHA PARA POSICIONAR O CURSOR EM FSEEK
        while (linhas == 0) {
            tam_primeira_linha++;
        }
        if (item == '\n') {
            linhas++;
        }
        colunas++;
    }
    colunas /= linhas;

    mapa->grid = (char**)malloc(linhas * sizeof(char*));
    for (int i = 0; i < linhas; i++) {
        mapa->grid[i] = (char*)malloc(colunas * sizeof(char));
    }
    mapa->nLinhas = linhas;
    mapa->nColunas = colunas;

    fseek(pMapa, tam_primeira_linha+1, SEEK_SET);

    // LÊ MAPA DEFINITIVAMENTE
    tPosicao* pos_inicial = CriaPosicao(0, 0);
    for (int i = 0; i < linhas; i++) {
        for (int j = 0; j < colunas; j++) {
            fscanf(pMapa, "%c", mapa->grid[i][j]);
            if (mapa->grid[i][j] == '>') {
                AtualizaPosicao(pos_inicial, CriaPosicao(i, j));
            }
        }
        // ESPAÇO
        fscanf(pMapa, "%*c");
    }

    CriaInicializacao(mapa, caminhoConfig, pos_inicial);
    return mapa;
}

/**
 * Obtem a posição de um item do mapa
 * \param mapa mapa
 * \param item item a ser procurado no mapa
 */
tPosicao* ObtemPosicaoItemMapa(tMapa* mapa, char item){
    if (!(MapaExiste(mapa) && GridExiste(mapa))){
        return false;
    }
    for (int i = 0; i < mapa->nLinhas; i++) {
        for (int j = 0; j < mapa->nColunas; j++) {
            if (mapa->grid[i][j] == item) {
                return CriaPosicao(i, j);
            }
        }
    }
}

/**
 * Retorna o túnel do mapa com os 2 acessos
 * \param mapa mapa
 */
tTunel* ObtemTunelMapa(tMapa* mapa){
    int n_de_tuneis = 0;
    tTunel* tunel;
    if ((MapaExiste(mapa) && GridExiste(mapa))){
        for (int i = 0; i < mapa->nLinhas; i++) {
            for (int j = 0; j < mapa->nColunas; j++) {
                if (mapa->grid[i][j] == '@') {
                    if (n_de_tuneis == 0) {
                        tPosicao* acesso = CriaPosicao(i,j);
                        tunel->acesso1 = acesso;
                        n_de_tuneis++;
                    }
                    else if (n_de_tuneis == 1) {
                        tPosicao* acesso = CriaPosicao(i,j);
                        tunel->acesso2 = acesso;
                        return tunel;
                    }
                }
            }
        }
    }
}

/**
 * Obtem o item do mapa dada a posição
 * \param mapa mapa
 * \param posicao posicao do item a ser retornado
 */
char ObtemItemMapa(tMapa* mapa, tPosicao* posicao){
    if ((MapaExiste(mapa) && GridExiste(mapa))){
        int pos_x = ObtemColunaPosicao(posicao), pos_y = ObtemLinhaPosicao(posicao);
        if ((pos_x <= mapa->nColunas) && (pos_y <= mapa->nLinhas)) {
            return mapa->grid[pos_y][pos_x];
        }
        return '\0';
    }
}

/**
 * Retorna o número de linhas do mapa
 * \param mapa mapa
 */
int ObtemNumeroLinhasMapa(tMapa* mapa){
    if (!(MapaExiste(mapa) && GridExiste(mapa))){
        return (mapa->nLinhas);
    }
    
}

/**
 * Retorna o número de colunas do mapa
 * \param mapa mapa
 */
int ObtemNumeroColunasMapa(tMapa* mapa){
    if (!(MapaExiste(mapa) && GridExiste(mapa))){
        return (mapa->nColunas);
    }
}

/**
 * Retorna a quantidade de frutas iniciais do mapa
 * \param mapa mapa
 */
int ObtemQuantidadeFrutasIniciaisMapa(tMapa* mapa){
    if (!(MapaExiste(mapa) && GridExiste(mapa))){
        return (mapa->nFrutasAtual);
    }
}

/**
 * Retorna o número máximo de movimentos permitidos do mapa
 * \param mapa mapa
 */
int ObtemNumeroMaximoMovimentosMapa(tMapa* mapa){
    if (!(MapaExiste(mapa) && GridExiste(mapa))){
        return (mapa->nFrutasAtual);
    }
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
void AtualizaItemMapa(tMapa* mapa, tPosicao* posicao, char item){
    if (!(MapaExiste(mapa) && GridExiste(mapa))){
        return;
    }
    int pos_x = ObtemColunaPosicao(posicao), pos_y = ObtemLinhaPosicao(posicao);
    if ((pos_x <= mapa->nColunas) && (pos_y <= mapa->nLinhas)) {
        mapa->grid[pos_y][pos_x] = item;
    }
    return;
}

/**
 * Verifica se o mapa possui tunel ou não
 * \param mapa mapa
 */
bool PossuiTunelMapa(tMapa* mapa){
    if (!(MapaExiste(mapa) && GridExiste(mapa))){
        return false;
    }
    for (int i = 0; i < mapa->nLinhas; i++) {
        for (int j = 0; j < mapa->nColunas; j++) {
            if (mapa->grid[i][j] == "@") {
                return true;
            }
        }
    }
    return false;
}

/**
 * Retorna se o tunel foi acessado ou não
 * \param mapa mapa
 * \param posicao posicao a ser verificada
 */
bool AcessouTunelMapa(tMapa* mapa, tPosicao* posicao){
    if (ObtemItemMapa(mapa, posicao) == "@"){
        return true;
    }
    return false;
}

/**
 * Entra no túnel do mapa.
 * \param mapa mapa
 * \param posicao posicao que vai entrar no túnel
 */
void EntraTunelMapa(tMapa* mapa, tPosicao* posicao){
    tTunel* tunel = ObtemTunelMapa(mapa);
    if (AcessouTunelMapa(mapa, tunel->acesso1)) {
        AtualizaPosicao(posicao, tunel->acesso2);
    }
    else if (AcessouTunelMapa(mapa, tunel->acesso2)) {
        AtualizaPosicao(posicao, tunel->acesso1);
    }
    return;
}

/**
 * Libera o espaço alocado para a estrutura tMapa
 * \param mapa mapa
 */
void DesalocaMapa(tMapa* mapa){
    if (MapaExiste(mapa)) {
        DesalocaTunel(mapa->tunel);
        free(mapa);
    }
    return;
}

bool MapaExiste(tMapa* mapa) {
    return (mapa != NULL);
}

bool GridExiste(tMapa* mapa) {
    return (mapa->grid != NULL);
}
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {MOV_ESQUERDA = 0, 
              MOV_CIMA = 1, 
              MOV_BAIXO = 2, 
              MOV_DIREITA = 3} COMANDO;

typedef struct tMovimento {
    int numeroDoMovimento;
    COMANDO comando;
    char acao[50];
} tMovimento;

/**
 * Cria o movimento dinamicamente
 * \param numeroDoMovimento número do movimento
 * \param comando comando que foi dado para o movimento
 * \param acao a ação gerada pelo movimento
 */
tMovimento* CriaMovimento(int numeroDoMovimento, COMANDO comando, const char* acao){
    tMovimento* mov = (tMovimento*) malloc(sizeof(tMovimento));
    mov->numeroDoMovimento = numeroDoMovimento;
    mov->comando = comando;
    strcpy(mov->acao, acao);
    return mov;
}

/**
 * Retorna o número do movimento
 * \param movimento movimento
 */
int ObtemNumeroMovimento(tMovimento* movimento){
    return (movimento->numeroDoMovimento);
}

/**
 * Retorna o comando do movimento
 * \param movimento movimento
 */
COMANDO ObtemComandoMovimento(tMovimento* movimento){
    return (movimento->comando);
}

/**
 * Retorna a ação do movimento
 * \param movimento movimento
 */
char* ObtemAcaoMovimento(tMovimento* movimento){
    return (movimento->acao);
}

/**
 * Libera o espaço alocado para a estrutura tMovimento
 * 
 * \param movimento movimento
 */
void DesalocaMovimento(tMovimento* movimento){
    if (movimento != NULL) {
        free(movimento);
    }
    return;
}

#!/bin/bash

# DIR_TEST=test
DIR_RESPOSTAS=Respostas
DIR_RESULTADOS=Resultados
# GAB_OBJ_FILES=`ls Gabarito-obj/*.o`
DIR_GAB_SRC="Gabarito-src"
DIR_GAB_OBJ="Gabarito-obj"
DIR_GAB_INCLUDES="Includes"
DIR_GAB_CASOS=Casos
DIR_INCLUDES=Includes

IGNORE_RESULTS=false
IGNORE_VALGRIND=false
RUN_PROFESSOR_SCRIPT=false # precisa rodar primeiro para gerar os arquivos objetos e o resultado txt do gabarito
RUN_STUDENT_SCRIPT=true # tem que rodar depois que o RUN_PROFESSOR_SCRIPT foi rodado primeiro
FIXED_INTERFACE=false # tem que rodar depois que o RUN_PROFESSOR_SCRIPT foi rodado primeiro

TERMINAL_OUTPUT_LOG=""

# Using getopt to handle long options
TEMP=$(getopt -o '' --long resultados,valgrind,professor,interfacefixa -- "$@")

# Terminate the script in case of wrong arguments
if [ $? != 0 ]; then
    echo 'Terminating...' >&2
    exit 1
fi

if test -f "log.txt"; then
    rm -r "log.txt"
fi

# Setting the positional parameters to the processed values
eval set -- "$TEMP"

# Initialize variables

# Process options
while true; do
    case "$1" in
        --resultados)
            IGNORE_RESULTS=true
            shift
            ;;
        --valgrind)
            IGNORE_VALGRIND=true
            shift
            ;;
        --professor)
            RUN_PROFESSOR_SCRIPT=true
            shift
            ;;
        --interfacefixa)
            FIXED_INTERFACE=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Sample output
if [[ "$RUN_PROFESSOR_SCRIPT" == true ]] ; then
    RUN_STUDENT_SCRIPT=false
fi
if $IGNORE_RESULTS; then TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}Ignorando os Resultados\n"; fi
if $IGNORE_VALGRIND; then TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}Ignorando o Valgrind\n"; fi
if $RUN_PROFESSOR_SCRIPT; then TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}Rodando apenas o script do Professor"; fi
if $RUN_STUDENT_SCRIPT; then TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}Rodando o script do Aluno"; fi
if $FIXED_INTERFACE; then TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}Considerando interface fixa do professor"; fi

echo -e $TERMINAL_OUTPUT_LOG

HEADER_FILES_EXIST=false
# Use the find command to search for .h files within the folder
if test -d "$DIR_GAB_SRC"; then
    if find "$DIR_GAB_SRC" -maxdepth 1 -type f -name "*.h" | read; then
        HEADER_FILES_EXIST=true
    fi
fi

script_com_pesos()
{
    if [ ! -f "pontuacao.txt" ]; then
        script_sem_pesos
        exit
    fi

    declare -A pesos
    arquivosHeaderDisponibilizados=()

    # Read the pontuacao.txt file line by line
    while IFS="=" read -r key value || [[ -n "$key" ]]; do
        if [ "$key" != "" ]; then
            if [[ "$key" == *".h" ]]; then
                arquivosHeaderDisponibilizados+=("$key")
            fi
            pesos["$key"]="$value"
        fi
    done < pontuacao.txt

    # Optionally, print the contents of the associative array to verify
    # for key in "${!pesos[@]}"; do
    #     echo "$key = ${pesos[$key]}"
    # done

    # for file in "${arquivosHeaderDisponibilizados[@]}"; do
    #     echo "FILE: $file" 
    # done

    contains() {
        local file_to_check=$1
        for file in "${arquivosHeaderDisponibilizados[@]}"; do
            if [[ $file == "$file_to_check" ]]; then
                return 0
            fi
        done
        return 1
    }

    if [[ "$RUN_PROFESSOR_SCRIPT" == true ]] ; then
        if test -d "$DIR_GAB_OBJ"; then
            rm -r $DIR_GAB_OBJ
        fi
        mkdir -p $DIR_GAB_OBJ
        echo " - Pasta $DIR_GAB_OBJ criada com sucesso!"
        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $DIR_GAB_OBJ criada com sucesso!\n"
        if test -d "$DIR_INCLUDES"; then
            rm -r $DIR_INCLUDES
        fi
        mkdir -p $DIR_INCLUDES
        echo " - Pasta $DIR_INCLUDES criada com sucesso!"
        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $DIR_INCLUDES criada com sucesso!\n"
        gab_src_files_names=()
        # Check if the folder exists and is a directory
        if [ -d "$DIR_INCLUDES" ] && [ -d "$DIR_GAB_SRC" ]; then

            if [ "$HEADER_FILES_EXIST" = "true" ]; then
                for fileH in "${arquivosHeaderDisponibilizados[@]}"; do
                    if [[ "$fileH" != "main" ]]; then
                        if [[ -f "$DIR_GAB_SRC/$fileH" ]]; then
                            cp $DIR_GAB_SRC/$fileH $DIR_INCLUDES
                        fi
                    fi
                done

                echo " - Arquivos .h do professor da pasta $DIR_GAB_SRC copiados para a pasta $DIR_INCLUDES com sucesso!"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos .h do professor da pasta $DIR_GAB_SRC copiados para a pasta $DIR_INCLUDES com sucesso!\n"
            else
                echo " - Não existem arquivos header na pasta $DIR_GAB_SRC do professor."
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Não existem arquivos header na pasta $DIR_GAB_SRC do professor.\n"
            fi
            
            src_files_array=()
            # Read the files with the specific extension into the array
            while IFS= read -r -d '' file; do
                src_files_array+=("$file")
            done < <(find "$DIR_GAB_SRC" -type f -name "*.c" -print0)
            # Print the elements of the array for verification
            for src_file in "${src_files_array[@]}"; do
                x=${src_file%.c}  # x sera' o nome do arquivo sem a extensao .c
                raw_file_name=${x##*/}  # raw_file_name sera' o nome do arquivo puro, sem os diretorios que contem ele
                echo "raw_file_name: $raw_file_name"
                if contains "$raw_file_name.h" || [[ "$raw_file_name" == "main" ]] ; then
                    gab_src_files_names+=("$raw_file_name")
                    src=$DIR_GAB_SRC/$raw_file_name.c
                    out=$DIR_GAB_OBJ/$raw_file_name.o
                    output=$(gcc -Wall -c $src -o $out 2>&1)
                    if [ $? -ne 0 ]; then 
                        echo "   - Erro de compilação! Verifique se o arquivo $src está correto."
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Erro de compilação! Verifique se o arquivo $src está correto.\n"
                        echo $TERMINAL_OUTPUT_LOG >> "log.txt"
                        exit 1
                    fi
                fi
            done
            
            output=$(gcc -Wall -o $DIR_GAB_OBJ/prog $DIR_GAB_OBJ/*.o -lm 2>&1)
            echo "$output"
            if [ $? -ne 0 ]; then 
                echo -e "   - Arquivos Linkados: Erro! Binário prog não gerado."
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Arquivos Linkados: Erro! Binário prog não gerado.\n"
                echo $TERMINAL_OUTPUT_LOG >> "log.txt"
                exit 1
            else 
                echo " - Arquivos objetos do gabarito gerados com sucesso na pasta $DIR_GAB_OBJ!"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos objetos do gabarito gerados com sucesso na pasta $DIR_GAB_OBJ!\n"
            fi       
        else
            echo " - Pasta não encontrada: $DIR_INCLUDES ou $DIR_GAB_SRC, abortado!"
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta não encontrada: $DIR_INCLUDES ou $DIR_GAB_SRC, abortado!\n"
            echo $TERMINAL_OUTPUT_LOG >> "log.txt"
            exit 1
        fi

        for DIR_CASE in "$DIR_GAB_CASOS"/*; do
            txt_input_file=$(find "$DIR_CASE" -maxdepth 1 -type f -name "*.txt" | head -n 1)
            directory_path=$(dirname "$txt_input_file")
            filename=$(basename -- "$txt_input_file")   # Get only the file name without the full path
            filename_no_ext="${filename%.*}"  # Get only the file name without the extension

            dir_saida=${DIR_CASE}/saida
            if [ ! -d "$dir_saida" ]; then
                mkdir -p $dir_saida
            fi

            txt_output_file=$(find "$DIR_CASE/saida" -maxdepth 1 -type f -name "*.txt" | head -n 1)
            if test -f "$txt_output_file"; then
                rm $DIR_CASE/saida/*.txt
            fi

            input_file=$directory_path/entrada.txt
            # output="${DIR_CASE}/saida/out_${filename_no_ext}.txt"
            output="${DIR_CASE}/saida/saida.txt"

            # $DIR_GAB_OBJ/prog < $txt_input_file > $output 2>&1
            $DIR_GAB_OBJ/prog $directory_path < $input_file 2>&1
            # mv *.txt $DIR_CASE/saida/

            for txtfile in *.txt; do
                if [[ "$txtfile" != "pontuacao.txt" ]]; then
                    mv "$txtfile" "$DIR_CASE/saida/"
                fi
            done

            echo " - Output do resultado do professor gerado com sucesso na pasta $output."
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Output do resultado do professor gerado com sucesso na pasta $output.\n"
        done

        echo -e " - Todos os arquivos necessários do professor gerados. Remova a pasta $DIR_GAB_SRC e envie o script para o Aluno!\n"
        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Todos os arquivos necessários do professor gerados. Remova a pasta $DIR_GAB_SRC e envie o script para o Aluno!\n"
    fi

    n_total_cases=0

    if [[ "$RUN_STUDENT_SCRIPT" == true ]] ; then

        if test -d "$DIR_INCLUDES"; then
            if find "$DIR_INCLUDES" -maxdepth 1 -type f -name "*.h" | read; then
                HEADER_FILES_EXIST=true
            fi
        fi

        if [ "$HEADER_FILES_EXIST" = "true" ]; then
            if [ -d "$DIR_INCLUDES" ]; then
                if [ $(find "$DIR_INCLUDES" -maxdepth 1 -type f -name "*.h" | wc -l) -gt 0 ]; then
                    echo " - Arquivos header necessários do professor existem na pasta $DIR_INCLUDES"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos header necessários do professor existem na pasta $DIR_INCLUDES\n"
                else
                    echo " - Arquivos header necessários do professor não existem na pasta $DIR_INCLUDES, por favor rode o script do professor primeiro. Abortado!"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos header necessários do professor não existem na pasta $DIR_INCLUDES, por favor rode o script do professor primeiro. Abortado!\n"
                    echo $TERMINAL_OUTPUT_LOG >> "log.txt"
                    exit 1
                fi
            else
                echo " - A pasta $DIR_INCLUDES com os arquivos header do professor não existe, por favor rode o script do professor primeiro. Abortado!"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - A pasta $DIR_INCLUDES com os arquivos header do professor não existe, por favor rode o script do professor primeiro. Abortado!\n"
                echo $TERMINAL_OUTPUT_LOG >> "log.txt"
                exit 1
            fi
        fi

        if [ -d "$DIR_GAB_OBJ" ]; then
            if [ $(find "$DIR_GAB_OBJ" -maxdepth 1 -type f -name "*.o" | wc -l) -gt 0 ]; then
                echo " - Arquivos objetos necessários do professor existem na pasta $DIR_GAB_OBJ."
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos objetos necessários do professor existem na pasta $DIR_GAB_OBJ."
            else
                echo " - Arquivos objetos necessários do professor não existem na pasta $DIR_GAB_OBJ, por favor rode o script do professor primeiro. Abortado!"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos objetos necessários do professor não existem na pasta $DIR_GAB_OBJ, por favor rode o script do professor primeiro. Abortado!\n"
                echo $TERMINAL_OUTPUT_LOG >> "log.txt"
                exit 1
            fi
        else
            echo " - A pasta $DIR_GAB_OBJ com os arquivos objetos do professor não existe, por favor rode o script do professor primeiro. Abortado!"
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - A pasta $DIR_GAB_OBJ com os arquivos objetos do professor não existe, por favor rode o script do professor primeiro. Abortado!\n"
            echo $TERMINAL_OUTPUT_LOG >> "log.txt"
            exit 1
        fi

        n_cases=0
        for DIR_CASE in "$DIR_GAB_CASOS"/*; do
            (( n_cases++ ))
        done

        # Create empty arrays
        declare -a src_files_names
        declare -a fullpaths

        n_files=0
        n_folders_to_compile=0
        n_compilations=0
        for filepath in "$DIR_GAB_OBJ/"*.o; do
            # Check if file exists to avoid the loop processing the "*.txt" string when there are no matches
            if [[ -f "$filepath" ]]; then
                # Extract just the file name without the path and extension
                filename=$(basename "$filepath" .o)
                src_files_names+=("$filename")
                fullpaths+=("$filepath")
                (( n_files++ ))
                (( n_folders_to_compile++ ))
                (( n_compilations++ ))
            fi
        done
        
        # n_compilations=$((n_compilations * n_files))
        # n_compilations=$((n_compilations + n_files)) # considerando a pasta completo
        n_compilations=$((n_compilations + 1)) # considerando a pasta completo
        n_folders_to_compile=$((n_folders_to_compile + 1)) # considerando a pasta completo
        n_linkings=$((n_files + 1))

        for headerpath in "$DIR_INCLUDES/"*.h; do
            if [[ -f "$headerpath" ]]; then
                # Extract just the file name without the path and extension
                (( n_files++ ))
            fi
        done

        if [[ ${#src_files_names[@]} -eq 0 ]]; then
            echo " - A Pasta $DIR_GAB_OBJ com os arquivos objetos do Gabarito está vazia, por favor rode primeiro o script do Professor!"
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - A Pasta $DIR_GAB_OBJ com os arquivos objetos do Gabarito está vazia, por favor rode primeiro o script do Professor!\n"
            echo $TERMINAL_OUTPUT_LOG >> "log.txt"
            exit 1
        fi
        src_files_names+=("completo")
        
        src_files_names=()

        for file in "${arquivosHeaderDisponibilizados[@]}"; do
            filename_no_ext="${file%.*}"  # Get only the file name without the extension
            src_files_names+=("$filename_no_ext")
        done
        src_files_names+=("completo")
        src_files_names+=("main")

        # for file in "${src_files_names[@]}"; do
        #     echo "ARQUIVO: $file"    
        # done
        

        declare -A all_students_results
        declare -A all_students_pontuacoes
        iteration=0
        
        # Check if the folder exists and is a directory
        if [ -d "$DIR_RESPOSTAS" ]; then

            if [ -z "$(ls -A $DIR_RESPOSTAS)" ]; then
                echo " - Erro! Por favor, crie uma pasta com o seu nome dentro da pasta Respostas/, por exemplo Respostas/JoaoAugusto/ e dentro dessa pasta do seu nome coloque os seus arquivos do código fonte."
                exit 1
            fi

            if [ ! -d "$DIR_RESULTADOS" ]; then
                mkdir -p $DIR_RESULTADOS
            fi

            # Loop through all folders in the specified folder using 'find'
            while IFS= read -r -d '' STUDENT_ANSWER_FOLDER; do
                if [ -d "$STUDENT_ANSWER_FOLDER" ]; then
                    (( iteration++ ))

                    # Get the student name
                    delimiter="/" # Set the delimiter
                    original_IFS="$IFS" # Save the old IFS
                    IFS="$delimiter" # Set the IFS to the delimiter to split the string
                    read -r _ student_name <<< "$STUDENT_ANSWER_FOLDER" # Read the second part of the string into a variable
                    IFS="$original_IFS" 

                    echo -e "\n#######################################"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\n#######################################\n"
                    echo "ALUNO: $student_name"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}ALUNO: $student_name\n"
                    echo -e "#######################################\n"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}#######################################\n"

                    declare -a files_to_compile
                    for element in "${src_files_names[@]}"; do
                        files_to_compile+=("$element")
                    done

                    declare -A test_cases_results

                    test_cases_results["student_name"]=$student_name
                    test_cases_results["arquivos_corretos"]=0
                    test_cases_results["nota_arquivos_corretos"]=0
                    test_cases_results["compilacoes_corretas"]=0
                    test_cases_results["nota_compilacoes_corretas"]=0
                    test_cases_results["linkagens_corretas"]=0
                    test_cases_results["nota_linkagens_corretas"]=0
                    
                    declare -A test_cases_pontuacoes
                    test_cases_pontuacoes["student_name"]=$student_name

                    for key in "${!pesos[@]}"; do

                        if [[ "$key" == *".txt" ]]; then
                            test_cases_pontuacoes["$key"]=0
                        fi
                    done

                    # for key in "${!test_cases_pontuacoes[@]}"; do
                    #     echo "$key = ${test_cases_pontuacoes[$key]}"
                    # done

                    # incrementValueDictPontuacao() {
                    #     local key=$1
                    #     local incrementAmount=$2
                    #     # Check if the key exists; if not, initialize it to 0
                    #     [[ ! -v test_cases_pontuacoes["$key"] ]] && test_cases_pontuacoes["$key"]=0

                    #     # Increment the value for the key
                    #     test_cases_pontuacoes["$key"]=$((test_cases_pontuacoes["$key"] + incrementAmount))
                    # }

                    for src_file_name in "${src_files_names[@]}"; do
                        acertos_field=acertos_$src_file_name
                        nota_acertos_field=nota_acertos_$src_file_name
                        acertosval_field=acertosval_$src_file_name
                        nota_acertosval_field=nota_acertosval_$src_file_name
                        test_cases_results[$acertos_field]=0
                        test_cases_results[$acertosval_field]=0
                        test_cases_results[$nota_acertos_field]=0
                        test_cases_results[$nota_acertosval_field]=0
                    done

                    ##########################################
                    # criando os diretorios de resultados para cada aluno
                    ##########################################
                    echo "CRIANDO O DIRETÓRIO DE RESULTADO PARA $student_name:"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}CRIANDO O DIRETÓRIO DE RESULTADO PARA $student_name:\n"
                    # create a directory in the Resultados folder with the student name and copy the content to there
                    STUDENT_RESULT_FOLDER=${DIR_RESULTADOS}/$student_name
                    if test -d "$STUDENT_RESULT_FOLDER"; then
                        rm -r $STUDENT_RESULT_FOLDER
                        sleep 1
                    fi
                    mkdir -p $STUDENT_RESULT_FOLDER
                    if test -d "$STUDENT_RESULT_FOLDER"; then
                        echo " - Diretório $STUDENT_RESULT_FOLDER criado com sucesso!"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Diretório $STUDENT_RESULT_FOLDER criado com sucesso!\n"
                    fi
                    for src_file_name in "${src_files_names[@]}"; do
                        FILE_NAME_FOLDER=$STUDENT_RESULT_FOLDER/$src_file_name
                        mkdir -p $FILE_NAME_FOLDER
                        if test -d "$FILE_NAME_FOLDER"; then
                            echo " - Diretório $FILE_NAME_FOLDER criado com sucesso!"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Diretório $FILE_NAME_FOLDER criado com sucesso!\n"
                        fi
                        # mkdir -p $FILE_NAME_FOLDER/test
                        # if test -d "$FILE_NAME_FOLDER/test"; then
                        #     echo " - Diretório $FILE_NAME_FOLDER/test criado com sucesso!"
                        #     TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Diretório $FILE_NAME_FOLDER/test criado com sucesso!\n"
                        # fi
                    done
                    echo -e " - Arquivos criados: ok!"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos criados: ok!\n"

                    ##########################################
                    # verifica se os arquivos esperados existem
                    ##########################################
                    echo -e "\nCHECKANDO OS ARQUIVOS DO ALUNO:"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nCHECKANDO OS ARQUIVOS DO ALUNO:\n"
                    student_files_missing=0
                    student_files_found=0
                    for src_file_name in "${src_files_names[@]}"; do
                        student_src=$STUDENT_ANSWER_FOLDER/$src_file_name.c
                        student_hdr=$STUDENT_ANSWER_FOLDER/$src_file_name.h
                        
                        if [ ! -f "$student_src" ] && [[ "$src_file_name" != "completo" ]] ; then 
                            echo " - Arquivo esperado '$student_src' não encontrado!"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivo esperado '$student_src' não encontrado!\n"
                            student_files_missing=$(expr $student_files_missing + 1)
                        elif [[ "$src_file_name" != "completo" ]]; then
                            echo " - Arquivo esperado '$student_src' encontrado!"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivo esperado '$student_src' encontrado!\n"
                            student_files_found=$(expr $student_files_found + 1)
                        fi

                        if [ "$HEADER_FILES_EXIST" = "true" ]; then
                            if [ ! -f "$student_hdr" ] && [[ "$src_file_name" != "completo" ]] && [[ "$src_file_name" != "main" ]]; then 
                                echo " - Arquivo esperado '$student_hdr' não encontrado!"
                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivo esperado '$student_hdr' não encontrado!\n"
                                student_files_missing=$(expr $student_files_missing + 1)
                            elif [[ "$src_file_name" != "completo" ]] && [[ "$src_file_name" != "main" ]]; then
                                echo " - Arquivo esperado '$student_hdr' encontrado!"
                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivo esperado '$student_hdr' encontrado!\n"
                                student_files_found=$(expr $student_files_found + 1)
                            fi
                        fi
                    done
                    if [ $student_files_missing -gt 0 ] ; then
                        # test_cases_results["arquivos_faltando"]=$student_files_missing
                        echo -e " - Arquivos esperados enviados: Faltando!"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos esperados enviados: Faltando!\n"
                    else 
                        echo -e " - Arquivos esperados enviados: Ok!"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos esperados enviados: Ok!\n"
                    fi
                    test_cases_results["arquivos_corretos"]=$student_files_found

                    ##########################################
                    # Copiando os arquivos
                    ##########################################
                    echo -e "\nCOPIANDO OS ARQUIVOS PARA A PASTA DE RESULTADO DO ALUNO:"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nCOPIANDO OS ARQUIVOS PARA A PASTA DE RESULTADO DO ALUNO:\n"

                    # for src_file_name in "${src_files_names[@]}"; do
                    #     echo " - Pasta $src_file_name:"
                    #     TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $src_file_name:\n"
                    #     FILE_NAME_FOLDER=$STUDENT_RESULT_FOLDER/$src_file_name
                        
                    #     echo "   - Copiando os $DIR_GAB_CASOS de teste para a pasta $FILE_NAME_FOLDER"
                    #     TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os $DIR_GAB_CASOS de teste para a pasta $FILE_NAME_FOLDER\n"
                    #     cp -r $DIR_GAB_CASOS $FILE_NAME_FOLDER

                    #     if find "$STUDENT_ANSWER_FOLDER" -maxdepth 1 -type f -name "*.h" | read; then
                    #         if find "$DIR_GAB_INCLUDES" -maxdepth 1 -type f -name "*.h" | read; then
                    #             if [[ "$src_file_name" != "completo" ]] ; then
                    #                 echo "   - Copiando os $DIR_GAB_INCLUDES/*.h do professor para a pasta $FILE_NAME_FOLDER"
                    #                 TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$DIR_GAB_INCLUDES/*.h' do professor para a pasta $FILE_NAME_FOLDER\n"
                    #                 cp $DIR_GAB_INCLUDES/*.h $FILE_NAME_FOLDER
                    #             fi
                    #         fi
                            
                    #         if [[ "$src_file_name" == "main" ]] || [[ "$src_file_name" == "completo" ]] ; then
                    #             echo "   - Copiando os $STUDENT_ANSWER_FOLDER/*.h do aluno para a pasta $FILE_NAME_FOLDER"
                    #             TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$STUDENT_ANSWER_FOLDER/*.h' do aluno para a pasta $FILE_NAME_FOLDER\n"
                    #             cp $STUDENT_ANSWER_FOLDER/*.h $FILE_NAME_FOLDER
                                
                    #         else
                    #             echo "   - Copiando os $STUDENT_ANSWER_FOLDER/$src_file_name.h do aluno para a pasta $FILE_NAME_FOLDER"
                    #             TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$STUDENT_ANSWER_FOLDER/src_file_name.h' do aluno para a pasta $FILE_NAME_FOLDER\n"
                    #             cp $STUDENT_ANSWER_FOLDER/$src_file_name.h $FILE_NAME_FOLDER
                    #         fi
                    #     fi

                    #     if [[ "$src_file_name" == "main" ]] || [[ "$src_file_name" == "completo" ]]; then
                    #         echo "   - Copiando os $STUDENT_ANSWER_FOLDER/*.c do aluno para a pasta $FILE_NAME_FOLDER"
                    #         TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$STUDENT_ANSWER_FOLDER/*.c' do aluno para a pasta $FILE_NAME_FOLDER\n"
                    #         cp $STUDENT_ANSWER_FOLDER/*.c $FILE_NAME_FOLDER
                    #     else
                    #         echo "   - Copiando os $STUDENT_ANSWER_FOLDER/$src_file_name.c do aluno para a pasta $FILE_NAME_FOLDER"
                    #         TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$STUDENT_ANSWER_FOLDER/src_file_name.c' do aluno para a pasta $FILE_NAME_FOLDER\n"
                    #         cp $STUDENT_ANSWER_FOLDER/$src_file_name.c $FILE_NAME_FOLDER
                    #     fi
                    # done

                    for src_file_name in "${src_files_names[@]}"; do
                        echo " - Pasta $src_file_name:"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $src_file_name:\n"
                        FILE_NAME_FOLDER=$STUDENT_RESULT_FOLDER/$src_file_name
                        
                        echo "   - Copiando os $DIR_GAB_CASOS de teste para a pasta $FILE_NAME_FOLDER"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os $DIR_GAB_CASOS de teste para a pasta $FILE_NAME_FOLDER\n"
                        cp -r $DIR_GAB_CASOS $FILE_NAME_FOLDER

                        if find "$STUDENT_ANSWER_FOLDER" -maxdepth 1 -type f -name "*.h" | read; then
                            if find "$DIR_GAB_INCLUDES" -maxdepth 1 -type f -name "*.h" | read; then
                                if [[ "$src_file_name" != "completo" ]] ; then
                                    echo "   - Copiando os $DIR_GAB_INCLUDES/*.h do professor para a pasta $FILE_NAME_FOLDER"
                                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$DIR_GAB_INCLUDES/*.h' do professor para a pasta $FILE_NAME_FOLDER\n"
                                    cp $DIR_GAB_INCLUDES/*.h $FILE_NAME_FOLDER
                                fi
                            fi
                            
                            if [[ "$src_file_name" == "main" ]] || [[ "$src_file_name" == "completo" ]] ; then
                                echo "   - Copiando os $STUDENT_ANSWER_FOLDER/*.h do aluno para a pasta $FILE_NAME_FOLDER"
                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$STUDENT_ANSWER_FOLDER/*.h' do aluno para a pasta $FILE_NAME_FOLDER\n"
                                cp $STUDENT_ANSWER_FOLDER/*.h $FILE_NAME_FOLDER
                                
                            else
                                echo "   - Copiando os $STUDENT_ANSWER_FOLDER/$src_file_name.h do aluno para a pasta $FILE_NAME_FOLDER"
                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$STUDENT_ANSWER_FOLDER/src_file_name.h' do aluno para a pasta $FILE_NAME_FOLDER\n"
                                cp $STUDENT_ANSWER_FOLDER/$src_file_name.h $FILE_NAME_FOLDER
                            fi
                        fi

                        if [[ "$src_file_name" == "main" ]] || [[ "$src_file_name" == "completo" ]]; then
                            echo "   - Copiando os $STUDENT_ANSWER_FOLDER/*.c do aluno para a pasta $FILE_NAME_FOLDER"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$STUDENT_ANSWER_FOLDER/*.c' do aluno para a pasta $FILE_NAME_FOLDER\n"
                            cp $STUDENT_ANSWER_FOLDER/*.c $FILE_NAME_FOLDER
                        else
                            echo "   - Copiando os $STUDENT_ANSWER_FOLDER/$src_file_name.c do aluno para a pasta $FILE_NAME_FOLDER"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$STUDENT_ANSWER_FOLDER/src_file_name.c' do aluno para a pasta $FILE_NAME_FOLDER\n"
                            cp $STUDENT_ANSWER_FOLDER/$src_file_name.c $FILE_NAME_FOLDER
                        fi
                    done



                    declare -a student_extra_src_files
                    if [[ "$FIXED_INTERFACE" == false ]] ; then
                        echo " - Copiando Arquivos Extras do Aluno:"
                        for filepath in "$STUDENT_ANSWER_FOLDER/"*.c; do
                            if [[ -f "$filepath" ]]; then
                                filename=$(basename "$filepath" .c)
                                found=false
                                for gab_src_file in "${src_files_names[@]}"; do
                                    if [[ "$gab_src_file" = "$filename" ]]; then
                                        found=true
                                        break
                                    fi
                                done
                                if [ "$found" = "false" ]; then
                                    student_extra_src_files+=("$filename")
                                    files_to_compile+=("$filename")

                                    # for gab_file in "${src_files_names[@]}"; do
                                    #     FILE_NAME_FOLDER=$STUDENT_RESULT_FOLDER/$gab_file
                                    #     echo "cp $filepath $FILE_NAME_FOLDER"
                                    #     cp $filepath $FILE_NAME_FOLDER
                                    # done

                                    echo "   - Copiando $filepath para $FILE_NAME_FOLDER/completo"
                                    cp $filepath $STUDENT_RESULT_FOLDER/completo
                                    echo "   - Copiando $filepath para $FILE_NAME_FOLDER/main"
                                    cp $filepath $STUDENT_RESULT_FOLDER/main
                                fi
                            fi
                        done

                        for filepath in "$STUDENT_ANSWER_FOLDER/"*.h; do
                            if [[ -f "$filepath" ]]; then
                                filename=$(basename "$filepath" .h)
                                found=false
                                for gab_src_file in "${src_files_names[@]}"; do
                                    if [[ "$gab_src_file" = "$filename" ]]; then
                                        found=true
                                        break
                                    fi
                                done
                                if [ "$found" = "false" ]; then
                                    # for gab_file in "${src_files_names[@]}"; do
                                    #     FILE_NAME_FOLDER=$STUDENT_RESULT_FOLDER/$gab_file
                                    #     echo "cp $filepath $FILE_NAME_FOLDER"
                                    #     cp $filepath $FILE_NAME_FOLDER
                                    # done

                                    echo "   - Copiando $filepath para $FILE_NAME_FOLDER/completo"
                                    cp $filepath $STUDENT_RESULT_FOLDER/completo
                                    echo "   - Copiando $filepath para $FILE_NAME_FOLDER/main"
                                    cp $filepath $STUDENT_RESULT_FOLDER/main
                                fi
                            fi
                        done
                    fi

                    extra_files_array_size=${#student_extra_src_files[@]}
                    extra_n_compilation=$((n_folders_to_compile * extra_files_array_size))
                    # student_n_compilations=$((n_compilations + extra_n_compilation))
                    student_n_compilations=$((n_compilations))

                    test_cases_results["student_n_compilations"]=$student_n_compilations


                    echo -e " - Arquivos copiados: ok!"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos copiados: ok!\n"

                    ##########################################
                    # Compilando os arquivos
                    ##########################################
                    echo -e "\nCOMPILANDO OS ARQUIVOS NA PASTA DE RESULTADO DO ALUNO:"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nCOMPILANDO OS ARQUIVOS NA PASTA DE RESULTADO DO ALUNO:\n"
                    compilation_errors=0
                    correct_compilations=0
                    
                    echo "cd $STUDENT_RESULT_FOLDER"
                    cd $STUDENT_RESULT_FOLDER
                    for src_file_dir in "${src_files_names[@]}"; do
                        echo "   - Compilando a pasta $src_file_dir do aluno, gerando os .o's"
                        cd $src_file_dir
                        gcc -Wall -c *.c 2>> result_compilation.txt
                        if [ $? -ne 0 ]; then 
                            echo "   - Erro de compilação! Verifique os arquivos da pasta $src_file_dir."
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Erro de compilação! Verifique os arquivos da pasta $src_file_dir.\n"
                            compilation_errors=$(expr $compilation_errors + 1)
                        else
                            correct_compilations=$(expr $correct_compilations + 1)
                        fi
                        cd ../
                    #     echo " - Pasta $    :"
                    #     TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $src_file_dir:\n"
                    #     for src_file_name in "${files_to_compile[@]}"; do
                    #         if [[ "$src_file_name" == "completo" ]] ; then
                    #             continue
                    #         fi
                    #         source_file=$STUDENT_RESULT_FOLDER/$src_file_dir/$src_file_name.c
                    #         object_file=$STUDENT_RESULT_FOLDER/$src_file_dir/$src_file_name.o

                    #         echo "   - Compilando o arquivo $src_file_name.c do aluno, gerando o $src_file_name.o"
                    #         TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Compilando o arquivo $src_file_name.c do aluno, gerando o $src_file_name.o\n"
                    #         gcc -Wall -c $source_file -o $object_file 2>> $STUDENT_RESULT_FOLDER/$src_file_dir/result_compilation.txt
                    #         if [ $? -ne 0 ]; then 
                    #             echo "   - Erro de compilação! Verifique se o arquivo $source_file está correto."
                    #             TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Erro de compilação! Verifique se o arquivo $source_file está correto.\n"
                    #             compilation_errors=$(expr $compilation_errors + 1)
                    #         else
                    #             correct_compilations=$(expr $correct_compilations + 1)
                    #         fi
                    #     done
                    #     echo "   - Arquivo de output gerado: $STUDENT_RESULT_FOLDER/$src_file_dir/result_compilation.txt"
                    #     TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Arquivo de output gerado: $STUDENT_RESULT_FOLDER/$src_file_dir/result_compilation.txt.\n"
                    done
                    cd ../../

                    test_cases_results["compilacoes_corretas"]=$correct_compilations
                    if [ $compilation_errors -gt 0 ] ; then
                        echo -e " - Arquivos Compilados: Erro!: $compilation_errors arquivos com erros de compilacao.\n"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos Compilados: Erro!: $compilation_errors arquivos com erros de compilacao.\n"
                        # test_cases_results["erros_de_compilacao"]=$compilation_errors
                    fi
                    echo " - Copiando os arquivos objetos do professor para cada subpasta do Resultado do $student_name:"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Copiando os arquivos objetos do professor para cada subpasta do Resultado do $student_name:\n"
                    for src_file_dir in "${src_files_names[@]}"; do
                        if [[ "$src_file_dir" == "completo" ]] ; then 
                            continue
                        fi
                        gab_object=$DIR_GAB_OBJ/$src_file_dir.o
                        for src_file_name in "${src_files_names[@]}"; do
                            if [[ "$src_file_name" == "completo" ]] || [[ "$src_file_name" == "$src_file_dir" ]]; then 
                                continue
                            fi
                            echo "   - Copiando o $gab_object para a pasta $STUDENT_RESULT_FOLDER/$src_file_name"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando o $gab_object para a pasta $STUDENT_RESULT_FOLDER/$src_file_name\n"
                            cp $gab_object $STUDENT_RESULT_FOLDER/$src_file_name
                        done
                    done
                    echo " - Arquivos Compilados: ok!"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos Compilados: ok!\n"

                    ##########################################
                    # Linkando os arquivos compilados
                    ##########################################
                    echo -e "\nLINKANDO OS ARQUIVOS COMPILADOS:"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nLINKANDO OS ARQUIVOS COMPILADOS:\n"
                    linking_errors=0
                    correct_linkings=0
                    for src_file_dir in "${src_files_names[@]}"; do
                        echo " - Pasta $src_file_dir:"
                        echo "   - Gerando o binário prog linkando com o(s) arquivo(s) $src_file_dir/*.o"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $src_file_dir:\n   - Gerando o binário prog linkando com o(s) arquivo(s) "$src_file_dir/\*.o"\n"
                        gcc -o $STUDENT_RESULT_FOLDER/$src_file_dir/prog $STUDENT_RESULT_FOLDER/$src_file_dir/*.o -lm 2>> $STUDENT_RESULT_FOLDER/$src_file_dir/result_linking.txt
                        if [ $? -ne 0 ]; then 
                            echo -e "   - Arquivos Linkados: Erro! Binário prog não gerado."
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Arquivos Linkados: Erro! Binário prog não gerado.\n"
                            linking_errors=$(expr $linking_errors + 1)
                        else 
                            echo -e "   - Arquivos Linkados: Ok! Binário prog gerado com sucesso."
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Arquivos Linkados: Ok! Binário prog gerado com sucesso.\n"
                            correct_linkings=$(expr $correct_linkings + 1)
                        fi
                        echo "   - Arquivo de output gerado: $STUDENT_RESULT_FOLDER/$src_file_dir/result_linking.txt"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Arquivo de output gerado: $STUDENT_RESULT_FOLDER/$src_file_dir/result_linking.txt\n"
                    done
                    if [ $linking_errors -gt 0 ] ; then
                        echo " - Arquivos Linkados: Erro! $linking_errors arquivos com erros de linkagem."
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos Linkados: Erro! $linking_errors arquivos com erros de linkagem.\n"
                        # test_cases_results["erros_de_linkagem"]=$linking_errors
                    fi 
                    test_cases_results["linkagens_corretas"]=$correct_linkings
                    unset files_to_compile

                    ##################################################
                    # Executando o Valgrind 
                    ##################################################

                    if [ "$IGNORE_RESULTS" = "false" ] || [ "$IGNORE_VALGRIND" = "false" ]; then
                        echo -e "\nEXECUTANDO O VALGRIND EM CADA CASO:"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nEXECUTANDO O VALGRIND EM CADA CASO:\n"

                        for src_file_dir in "${src_files_names[@]}"; do
                            DIR_CASES=$STUDENT_RESULT_FOLDER/$src_file_dir/Casos
                            n_cases_folders=0
                            n_correct_answers=0
                            n_correct_valgrinds=0
                            sum_of_the_grades_of_all_cases=0.0
                            for DIR_CASE in "$DIR_CASES"/*; do
                                (( n_cases_folders++ ))
                                (( n_total_cases++ ))
                                sum_of_the_grades_of_current_case=0.0
                                txt_out_files=$(find "$DIR_CASE/saida/" -type f -name "*.txt")
                                if [ -n "$txt_out_files" ]; then
                                    rm -r $DIR_CASE/saida/*.txt
                                fi
                                txt_input_file=$(find "$DIR_CASE" -type f -name "*.txt")

                                case_number=${DIR_CASE##*/}
                                echo " - Pasta $src_file_dir / Caso $case_number:"
                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $src_file_dir / Caso $case_number:\n"

                                # Valgrind options and arguments
                                # binary=$STUDENT_RESULT_FOLDER/$src_file_dir/prog
                                # valgrind_args="--leak-check=full --log-file=$DIR_CASE/result_valgrind.txt"
                                # output=$(valgrind $valgrind_args $binary < $DIR_CASE/in.txt > "$DIR_CASE/saida/out.txt" 2>&1)
                                
                                txt_input_file=$(find "$DIR_CASE" -maxdepth 1 -type f -name "*.txt" | head -n 1)
                                directory_path=$(dirname "$txt_input_file")
                                filename=$(basename -- "$txt_input_file")   # Get only the file name without the full path
                                filename_no_ext="${filename%.*}"  # Get only the file name without the extension
                                # output="${DIR_CASE}/saida/out_${filename_no_ext}.txt"
                                output="${DIR_CASE}/saida/saida.txt"
                                input_file=$directory_path/entrada.txt
                                # echo "GErando output: $output"
                                filename_out=$(basename -- "$output")   # Get only the file name without the full path

                                binary=$STUDENT_RESULT_FOLDER/$src_file_dir/prog
                                valgrind_args="--leak-check=full --log-file=$DIR_CASE/result_valgrind.txt"
                                # output=$(timeout 5 valgrind $valgrind_args $binary < $txt_input_file > $output 2>&1)

                                if [ "$IGNORE_VALGRIND" = "false" ]; then
                                    output=$(timeout 50 valgrind $valgrind_args $binary $directory_path < $input_file > $output 2>&1)
                                else
                                    output=$(timeout 50 $binary $directory_path < $input_file > $output 2>&1)
                                fi

                                # find "." -maxdepth 1 -type f -name "*.txt" ! -name "log.txt" -exec mv {} "${DIR_CASE}/saida/" \;
                                find "." -maxdepth 1 -type f -name "*.txt" ! -name "log.txt" ! -name "pontuacao.txt" -exec mv {} "${DIR_CASE}/saida/" \;

                                # echo "output: $output"
                                # output=$(valgrind $valgrind_args $binary < $DIR_CASE/in.txt > "out.txt" 2>&1)

                                valgrind_desconto=0.5

                                for key in "${!pesos[@]}"; do
                                    if [[ "$key" == "valgrind" ]]; then
                                        valgrind_desconto=$(echo "scale=2; ${pesos["$key"]}" | bc)
                                    fi
                                done


                                if [[ "$IGNORE_VALGRIND" = "true" ]] ; then
                                    valgrind_desconto=0.0
                                fi

                                valgrind_desconto_percent=$(echo "scale=2; $valgrind_desconto * 100.0" | bc)

                                there_is_a_wrong_valgrind=false
                                if [ "$IGNORE_VALGRIND" = "false" ]; then
                                    if [[ -f "$DIR_CASE/result_valgrind.txt" ]]; then
                                        valgrind_result_file=$DIR_CASE/result_valgrind.txt
                                        echo "   - Arquivo de output gerado: $DIR_CASE/result_valgrind.txt."
                                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Arquivo de output gerado: $DIR_CASE/result_valgrind.txt.\n"
                                
                                        # Valgring returns
                                        allocs=0
                                        frees=0
                                        errors=0
                                        contexts=0

                                        # Using while read loop to process each line of the file
                                        while IFS= read -r line; do
                                            if echo "$line" | grep -q "total heap usage"; then
                                                # Extract the allocs (position 5) and frees (position 7) numbers on the string
                                                allocs=$(echo "$line" | awk '{print $5}')
                                                frees=$(echo "$line" | awk '{print $7}')
                                            elif echo "$line" | grep -q "ERROR SUMMARY"; then
                                                # Extract the errors (position 4) and contexts (position 7) numbers on the string
                                                errors=$(echo "$line" | awk '{print $4}')
                                                contexts=$(echo "$line" | awk '{print $7}')
                                            fi
                                        done < "$valgrind_result_file"

                                        # if [[ -f $valgrind_result_file ]]; then 
                                        #     rm -r $valgrind_result_file
                                        # fi

                                        # echo "Test Case: $DIR_CASE" >> $valgrind_result_file
                                        # echo "Valgrind result: allocs: $allocs frees: $frees errors: $errors contexts: $contexts" >> $valgrind_result_file

                                        if test "$allocs" = "$frees" && test "$errors" = "0"; then
                                            valgrind_desconto_percent="0.0"
                                            valgrind_desconto=0.0
                                            echo "   - Valgrind: Ok! allocs: $allocs, frees: $frees, errors: $errors | Desconto do valgrind: 0.0%"
                                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Valgrind: Ok! allocs: $allocs, frees: $frees, errors: $errors | Desconto do valgrind: 0.0%\n"
                                        else
                                            echo "   - Valgrind: Incorreto! allocs: $allocs, frees: $frees, errors: $errors | Desconto do valgrind $valgrind_desconto_percent%"
                                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Valgrind: Incorreto! allocs: $allocs, frees: $frees, errors: $errors | Desconto do valgrind $valgrind_desconto_percent%\n"
                                            there_is_a_wrong_valgrind=true
                                        fi
                                    else
                                        echo "   - Valgrind: Incorreto! Verifique se o binário prog foi gerado corretamente. Ou se o Valgrind está instalado."
                                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Valgrind: Incorreto! Verifique se o binário prog foi gerado corretamente. Ou se o Valgrind está instalado.\n"
                                        there_is_a_wrong_valgrind=true
                                    fi
                                fi

                                DIR_CASE_SAIDA=$DIR_CASE/saida
                                txt_file_names=()
                                there_is_a_wrong_answer=false
                                # Loop through all files in the saida folder

                                declare -A txts_corretos

                                for key in "${!pesos[@]}"; do
                                    if [[ "$key" == *".txt" ]]; then
                                        txts_corretos["$key"]=0.0
                                    fi
                                done

                                for gab_case_txt_file in "$DIR_GAB_CASOS/$case_number/saida"/*.txt; do
                                    if [ -f "$gab_case_txt_file" ]; then         # Check if the file is a regular file (not a directory or special file)
                                        # txt_file_names+=("$gab_case_txt_file")       # Add the file name to the array
                                        filename=$(basename -- "$gab_case_txt_file")   # Get only the file name without the full path
                                        txt_file_names+=("$filename")  # Add the file name to the array
                                        filename_no_ext="${filename%.*}"  # Get only the file name without the extension
                                        
                                        student_output_file=$DIR_CASE/saida/$filename
                                        # echo "student_output_file: $student_output_file"

                                        if test -e "$student_output_file"; then
                                            # mv $filename $DIR_CASE_SAIDA
                                            # Making a copy of the professor out.txt file and the student out.txt file, inside the test cases student folder
                                            output_student_copy="$filename_no_ext"_student_copy.txt
                                            output_professor_copy="$filename_no_ext"_professor_copy.txt

                                            cp $DIR_CASE_SAIDA/$filename $DIR_CASE_SAIDA/$output_student_copy
                                            cp $DIR_GAB_CASOS/$case_number/saida/$filename $DIR_CASE_SAIDA/$output_professor_copy

                                            chmod 777 $DIR_CASE_SAIDA/$output_student_copy
                                            chmod 777 $DIR_CASE_SAIDA/$output_professor_copy

                                            # Removing trailing white spaces at end of each line, and removing trailing newlines at the end of the file
                                            sed -i 's/[[:space:]]*$//' "$DIR_CASE_SAIDA/$output_student_copy"
                                            sed -i ':a; /./,$!{N;ba}; /^$/d' "$DIR_CASE_SAIDA/$output_student_copy"
                                            sed -i 's/[[:space:]]*$//' "$DIR_CASE_SAIDA/$output_professor_copy"
                                            sed -i ':a; /./,$!{N;ba}; /^$/d' "$DIR_CASE_SAIDA/$output_professor_copy"
                                            
                                            # Open both files for reading
                                            exec 3< "$DIR_CASE_SAIDA/$output_student_copy"
                                            exec 4< "$DIR_CASE_SAIDA/$output_professor_copy"

                                            files_are_equal="true"

                                            while true; do
                                                # Read a line from each file
                                                read -r line1 <&3
                                                read -r line2 <&4

                                                # Check if we reached the end of both files
                                                if [[ -z "$line1" && -z "$line2" ]]; then
                                                    break
                                                fi

                                                # Ignore blank lines and continue the loop
                                                if [[ -z "$line1" && -z "$line2" ]]; then
                                                    continue
                                                fi

                                                # Compare lines and check for differences
                                                if [[ "$line1" != "$line2" ]]; then
                                                    files_are_equal="false"
                                                fi
                                            done

                                            # Close file descriptors
                                            exec 3<&-
                                            exec 4<&-
                                        
                                            if test "$files_are_equal" = "false"; then
                                                there_is_a_wrong_answer=true
                                                echo "   - Resultado para o $filename: Incorreto! Peso: 0.0"
                                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Resultado para o $filename: Incorreto!\n"

                                            else

                                                txts_corretos["$filename"]=1.0
                                                echo "   - Resultado para o $filename: Ok! Peso: ${pesos[$filename]}"
                                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Resultado para o $filename: Ok! Peso: ${pesos[$filename]}\n"

                                                (( n_correct_answers++ ))
                                                test_cases_pontuacoes["$filename"]=$((test_cases_pontuacoes["$filename"] + 1))
                                            fi

                                            rm "$DIR_CASE_SAIDA/$output_student_copy"
                                            rm "$DIR_CASE_SAIDA/$output_professor_copy"
                                        else
                                            echo "   - O aluno não gerou o arquivo de saída $DIR_CASE_SAIDA/$filename, considerando resultado incorreto! Peso: 0.0"
                                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - O aluno não gerou o arquivo de saída $DIR_CASE_SAIDA/$filename, considerando resultado incorreto!\n"

                                            there_is_a_wrong_answer=true
                                        fi
                                    fi
                                done

                                for key in "${!pesos[@]}"; do
                                    if [[ "$key" == *".txt" ]]; then
                                        sum_of_the_grades_of_current_case=$(echo "scale=2; $sum_of_the_grades_of_current_case + ${txts_corretos["$key"]} * ${pesos["$key"]}" | bc)
                                    fi
                                done
                        
                                descontar=$(echo "scale=2; 1.0 - $valgrind_desconto" | bc)
                                sum_of_the_grades_of_current_case_minus_valgrind=$(echo "scale=2; $sum_of_the_grades_of_current_case * $descontar" | bc)
                                echo "   - Nota para o Caso (soma dos pesos): $sum_of_the_grades_of_current_case (soma total) - $valgrind_desconto_percent% (desconto do valgrind) = $sum_of_the_grades_of_current_case_minus_valgrind"

                                sum_of_the_grades_of_all_cases=$(echo "scale=2; $sum_of_the_grades_of_all_cases + $sum_of_the_grades_of_current_case_minus_valgrind" | bc)
                                # if [[ "$there_is_a_wrong_answer" = "false" ]]; then
                                #     (( n_correct_answers++ ))
                                # fi

                                if [[ "$there_is_a_wrong_valgrind" = "false" ]]; then
                                    (( n_correct_valgrinds++ ))
                                fi
                            done

                            nota_para_pasta=$(echo "scale=2; $sum_of_the_grades_of_all_cases / $n_cases_folders" | bc)
                            # nota_final_para_pasta=$((nota_para_pasta * pesos[$dictFolder] / 10))
                            

                            dictFolder=""
                            if [[ "$src_file_dir" = "completo" ]] || [[ "$src_file_dir" = "main" ]] ; then
                                dictFolder=$src_file_dir
                            else
                                dictFolder=$src_file_dir.h
                            fi

                            # for key in "${!pesos[@]}"; do
                            #     echo "$key = ${pesos[$key]}"
                            # done

                            nota_final_para_pasta=$(echo "scale=2; $nota_para_pasta * ${pesos[$dictFolder]} / 10.0" | bc)
                            echo " - Nota para a pasta $src_file_dir (peso ${pesos[$dictFolder]}) considerando a média das notas de todos os casos ($nota_para_pasta) : $nota_para_pasta * ${pesos[$dictFolder]}/10.0 = $nota_final_para_pasta"
                            echo " -----"

                            # grade_for_the_test=$(echo "scale=2; $n_correct_answers / $n_cases_folders * 10.0" | bc)
                            # acertos_field=acertos_$src_file_dir
                            # test_cases_results[$acertos_field]=$n_correct_answers


                            acertos_field=acertos_$src_file_dir
                            test_cases_results[$acertos_field]=$n_correct_answers
                            nota_field=nota_$src_file_dir
                            test_cases_results[$nota_field]=$nota_final_para_pasta

                            valgrade_for_the_test=$(echo "scale=2; $n_correct_valgrinds / $n_cases_folders * 10.0" | bc)
                            valacertos_field=valacertos_$src_file_dir
                            test_cases_results[$valacertos_field]=$n_correct_valgrinds

                        done
                    fi

                    all_students_results[$iteration]=$(declare -p test_cases_results)
                    all_students_pontuacoes[$iteration]=$(declare -p test_cases_pontuacoes)
                fi
            done < <(find "$DIR_RESPOSTAS" -mindepth 1 -type d -print0)
        else
            echo -e "\nPasta não encontrada: $DIR_RESPOSTAS\n - Erro! Por favor, crie uma pasta chamada Respostas/ na raíz onde ta o Script e dentro desta pasta crie outra com o seu nome, por exemplo Respostas/JoaoAugusto/ e dentro dessa pasta do seu nome coloque os seus arquivos do código fonte."
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nPasta não encontrada: $DIR_RESPOSTAS\n - Erro! Por favor, crie uma pasta chamada Respostas/ na raíz onde ta o Script e dentro desta pasta crie outra com o seu nome, por exemplo Respostas/JoaoAugusto/ e dentro dessa pasta coloque os seus arquivos do código fonte."
            exit 1
        fi

        echo -e "\n#######################################"
        echo -e "RESULTADOS FINAIS"
        echo -e "#######################################"
        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\n#######################################\nRESULTADOS FINAIS\n#######################################\n"

        # Function to create and fill the CSV file
        create_csv() {
            # CSV file name
            csv_name="Resultado.csv"
            if [[ -f $csv_name ]]; then 
                rm -r $csv_name
            fi
            # CSV header row
            header_csv_str="Nome"
            header_csv_created=false

            n_src_files_names=${#src_files_names[@]}
            n_fields_to_consider=4.0
            # if [[ "$IGNORE_RESULTS" = "false" ]]; then
            #     n_fields_to_consider=$(echo "$n_fields_to_consider + $n_src_files_names" | bc)
            #     # n_fields_to_consider=$((n_fields_to_consider + $n_src_files_names))
            # fi
            # if [[ "$IGNORE_VALGRIND" = "false" ]]; then
            #     n_fields_to_consider=$(echo "$n_fields_to_consider + $n_src_files_names" | bc)
            # fi

            students_number=${#all_students_results[@]}
            for (( i=0; i<students_number; i++ )); do
                # Extract the dictionary string from the main array
                dict_string=${all_students_results[$i]}
                # Evaluate the dictionary string to recreate the dictionary
                eval "$dict_string"
                # Access elements in the dictionary
                echo -e "\n----------------------------------------------------------------------------"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\n----------------------------------------------------------------------------\n"
                echo "Nome $i: ${test_cases_results[student_name]}"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}Nome $i: ${test_cases_results[student_name]}\n"

                dict_string_pontuacoes=${all_students_pontuacoes[$i]}
                eval "$dict_string_pontuacoes"

                # integer_number=$(expr "$student_average_grade" + 0)
                # n_files_each_type=$(expr "$n_fields_to_consider" - 3)

                # Multiply value1 and value2 and store the result in value3
                n_files_each_type=$((n_src_files_names * n_cases))

                # CSV content rows
                content_csv_str="${test_cases_results[student_name]}"
                student_name=${test_cases_results[student_name]}
                student_grades_sum=0.0

                correct_files=${test_cases_results["arquivos_corretos"]}
                grade_for_correct_files=$(echo "scale=3; $correct_files / $n_files * 10.0" | bc)
                grade_decimal_value=$(echo "$grade_for_correct_files" | bc)
                student_grades_sum=$(echo "$student_grades_sum + $grade_decimal_value" | bc)
                trimmed_grade_to_show="${grade_decimal_value%?}"
                if [ "$grade_decimal_value" = "0" ]; then
                    trimmed_grade_to_show="0.00"
                fi
                # content_csv_str=$content_csv_str",$trimmed_grade_to_show"
                # echo "  - Arquivos Corretos: $correct_files de $n_files / Nota $trimmed_grade_to_show"
                # TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Arquivos Corretos: $correct_files de $n_files / Nota $trimmed_grade_to_show\n"
                # echo "  - Arquivos Corretos: $correct_files de $n_files"
                # TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Arquivos Corretos: $correct_files de $n_files"

                echo "   - Resumo dos Resultados:"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Resumo dos Resultados:\n"

                correct_comps=${test_cases_results["compilacoes_corretas"]}
                grade_for_correct_comps=$(echo "scale=3; $correct_comps / ${test_cases_results[student_n_compilations]} * 10.0" | bc)
                grade_decimal_value=$(echo "$grade_for_correct_comps" | bc)
                student_grades_sum=$(echo "$student_grades_sum + $grade_decimal_value" | bc)
                trimmed_grade_to_show="${grade_decimal_value%?}"
                if [ "$grade_decimal_value" = "0" ]; then
                    trimmed_grade_to_show="0.00"
                fi
                # content_csv_str=$content_csv_str",$trimmed_grade_to_show"
                # echo "  - Compilações Corretas: $correct_comps de ${test_cases_results[student_n_compilations]} / Nota $trimmed_grade_to_show"
                # TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Compilações Corretas: $correct_comps de ${test_cases_results[student_n_compilations]} / Nota $trimmed_grade_to_show\n"
                echo "      - Resumo das Compilações: $correct_comps compilações corretas de ${test_cases_results[student_n_compilations]} no total"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Resumo das Compilações: $correct_comps compilações corretas de ${test_cases_results[student_n_compilations]} no total\n"

                correct_links=${test_cases_results["linkagens_corretas"]}
                grade_for_correct_links=$(echo "scale=3; $correct_links / $n_linkings * 10.0" | bc)
                grade_decimal_value=$(echo "$grade_for_correct_links" | bc)
                student_grades_sum=$(echo "$student_grades_sum + $grade_decimal_value" | bc)
                trimmed_grade_to_show="${grade_decimal_value%?}"
                if [ "$grade_decimal_value" = "0" ]; then
                    trimmed_grade_to_show="0.00"
                fi
                # content_csv_str=$content_csv_str",$trimmed_grade_to_show"
                # echo "  - Linkagens Corretas: $correct_links de $n_linkings / Nota $trimmed_grade_to_show"
                # TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Linkagens Corretas: $correct_links de $n_linkings / Nota $trimmed_grade_to_show\n"
                echo "      - Resumo das Linkagens: $correct_links linkagens corretas de $n_linkings no total"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Resumo das Linkagens: $correct_links linkagens corretas de $n_linkings no total\n"
                
                n_txt_files=6
                total_txt_files=$((n_txt_files * n_cases))
                
                # Evaluate the dictionary string to recreate the dictionary
                echo "      - Resumo dos Resultados por arquivo de saída:"

                for key in "${!pesos[@]}"; do
                    if [[ "$key" == *".txt" ]]; then
                        sum_of_the_grades_of_current_case=$(echo "scale=2; $sum_of_the_grades_of_current_case + ${txts_corretos["$key"]} * ${pesos["$key"]}" | bc)
                        echo "          - Acertou ${test_cases_pontuacoes["$key"]} de $n_files_each_type $key ($n_src_files_names $key em cada um dos $n_cases Casos)"
                    fi
                done
                
                total_n_correct_valgrinds=0
                if [[ "$IGNORE_VALGRIND" = "false" ]] ; then
                    echo "      - Resumo dos Valgrinds por pasta de Teste:"
                    for src_file_name in "${src_files_names[@]}"; do
                        filename_with_ext=$src_file_name.h
                        # if contains "$filename_with_ext" || [[ "$fruit_tofilename_with_ext_find" == "completo" ]]; then
                        if contains "$filename_with_ext" || [[ "$src_file_name" = "completo" ]] || [[ "$src_file_name" = "main" ]] ; then
                            valacertos_field=valacertos_$src_file_name
                            n_correct_valgrinds=${test_cases_results[$valacertos_field]}
                            total_n_correct_valgrinds=$((total_n_correct_valgrinds + n_correct_valgrinds))
                            valgrade_for_the_test=$(echo "scale=3; $n_correct_valgrinds / $n_cases * 10.0" | bc)
                            valgrade_decimal_value=$(echo "$valgrade_for_the_test" | bc)
                            # student_grades_sum=$(echo "$student_grades_sum + $valgrade_decimal_value" | bc)
                            trimmed_grade_to_show="${valgrade_decimal_value%?}"
                            if [ "$valgrade_decimal_value" = "0" ]; then
                                trimmed_grade_to_show="0.00"
                            fi
                            # header_csv_str=$header_csv_str",Valgrind $src_file_name"
                            # content_csv_str=$content_csv_str",$trimmed_grade_to_show"

                            teve_desconto="(teve desconto na nota para a pasta $src_file_name, olhar detalhamento nos prints acima!)"
                            if [[ "$n_correct_valgrinds" = "$n_cases" ]] ; then
                                teve_desconto="(não teve desconto na nota)"
                            fi

                            echo "          - Pasta $src_file_name: $n_correct_valgrinds valgrinds corretos de $n_cases $teve_desconto"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Valgrinds Corretos $src_file_name: $n_correct_valgrinds valgrinds corretos de $n_cases $teve_desconto\n"
                        fi
                    done
                    echo "          - Acertou $total_n_correct_valgrinds valgrinds de $n_files_each_type no total ($n_src_files_names pastas para cada um dos $n_cases Casos)"
                fi
                
                echo "   - Cômputo das Notas:"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Cômputo final das Notas:\n"

                nota_final_para_resultados=0.0
                echo "      - Notas dos Resultados por pasta de teste:"
                for src_file_name in "${src_files_names[@]}"; do
                    if [[ "$IGNORE_RESULTS" = "false" ]] ; then
                        filename_with_ext=$src_file_name.h
                        # if contains "$filename_with_ext" || [[ "$fruit_tofilename_with_ext_find" == "completo" ]]; then
                        if contains "$filename_with_ext" || [[ "$src_file_name" = "completo" ]] || [[ "$src_file_name" = "main" ]] ; then
                            nota_field=nota_$src_file_name
                            grade_field=${test_cases_results[$nota_field]}
                            # test_cases_results[$nota_field]=$nota_para_pasta

                            acertos_field=acertos_$src_file_name
                            n_correct_answers=${test_cases_results[$acertos_field]}
                            grade_for_the_test=$(echo "scale=3; $n_correct_answers / $total_txt_files * 10.0" | bc)
                            grade_decimal_value=$(echo "$grade_for_the_test" | bc)
                            # student_grades_sum=$(echo "$student_grades_sum + $grade_decimal_value" | bc)
                            trimmed_grade_to_show="${grade_decimal_value%?}"
                            if [ "$grade_decimal_value" = "0" ]; then
                                trimmed_grade_to_show="0.00"
                            fi

                            dictFolder=""
                            if [[ "$src_file_name" = "completo" ]] || [[ "$src_file_name" = "main" ]] ; then
                                dictFolder=$src_file_name
                            else
                                dictFolder=$src_file_name.h
                            fi

                            header_csv_str=$header_csv_str",$src_file_name (Peso ${pesos[$dictFolder]})"
                            content_csv_str=$content_csv_str",$grade_field"

                            echo "          - Pasta $src_file_name (peso ${pesos[$dictFolder]}): $n_correct_answers resultados corretos de $total_txt_files / Nota $grade_field"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}          - Pasta $src_file_name (peso ${pesos[$dictFolder]}): $n_correct_answers resultados corretos de $total_txt_files / Nota $grade_field\n"

                            # nota_final_para_resultados=$((nota_final_para_resultados + grade_field))
                            nota_final_para_resultados=$(echo "$nota_final_para_resultados + $grade_field" | bc)
                        fi
                    fi
                done

                considerar_valgrind="considerando o valgrind"
                if [[ "$IGNORE_VALGRIND" = "true" ]] ; then
                    considerar_valgrind="sem considerar o valgrind"
                fi
                echo "          - Soma das notas das pastas ($considerar_valgrind): $nota_final_para_resultados"
            
                student_grades_sum=$(echo "scale=2; $student_grades_sum + $nota_final_para_resultados" | bc)
                student_average_grade=$(echo "scale=2; $student_grades_sum / $n_fields_to_consider" | bc)
                trimmed_grade_to_show="${student_grades_sum%?}"
                if [ "$student_grades_sum" = "0" ]; then
                    trimmed_grade_to_show="0.00"
                fi
                # echo "  - Soma das notas do $student_name: $trimmed_grade_to_show"
                # TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Soma das notas do $student_name: $student_grades_sum\n"

                # integer_part=$(echo "$n_fields_to_consider" | awk -F. '{print $1}')
                # echo "  - Quantidade de notas: $integer_part"
                # TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Campos Considerados: $integer_part\n"
                
                # integer_number=$(expr "$student_average_grade" + 0)
                if [ "$student_average_grade" = "0" ]; then
                    student_average_grade="0.00"
                elif (( $(echo "$student_average_grade < 1" | bc -l) )); then
                    student_average_grade="0""$student_average_grade"
                fi

                echo "   - Nota final do $student_name: $nota_final_para_resultados"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Nota Final $student_name: $nota_final_para_resultados\n"
                content_csv_str=$content_csv_str",$nota_final_para_resultados"

                header_csv_str=$header_csv_str",Nota Final"
                if [[ "$header_csv_created" = "false" ]]; then
                    echo $header_csv_str >> "$csv_name"
                    header_csv_created=true
                fi
                echo $content_csv_str >> "$csv_name"
                content_csv_str=""
                header_csv_str=""
            done
            echo -e "\n----------------------------------------------------------------------------"
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\n----------------------------------------------------------------------------\n"
            echo -e "\nArquivo CSV $csv_name com os resultados finais foi gerado na pasta raíz!\n\n" 
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nArquivo CSV $csv_name com os resultados finais foi gerado na pasta raíz!\n\n"
            echo -e $TERMINAL_OUTPUT_LOG >> "log.txt"
        }

        create_csv
    fi
}

function script_sem_pesos()
{
    if [[ "$RUN_PROFESSOR_SCRIPT" == true ]] ; then
        if test -d "$DIR_GAB_OBJ"; then
            rm -r $DIR_GAB_OBJ
        fi
        mkdir -p $DIR_GAB_OBJ
        echo " - Pasta $DIR_GAB_OBJ criada com sucesso!"
        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $DIR_GAB_OBJ criada com sucesso!\n"
        if test -d "$DIR_INCLUDES"; then
            rm -r $DIR_INCLUDES
        fi
        mkdir -p $DIR_INCLUDES
        echo " - Pasta $DIR_INCLUDES criada com sucesso!"
        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $DIR_INCLUDES criada com sucesso!\n"
        gab_src_files_names=()
        # Check if the folder exists and is a directory
        if [ -d "$DIR_INCLUDES" ] && [ -d "$DIR_GAB_SRC" ]; then

            if [ "$HEADER_FILES_EXIST" = "true" ]; then
                cp $DIR_GAB_SRC/*.h $DIR_INCLUDES
                echo " - Arquivos .h do professor da pasta $DIR_GAB_SRC copiados para a pasta $DIR_INCLUDES com sucesso!"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos .h do professor da pasta $DIR_GAB_SRC copiados para a pasta $DIR_INCLUDES com sucesso!\n"
            else
                echo " - Não existem arquivos header na pasta $DIR_GAB_SRC do professor."
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Não existem arquivos header na pasta $DIR_GAB_SRC do professor.\n"
            fi
            
            src_files_array=()
            # Read the files with the specific extension into the array
            while IFS= read -r -d '' file; do
                src_files_array+=("$file")
            done < <(find "$DIR_GAB_SRC" -type f -name "*.c" -print0)
            # Print the elements of the array for verification
            for src_file in "${src_files_array[@]}"; do
                x=${src_file%.c}  # x sera' o nome do arquivo sem a extensao .c
                raw_file_name=${x##*/}  # raw_file_name sera' o nome do arquivo puro, sem os diretorios que contem ele
                gab_src_files_names+=("$raw_file_name")
                src=$DIR_GAB_SRC/$raw_file_name.c
                out=$DIR_GAB_OBJ/$raw_file_name.o
                output=$(gcc -Wall -c $src -o $out 2>&1)
                if [ $? -ne 0 ]; then 
                    echo "   - Erro de compilação! Verifique se o arquivo $src está correto."
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Erro de compilação! Verifique se o arquivo $src está correto.\n"
                    echo $TERMINAL_OUTPUT_LOG >> "log.txt"
                    exit 1
                fi
            done

            output=$(gcc -Wall -o $DIR_GAB_OBJ/prog $DIR_GAB_OBJ/*.o -lm 2>&1)
            if [ $? -ne 0 ]; then 
                echo -e "   - Arquivos Linkados: Erro! Binário prog não gerado."
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Arquivos Linkados: Erro! Binário prog não gerado.\n"
                echo $TERMINAL_OUTPUT_LOG >> "log.txt"
                exit 1
            else 
                echo " - Arquivos objetos do gabarito gerados com sucesso na pasta $DIR_GAB_OBJ!"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos objetos do gabarito gerados com sucesso na pasta $DIR_GAB_OBJ!\n"
            fi       
        else
            echo " - Pasta não encontrada: $DIR_INCLUDES ou $DIR_GAB_SRC, abortado!"
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta não encontrada: $DIR_INCLUDES ou $DIR_GAB_SRC, abortado!\n"
            echo $TERMINAL_OUTPUT_LOG >> "log.txt"
            exit 1
        fi

        for DIR_CASE in "$DIR_GAB_CASOS"/*; do
            txt_input_file=$(find "$DIR_CASE" -maxdepth 1 -type f -name "*.txt" | head -n 1)
            directory_path=$(dirname "$txt_input_file")
            filename=$(basename -- "$txt_input_file")   # Get only the file name without the full path
            filename_no_ext="${filename%.*}"  # Get only the file name without the extension

            dir_saida=${DIR_CASE}/saida
            if [ ! -d "$dir_saida" ]; then
                mkdir -p $dir_saida
            fi

            txt_output_file=$(find "$DIR_CASE/saida" -maxdepth 1 -type f -name "*.txt" | head -n 1)
            if test -f "$txt_output_file"; then
                rm $DIR_CASE/saida/*.txt
            fi

            input_file=$directory_path/entrada.txt
            # output="${DIR_CASE}/saida/out_${filename_no_ext}.txt"
            output="${DIR_CASE}/saida/saida.txt"

            # $DIR_GAB_OBJ/prog < $txt_input_file > $output 2>&1
            $DIR_GAB_OBJ/prog $directory_path < $input_file 2>&1
            # mv *.txt $DIR_CASE/saida/
            for txtfile in *.txt; do
                if [[ "$txtfile" != "pontuacao.txt" ]]; then
                    mv "$txtfile" "$DIR_CASE/saida/"
                fi
            done
            echo " - Output do resultado do professor gerado com sucesso na pasta $output."
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Output do resultado do professor gerado com sucesso na pasta $output.\n"
        done

        echo -e " - Todos os arquivos necessários do professor gerados. Remova a pasta $DIR_GAB_SRC e envie o script para o Aluno!\n"
        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Todos os arquivos necessários do professor gerados. Remova a pasta $DIR_GAB_SRC e envie o script para o Aluno!\n"
    fi

    if [[ "$RUN_STUDENT_SCRIPT" == true ]] ; then

        if test -d "$DIR_INCLUDES"; then
            if find "$DIR_INCLUDES" -maxdepth 1 -type f -name "*.h" | read; then
                HEADER_FILES_EXIST=true
            fi
        fi

        if [ "$HEADER_FILES_EXIST" = "true" ]; then
            if [ -d "$DIR_INCLUDES" ]; then
                if [ $(find "$DIR_INCLUDES" -maxdepth 1 -type f -name "*.h" | wc -l) -gt 0 ]; then
                    echo " - Arquivos header necessários do professor existem na pasta $DIR_INCLUDES"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos header necessários do professor existem na pasta $DIR_INCLUDES\n"
                else
                    echo " - Arquivos header necessários do professor não existem na pasta $DIR_INCLUDES, por favor rode o script do professor primeiro. Abortado!"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos header necessários do professor não existem na pasta $DIR_INCLUDES, por favor rode o script do professor primeiro. Abortado!\n"
                    echo $TERMINAL_OUTPUT_LOG >> "log.txt"
                    exit 1
                fi
            else
                echo " - A pasta $DIR_INCLUDES com os arquivos header do professor não existe, por favor rode o script do professor primeiro. Abortado!"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - A pasta $DIR_INCLUDES com os arquivos header do professor não existe, por favor rode o script do professor primeiro. Abortado!\n"
                echo $TERMINAL_OUTPUT_LOG >> "log.txt"
                exit 1
            fi
        fi

        if [ -d "$DIR_GAB_OBJ" ]; then
            if [ $(find "$DIR_GAB_OBJ" -maxdepth 1 -type f -name "*.o" | wc -l) -gt 0 ]; then
                echo " - Arquivos objetos necessários do professor existem na pasta $DIR_GAB_OBJ."
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos objetos necessários do professor existem na pasta $DIR_GAB_OBJ."
            else
                echo " - Arquivos objetos necessários do professor não existem na pasta $DIR_GAB_OBJ, por favor rode o script do professor primeiro. Abortado!"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos objetos necessários do professor não existem na pasta $DIR_GAB_OBJ, por favor rode o script do professor primeiro. Abortado!\n"
                echo $TERMINAL_OUTPUT_LOG >> "log.txt"
                exit 1
            fi
        else
            echo " - A pasta $DIR_GAB_OBJ com os arquivos objetos do professor não existe, por favor rode o script do professor primeiro. Abortado!"
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - A pasta $DIR_GAB_OBJ com os arquivos objetos do professor não existe, por favor rode o script do professor primeiro. Abortado!\n"
            echo $TERMINAL_OUTPUT_LOG >> "log.txt"
            exit 1
        fi

        n_cases=0
        for DIR_CASE in "$DIR_GAB_CASOS"/*; do
            (( n_cases++ ))
        done

        # Create empty arrays
        declare -a src_files_names
        declare -a fullpaths

        n_files=0
        n_folders_to_compile=0
        n_compilations=0
        for filepath in "$DIR_GAB_OBJ/"*.o; do
            # Check if file exists to avoid the loop processing the "*.txt" string when there are no matches
            if [[ -f "$filepath" ]]; then
                # Extract just the file name without the path and extension
                filename=$(basename "$filepath" .o)
                src_files_names+=("$filename")
                fullpaths+=("$filepath")
                (( n_files++ ))
                (( n_folders_to_compile++ ))
                (( n_compilations++ ))
            fi
        done
        
        n_compilations=$((n_compilations * n_files))
        n_compilations=$((n_compilations + n_files)) # considerando a pasta completo
        n_folders_to_compile=$((n_folders_to_compile + 1)) # considerando a pasta completo
        n_linkings=$((n_files + 1))

        for headerpath in "$DIR_INCLUDES/"*.h; do
            if [[ -f "$headerpath" ]]; then
                # Extract just the file name without the path and extension
                (( n_files++ ))
            fi
        done

        if [[ ${#src_files_names[@]} -eq 0 ]]; then
            echo " - A Pasta $DIR_GAB_OBJ com os arquivos objetos do Gabarito está vazia, por favor rode primeiro o script do Professor!"
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - A Pasta $DIR_GAB_OBJ com os arquivos objetos do Gabarito está vazia, por favor rode primeiro o script do Professor!\n"
            echo $TERMINAL_OUTPUT_LOG >> "log.txt"
            exit 1
        fi

        src_files_names+=("completo")

        declare -A all_students_results
        iteration=0
        
        # Check if the folder exists and is a directory
        if [ -d "$DIR_RESPOSTAS" ]; then

            if [ -z "$(ls -A $DIR_RESPOSTAS)" ]; then
                echo " - Erro! Por favor, crie uma pasta com o seu nome dentro da pasta Respostas/, por exemplo Respostas/JoaoAugusto/ e dentro dessa pasta do seu nome coloque os seus arquivos do código fonte."
                exit 1
            fi

            if [ ! -d "$DIR_RESULTADOS" ]; then
                mkdir -p $DIR_RESULTADOS
            fi

            # Loop through all folders in the specified folder using 'find'
            while IFS= read -r -d '' STUDENT_ANSWER_FOLDER; do
                if [ -d "$STUDENT_ANSWER_FOLDER" ]; then
                    (( iteration++ ))

                    # Get the student name
                    delimiter="/" # Set the delimiter
                    original_IFS="$IFS" # Save the old IFS
                    IFS="$delimiter" # Set the IFS to the delimiter to split the string
                    read -r _ student_name <<< "$STUDENT_ANSWER_FOLDER" # Read the second part of the string into a variable
                    IFS="$original_IFS" 

                    echo -e "\n#######################################"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\n#######################################\n"
                    echo "ALUNO: $student_name"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}ALUNO: $student_name\n"
                    echo -e "#######################################\n"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}#######################################\n"

                    declare -a files_to_compile
                    for element in "${src_files_names[@]}"; do
                        files_to_compile+=("$element")
                    done

                    declare -a student_extra_src_files
                    if [[ "$FIXED_INTERFACE" == false ]] ; then
                        for filepath in "$STUDENT_ANSWER_FOLDER/"*.c; do
                            if [[ -f "$filepath" ]]; then
                                filename=$(basename "$filepath" .c)
                                found=false
                                for gab_src_file in "${src_files_names[@]}"; do
                                    if [[ "$gab_src_file" = "$filename" ]]; then
                                        found=true
                                        break
                                    fi
                                done
                                if [ "$found" = "false" ]; then
                                    student_extra_src_files+=("$filename")
                                    files_to_compile+=("$filename")
                                fi
                            fi
                        done
                    fi
                    extra_files_array_size=${#student_extra_src_files[@]}
                    extra_n_compilation=$((n_folders_to_compile * extra_files_array_size))
                    student_n_compilations=$((n_compilations + extra_n_compilation))

                    declare -A test_cases_results

                    test_cases_results["student_name"]=$student_name
                    test_cases_results["arquivos_corretos"]=0
                    test_cases_results["nota_arquivos_corretos"]=0
                    test_cases_results["compilacoes_corretas"]=0
                    test_cases_results["nota_compilacoes_corretas"]=0
                    test_cases_results["linkagens_corretas"]=0
                    test_cases_results["nota_linkagens_corretas"]=0
                    test_cases_results["student_n_compilations"]=$student_n_compilations
                    
                    for src_file_name in "${src_files_names[@]}"; do
                        acertos_field=acertos_$src_file_name
                        nota_acertos_field=nota_acertos_$src_file_name
                        acertosval_field=acertosval_$src_file_name
                        nota_acertosval_field=nota_acertosval_$src_file_name
                        test_cases_results[$acertos_field]=0
                        test_cases_results[$acertosval_field]=0
                        test_cases_results[$nota_acertos_field]=0
                        test_cases_results[$nota_acertosval_field]=0
                    done

                    ##########################################
                    # criando os diretorios de resultados para cada aluno
                    ##########################################
                    echo "CRIANDO O DIRETÓRIO DE RESULTADO PARA $student_name:"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}CRIANDO O DIRETÓRIO DE RESULTADO PARA $student_name:\n"
                    # create a directory in the Resultados folder with the student name and copy the content to there
                    STUDENT_RESULT_FOLDER=${DIR_RESULTADOS}/$student_name
                    if test -d "$STUDENT_RESULT_FOLDER"; then
                        rm -r $STUDENT_RESULT_FOLDER
                        sleep 1
                    fi
                    mkdir -p $STUDENT_RESULT_FOLDER
                    if test -d "$STUDENT_RESULT_FOLDER"; then
                        echo " - Diretório $STUDENT_RESULT_FOLDER criado com sucesso!"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Diretório $STUDENT_RESULT_FOLDER criado com sucesso!\n"
                    fi
                    for src_file_name in "${src_files_names[@]}"; do
                        FILE_NAME_FOLDER=$STUDENT_RESULT_FOLDER/$src_file_name
                        mkdir -p $FILE_NAME_FOLDER
                        if test -d "$FILE_NAME_FOLDER"; then
                            echo " - Diretório $FILE_NAME_FOLDER criado com sucesso!"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Diretório $FILE_NAME_FOLDER criado com sucesso!\n"
                        fi
                        # mkdir -p $FILE_NAME_FOLDER/test
                        # if test -d "$FILE_NAME_FOLDER/test"; then
                        #     echo " - Diretório $FILE_NAME_FOLDER/test criado com sucesso!"
                        #     TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Diretório $FILE_NAME_FOLDER/test criado com sucesso!\n"
                        # fi
                    done
                    echo -e " - Arquivos criados: ok!"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos criados: ok!\n"

                    ##########################################
                    # verifica se os arquivos esperados existem
                    ##########################################
                    echo -e "\nCHECKANDO OS ARQUIVOS DO ALUNO:"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nCHECKANDO OS ARQUIVOS DO ALUNO:\n"
                    student_files_missing=0
                    student_files_found=0
                    for src_file_name in "${src_files_names[@]}"; do
                        student_src=$STUDENT_ANSWER_FOLDER/$src_file_name.c
                        student_hdr=$STUDENT_ANSWER_FOLDER/$src_file_name.h
                        
                        if [ ! -f "$student_src" ] && [[ "$src_file_name" != "completo" ]] ; then 
                            echo " - Arquivo esperado '$student_src' não encontrado!"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivo esperado '$student_src' não encontrado!\n"
                            student_files_missing=$(expr $student_files_missing + 1)
                        elif [[ "$src_file_name" != "completo" ]]; then
                            echo " - Arquivo esperado '$student_src' encontrado!"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivo esperado '$student_src' encontrado!\n"
                            student_files_found=$(expr $student_files_found + 1)
                        fi

                        if [ "$HEADER_FILES_EXIST" = "true" ]; then
                            if [ ! -f "$student_hdr" ] && [[ "$src_file_name" != "completo" ]] && [[ "$src_file_name" != "main" ]]; then 
                                echo " - Arquivo esperado '$student_hdr' não encontrado!"
                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivo esperado '$student_hdr' não encontrado!\n"
                                student_files_missing=$(expr $student_files_missing + 1)
                            elif [[ "$src_file_name" != "completo" ]] && [[ "$src_file_name" != "main" ]]; then
                                echo " - Arquivo esperado '$student_hdr' encontrado!"
                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivo esperado '$student_hdr' encontrado!\n"
                                student_files_found=$(expr $student_files_found + 1)
                            fi
                        fi
                    done
                    if [ $student_files_missing -gt 0 ] ; then
                        # test_cases_results["arquivos_faltando"]=$student_files_missing
                        echo -e " - Arquivos esperados enviados: Faltando!"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos esperados enviados: Faltando!\n"
                    else 
                        echo -e " - Arquivos esperados enviados: Ok!"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos esperados enviados: Ok!\n"
                    fi
                    test_cases_results["arquivos_corretos"]=$student_files_found

                    ##########################################
                    # Copiando os arquivos
                    ##########################################
                    echo -e "\nCOPIANDO OS ARQUIVOS PARA A PASTA DE RESULTADO DO ALUNO:"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nCOPIANDO OS ARQUIVOS PARA A PASTA DE RESULTADO DO ALUNO:\n"

                    for src_file_name in "${src_files_names[@]}"; do
                        echo " - Pasta $src_file_name:"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $src_file_name:\n"
                        FILE_NAME_FOLDER=$STUDENT_RESULT_FOLDER/$src_file_name
                        
                        echo "   - Copiando os $DIR_GAB_CASOS de teste para a pasta $FILE_NAME_FOLDER"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os $DIR_GAB_CASOS de teste para a pasta $FILE_NAME_FOLDER\n"
                        cp -r $DIR_GAB_CASOS $FILE_NAME_FOLDER

                        if find "$STUDENT_ANSWER_FOLDER" -maxdepth 1 -type f -name "*.h" | read; then
                            echo "   - Copiando os $STUDENT_ANSWER_FOLDER/*.h do aluno para a pasta $FILE_NAME_FOLDER"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$STUDENT_ANSWER_FOLDER/*.h' do aluno para a pasta $FILE_NAME_FOLDER\n"
                            cp $STUDENT_ANSWER_FOLDER/*.h $FILE_NAME_FOLDER

                            if find "$DIR_GAB_INCLUDES" -maxdepth 1 -type f -name "*.h" | read; then
                                if [[ "$src_file_name" != "completo" ]] ; then
                                    echo "   - Copiando os $DIR_GAB_INCLUDES/*.h do professor para a pasta $FILE_NAME_FOLDER"
                                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$DIR_GAB_INCLUDES/*.h' do professor para a pasta $FILE_NAME_FOLDER\n"
                                    cp $DIR_GAB_INCLUDES/*.h $FILE_NAME_FOLDER
                                fi
                            fi
                        fi

                        echo "   - Copiando os $STUDENT_ANSWER_FOLDER/*.c do aluno para a pasta $FILE_NAME_FOLDER"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando os '$STUDENT_ANSWER_FOLDER/*.c' do aluno para a pasta $FILE_NAME_FOLDER\n"
                        cp $STUDENT_ANSWER_FOLDER/*.c $FILE_NAME_FOLDER
                    done
                    echo -e " - Arquivos copiados: ok!"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos copiados: ok!\n"

                    ##########################################
                    # Compilando os arquivos
                    ##########################################
                    echo -e "\nCOMPILANDO OS ARQUIVOS NA PASTA DE RESULTADO DO ALUNO:"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nCOMPILANDO OS ARQUIVOS NA PASTA DE RESULTADO DO ALUNO:\n"
                    compilation_errors=0
                    correct_compilations=0
                    for src_file_dir in "${src_files_names[@]}"; do
                        echo " - Pasta $src_file_dir:"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $src_file_dir:\n"
                        for src_file_name in "${files_to_compile[@]}"; do
                            if [[ "$src_file_name" == "completo" ]] ; then
                                continue
                            fi
                            source_file=$STUDENT_RESULT_FOLDER/$src_file_dir/$src_file_name.c
                            object_file=$STUDENT_RESULT_FOLDER/$src_file_dir/$src_file_name.o

                            echo "   - Compilando o arquivo $src_file_name.c do aluno, gerando o $src_file_name.o"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Compilando o arquivo $src_file_name.c do aluno, gerando o $src_file_name.o\n"
                            gcc -Wall -c $source_file -o $object_file 2>> $STUDENT_RESULT_FOLDER/$src_file_dir/result_compilation.txt
                            if [ $? -ne 0 ]; then 
                                echo "   - Erro de compilação! Verifique se o arquivo $source_file está correto."
                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Erro de compilação! Verifique se o arquivo $source_file está correto.\n"
                                compilation_errors=$(expr $compilation_errors + 1)
                            else
                                correct_compilations=$(expr $correct_compilations + 1)
                            fi
                        done
                        echo "   - Arquivo de output gerado: $STUDENT_RESULT_FOLDER/$src_file_dir/result_compilation.txt"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Arquivo de output gerado: $STUDENT_RESULT_FOLDER/$src_file_dir/result_compilation.txt.\n"
                    done
                    test_cases_results["compilacoes_corretas"]=$correct_compilations
                    if [ $compilation_errors -gt 0 ] ; then
                        echo -e " - Arquivos Compilados: Erro!: $compilation_errors arquivos com erros de compilacao.\n"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos Compilados: Erro!: $compilation_errors arquivos com erros de compilacao.\n"
                        # test_cases_results["erros_de_compilacao"]=$compilation_errors
                    fi
                    echo " - Copiando os arquivos objetos do professor para cada subpasta do Resultado do $student_name:"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Copiando os arquivos objetos do professor para cada subpasta do Resultado do $student_name:\n"
                    for src_file_dir in "${src_files_names[@]}"; do
                        if [[ "$src_file_dir" == "completo" ]] ; then 
                            continue
                        fi
                        gab_object=$DIR_GAB_OBJ/$src_file_dir.o
                        for src_file_name in "${src_files_names[@]}"; do
                            if [[ "$src_file_name" == "completo" ]] || [[ "$src_file_name" == "$src_file_dir" ]]; then 
                                continue
                            fi
                            echo "   - Copiando o $gab_object para a pasta $STUDENT_RESULT_FOLDER/$src_file_name"
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Copiando o $gab_object para a pasta $STUDENT_RESULT_FOLDER/$src_file_name\n"
                            cp $gab_object $STUDENT_RESULT_FOLDER/$src_file_name
                        done
                    done
                    echo " - Arquivos Compilados: ok!"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos Compilados: ok!\n"

                    ##########################################
                    # Linkando os arquivos compilados
                    ##########################################
                    echo -e "\nLINKANDO OS ARQUIVOS COMPILADOS:"
                    TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nLINKANDO OS ARQUIVOS COMPILADOS:\n"
                    linking_errors=0
                    correct_linkings=0
                    for src_file_dir in "${src_files_names[@]}"; do
                        echo " - Pasta $src_file_dir:"
                        echo "   - Gerando o binário prog linkando com o(s) arquivo(s) $src_file_dir/*.o"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $src_file_dir:\n   - Gerando o binário prog linkando com o(s) arquivo(s) "$src_file_dir/\*.o"\n"
                        gcc -o $STUDENT_RESULT_FOLDER/$src_file_dir/prog $STUDENT_RESULT_FOLDER/$src_file_dir/*.o -lm 2>> $STUDENT_RESULT_FOLDER/$src_file_dir/result_linking.txt
                        if [ $? -ne 0 ]; then 
                            echo -e "   - Arquivos Linkados: Erro! Binário prog não gerado."
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Arquivos Linkados: Erro! Binário prog não gerado.\n"
                            linking_errors=$(expr $linking_errors + 1)
                        else 
                            echo -e "   - Arquivos Linkados: Ok! Binário prog gerado com sucesso."
                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Arquivos Linkados: Ok! Binário prog gerado com sucesso.\n"
                            correct_linkings=$(expr $correct_linkings + 1)
                        fi
                        echo "   - Arquivo de output gerado: $STUDENT_RESULT_FOLDER/$src_file_dir/result_linking.txt"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Arquivo de output gerado: $STUDENT_RESULT_FOLDER/$src_file_dir/result_linking.txt\n"
                    done
                    if [ $linking_errors -gt 0 ] ; then
                        echo " - Arquivos Linkados: Erro! $linking_errors arquivos com erros de linkagem."
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Arquivos Linkados: Erro! $linking_errors arquivos com erros de linkagem.\n"
                        # test_cases_results["erros_de_linkagem"]=$linking_errors
                    fi 
                    test_cases_results["linkagens_corretas"]=$correct_linkings
                    unset files_to_compile

                    ##################################################
                    # Executando o Valgrind 
                    ##################################################

                    if [ "$IGNORE_RESULTS" = "false" ] || [ "$IGNORE_VALGRIND" = "false" ]; then
                        echo -e "\nEXECUTANDO O VALGRIND EM CADA CASO:"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nEXECUTANDO O VALGRIND EM CADA CASO:\n"
                        for src_file_dir in "${src_files_names[@]}"; do
                            DIR_CASES=$STUDENT_RESULT_FOLDER/$src_file_dir/Casos
                            n_cases_folders=0
                            n_correct_answers=0
                            n_correct_valgrinds=0
                            for DIR_CASE in "$DIR_CASES"/*; do
                                (( n_cases_folders++ ))
                                txt_out_files=$(find "$DIR_CASE/saida/" -type f -name "*.txt")
                                if [ -n "$txt_out_files" ]; then
                                    rm -r $DIR_CASE/saida/*.txt
                                fi
                                txt_input_file=$(find "$DIR_CASE" -type f -name "*.txt")

                                case_number=${DIR_CASE##*/}
                                echo " - Pasta $src_file_dir / Caso $case_number:"
                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG} - Pasta $src_file_dir / Caso $case_number:\n"

                                # Valgrind options and arguments
                                # binary=$STUDENT_RESULT_FOLDER/$src_file_dir/prog
                                # valgrind_args="--leak-check=full --log-file=$DIR_CASE/result_valgrind.txt"
                                # output=$(valgrind $valgrind_args $binary < $DIR_CASE/in.txt > "$DIR_CASE/saida/out.txt" 2>&1)
                                
                                txt_input_file=$(find "$DIR_CASE" -maxdepth 1 -type f -name "*.txt" | head -n 1)
                                directory_path=$(dirname "$txt_input_file")
                                filename=$(basename -- "$txt_input_file")   # Get only the file name without the full path
                                filename_no_ext="${filename%.*}"  # Get only the file name without the extension
                                # output="${DIR_CASE}/saida/out_${filename_no_ext}.txt"
                                output="${DIR_CASE}/saida/saida.txt"
                                input_file=$directory_path/entrada.txt
                                # echo "GErando output: $output"
                                filename_out=$(basename -- "$output")   # Get only the file name without the full path

                                binary=$STUDENT_RESULT_FOLDER/$src_file_dir/prog
                                valgrind_args="--leak-check=full --track-origins=yes --log-file=$DIR_CASE/result_valgrind.txt"
                                # output=$(timeout 5 valgrind $valgrind_args $binary < $txt_input_file > $output 2>&1)

                                if [ "$IGNORE_VALGRIND" = "false" ]; then
                                    output=$(timeout 50 valgrind $valgrind_args $binary $directory_path < $input_file > $output 2>&1)
                                else
                                    output=$(timeout 50 $binary $directory_path < $input_file > $output 2>&1)
                                fi

                                # find "." -maxdepth 1 -type f -name "*.txt" ! -name "log.txt" -exec mv {} "${DIR_CASE}/saida/" \;
                                find "." -maxdepth 1 -type f -name "*.txt" ! -name "log.txt" ! -name "pontuacao.txt" -exec mv {} "${DIR_CASE}/saida/" \;
                                # echo "output: $output"
                                # output=$(valgrind $valgrind_args $binary < $DIR_CASE/in.txt > "out.txt" 2>&1)

                                there_is_a_wrong_valgrind=false
                                if [ "$IGNORE_VALGRIND" = "false" ]; then
                                    if [[ -f "$DIR_CASE/result_valgrind.txt" ]]; then
                                        valgrind_result_file=$DIR_CASE/result_valgrind.txt
                                        echo "   - Arquivo de output gerado: $DIR_CASE/result_valgrind.txt."
                                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Arquivo de output gerado: $DIR_CASE/result_valgrind.txt.\n"
                                
                                        # Valgring returns
                                        allocs=0
                                        frees=0
                                        errors=0
                                        contexts=0

                                        # Using while read loop to process each line of the file
                                        while IFS= read -r line; do
                                            if echo "$line" | grep -q "total heap usage"; then
                                                # Extract the allocs (position 5) and frees (position 7) numbers on the string
                                                allocs=$(echo "$line" | awk '{print $5}')
                                                frees=$(echo "$line" | awk '{print $7}')
                                            elif echo "$line" | grep -q "ERROR SUMMARY"; then
                                                # Extract the errors (position 4) and contexts (position 7) numbers on the string
                                                errors=$(echo "$line" | awk '{print $4}')
                                                contexts=$(echo "$line" | awk '{print $7}')
                                            fi
                                        done < "$valgrind_result_file"

                                        # if [[ -f $valgrind_result_file ]]; then 
                                        #     rm -r $valgrind_result_file
                                        # fi

                                        # echo "Test Case: $DIR_CASE" >> $valgrind_result_file
                                        # echo "Valgrind result: allocs: $allocs frees: $frees errors: $errors contexts: $contexts" >> $valgrind_result_file
                                        if test "$allocs" = "$frees" && test "$errors" = "0"; then
                                            echo "   - Valgrind: Ok! allocs: $allocs, frees: $frees, errors: $errors"
                                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Valgrind: Ok! allocs: $allocs, frees: $frees, errors: $errors.\n"
                                        else
                                            echo "   - Valgrind: Incorreto! allocs: $allocs, frees: $frees, errors: $errors"
                                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Valgrind: Incorreto! allocs: $allocs, frees: $frees, errors: $errors.\n"
                                            there_is_a_wrong_valgrind=true
                                        fi
                                    else
                                        echo "   - Valgrind: Incorreto! Verifique se o binário prog foi gerado corretamente. Ou se o Valgrind está instalado."
                                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Valgrind: Incorreto! Verifique se o binário prog foi gerado corretamente. Ou se o Valgrind está instalado.\n"
                                        there_is_a_wrong_valgrind=true
                                    fi
                                fi

                                DIR_CASE_SAIDA=$DIR_CASE/saida
                                txt_file_names=()
                                there_is_a_wrong_answer=false
                                # Loop through all files in the saida folder
                                for gab_case_txt_file in "$DIR_GAB_CASOS/$case_number/saida"/*.txt; do
                                    if [ -f "$gab_case_txt_file" ]; then         # Check if the file is a regular file (not a directory or special file)
                                        # txt_file_names+=("$gab_case_txt_file")       # Add the file name to the array
                                        filename=$(basename -- "$gab_case_txt_file")   # Get only the file name without the full path
                                        txt_file_names+=("$filename")  # Add the file name to the array
                                        filename_no_ext="${filename%.*}"  # Get only the file name without the extension
                                        
                                        student_output_file=$DIR_CASE/saida/$filename
                                        # echo "student_output_file: $student_output_file"

                                        if test -e "$student_output_file"; then
                                            # mv $filename $DIR_CASE_SAIDA
                                            # Making a copy of the professor out.txt file and the student out.txt file, inside the test cases student folder
                                            output_student_copy="$filename_no_ext"_student_copy.txt
                                            output_professor_copy="$filename_no_ext"_professor_copy.txt

                                            cp $DIR_CASE_SAIDA/$filename $DIR_CASE_SAIDA/$output_student_copy
                                            cp $DIR_GAB_CASOS/$case_number/saida/$filename $DIR_CASE_SAIDA/$output_professor_copy

                                            chmod 777 $DIR_CASE_SAIDA/$output_student_copy
                                            chmod 777 $DIR_CASE_SAIDA/$output_professor_copy

                                            # Removing trailing white spaces at end of each line, and removing trailing newlines at the end of the file
                                            sed -i 's/[[:space:]]*$//' "$DIR_CASE_SAIDA/$output_student_copy"
                                            sed -i ':a; /./,$!{N;ba}; /^$/d' "$DIR_CASE_SAIDA/$output_student_copy"
                                            sed -i 's/[[:space:]]*$//' "$DIR_CASE_SAIDA/$output_professor_copy"
                                            sed -i ':a; /./,$!{N;ba}; /^$/d' "$DIR_CASE_SAIDA/$output_professor_copy"
                                            
                                            # Open both files for reading
                                            exec 3< "$DIR_CASE_SAIDA/$output_student_copy"
                                            exec 4< "$DIR_CASE_SAIDA/$output_professor_copy"

                                            files_are_equal="true"

                                            while true; do
                                                # Read a line from each file
                                                read -r line1 <&3
                                                read -r line2 <&4

                                                # Check if we reached the end of both files
                                                if [[ -z "$line1" && -z "$line2" ]]; then
                                                    break
                                                fi

                                                # Ignore blank lines and continue the loop
                                                if [[ -z "$line1" && -z "$line2" ]]; then
                                                    continue
                                                fi

                                                # Compare lines and check for differences
                                                if [[ "$line1" != "$line2" ]]; then
                                                    files_are_equal="false"
                                                fi
                                            done

                                            # Close file descriptors
                                            exec 3<&-
                                            exec 4<&-
                                        
                                            if test "$files_are_equal" = "false"; then
                                                there_is_a_wrong_answer=true
                                                echo "   - Resultado para o $filename: Incorreto!"
                                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Resultado para o $filename: Incorreto!\n"
                                            else
                                                echo "   - Resultado para o $filename: Ok!"
                                                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - Resultado para o $filename: Ok!\n"
                                            fi

                                            rm "$DIR_CASE_SAIDA/$output_student_copy"
                                            rm "$DIR_CASE_SAIDA/$output_professor_copy"
                                        else
                                            echo "   - O aluno não gerou o arquivo de saída $DIR_CASE_SAIDA/$filename, considerando resultado incorreto!"
                                            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}   - O aluno não gerou o arquivo de saída $DIR_CASE_SAIDA/$filename, considerando resultado incorreto!\n"
                                            there_is_a_wrong_answer=true
                                        fi
                                    fi
                                done

                                if [[ "$there_is_a_wrong_answer" = "false" ]]; then
                                    (( n_correct_answers++ ))
                                fi

                                if [[ "$there_is_a_wrong_valgrind" = "false" ]]; then
                                    (( n_correct_valgrinds++ ))
                                fi
                            done

                            grade_for_the_test=$(echo "scale=2; $n_correct_answers / $n_cases_folders * 10.0" | bc)
                            acertos_field=acertos_$src_file_dir
                            test_cases_results[$acertos_field]=$n_correct_answers
                            valgrade_for_the_test=$(echo "scale=2; $n_correct_valgrinds / $n_cases_folders * 10.0" | bc)
                            valacertos_field=valacertos_$src_file_dir
                            test_cases_results[$valacertos_field]=$n_correct_valgrinds

                            # resultados_field=resultados_incorretos_$src_file_dir
                            # ((test_cases_results[$resultados_field]++))
                            # valgrind_field=valgrinds_incorretos_$src_file_dir

                            # test_cases_results[$resultados_field]=$grade_for_the_test
                            # test_cases_results[$valgrind_field]="X"
                        done
                    fi

                    all_students_results[$iteration]=$(declare -p test_cases_results)       
                fi
            done < <(find "$DIR_RESPOSTAS" -mindepth 1 -type d -print0)
        else
            echo -e "\nPasta não encontrada: $DIR_RESPOSTAS\n - Erro! Por favor, crie uma pasta chamada Respostas/ na raíz onde ta o Script e dentro desta pasta crie outra com o seu nome, por exemplo Respostas/JoaoAugusto/ e dentro dessa pasta do seu nome coloque os seus arquivos do código fonte."
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nPasta não encontrada: $DIR_RESPOSTAS\n - Erro! Por favor, crie uma pasta chamada Respostas/ na raíz onde ta o Script e dentro desta pasta crie outra com o seu nome, por exemplo Respostas/JoaoAugusto/ e dentro dessa pasta coloque os seus arquivos do código fonte."
            exit 1
        fi

        echo -e "\n#######################################"
        echo -e "RESULTADOS FINAIS"
        echo -e "#######################################"
        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\n#######################################\nRESULTADOS FINAIS\n#######################################\n"

        # Function to create and fill the CSV file
        create_csv() {
            # CSV file name
            csv_name="Resultado.csv"
            if [[ -f $csv_name ]]; then 
                rm -r $csv_name
            fi
            # CSV header row
            header_csv_str="Nome,Arquivos,Compilação,Linkagem"
            header_csv_created=false

            n_src_files_names=${#src_files_names[@]}
            n_fields_to_consider=3.0
            if [[ "$IGNORE_RESULTS" = "false" ]]; then
                n_fields_to_consider=$(echo "$n_fields_to_consider + $n_src_files_names" | bc)
                # n_fields_to_consider=$((n_fields_to_consider + $n_src_files_names))
            fi
            if [[ "$IGNORE_VALGRIND" = "false" ]]; then
                n_fields_to_consider=$(echo "$n_fields_to_consider + $n_src_files_names" | bc)
            fi
            
            students_number=${#all_students_results[@]}
            for (( i=0; i<students_number; i++ )); do
                # Extract the dictionary string from the main array
                dict_string=${all_students_results[$i]}
                # Evaluate the dictionary string to recreate the dictionary
                eval "$dict_string"
                # Access elements in the dictionary
                echo -e "\n----------------------------------------------------------------------------"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\n----------------------------------------------------------------------------\n"
                echo "Nome $i: ${test_cases_results[student_name]}"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}Nome $i: ${test_cases_results[student_name]}\n"
                # CSV content rows
                content_csv_str="${test_cases_results[student_name]}"
                student_name=${test_cases_results[student_name]}
                student_grades_sum=0.0

                correct_files=${test_cases_results["arquivos_corretos"]}
                grade_for_correct_files=$(echo "scale=3; $correct_files / $n_files * 10.0" | bc)
                grade_decimal_value=$(echo "$grade_for_correct_files" | bc)
                student_grades_sum=$(echo "$student_grades_sum + $grade_decimal_value" | bc)
                trimmed_grade_to_show="${grade_decimal_value%?}"
                if [ "$grade_decimal_value" = "0" ]; then
                    trimmed_grade_to_show="0.00"
                fi
                content_csv_str=$content_csv_str",$trimmed_grade_to_show"
                echo "  - Arquivos Corretos: $correct_files de $n_files / Nota $trimmed_grade_to_show"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Arquivos Corretos: $correct_files de $n_files / Nota $trimmed_grade_to_show\n"

                correct_comps=${test_cases_results["compilacoes_corretas"]}
                grade_for_correct_comps=$(echo "scale=3; $correct_comps / ${test_cases_results[student_n_compilations]} * 10.0" | bc)
                grade_decimal_value=$(echo "$grade_for_correct_comps" | bc)
                student_grades_sum=$(echo "$student_grades_sum + $grade_decimal_value" | bc)
                trimmed_grade_to_show="${grade_decimal_value%?}"
                if [ "$grade_decimal_value" = "0" ]; then
                    trimmed_grade_to_show="0.00"
                fi
                content_csv_str=$content_csv_str",$trimmed_grade_to_show"
                echo "  - Compilações Corretas: $correct_comps de ${test_cases_results[student_n_compilations]} / Nota $trimmed_grade_to_show"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Compilações Corretas: $correct_comps de ${test_cases_results[student_n_compilations]} / Nota $trimmed_grade_to_show\n"

                correct_links=${test_cases_results["linkagens_corretas"]}
                grade_for_correct_links=$(echo "scale=3; $correct_links / $n_linkings * 10.0" | bc)
                grade_decimal_value=$(echo "$grade_for_correct_links" | bc)
                student_grades_sum=$(echo "$student_grades_sum + $grade_decimal_value" | bc)
                trimmed_grade_to_show="${grade_decimal_value%?}"
                if [ "$grade_decimal_value" = "0" ]; then
                    trimmed_grade_to_show="0.00"
                fi
                content_csv_str=$content_csv_str",$trimmed_grade_to_show"
                echo "  - Linkagens Corretas: $correct_links de $n_linkings / Nota $trimmed_grade_to_show"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Linkagens Corretas: $correct_links de $n_linkings / Nota $trimmed_grade_to_show\n"

                for src_file_name in "${src_files_names[@]}"; do
                    if [[ "$IGNORE_RESULTS" = "false" ]] ; then

                        acertos_field=acertos_$src_file_name
                        n_correct_answers=${test_cases_results[$acertos_field]}
                        grade_for_the_test=$(echo "scale=3; $n_correct_answers / $n_cases * 10.0" | bc)
                        grade_decimal_value=$(echo "$grade_for_the_test" | bc)
                        student_grades_sum=$(echo "$student_grades_sum + $grade_decimal_value" | bc)
                        trimmed_grade_to_show="${grade_decimal_value%?}"
                        if [ "$grade_decimal_value" = "0" ]; then
                            trimmed_grade_to_show="0.00"
                        fi
                        header_csv_str=$header_csv_str",Resultado $src_file_name"
                        content_csv_str=$content_csv_str",$trimmed_grade_to_show"
                        echo "  - Resultados Corretos $src_file_name: $n_correct_answers de $n_cases / Nota $trimmed_grade_to_show"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Resultados Corretos $src_file_name: $n_correct_answers de $n_cases / Nota $trimmed_grade_to_show\n"
                    fi
                    if [[ "$IGNORE_VALGRIND" = "false" ]] ; then

                        valacertos_field=valacertos_$src_file_name
                        n_correct_valgrinds=${test_cases_results[$valacertos_field]}
                        valgrade_for_the_test=$(echo "scale=3; $n_correct_valgrinds / $n_cases * 10.0" | bc)
                        valgrade_decimal_value=$(echo "$valgrade_for_the_test" | bc)
                        student_grades_sum=$(echo "$student_grades_sum + $valgrade_decimal_value" | bc)
                        trimmed_grade_to_show="${valgrade_decimal_value%?}"
                        if [ "$valgrade_decimal_value" = "0" ]; then
                            trimmed_grade_to_show="0.00"
                        fi
                        header_csv_str=$header_csv_str",Valgrind $src_file_name"
                        content_csv_str=$content_csv_str",$trimmed_grade_to_show"
                        echo "  - Valgrinds Corretos $src_file_name: $n_correct_valgrinds de $n_cases / Nota $trimmed_grade_to_show"
                        TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Valgrinds Corretos $src_file_name: $n_correct_valgrinds de $n_cases / Nota $trimmed_grade_to_show\n"
                    fi
                done
                
                student_average_grade=$(echo "scale=2; $student_grades_sum / $n_fields_to_consider" | bc)
                trimmed_grade_to_show="${student_grades_sum%?}"
                if [ "$student_grades_sum" = "0" ]; then
                    trimmed_grade_to_show="0.00"
                fi
                echo "  - Soma das notas do $student_name: $trimmed_grade_to_show"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Soma das notas do $student_name: $student_grades_sum\n"


                integer_part=$(echo "$n_fields_to_consider" | awk -F. '{print $1}')
                echo "  - Quantidade de notas: $integer_part"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Campos Considerados: $integer_part\n"
                
                # integer_number=$(expr "$student_average_grade" + 0)
                if [ "$student_average_grade" = "0" ]; then
                    student_average_grade="0.00"
                elif (( $(echo "$student_average_grade < 1" | bc -l) )); then
                    student_average_grade="0""$student_average_grade"
                fi

                echo "  - Média do $student_name: $student_average_grade"
                TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}  - Média do $student_name: $student_average_grade\n"
                content_csv_str=$content_csv_str",$student_average_grade"

                header_csv_str=$header_csv_str",Média"
                if [[ "$header_csv_created" = "false" ]]; then
                    echo $header_csv_str >> "$csv_name"
                    header_csv_created=true
                fi
                echo $content_csv_str >> "$csv_name"
                content_csv_str=""
                header_csv_str=""
            done
            echo -e "\n----------------------------------------------------------------------------"
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\n----------------------------------------------------------------------------\n"
            echo -e "\nArquivo CSV $csv_name com os resultados finais foi gerado na pasta raíz!\n\n" 
            TERMINAL_OUTPUT_LOG="${TERMINAL_OUTPUT_LOG}\nArquivo CSV $csv_name com os resultados finais foi gerado na pasta raíz!\n\n"
            echo -e $TERMINAL_OUTPUT_LOG >> "log.txt"
        }

        create_csv
    fi
}

script_com_pesos


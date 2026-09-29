# Etapa 3 del pipeline. Lee salida/resultado.txt, extrae la secuencia de
# RESULT= y el valor de OPS=, calcula la firma y la escribe en salida/firma.txt.
#
# Firma
#   checksum = 0
#   por cada numero n de la secuencia, checksum = checksum * 31 + n
#   checksum = checksum XOR ops
#   checksum = checksum + 17
# Con un solo resultado equivale a la formula del enunciado, (resultado XOR ops) + 17.
#
# Uso de registros en main
#   $s0 descriptor de archivo
#   $s1 bytes leidos
#   $s2 puntero que recorre la secuencia de RESULT=
#   $s3 valor de OPS
#   $s4 checksum
#   $s5 longitud del texto de salida
# Las subrutinas solo usan registros $t, por eso los valores en $s se conservan
# entre llamadas. main termina con la syscall 10, por eso puede usar jal sin
# guardar $ra.
#
# Limites
#   resultado.txt debe tener menos de 4095 bytes para caber en el buffer.
#   Los numeros son enteros de 32 bits. Si un valor no cabe, da la vuelta
#   (aritmetica modulo 2^32) y la firma sigue siendo la misma para la misma entrada.

        .data
archivo_entrada:    .asciiz "salida/resultado.txt"
archivo_salida:     .asciiz "salida/firma.txt"
clave_result:       .asciiz "RESULT="
clave_ops:          .asciiz "OPS="
prefijo_firma:      .asciiz "FIRMA="
msg_error_abrir:    .asciiz "Error MIPS, no se pudo leer salida/resultado.txt\n"
msg_error_formato:  .asciiz "Error MIPS, resultado.txt no cumple el contrato de RESULT= y OPS=\n"
msg_error_escribir: .asciiz "Error MIPS, no se pudo crear salida/firma.txt\n"
msg_error_tamano:   .asciiz "Error MIPS, resultado.txt tiene 4095 bytes o mas y no cabe en el buffer\n"
buffer:             .space 4096
texto_salida:       .space 64
digitos_tmp:        .space 16

        .text
        .globl main
main:
        # 1. Abrir resultado.txt en modo lectura
        li    $v0, 13
        la    $a0, archivo_entrada
        li    $a1, 0                # 0 = solo lectura
        li    $a2, 0
        syscall
        bltz  $v0, error_abrir      # descriptor negativo = no se pudo abrir
        move  $s0, $v0

        # 2. Leer el archivo completo al buffer
        li    $v0, 14
        move  $a0, $s0
        la    $a1, buffer
        li    $a2, 4095             # deja un byte para el terminador
        syscall
        bltz  $v0, error_abrir
        move  $s1, $v0

        la    $t0, buffer           # terminar el texto con 0 para saber donde acaba
        addu  $t0, $t0, $s1
        sb    $zero, 0($t0)

        li    $v0, 16               # cerrar el archivo
        move  $a0, $s0
        syscall

        li    $t0, 4095             # si se llenaron los 4095 bytes, el archivo pudo quedar incompleto
        beq   $s1, $t0, error_tamano

        # 3. Ubicar la secuencia de RESULT=
        la    $a0, buffer
        la    $a1, clave_result
        jal   buscar_clave
        beqz  $v0, error_formato
        move  $s2, $v0

        # 4. Leer el valor de OPS=
        la    $a0, buffer
        la    $a1, clave_ops
        jal   buscar_clave
        beqz  $v0, error_formato
        move  $s3, $v0              # guardar la posicion para detectar si no hubo numero
        move  $a0, $v0
        jal   leer_entero
        beq   $v1, $s3, error_formato
        move  $s3, $v0

        # 5. Recorrer la secuencia y acumular el checksum
        li    $s4, 0
        lb    $a0, 0($s2)
        jal   es_fin
        bnez  $v0, fin_secuencia    # RESULT= vacio, la secuencia no tiene elementos
siguiente_elemento:
        move  $a0, $s2
        jal   leer_entero
        beq   $v1, $s2, error_formato   # no habia un numero valido
        li    $t0, 31
        mul   $s4, $s4, $t0         # checksum = checksum * 31 + n
        addu  $s4, $s4, $v0         # addu no genera excepcion si hay desbordamiento
        move  $s2, $v1
        lb    $t1, 0($s2)
        li    $t0, 44               # 44 = ','
        bne   $t1, $t0, revisar_fin
        addiu $s2, $s2, 1           # saltar la coma y seguir con el siguiente numero
        j     siguiente_elemento
revisar_fin:
        move  $a0, $t1
        jal   es_fin
        beqz  $v0, error_formato    # despues de un numero solo puede venir coma o fin de linea
fin_secuencia:

        # 6. Operacion logica y operacion aritmetica
        xor   $s4, $s4, $s3         # checksum = checksum XOR ops
        addiu $s4, $s4, 17          # checksum = checksum + 17

        # 7. Armar el texto FIRMA=<numero> en memoria
        la    $a0, prefijo_firma
        la    $a1, texto_salida
        jal   copiar_texto
        move  $a0, $s4
        move  $a1, $v0
        jal   entero_a_texto
        li    $t0, 10               # 10 = salto de linea
        sb    $t0, 0($v0)
        sb    $zero, 1($v0)
        addiu $v0, $v0, 1
        la    $t1, texto_salida
        subu  $s5, $v0, $t1         # longitud del texto

        # 8. Escribir firma.txt
        li    $v0, 13
        la    $a0, archivo_salida
        li    $a1, 1                # 1 = escritura, crea o reemplaza el archivo
        li    $a2, 0
        syscall
        bltz  $v0, error_escribir
        move  $s0, $v0

        li    $v0, 15
        move  $a0, $s0
        la    $a1, texto_salida
        move  $a2, $s5
        syscall

        li    $v0, 16
        move  $a0, $s0
        syscall

        # 9. Mostrar la firma en consola y terminar
        li    $v0, 4
        la    $a0, texto_salida
        syscall
        li    $v0, 10               # 10 = terminar con codigo 0
        syscall

# Errores, muestran un mensaje y terminan con codigo 1
error_abrir:
        la    $a0, msg_error_abrir
        j     terminar_con_error
error_formato:
        la    $a0, msg_error_formato
        j     terminar_con_error
error_escribir:
        la    $a0, msg_error_escribir
        j     terminar_con_error
error_tamano:
        la    $a0, msg_error_tamano
terminar_con_error:
        li    $v0, 4
        syscall
        li    $v0, 17               # 17 = terminar con codigo de salida, aqui 1
        li    $a0, 1
        syscall

# buscar_clave
# Entrada  $a0 texto, $a1 clave
# Salida   $v0 direccion justo despues de la clave, o 0 si ninguna linea empieza con ella
# Solo compara al inicio de cada linea, asi las lineas de traza no se confunden con la clave
buscar_clave:
        move  $t0, $a0              # inicio de la linea actual
linea_actual:
        lb    $t1, 0($t0)
        beqz  $t1, clave_no_encontrada
        move  $t2, $t0
        move  $t3, $a1
comparar:
        lb    $t4, 0($t3)
        beqz  $t4, clave_encontrada # se recorrio toda la clave sin diferencias
        lb    $t5, 0($t2)
        bne   $t4, $t5, saltar_linea
        addiu $t2, $t2, 1
        addiu $t3, $t3, 1
        j     comparar
clave_encontrada:
        move  $v0, $t2
        jr    $ra
saltar_linea:
        lb    $t1, 0($t0)
        beqz  $t1, clave_no_encontrada
        addiu $t0, $t0, 1
        li    $t6, 10               # 10 = salto de linea
        bne   $t1, $t6, saltar_linea
        j     linea_actual
clave_no_encontrada:
        li    $v0, 0
        jr    $ra

# leer_entero
# Entrada  $a0 direccion del primer caracter
# Salida   $v0 valor, $v1 direccion del primer caracter que no es parte del numero
#          Si no hay digitos, $v1 = $a0
leer_entero:
        move  $t0, $a0
        li    $t1, 0                # valor acumulado
        li    $t2, 0                # 1 si el numero es negativo
        lb    $t3, 0($t0)
        li    $t4, 45               # 45 = '-'
        bne   $t3, $t4, inicio_digitos
        li    $t2, 1
        addiu $t0, $t0, 1
inicio_digitos:
        move  $t5, $t0
leer_digito:
        lb    $t3, 0($t0)
        li    $t4, 48               # 48 = '0'
        blt   $t3, $t4, fin_digitos # blt y bgt son pseudoinstrucciones, se traducen a slt y bne
        li    $t4, 57               # 57 = '9'
        bgt   $t3, $t4, fin_digitos
        addiu $t3, $t3, -48         # caracter a valor numerico
        li    $t4, 10
        mul   $t1, $t1, $t4         # valor = valor * 10 + digito
        addu  $t1, $t1, $t3
        addiu $t0, $t0, 1
        j     leer_digito
fin_digitos:
        beq   $t0, $t5, sin_digitos
        beqz  $t2, entero_listo
        subu  $t1, $zero, $t1       # aplicar el signo negativo
entero_listo:
        move  $v0, $t1
        move  $v1, $t0
        jr    $ra
sin_digitos:
        li    $v0, 0
        move  $v1, $a0
        jr    $ra

# es_fin
# Entrada  $a0 caracter
# Salida   $v0 = 1 si es fin de texto (0), salto de linea (10) o retorno (13), si no 0
es_fin:
        li    $v0, 1
        beqz  $a0, es_fin_listo
        li    $t9, 10
        beq   $a0, $t9, es_fin_listo
        li    $t9, 13
        beq   $a0, $t9, es_fin_listo
        li    $v0, 0
es_fin_listo:
        jr    $ra

# copiar_texto
# Entrada  $a0 texto de origen terminado en 0, $a1 destino
# Salida   $v0 direccion del destino justo despues del ultimo caracter copiado
copiar_texto:
        lb    $t0, 0($a0)
        beqz  $t0, copia_lista
        sb    $t0, 0($a1)
        addiu $a0, $a0, 1
        addiu $a1, $a1, 1
        j     copiar_texto
copia_lista:
        move  $v0, $a1
        jr    $ra

# entero_a_texto
# Entrada  $a0 valor, $a1 destino
# Salida   $v0 direccion del destino justo despues del ultimo digito
# Divide entre 10 repetidamente. Los digitos salen al reves y luego se copian en orden.
entero_a_texto:
        move  $t0, $a0
        move  $t1, $a1
        bgez  $t0, convertir
        li    $t2, 45               # 45 = '-'
        sb    $t2, 0($t1)
        addiu $t1, $t1, 1
        subu  $t0, $zero, $t0       # trabajar con el valor absoluto
convertir:
        la    $t3, digitos_tmp
        move  $t4, $t3
        li    $t5, 10
dividir:
        divu  $t0, $t5
        mfhi  $t6                   # residuo, el ultimo digito
        mflo  $t0                   # cociente
        addiu $t6, $t6, 48          # valor a caracter
        sb    $t6, 0($t4)
        addiu $t4, $t4, 1
        bnez  $t0, dividir
invertir:
        addiu $t4, $t4, -1
        lb    $t6, 0($t4)
        sb    $t6, 0($t1)
        addiu $t1, $t1, 1
        bne   $t4, $t3, invertir
        move  $v0, $t1
        jr    $ra

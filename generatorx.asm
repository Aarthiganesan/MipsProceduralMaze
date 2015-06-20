# VARIABILI GLOBALI (persistenti e utilizzabili per un singolo scopo in qualsiasi punto del codice):
#	$s0 seed
#	$s1 string pointer dinamico
#	$s2 string pointer statico
#	$s3 contiene il contatore delle celle esplorate

# STATO DIREZIONI[0:inesplorata, 1:esplorata, 2:provenienza]:
#	$s4 nord
#	$s5 est
#	$s6 sud
#	$s7 ovest

.data

spbackup: .word 0
wh: .space 2				#alloco lo spazio di due byte per salvare le variabili larghezza (w) e altezza (h)
labirinto: .space 1157 		#alloco lo spazio massimo (necessario per un labirinto 16x16) potevo usare sbrk per allocare dinamicamente la memoria

benvenuto: .asciiz "\nGeneratore procedurale di labirinti in MIPS"
saluto: .asciiz "\nProgramma terminato!\nCreato da Ciacco Davide 794163"
stringX: .asciiz " Inserire la larghezza del labirinto [4..16]: "
stringY: .asciiz " Inserire l'altezza del labirinto [4..16]: "
stringS: .asciiz " Inserire il seed: "

.text
main:

#################################
# PROCEDURA DI INIZIALIZZAZIONE #
#################################
init:
	#salva $sp iniziale
	la $t0, spbackup
	sw $sp, ($t0)

	#chiede all'utente di inserire la larghezza (in celle) del labirinto
	li $v0, 4				# selezione di print_string (codice = 4)
	la $a0, stringX			# $a0 = indirizzo di string1
	syscall					# lancio print_string
	li $v0, 5				# Selezione read_int (codice = 5)
	syscall

	blt $v0, 2, init 		#w>=2
	bgt $v0, 16, init 		#w<=16

	la $t1, wh				#carica in $t1 l'indirizzo di wh
	sb $v0, ($t1)			#salva la larghezza nella memoria

	#chiede all'utente di inserire l'altezza (in celle) del labirinto
	li $v0, 4				# selezione di print_string (codice = 4)
	la $a0, stringY			# $a0 = indirizzo di string1
	syscall					# lancio print_string
	li $v0, 5				# Selezione read_int (codice = 5)
	syscall

	blt $v0, 2, init 		#h>=2
	bgt $v0, 16, init 		#h<=16

	sb $v0, 1($t1)			#salva l'altezza nella memoria

	#ottenute le dimensioni del labirinto da generare, si crea la stringa in cui verrà "scolpito" il labirinto
	la $s1, labirinto 		#carica l'indirizzo di labirinto in $s1
	#start doppio for x,y
	lb $t3, 1($t1) 			#carico l'altezza in t2
	mul $t3, $t3, 2			#
	addi $t3, $t3, 1		#calcolo il numero di righe necessario per disegnare il labirinto in altezza
	fory:
		lb $t2, ($t1)			#carico la x in t1
		mul $t2, $t2, 2			#
		addi $t2, $t2, 1		#calcolo il numero di colonne necessario per disegnare il labirinto in larghezza

		forx:
			addi $a0, $zero, 35		#carico il carattere '#' in $a0 per passarlo alla funzione storeChar
			jal storeChar

			addi $s1, $s1, 1		#sposto il puntatore dinamico sul prossimo byte/carattere
			addi $t2, $t2, -1		#larghezza--
			bne $t2, $zero, forx	#if(larghezza==0)return;

		addi $a0, $zero, 10		#carico il carattere '\n' in $a0 per passarlo alla funzione storeChar
		jal storeChar

		addi $s1, $s1, 1		#sposto il puntatore dinamico sul prossimo byte/carattere
		addi $t3, $t3, -1		#altezza--
		bne $t3, $zero, fory	#if(altezza==0)return;

	addi $a0, $zero, 0	#carico il carattere '\0' in $a0 per passarlo alla funzione storeChar
	jal storeChar
	#fine della generazione della stringa

	la $s2, labirinto 	#$s2 (puntatore statico) mi serve per calcolare l'offset sulla stringa $s1 > $s2+11
	la $s1, labirinto	#carica l'indirizzo di labirinto in $s1 (puntatore dinamico)

	jal seed			#si chiede all'utente di inserire un seed per la generazione di numeri pseudocasuali

	#GENERO LE COORDINATE INIZIALI
	la $t1, wh
	lb $t8, 0($t1) 		#salvo la larghezza in $t8
	add $a0, $zero, $t8	#passo la larghezza alla procedura rand
	jal rand 			#GENERA la X iniziale
	add $t3, $zero, $v0 #salva la x in $t3

	lb $t9, 1($t1) 		#salvo l'altezza in $t9
	add $a0, $zero, $t9	#passo l'altezza alla procedura rand
	jal rand 			#GENERA la Y iniziale
	add $t4, $zero, $v0 #salva la y in $t4

	#DETERMINO L'OFFSET SULLA STRINGA DEL LABIRINTO e lo salvo in $t2
	mul $t3, $t3, 2		# (2*x)
	mul $t5, $t8, 4		#          4*larghezza
	addi $t5, $t5, 4	#          4*larghezza+4
	mul $t4, $t4, $t5	#         (4*larghezza+4)*y

	add $t2, $t3, $t4	# (2*x) + (4*larghezza+4)*y
	add $t2, $t2, $t8	# (2*x) + (4*larghezza+4)*y +   larghezza
	add $t2, $t2, $t8	# (2*x) + (4*larghezza+4)*y + 2*larghezza
	addi $t2, $t2, 3	# (2*x) + (4*larghezza+4)*y +(2*larghezza+3)

	#POSIZIONO IL PUNTO DI PARTENZA
	add $s1, $s1, $t2	#sposto il puntatore dinamico sulla cella di partenza
	li $a0, 65			#carico il carattere A di partenza in $t0
	jal storeChar		#salva il carattere A nel labirinto

	addi $a1, $zero, 4 	#direzione di provenienza nulla
	addi $s3, $zero, 1	#setta 'celle esplorate' a uno (mi trovo già sulla prima cella)
	#imposto le direzioni tutte a 'inesplorate'
	addi $s4, $zero, 0	#nord
	addi $s5, $zero, 0	#est
	addi $s6, $zero, 0	#sud
	addi $s7, $zero, 0	#ovest

	j passoAvanti 		#passa alla funzione ricorsiva (tenta di fare il primo passo avanti)

############################
# PROCEDURA DI GENERAZIONE #
############################
passoAvanti:	#passoAvanti(provenienza $a1)

	#controlla se tutte le celle sono state esplorate ($s3==16)
	mul $t7, $t8, $t9	#numero di celle esplorabili (lo posso calcolare ogni volta visto che e' storato in dei registri temporanei, ma per ora e' uno spreco di risorse anche se non conforme alle convenzioni MIPS)
	beq $s3, $t7, termina #il termina stampera' direttamente la B

	ricalcolaDirezione:
	#controlla se tutte le direzioni sono state provate
	beq $s4, $zero, continua
	beq $s5, $zero, continua
	beq $s6, $zero, continua
	beq $s7, $zero, continua
	j passoIndietro				#se tutte le direzioni sono state provate allora torna indietro
	continua:

	#GENERO LA PROSSIMA DIREZIONE DA PROVARE
	addi $a0, $zero, 4		#set dell'argomento da passare a rand
	jal rand 				#GENERA la direzione e la controlla
	add $a1, $zero, $v0		#salva la direzione di movimento per passarla al passo avanti
	beq $v0, $zero, nord 	#0:nord
	addi $v0, $v0, -1
	beq $v0, $zero, est 	#1:est
	addi $v0, $v0, -1
	beq $v0, $zero, sud 	#2:sud
	addi $v0, $v0, -1
	beq $v0, $zero, ovest 	#3:ovest
	j ExitSwitch	#jump inutile... ATTENZIONE: rand porta $t0 a 0, quindi non possiamo più ricavarne la dir di prov per il passo successivo!

	nord:
	#controlla se la destinazione è già stata provata
	bne $s4, 0, ricalcolaDirezione
	#segna che ha considerato questa direzione
	addi $s4, $zero, 1
	#controlla se può andare a nord
	mul $t7, $t8, 2		# 2*larghezza
	addi $t7, $t7, 2	#(2*larghezza + 2)
	mul $t7, $t7, 3		#(2*larghezza + 2)*2
	add $t1, $s2, $t7
	blt $s1, $t1, ricalcolaDirezione
	#controlla se la destinazione è già stata esplorata anche da qualche altro punto

	mul $t7, $t8, 4
	addi $t7, $t7, 4

	sub $t1, $s1, $t7
	lb $t1, ($t1)
	bne $t1, 35, ricalcolaDirezione	#se è # allora non è ancora esplorato (carattere 35 = #)

	li $a0, 46			#carico il carattere '.' in $a0 per passarlo alla funzione storeChar
	div $t7, $t7, 2
	sub $s1, $s1, $t7
	jal storeChar
	sub $s1, $s1, $t7
	jal storeChar
	j ExitSwitch

	est:
	#controlla se la destinazione è già stata provata
	bne $s5, 0, ricalcolaDirezione
	#segna che ha considerato questa direzione
	addi $s5, $zero, 1
	#controlla se può andare a est

	mul $t7, $t8, 2
	addi $t7, $t7, 3
	sub $t6, $s1, $s2 	#$s1-$s2
	sub $t7, $t6, $t7 	#($s1-$s2)-(2*larghezza+3)
	addi $t6, $t8, -1 	#(x-1)
	mul $t6, $t6, 2  	#2*(x-1)
	add $t7, $t7, $t6 	#2*(x-1)+($s1-$s2)-(2*larghezza+3)
	beq $t7, $zero, ricalcolaDirezione

	mul $t6, $t8, 2		# 2*larghezza
	addi $t6, $t6, 2	#(2*larghezza + 2)
	mul $t6, $t6, 2		#(2*larghezza + 2)*2
	div $t7, $t7, $t6
	mfhi $t7
	beq $t7, $zero, ricalcolaDirezione

	#controlla se la destinazione è già stata esplorata
	addi $t1, $s1, 2
	lb $t1, ($t1)
	bne $t1, 35, ricalcolaDirezione	#se è # allora non è ancora esplorato (carattere 35 = #)

	li $a0, 46			#carico il carattere '.' in $a0 per passarlo alla funzione storeChar
	addi $s1, $s1, 1
	jal storeChar
	addi $s1, $s1, 1
	jal storeChar
	j ExitSwitch

	sud:
	#controlla se la destinazione è già stata provata
	bne $s6, 0, ricalcolaDirezione
	#segna che ha considerato questa direzione
	addi $s6, $zero, 1
	#controlla se può andare a sud

	mul $t7, $t8, 2
	addi $t7, $t7, 2
	mul $t6, $t9, 2
	addi $t6, $t6, 2
	mul $t7, $t7, $t6	#lunghezza stringa
	mul $t6, $t8, 2		#larghezza*2
	addi $t6, $t6, 2	#larghezza*2)+2
	mul $t6, $t6, 3
	sub $t7, $t7, $t6

	add $t1, $s2, $t7
	bgt $s1, $t1, ricalcolaDirezione
	#controlla se la destinazione è già stata esplorata

	#prima ricalcola la cella sotto
	mul $t7, $t8, 4
	addi $t7, $t7, 4

	add $t1, $s1, $t7
	lb $t1, ($t1)
	bne $t1, 35, ricalcolaDirezione	#se è # allora non è ancora esplorato (carattere 35 = #)

	li $a0, 46			#carico il carattere '.' in $a0 per passarlo alla funzione storeChar
	div $t7, $t7, 2
	add $s1, $s1, $t7
	jal storeChar
	add $s1, $s1, $t7
	jal storeChar
	j ExitSwitch

	ovest:
	#controlla se la destinazione è già stata provata
	bne $s7, 0, ricalcolaDirezione
	#segna che ha considerato questa direzione
	addi $s7, $zero, 1
	#controlla se può andare a ovest

	mul $t7, $t8, 2
	addi $t7, $t7, 3
	sub $t6, $s1, $s2 #$s1-$s2
	sub $t7, $t6, $t7 #($s1-$s2)-(2*larghezza+3)
	beq $t7, $zero, ricalcolaDirezione

	mul $t6, $t8, 2		# 2*larghezza
	addi $t6, $t6, 2	#(2*larghezza + 2)
	mul $t6, $t6, 2		#(2*larghezza + 2)*2
	div $t7, $t7, $t6
	mfhi $t7
	beq $t7, $zero, ricalcolaDirezione


	#controlla se la destinazione è già stata esplorata
	addi $t1, $s1, -2
	lb $t1, ($t1)
	bne $t1, 35, ricalcolaDirezione	#se è # allora non è ancora esplorato (carattere 35 = #)

	li $a0, 46			#carico il carattere '.' in $a0 per passarlo alla funzione storeChar
	addi $s1, $s1, -1
	jal storeChar
	addi $s1, $s1, -1
	jal storeChar
	j ExitSwitch

	ExitSwitch:

	#stack save
	addi $sp, $sp, -4
	sb $s7, 3($sp)
	sb $s6, 2($sp)
	sb $s5, 1($sp)
	sb $s4, 0($sp)

	addi $s3, $s3, 1 #aggiungi 1 alle celle esplorate (solo quando si muove in avanti)

	#setta la provenienza (invertita perche' dovra' essere usata dalla prossima posizione)
	add $t0, $zero, $a1
	bne $t0, $zero, notNord
	addi $s4, $zero, 0
	addi $s5, $zero, 0
	addi $s6, $zero, 2
	addi $s7, $zero, 0
	j notOvest
	notNord:
	addi $t0, $t0, -1
	bne $t0, $zero, notEst
	addi $s4, $zero, 0
	addi $s5, $zero, 0
	addi $s6, $zero, 0
	addi $s7, $zero, 2
	j notOvest
	notEst:
	addi $t0, $t0, -1
	bne $t0, $zero, notSud
	addi $s4, $zero, 2
	addi $s5, $zero, 0
	addi $s6, $zero, 0
	addi $s7, $zero, 0
	j notOvest
	notSud:
	addi $t0, $t0, -1
	bne $t0, $zero, notOvest
	addi $s4, $zero, 0
	addi $s5, $zero, 2
	addi $s6, $zero, 0
	addi $s7, $zero, 0
	notOvest:

	j passoAvanti






passoIndietro:
	#fa un passo indietro nella direzione da cui era arrivato (0:sud,1:ovest,2:nord,3:est)
	beq $s4, 2, backToNord
	beq $s5, 2, backToEst
	beq $s6, 2, backToSud
	beq $s7, 2, backToOvest

	#j wentBack
	j termina #dovrebbe essere impossibile arrivare qui, giusto?

	backToNord:
	mul $t7, $t8, 2		# 2*larghezza
	addi $t7, $t7, 2	#(2*larghezza + 2)

	li $a0, 32			#carico il carattere ' ' in $a0 per passarlo alla funzione storeChar
	jal storeChar
	sub $s1, $s1, $t7
	jal storeChar
	sub $s1, $s1, $t7
	j wentBack

	backToEst:
	li $a0, 32			#carico il carattere ' ' in $a0 per passarlo alla funzione storeChar
	jal storeChar
	addi $s1, $s1, 1
	jal storeChar
	addi $s1, $s1, 1
	j wentBack

	backToSud:
	mul $t7, $t8, 2		# 2*larghezza
	addi $t7, $t7, 2	#(2*larghezza + 2)

	li $a0, 32			#carico il carattere ' ' in $a0 per passarlo alla funzione storeChar
	jal storeChar
	add $s1, $s1, $t7
	jal storeChar
	add $s1, $s1, $t7
	j wentBack

	backToOvest:
	li $a0, 32			#carico il carattere ' ' in $a0 per passarlo alla funzione storeChar
	jal storeChar
	addi $s1, $s1, -1
	jal storeChar
	addi $s1, $s1, -1
	j wentBack

	wentBack:
	#stack reload
	lb $s7, 3($sp)
	lb $s6, 2($sp)
	lb $s5, 1($sp)
	lb $s4, 0($sp)
	addi $sp, $sp, 4


	j passoAvanti





###################
# ALTRE PROCEDURE #
###################
seed:
	li $v0, 4				# selezione di print_string (codice = 4)
	la $a0, stringS			# $a0 = indirizzo di string1
	syscall					# lancio print_string

	li $v0, 5				# Selezione read_int (codice = 5)
	syscall

	beq $v0, $zero, seed 	#IL SEED DEVE ESSERE DIVERSO DA 0
	add $s0, $zero, $v0		# memorizzo il seed iniziale in $s0

	jr $ra


rand:	#restituisce in $v0 un valore pseudorandom [0..$a0]
	srl $t0, $s0, 3			#shift a destra di 2
	xor $s0, $s0, $t0		#xor tra seed e shiftato
	sll $t0, $s0, 5			#shift a sinistra di 6
	xor $s0, $s0, $t0		#xor tra seed e shiftato

	div $t0, $s0, $a0	#divide per il valore passato attraverso $a0
	mfhi $t0
	abs $v0 $t0  #l'abs potrebbe essere semplice usando una xor?
	jr $ra


storeChar:				# void storeChar($a0) accetta un byte per salvare il corrispondente ascii nella stringa
	sb $a0, ($s1)		#salva il char contenuto in $a0 #dovrei passargli anche $s1? o è una "variabile globale"?
	jr $ra




#############################
# PROCEDURA DI TERMINAZIONE #
#############################
termina:	#da migliorare con menu per la scelta: 0:termina 1:reset e restart!

	li $a0, 66			#carico il carattere B di arrivo in $a0
	jal storeChar		#salva il carattere A nel labirinto

	li $v0, 4				# selezione di print_string
	la $a0, labirinto		# $a0 = indirizzo di string2
	syscall					# lancio print_string

	li $v0, 4		#stampo l'autore del programma
	la $a0, saluto
	syscall


	resetStack:
	la $t0, spbackup
	lw $t0, ($t0)
	add $sp, $zero, $t0



	j init	#ORA CONTINUA ALL'INFINITO CHIEDENDO SEMPRE NUOVI SEEDS

	li $v0, 10     	#termino il programma tramite syscall apposita
	syscall

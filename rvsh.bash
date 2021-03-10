#!/bin/bash
trap '' 2; # Commande trap permettant de bloquer le [CTRL+C]

flechehaut=$'\x1b[A'; # Définit la variable qui contient la valeur de la flèche du haut
flechebas=$'\x1b[B'; # Définit la variable qui contient la valeur de la flèche du bas
PROGRAMME_EN_COURS=0; # Variable permettant 

# Fonction erreur qui affiche différents types d'erreurs en fonction de l'argument passé en entrée de la fonction
function erreur {
	case $1 in
		1 )
			echo "Erreur 1. Le nombre d'arguments en entrée de la commande doit être égal à 2 ou 3 en fonction du mode utilisé.";
			echo "En mode connect: rvsh -connect nom_de_la_machine nom_de_l'utilisateur.";
			echo "En mode admin: rvsh -admin mot_de_passe_administrateur.";;
		2 )
			echo "Erreur 2. Le fichier machines n'existe pas.";;
		3 )
			echo "Erreur 3. Le fichier utilisateurs n'existe pas.";;
		4 )
			echo "Erreur 4. Le nom de machine que vous avez entré est inconnu.";;
		5 )
			echo "Erreur 5. Le nom d'utilisateur que vous avez entré n'existe pas.";;
		6 )
			echo "Erreur 6. Cet utilisateur n'a pas l'accès sur cette machine ou cette machine n'existe pas.";;
		7 )
			echo "Erreur 7. Vous avez rentré le mauvais de mot de passe à plus de 3 reprises.";
			echo "L'authentification a échoué.";;
		8 ) 
			echo "Erreur 8. Nombre d'arguments incorrect, tapez la commande help pour plus d'informations.";;
		9 ) 
			echo "Erreur 9. Pas d'espace dans le mot de passe.";;
		10 )
			echo "Erreur 10. L'utilisateur n'existe pas.";;
		11 ) 
			echo "Erreur 11. Option invalide. -a pour ajouter une machine -d pour supprimer une machine.";;
		12 ) 
			echo "Erreur 12. Commande incorrecte. Utilisez la commande help afficher l'aide." ;;
		13 )
			echo "Erreur 13. L'option entrée n'existe pas. Les options disponibles sont les suivantes: -a (pour ajouter un utilisateur -d (pour supprimer) -ma (pour modifier les accès).";;
		14 )
			echo "Erreur 14. Mot de passe administrateur incorrect.";
	esac
	if [[ $PROGRAMME_EN_COURS == 0 ]]; then
		exit 1; # Si on est pas encore entrés dans la commande on sort du programme dès qu'il y a une erreur
	else
		return 1; # Sinon on reste dans la commande pour laisser une nouvelle chance à l'utilisateur
	fi
}

# Fonction apropos décrivant les commandes indispensables et les auteurs de la commande
function apropos {
	echo "############ Commande rvsh ############";
	echo "Pour l'aide, tapez la commande help.";
	echo "Tapez exit pour sortir de l'invite de commandes."
	echo "Enjoy it!";
}

# Fonction verifNbArguments permettant de vérifier si le nombre d'arguments passés en entrée de la commande est correct
function verifNbArguments { # Argument 1: nombre d'arguments en entrée de la commande Argument 2: premier argument de la commande
	if [[ ! $1 -eq 3 ]]; then # Si le nombre d'arguments n'est pas égal à 3
		if [[ $1 -eq 2 && $2 == "-admin" ]]; then # Si le nombre d'arguments est égal à 1 et que celui-ci est égal à "-admin"
			if [[ $3 == "admin" ]] ; then # On vérifier le mot de passe
				PROGRAMME_EN_COURS=1; # On affecte 1 à la variable PROGRAMME_EN_COURS pour dire qu'on rentre dans la commande
				promptAdmin; # On lance le prompt administrateur
			else
				erreur 14; # On lance l'erreur 14
			fi;
		else
			erreur 1; # Sinon on lance l'erreur 1 (voir plus haut)
		fi
	else
		if [[ $2 != "-connect" ]]; then # Si l'argument 1 de la commande n'est pas égal à "-connect"
			erreur 1; # On lance l'erreur 1
		fi
	fi
}

# Fonction verifFichiers permettant de vérifier si les fichiers machines et utilisateurs existent si ils n'existent pas on lance l'erreur 2 ou 3 en fonction du fichier manquant
function verifFichiers {
	if [[ ! -f "machines.txt" ]]; then
		erreur 2;
	elif [[ ! -f "utilisateurs.txt" ]]; then
		erreur 3;
	fi
}

# Fonciton verifNomMachine permettant de vérifier si le nom de la machine qu'on a rentré dans la commande existe
function verifNomMachine { # Argument 1: nom de la machine rentré par l'utilisateur
	machineFound=0;
	while read ligne  # Lecture du fichier machines.txt contenant toutes les machines rattachées au réseau virtuel
	do
		if [[ "$ligne" == "$1" ]]; then # Si on trouve la machine dans le fichier
			machineFound=1; # On affecte 1 à la variable machineFound
		fi	
	done < machines.txt
	if [[ $machineFound == 0 ]]; then # Si on a pas trouvé la machine dans le fichier
		erreur 4; # On lance l'erreur 4
	fi

}

# Fonction verifUtilisateur permettant de vérifier si l'utilisateur rentré dans la commande existe
function verifUtilisateur { #  Argument 1 : utilisateur   Argument 2 : machine
	# L'utilisateur existe dans le fichier
	if [[ $1 == $(egrep -w $1 utilisateurs.txt | cut -f1 -d' ') ]]; then # Grâce au egrep on récupère la ligne de l'utilisateur recherché et le cut nous permet de récupérer uniquement le nom de l'utilisateur, on vérifie ensuite la correspondance
		verifAcces $1 $2; # Si l'utilisateur existe bien, on lance la fonction verifAcces afin de voir si cette utilisateur a bien accès à la machine souhaitée
	else
		erreur 5; # Sinon on lance l'erreur 5 (voir plus haut)
	fi
}

# Fonction verifAcces permettant de voir si l'utilisateur a bien accès à la machine souhaitée
function verifAcces { #  Argument 1 : utilisateur   Argument 2 : machine
	if [[ $(grep -w $1 utilisateurs.txt | grep -w -o $2) != $2 ]] ; then # Le premier grep nous permet de récupérer la ligne de l'utilisateur puis on envoie la ligne dans un pipe où on vérifie si la machine existe sur cette ligne
		erreur 6; # Si elle n'existe pas on lance l'erreur 6
	else
		return 0; # Sinon on renvoie 0 pour dire que c'est bon
	fi
}

# Fonction verifMdp permettant de vérifier si l'utilisateur rentre le bon mot de passe
function verifMdp { # Argument 1: utilisateur
	essai=3; # On donne 3 essais à l'utilisateur
	wpGivenByUser=0; 
	mdp=$(grep -w $1 utilisateurs.txt | cut -f2 -d' ');	# Le grep permet de récupérer la ligne de l'utilisateur en question puis le cut permet de récupérer le mot de passe situé sur la 2ème colonne
	while [[ $wpGivenByUser != $mdp && $essai -gt 0 ]] # Tant que le mot de passe donné par l'utilisateur est faux et que le nombre d'essais n'est pas nul
	do
		echo "Vous avez $essai essais."; # Affiche le nombre d'essais restant
		stty -echo; # Permet de désactiver l'echo sur le terminal afin qu'on ne voie pas le mot de passe rentré
		read -p "Mot de passe : " wpGivenByUser ; # Lit le mot de passe
		essai=$((essai-1)); # Décrémente la variable essai
		stty echo; # Réactive l'echo sur le terminal
		echo ""; # Saute une ligne
	done
	if [[ $wpGivenByUser != $mdp ]]; then # Si le mot de passe n'a pas été trouvé au bout de 3 fois
		erreur 7; # On lance l'erreur 7
	else
		return 0; # Sinon on retourne 0 pour dire que c'est bon
	fi
}

# Fonction ajoutLog permettant d'ajouter un log au fichier connexion.log à chaque fois qu'un utilisateur se connecte
function ajoutLog { # Argument 1 : nom machine Argument 2 : nom utilisateur
	d=$(date); # Date à laquelle l'utilisateur s'est connecté
	t=$(tty); # Numéro du terminal sur lequel il s'est connecté
	echo "$1 $2 $d $t" >> connexion.log; # Ecriture des données dans le fichier connexion.log
}

# Fonction supprimeLog permettant de supprimer le log quand l'utilisateur se déconnecte
function supprimeLog { # Argument 1 : nom machine Argument 2 : nom utilisateur
	sed '/'$1' '$2'/d' connexion.log > nconnexion.log && mv nconnexion.log connexion.log; # Recherche l'utilisateur et la machine associée pour supprimer la ligne du fichier log
	rm -f nconnexion.log; # Supprime le fichier temporaire
}

# Fonction help permettant d'indiquer à l'utilisateur les commandes possibles
function commande-help {
	echo "Liste des commandes possibles en mode connect :";
	echo "   who : permet d’accéder à l’ensemble des utilisateurs connectés sur la machine.";
	echo "   rusers : permet d’accéder à la liste des utilisateurs connectés sur le réseau.";
	echo "   rhost : renvoie la liste des machines rattachées au réseau virtuel.";
	echo "   connect : permet de se connecter à une autre machine du réseau.";
	echo "   su : permet de changer utilisateur.";
	echo "   passwd : permet à l’utilisateur de changer de mot de passe sur l’ensemble du réseau virtuel.";
	echo "   finger : permet de renvoyer des éléments complémentaires sur l’utilisateur.";
	echo "   write : permet d’envoyer un message à un utilisateur connecté sur une machine du réseau. La syntaxe de la commande est la suivante : write nom_utilisateur@nom_machine message";
	echo "Liste des commandes possibles en mode administrateur :";
	echo "   host : permet d’ajouter ou d’enlever une machine au réseau virtuel.";
	echo "   users : permet d’ajouter ou d’enlever un utilisateur, de lui donner les droits d’accès à une ou plusieurs machines du réseau et de lui fixer un mot de passe.";
	echo "   afinger : permet à l’administrateur de renseigner les informations complémentaires sur l’utilisateur. (celles-ci peuvent être affichées en mode connect via la commande finger";
}

# Fonction who permettant de voir qui est connecté sur la machine passée en argument
function commande-who { # Argument 1 : machine
	sed -n '/'$1'/ p' connexion.log | sed 's/'$1' //' ; # Le premier sed permet d'afficher les lignes du log ou la machine est présente et le deuxième sed permet de supprimer la machine afin de voir uniquement les infos qui nous intéressent
}

# Fonction rusers permettant d'afficher les utilisateurs connectés au réseau virtuel
function commande-rusers {
	while read ligne # Affiche le fichier connexion.log dans lequel on trouve tous les utilisateurs connectés
	do
		echo $ligne;
	done < connexion.log
	return 0;
}

# Fonction rhost permettant d'afficher toutes les machines connectées au réseau virtuel
function commande-rhost {
	while read ligne # Affiche le fichier machines.txt
	do
		echo $ligne;
	done < machines.txt
	return 0;
}

# Fonction connect permettant à un utilisateur de se connecter sur une autre machine
function commande-connect { # Argument 1 : utilisateur Argument 2 : machine
	verifAcces $1 $2; # Vérifie si l'utilisateur a les accès sur la machine en question
	if [[ $? == 0 ]]; then # Si la fonction retourne 0
		ajoutLog $2 $1; # On ajoute le log pour dire qu'il est connecté
		promptConnect $2 $1; # On relance un nouveau prompt
	fi
}

# Fonction su permettant de changer d'utilisateur dans la commande rvsh
function commande-su { # Argument 1 : utilisateur Argument 2 : machine
	verifUtilisateur $1 $2; # Verifie si l'utilisateur entré existe bien 
	if [[ $? == 1 ]] ; then # Si la fonction retourne un 1
		return 1; # On sort de la fonction avec un 1
	fi
	verifMdp $1; # Vérifie que l'utilisateur rentre le bon mot de passe
	if [[ $? == 0 ]] ; then # Si la fonction retourne un 0
		return 0; # On retourne un 0 et tout s'est bien passé
	else 
		return 1; # Sinon on retourne un 1
	fi;
}

# Fonction passwd permettant à un utilisateur de changer son mot de passe
function commande-passwd { # Argument 1: utilisateur Argument 2: nouveau mot de passe
	currentWp=$(grep -w $1 utilisateurs.txt | cut -f2 -d' '); # Récupère le mot de passe actuel en faisant un grep pour récupérer la ligne correspondant à l'utilisateur puis un cut pour récupérer son mot de passe
	touch intermediaire; # Crée un fichier intermediaire
	while read ligne # Lit le fichier utilisateurs.txt
	do
		if [[ $ligne == $(grep -w $1 utilisateurs.txt) ]] ; then # On se replace sur la ligne correspondant à l'utilisateur
			echo $ligne | sed 's/'$currentWp'/'$2'/g' >> intermediaire ; # On envoie dans un pipe cette ligne et on change l'ancien mot de passe par le nouveau puis on met cette ligne dans le fichier intermediaire
			echo "Mot de passe changé !" # On dit à l'utilisateur que son mot de passe a bien été changé
		else
			echo $ligne >> intermediaire; # Si la ligne n'est pas celle qu'on cherche on met la ligne en question dans le fichier intermediaire sans la modifier
		fi
	done < utilisateurs.txt
	rm -f utilisateurs.txt; # On supprime le fichier utilisateurs
	mv intermediaire utilisateurs.txt; # Le fichier intermediaire devient notre nouveau fichier utilisateurs
	chmod 777 utilisateurs.txt; # On change les accès pour le nouveau fichier
	return 0;

}

# Fonction finger permettant d'afficher les commentaires liés à un utilisateur
function commande-finger { # Argument 1 : utilisateur
	if [[ -f finger/$1_finger.txt ]] ; then # Si le fichier finger propre à l'utilisateur existe
		while read ligne # On lit le fichier en question
		do
			echo $ligne;
		done < finger/$1_finger.txt
	else
		erreur 10 ; # Sinon on lance l'erreur 10
	fi	
	if [[ -f messages_box/$1.txt ]] ; then # Si l'utilisateurs a reçu un message
		echo "============= Vous avez des messages ! ============= ";
		while read ligne # On affiche ce(s) dernier(s)
		do
			echo $ligne;
		done < messages_box/$1.txt
	fi
}

# Fonction deleteMessage permettant à l'utilisateur de supprimer ses messages
function commande-deleteMessage { # Argument 1 : utilisateur à supprimer les messages Argument 2 : utilisateurs qui lance la commande
	if [[ $1 == $2 ]] ; then # Vérifie si l'utilisateur qui veut supprimer ses messages est bien celui qui lance la commande
		re=0;
		read -p "Etes-vous sur de vouloir supprimer les messages de $1 ? (O/N)" re ; # Demande à l'utilisateur de confirmer
		if [[ $re == O || $re == o ]] ; then # Si l'utilisateur confirme
			rm -f messages_box/$1.txt; # On supprime les messages
			touch messages_box/$1.txt; # On recrée un fichier messages
			echo "Messages supprimés"; # On indique à l'utilisateur que ses messages ont bien été supprimés
		else
			echo "Opération annulé"; # Sinon l'opération est annulée
		fi
	else
		echo "Vous ne pouvez supprimer que vos messages." # Sinon on lui affiche un message d'erreur
	fi
}

# Fonction write permettant à un utilisateur d'envoyer un message à un autre utilisateur
function commande-write { # Argument 1 : expediteur Argument 2 : machine expediteur Argument 3 : destination (user@machine)  Argument 4 : message
	ttyreceiver=O;
	us=$(echo $3 | cut -f1 -d'@');
	mac=$(echo $3 | cut -f2 -d'@');
	ttyreceiver=$(grep -w "$mac $us" connexion.log | tail -n 1 | rev | cut -f1 -d' ' | rev) #afficher le termianl de la derniere conenxion machine user
	if [[ -z $ttyreceiver || -z $3 ]]; then
		echo "L'utilisateur demandé sur la machine demandée n'est pas connecté.";
	else
		echo "l'autre est sur $ttyreceiver";
		if [[ "$mac $us" == $(grep -w $ttyreceiver connexion.log | tail -n 1 | cut -f1,2 -d' ') ]] ; then #afficher dernier log machine et user du tty
			echo "Message de $1 depuis $2 : $arg2" >> $ttyreceiver;
		else
			n=0;
			n=$(date +%D' '%r);
			touch messages_box/$us.txt ;
			echo "$n Message de $1 depuis $2 : $arg2" >> messages_box/$us.txt
			echo "L'utilisateurs n'est pas en avant plan. Votre message est sauvegardé dans son historique de message. Il peut l'afficher grâce à la commande finger.";
		fi
	fi
}

# Fonction host-a permettant d'ajouter une nouvelle machine sur le réseau virtuel
function commande-host-a { # Argument 1: machine à ajouter
	read -p "Etes-vous sûr de vouloir ajouter la machine \"$1\" au réseau ? (Y/N)" rep ; # Message de confirmation
	if [[ $rep == Y || $rep == y ]] ; then # Si l'utilisateur confirme
		echo "$1" >> machines.txt; # On ajoute la machine dans le fichier machines
		echo "$1 ajoutée au réseau !"; # On indique que l'opération s'est bien effectuée
	else
		echo "Ajout annulé"; # Sinon l'opération est annulée
	fi;
}

# Fonction host-d permettant de supprimer une machine du réseau virtuel
function commande-host-d { # Argument 1: machine à supprimer
	if [[ $1 == $(grep -w $1 machines.txt) ]] ; then # Vérifie si la machine entrée existe bien
		sed '/'$1'/d' machines.txt > nmachines.txt && mv nmachines.txt machines.txt; # Supprimer la machine du fichier machines.txt
		rm -f nmachines.txt; # Supprime le fichier temporaire
		echo "Machine supprimée !"; # Indique à l'utilisateur que l'opération est effectuée
		sed -i 's/'$1'[ ]//g' utilisateurs.txt; # Supprime la machine en question dans le fichier utilisateur
	else
		echo "\"$1\" inconnue"; # Sinon on indique que la machine n'existe pas
	fi
}

# Fonction users permettant d'ajouter, de supprimer ou de modifier un utilisateur
function commande-users { # Argument 1: option Argument 2: utilisateur  Argument 3: machine à ajouter ou mot de passe en fonction de l'option
	if [[ $1 == "-a" ]]; then # Si l'option choisie et -a
		echo "$2 $3 $4">> utilisateurs.txt; # On ajoute un nouvel utilisateur dans le fichier utilisateurs.txt
		touch finger/$2_finger.txt ; # On lui crée un fichier finger vide
	elif [[ $1 == "-d" && -z $3 ]]; then # Si l'option choisie est -d
		if [[ $2 == $(egrep -w $2 utilisateurs.txt | cut -f1 -d' ') ]] ; then # On regarde si l'utilisateur existe
			sed '/'^$2'[ ]/ d' utilisateurs.txt > nutilisateurs.txt && mv nutilisateurs.txt utilisateurs.txt; # On supprime l'utilisateur du fichier utilisateur avec un sed
			rm -f nutilisateurs.txt; # On supprimer le fichier temporaire
			echo "Utilisateur supprimé"; # On indique à l'utilisateur que l'opération s'est bien effectuée
		else 
			echo "Cet utilisateur n'existe pas."; # Sinon on indique à l'utilisateur que l'utilisateur n'existe pas
		fi
	elif [[ $1 == "-ma" ]]; then # Si l'option choisie est -ma
		l=$(grep -w $2 utilisateurs.txt); # On récupère la ligne de l'utilisateur
		if [[ $l != $(grep -w $2 utilisateurs.txt | grep -w $3) ]] ; then # Permet de vérifier si l'utilisateur n'a pas déjà accès à la machine souhaitée
			sed '/'^$2'[ ]/ d' utilisateurs.txt > nutilisateurs.txt && mv nutilisateurs.txt utilisateurs.txt; # Supprime la ligne de l'utilisateur en question
			rm -f nutilisateurs.txt; # Supprime le fichier temporaire
			echo "$l $3 " >> utilisateurs.txt; # On ajoute la nouvelle ligne avec la machine en plus
		else
			echo "Erreur $2 avait deja useraccès à $3"; # Sinon on indique à l'utilisateur qu'il a déjà accès à cette machine
		fi
	else
		erreur 13; # Sinon on lance l'erreur 13
	fi
}

# Fonction afinger permettant de modifier le fichier finger
function commande-afinger { # Argument 1 : utilisateur
	if [[ -f finger/$1_finger.txt ]] ; then # Vérifie si le fichier finger existe
		vi finger/$1_finger.txt; # On lance un editeur pour l'utilisateur puisse modifier le fichier
	else
		echo "L'utilisateur n'existe pas"; # Sinon on l'indique à l'utilisateur
	fi
}

# Fonction historique permettant de récupérer les commandes précédentes 
# Fonction a tester
# function historique {
# 	if [[ -f historique.txt ]]; then # Si le fichier historique existe
# 		num=$(sed -n '$=' historique.txt); # On place le pointeur de ligne à la fin du fichier historique
# 		num=$((num+1)); # On l'incrémente de 1
# 	fi
# 	read -n3 -p "$2@$1> " x; # Attend que l'utilisateur tape la fleche haut ou la fleche bas
# 	while [[ "$premierChar" == "$flechehaut" || "$premierChar" == "$flechebas" ]] # Tant que l'utilisateur tape la fleche haut ou bas
# 	do
# 		if [[ "$premierChar" == "$flechehaut" ]]; then # Si l'utilisateur tape la fleche haut
# 			if [[ "$num" != "1" ]]; then  # Si le pointeur n'est pas égal à 1 cela veut dire qu'on est pas encore remonté au début du fichier
# 				num=$((num-1)); # On décrémente le pointeur 
# 				sed -n "$num"p historique.txt; # On affiche la ligne correspondante du fichier historique
# 			fi
# 		else
# 			if [[ "$num" != $(sed -n '$=' historique.txt) ]]; then # Si le pointeur n'est pas encore à la fin du fichier historique
# 				num=$((num+1)); # On incrémente le pointeur
# 				sed -n "$num"p historique.txt; # On affiche la ligne correspondante du fichier historique
# 			fi
# 		fi
# 		read -s -n3 -p "$2@$1> " x; # Attend que l'utilisateur tape la fleche haut ou la fleche bas
# 	done
# }

# Fonction promptConnect affichant le prompt si on a rentré l'option -connect
function promptConnect { # Argument 1 : machine   Argument 2 : utilisateur
	
	while [ true ] # Boucle infinie
	do
		if [[ -f historique.txt ]]; then # Si le fichier historique existe
			num=$(sed -n '$=' historique.txt); # On place le pointeur de ligne à la fin du fichier historique
			num=$((num+1)); # On l'incrémente de 1
		fi
		read -n3 -p "$2@$1>" premierChar;
		if [[ $premierChar == "$flechehaut" || $premierChar == "$flechebas" ]]; then
			while [[ "$premierChar" == "$flechehaut" || "$premierChar" == "$flechebas" ]] # Tant que l'utilisateur tape la fleche haut ou bas
			do
				echo -en "                                                "; 
				echo -en "\r$2@$1>";
				if [[ "$premierChar" == "$flechehaut" ]]; then # Si l'utilisateur tape la fleche haut
					if [[ "$num" != "1" ]]; then  # Si le pointeur n'est pas égal à 1 cela veut dire qu'on est pas encore remonté au début du fichier
						num=$((num-1)); # On décrémente le pointeur
						echo -en $(sed -n "$num"p historique.txt);
						comd=$(sed -n "$num"p historique.txt); # On affiche la ligne correspondante du fichier historique
					fi
				else
					if [[ "$num" != $(sed -n '$=' historique.txt) ]]; then # Si le pointeur n'est pas encore à la fin du fichier historique
						num=$((num+1)); # On incrémente le pointeur
						echo -en $(sed -n "$num"p historique.txt); # On affiche la ligne correspondante du fichier historique
						comd=$(sed -n "$num"p historique.txt);
					fi
				fi
			premierChar=0;
			read -n3 -p "" premierChar;
			done
			read -p "" reponse arg1 arg2 arg3;
			reponse=$comd$premierChar$reponse;
			arg1=$(echo $reponse | cut -f2 -d' ');
			reponse=$(echo $reponse | cut -f1 -d' ');
		else
			read -p "" reponse arg1 arg2 arg3;
			reponse=$premierChar$reponse;
		fi
		#echo "$reponse $arg1 $arg2 $arg3" >> historique.txt; # Ecrit la reponse dans l 'historique
		case $reponse in # En fonction de la réponse écrite le prompt lance une commande
			help )
				if [[ -z $arg1 ]]; then # Si arg1 est nul
					commande-help; # Lance la commande help
				else
					erreur 8; # On lance l'erreur 8
				fi
				;;
			who )
				if [[ ! -z $arg1 ]]; then # Si arg1 n'est pas nul
					erreur 8; # On lance l'erreur 8
				else
					commande-who $1; # Sinon on lance la commande who
				fi
				;;
			rusers )
				if [[ ! -z $arg1 ]]; then # Si arg1 n'est pas nul
					erreur 8; # On lance l'erreur 8
				else
					commande-rusers; # Sinon on lance la commande rusers
				fi
				;;
			rhost )
				if [[ ! -z $arg1 ]]; then # Si arg1 n'est pas nul
					erreur 8; # On lance l'erreur 8
				else
					commande-rhost; # Sinon on lance la commande rhost
				fi
				;;
			connect )
				if [[ -z $arg1 || ! -z $arg2 ]]; then # Si arg1 est nul est que arg2 n'est pas nul
					erreur 8; # On lance l'erreur 8
				else
					commande-connect $2 $arg1; # Sinon on lance la commande connect
				fi
				;;
			su )
				if [[ -z $arg1 || ! -z $arg2 ]]; then # Si arg1 est nul est que arg2 n'est pas nul
					erreur 8; # On lance l'erreur 8
				else
					commande-su $arg1 $1 ; # Sinon on lance la commande su
					if [[ $? == 0 ]]; then # Si la commande su renvoie 0
						ajoutLog $1 $arg1; # On ajoute le log
						promptConnect $1 $arg1; # On relance un prompt
					fi
				fi
				;;
			passwd )
				if [[ -z $arg1 || ! -z $arg2 ]]; then # Si arg1 est nul est que arg2 n'est pas nul
					erreur 8; # On lance l'erreur 8
					erreur 9; # Et l'erreur 9
				else
					commande-passwd $2 $arg1; # On lance la commande passwd
				fi
				;;
			finger )
				if [[ ! -z $arg1 && -z $arg2 ]]; then # Si arg1 n'est pas nul et que arg2 est nul
					commande-finger $arg1; # On lance la commande finger
				elif [[ $arg1 == "-d" && ! -z $arg2 && -z $arg3 ]]; then # Si arg1 est égal à -d et que arg2 n'est pas nul et que arg3 est nul
					commande-deleteMessage $arg2 $2; # On lance la commande deleteMessage
				else
					erreur 8; # Sinon on lance l'erreur 8
				fi
				;;
			write )
				if [[ ! -z $arg1 && ! -z $arg2 && -z $arg3 ]]; then # Si arg1 et arg2 ne sont pas nuls et que arg3 est nul
					commande-write $2 $1 $arg1 $arg2; # On lance la commande write
				else
					erreur 8; # Sinon on lance l'erreur 8
				fi
				;;
			exit )
				if [[ -z $arg1 ]]; then # Si arg1 est nul
					supprimeLog $1 $2; # Suppression du log
					return 1; # Sortie de la fonction avec un 1
				else
					erreur 8; # On lance l'erreur 8
				fi
				;;
			*)
				erreur 12;; # Si l'utilisateur n'entre pas une commande correcte on lance l'erreur 12
		esac
	done
}

# Fonction promptAdmin affichant le prompt si on a rentré l'option -admin
function promptAdmin {
	echo "Vous êtes connecté en tant qu'administrateur !"; # Confirme à l'utilisateur qu'il est en mode admin
	while [ true ] # Boucle infinie
	do
		read -p "rvsh> " reponse arg1 arg2 arg3 arg4; # Attend une réponse de l'utilisateur
		case $reponse in # En fonction de la réponse écrite le prompt lance une commande
			help )
				if [[ -z $arg1 ]]; then # Si arg1 est nul
					commande-help; # Lance la commande help
				else
					erreur 8; # On lance l'erreur 8
				fi
				;;
			host )
				if [[ ! -z $arg3 ]] ; then # Si arg3 n'est pas nul
					erreur 8; # On lance l'erreur 8
				else
					if [[ $arg1 == "-a" ]]; then # Si l'option est -a
						commande-host-a $arg2; # On lance la commande host-a
					elif [[ $arg1 == '-d' ]]; then # Si l'option est -d
						commande-host-d $arg2; # On lance la commande host-d
					else
						erreur 11; # Sinon on lance l'erreur 11
					fi;
				fi
				;;
			users )
				if [[ ! -z $arg1 && ! -z $arg2 || ! -z $arg3 || ! -z $arg4 ]]; then # Si arg1 arg2 arg3 et arg4 ne sont pas nuls
					commande-users $arg1 $arg2 $arg3 $arg4; # On lance la commande useres
				else 
					erreur 8; # Sinon on lance l'erreur 8
				fi
				;;
			afinger )
				if [[ -z $arg2 ]]; then # Si arg1 est nul
					commande-afinger $arg1; # On lance la commande afinger
				else
					erreur 8; # On lance l'erreur 8
				fi
				;;
			exit )
				if [[ -z $arg1 ]]; then # Si arg1 est nul
					exit 1; # Sortie du programme
				else
					erreur 8; # On lance l'erreur 8
				fi
				;;
			*)
				erreur 12;; # Si l'utilisateur n'entre pas une commande correcte on lance l'erreur 12
		esac
	done
}

# Fonction main
function main {
	verifNbArguments $# $1 $2; #1er parametre : nombre d'arguments /// 2eme parametre : mode choisi
	verifFichiers;
	verifNomMachine $2; #1er parametre : nom machine
	verifUtilisateur $3 $2; #1er parametre : nom d'utilisateur /// 2eme parametre : nom machine
	verifMdp $3; #1er parametre : nom d'utilisateur
	ajoutLog $2 $3; #1er parametre : nom machine /// #2eme parametre : nom d'utilisateur
	apropos; # Commande apropos
	PROGRAMME_EN_COURS=1; # Affecte 1 à la variable PROGRAMME_EN_COURS pour dire qu'on est entré dans la commande
	promptConnect $2 $3; # Affiche le promt
}

main "$@"; # Lance la fonciton main avec tous les arguments passés en entrée de la commande
exit 0; # Sortie du programme avec un 0

trap 2; # Réactivation du [CTRL+C]
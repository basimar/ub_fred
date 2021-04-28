#!/bin/bash
# Script zur Abholung und Verarbeitung von angereicherten SE-Daten (FRED)
# Autor: Marcus Zerbst; Anpassungen IBB: Bernd Luchner
# Stand: 22.06.2018
# Letzte Aenderung: 22.06.2018, Basil Marti

# Voraussetzungen: 

  basedir=/exlibris/aleph/u22_1/dsv01/scripts/fred_import
  putdir=$basedir/input
  heute=2020-06-07
  date=20200607
  file_data=out-$heute.txt
  file_load=out-$heute.seq
  file_log=out-$heute.log.gz
  file_log_extracted=out-$heute.log
  file_duplicates=duplicates-$heute.txt
  file_duplicates_mail=duplicates-mail-$heute.txt
  file_duplicates_bl=duplicates-blacklist-$heute.txt

  source $basedir/fred_import.conf

function quit {
   printf "FRED-Out-Datei vom ${heute}: http://aleph.unibas.ch/dirlist/u/dsv01/scripts/fred_import/input/${file_data}\n\nSystemnummernliste des Imports: http://aleph.unibas.ch/dirlist/u/alephe/scratch/out-${heute}.seq.doc_log\n\nDuplicates-Meldungen: http://aleph.unibas.ch/dirlist/u/dsv01/scripts/fred_import/input/${file_duplicates_mail}" | mailx -r @unibas.ch -s "FRED-Out-Datei vom ${heute} -- Achtung Fehler" $MAIL_FRED
    exit
}

function success {
   printf "FRED-Out-Datei vom ${heute}: http://aleph.unibas.ch/dirlist/u/dsv01/scripts/fred_import/input/${file_data}\n\nSystemnummernliste des Imports: http://aleph.unibas.ch/dirlist/u/alephe/scratch/out-${heute}.seq.doc_log\n\nDuplicates-Meldungen: http://aleph.unibas.ch/dirlist/u/dsv01/scripts/fred_import/input/${file_duplicates_mail}" | mailx -r @unibas.ch -s "FRED-Out-Datei vom ${heute}" $MAIL_FRED
    exit
}

# Lokal zum Ziel-Verzeichnis wechseln:

  cd $putdir

# FTP durchfuehren (Daten ascii, gepacktes Logfile binaer): 

  ftp -n $FTP_HOST <<END_SCRIPT
  quote USER $FTP_USER
  quote PASS $FTP_PASSWORD
  cd out
  ascii
  get $file_data
  bin
  get $file_log
  quit

END_SCRIPT

# Daten fuer Laden bereit stellen:  

  if [ -e $file_data ]; then
    cp $putdir/$file_data $alephe_dev/dsv01/scratch/$file_load
    gunzip $putdir/$file_log

    # Duplicates mit grep extrahieren
    grep -h "FIELD_DUPLICATE" $putdir/$file_log_extracted > $putdir/$file_duplicates
    grep -Ph "FIELD_DUPLICATE.(gnd|mesh)" $putdir/$file_duplicates > $putdir/$file_duplicates_mail
    grep -h "FIELD_DUPLICATE.lcsh" $putdir/$file_duplicates | cut -c1-9 > $putdir/$file_duplicates_bl
    sed -i "s/$/\t$date\tdelete/" $putdir/$file_duplicates_bl
    cp $putdir/$file_duplicates_bl $putdir/${date}_blacklist_ibb

  else
    echo "Keine FRED-Datei abzuholen, Abbruch."
    quit
  fi

# LCSH-Duplicates als Blacklist nach FRED laden

if [ -s $file_duplicates_bl ]; then
  
  ftp -n $FTP_HOST <<END_SCRIPT
  quote USER $FTP_USER
  quote PASS $FTP_PASSWORD
  cd in
  binary
  put ${date}_blacklist_ibb
  quit

END_SCRIPT

else
  echo "Keine LSCH-Duplicates"
fi

# Daten nach Aleph laden: 
# Saetze aendern, Felder anhaengen, output 10-stellig fuer Laden in Recherche, 
# Fix fuer Angleichung wie aus EXT09, kein Merge, cat=CAT-Feld, Hohe Index-Prio (1990): 

 fix="fred"
 cataloger="BS/BE-FRED"
 prio="1990"

 csh -f $aleph_proc/p_manage_18 DSV01,$file_load,$file_load.rej,$file_load.doc_log,OLD,$fix,,FULL,APP,M,,,$cataloger,20,,,,$prio, &



 echo "======================================================"
 echo " Job ist gelaufen:"
 echo " - Job-Name ..... $0"
 echo " - PID .......... $$"
 echo " - Datum ........ `date +%d-%m-%Y`"
 echo " - Uhrzeit ...... `date +%H:%M`"
 echo " - In Directory . `pwd`"
 echo "======================================================"

 success


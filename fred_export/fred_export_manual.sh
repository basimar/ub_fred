#!/bin/bash
# Script zur manuellen Ablieferung von Systemnummern an FRED
# Autor: Basil Marti
# Stand: 13.03.2018

# Dieses Script liefert Systemnummern, die vorher von Hand zusammengestellt wurden, an FRED. Das Script muss mit der Input Datei als Argument ausgefÃhrt werden.
# Achtung: Nur AusfÃhren, wenn der regulÃre Export mit fred_export.sh ausgeschaltet ist (StandardmÃssig am Sonntag)

BASEDIR=/exlibris/aleph/u22_1/dsv01/scripts/fred_export
ARCHIVEDIR=$BASEDIR/archive
source $BASEDIR/fred_export.conf

DATE=`date "+%Y%m%d"`

INPUT_FILE="$1"
LOG=$BASEDIR/log/fred_export_$DATE.log

cd $BASEDIR

function quit {
    cat $LOG | mailx -s "Logfile: FRED-Export vom $DATE generiert -- Achtung Fehler" $MAIL_EDV
    exit
}

function success {
    cat $LOG | mailx -s "Logfile: FRED-Export vom $DATE generiert" $MAIL_EDV
    exit
}
# PrÃfen, ob Script mit Argument ausgefÃhrt wurde

if [[ $# -eq 0 ]] ; then
    echo 'Keine Input-Datei als Argument mitgegeben - Abbruch'
    exit 0
fi

if [[ $# -ne 1 ]] ; then
    echo 'Zuviele Input-Dateien als Argument mitgegeben - Abbruch'
    exit 0
fi
	
printf "Export von manuell exportierten Systemnummern an FRED vom $DATE\n" >> $LOG


if [ -s $INPUT_FILE ]; then
    printf "\n\nSystemnummern zum Exportieren\n" >> $LOG
else
    printf "\n\nKeine neuen Systemnummern zum Exportieren\n" >> $LOG
    quit
fi

printf "\nUebemitteln der Systemnummern an FRED\n" >> $LOG
# Uebermittlung Daten per FTP an FRED

cp $INPUT_FILE liste_ibb_$DATE.csv

ftp -n $FTP_HOST <<END_SCRIPT
quote USER $FTP_USER
quote PASS $FTP_PASSWORD

cd in
binary
put liste_ibb_$DATE.csv 
quit
END_SCRIPT

# Aufraeumen
printf "\nVerschieben von Input-Dateien nach dsv01/scripts/fred/archive\n" >> $LOG
mv $INPUT_FILE $ARCHIVEDIR/
rm liste_ibb_$DATE.csv

success

exit







#!/bin/bash
# Script zur Ablieferung von Systemnummern an FRED
# Autor: Basil Marti
# Stand: 13.03.2018

BASEDIR=/exlibris/aleph/u22_1/dsv01/scripts/fred_export
ARCHIVEDIR=$BASEDIR/archive
source $BASEDIR/fred_export.conf

DATE=`date "+%Y%m%d"`

LOG=$BASEDIR/log/fred_export_$DATE.log
INFOMAIL=$BASEDIR/fred_export_infomail.txt

cd $BASEDIR

function quit {
    cat $LOG | mailx -s "Logfile: FRED-Export vom $DATE generiert -- Achtung Fehler" $MAIL_EDV
    exit
}

function success {
    cat $LOG | mailx -s "Logfile: FRED-Export vom $DATE generiert" $MAIL_EDV
    exit
}
	
printf "Export von neu erstellten Systemnummern an FRED vom $DATE\n" >> $LOG

# Pruefen, ob Datei mit letzter exportierter Systemnummer a) vorhanden und b) eine neunstellige Nummer enthaelt, sonst Abbruch

if [ -e $BASEDIR/fred_export_last_sys.txt ]; then
    LASTSYS=`cat $BASEDIR/fred_export_last_sys.txt`
    if [[ $LASTSYS =~ ^[0-9]{9}$ ]]; then
	printf "Letzte Systemnummer gueltig\n" >> $LOG
    else
        printf "Datei fred_export_last_sys.txt ungueltig formatiert, Abbruch\n" >> $LOG
	quit
    fi
else
    printf "Datei fred_export_last_sys.txt nicht vorhanden, Abbruch\n" >> $LOG
    quit
fi

# SQL-Abfrage auf Basis der letzten exportierten Systemnummer, Ausgabe in fred_export_last_sys.txt

sqlplus dsv01/dsv01 @fred_export.sql $DATE $LASTSYS >> $LOG

# Pruefen ob Output-File Inhalt hat, sonst Abbruch

if [ -s $BASEDIR/fred_export.lst ]; then
    tail -1 fred_export.lst | cut -c1-9 > fred_export_last_sys.txt
    cp $BASEDIR/fred_export_last_sys.txt $ARCHIVEDIR/fred_export_last_sys_$DATE.txt
    NEWSYS=`cat $BASEDIR/fred_export_last_sys.txt`
    printf "\n\nSystemnummern wurden exportiert\n" >> $LOG
    printf "$LASTSYS bis $NEWSYS\n" >> $LOG
else
    printf "\n\nKeine neuen Systemnummern zum Exportieren\n" >> $LOG
    quit
fi

printf "\nUebemitteln der Systemnummern an FRED\n" >> $LOG
# Uebermittlung Daten per FTP an FRED

cp fred_export.lst liste_ibb_$DATE.csv

ftp -n $FTP_HOST <<END_SCRIPT
quote USER $FTP_USER
quote PASS $FTP_PASSWORD

cd in
binary
put liste_ibb_$DATE.csv 
quit
END_SCRIPT

# Aufraeumen
printf "\nVerschieben von Log-Dateien nach dsv01/scripts/fred/archive\n" >> $LOG
mv $BASEDIR/fred_export.lst $ARCHIVEDIR/fred_export_$DATE.lst
rm liste_ibb_$DATE.csv

success

exit







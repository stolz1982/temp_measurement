#/bin/bash
#Pfad zum Sensor 
PFAD=/sys/devices/w1_bus_master1/
#Name der Datendatei welche die Temperatur enthaelt
DATEI=w1_slave
#ID des DS1820 auf dem RPI-EXP
ID=$2/
#Messpunkt_ID
MP_ID=$1

#letzte zeile der Bus_Sensor_Datei holen
str=`tail -1 $PFAD$ID$DATEI`

#erste zeile der Datei aufrufen , Prüfung Messstatus
str_ok=`head -1 $PFAD$ID$DATEI`

#wenn nicht yes in im str_ok steht war die Messung fehlerhaft und kann ignoritert werden
str_ok=${str_ok##*=}
str_ok=${str_ok##* }

#if [ $str_ok -ne "YES" ];; then
#exit 0;
#fi

#sucht im String nach eine Gleichheitszeichen und gibt alles rechts davon wieder
str=${str##*=}
# rechts 3 Zeichen abschneiden
vorstellen=${str%???}

#Berechnung Nachkommastellen je nach Laenge des Strings
#Stringlaenge = 4 dann 1 Stelle wegschneiden und Wert setzen
#Stringlaenge = 5 dann 2 Stellen wegschneiden und Wert setzen
#Stringlaenge = 6 dann 3 Stellen wegschneiden und Wert setzen

case "${#str}" in
7)	nachstellen=${str#????} #Scheissekalt,bei Plus wird diese Messung wohl die letzte Messung sein
	;;
6) 	nachstellen=${str#???}
	;;
5)	nachstellen=${str#??}
	;;
4)	nachstellen=${str#?}
	;;
3)	vorstellen=0
	nachstellen=$str
	;;
esac

#Datum uns Uhrzeit fuer das Setzen in den SQL String formatieren
now="$(date +'%Y-%m-%d %T')"

#echo "Die Temperatur betraegt $vorstellen.$nachstellen ($str) Grad Celsius, gemessen: $now."

#es gibt immer wieder eine Messtemperatur die 85.000 beträgt und das ist
#eine Fehlmessung und soll mit nachfolgender IF Bedingung unterdrückt werden 
if [ $vorstellen.$nachstellen = 85.000 ] || [ $vorstellen.$nachstellen = 0.000 ]; 
then
exit 0
fi

mysql --host=192.168.2.202 --user=temperatur --password=temperatur -D home << EOF
insert into temperatur (messpunkt_id,temperatur, datum_uhrzeit,kommentar) values ($MP_ID,"$vorstellen.$nachstellen",'$now','$str_ok-DS1820');
EOF

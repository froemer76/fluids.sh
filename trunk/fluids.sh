#!/usr/bin/env sh
###############################################################################
#
# fluids.sh
# ---------
# This is a shell script which utilised 'wget' to acquire fluid properties from
# the NIST Chemistry WebBook (http://webbook.nist.gov/chemistry/) in a format 
# suitable for further processing with shell scripts or e.g. xmgrace. 
# It supports the full functionality provided by the website!
#
# Type "fluid.sh -show" to show fluids (ID) available at NIST webbook or 
# "fluids.sh -h" to display the help message for informations about the usage.
#
# Example:
# Calculate an isotherm (-it) of water (-id C7732185) for T/K=725.5
# from p/MPa=1.0 to 10.0 with p.increment/MPa=0.5 and use SI units.
#
#   fluids.sh -id C7732185 -it -T 725.5 -pl 1.0 -ph 10.0 -i 0.5 -si
#
# Note!
# - There are no sanity checks implemented.
# - Your input parameters must be reasonable.
# - Incorrect entries can lead to unpredictable behaviour.
#
#==============================================================================
#
# This software was written by Frank Roemer and 
# is distributed under the following terms (MIT License):
#
# Copyright (c) 2013 Frank Roemer
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
###############################################################################

# Here you can define the default units you wish to use. 
# To define differing units one can use the '-u' option.
# Type "fluids.sh -units" for more information about handling of units.
#--------------------------------------------------------------------
UI_T=1  # Temperature: 1=Kelvin, 2=Celsius, 3=Fahrenheit, 4=Rankine
UI_P=2  # Pressure: 1=MPa, 2=bar, 3=atm, 4=torr, 5=psia
UI_D=3  # Density: 1=mol/l, 2=mol/m3, 3=g/ml, 4=kg/m3, 5=lb-mole/ft3, 6=lbm/ft3
UI_E=1  # Energy: 1=kJ/mol, 2=kJ/kg, 3=kcal/mol, 4=Btu/lb-mole, 5=kcal/g, 6=Btu/lbm
UI_V=1  # Velocity: 1=m/s, 2=ft/s, 3=mph
UI_W=2  # Viscosity: 1=uPa*s, 2=Pa*s, 3=cP, 4=lbm/ft*s
UI_S=1  # Surface tension: 1=N/m, 2=dyn/cm, 3=lb/ft, 4=lb/in

# Here you can define the default values for some options & parameter.
#--------------------------------------------------------------------
INC="1.0"      # [-i] increment
DIGI="5"       # [-s] number of digits
ID=""          # [-id] NIST ID of the substance
ISOX=""        # [-ib|-it|-ic|-st|-sp] type of data, use 1,2,3,4 or 5
REFSTATE="DEF" # [-ref] standard state convention
OUTF=""        # [-o] output file name

#=====================================================================#
#        Nothing need to be modified below this comment. ;)           #
#=====================================================================#

# local functions
#--------------------------------------------------------------------
manunits () {
   # descriptors
   UD_T=`echo "K C F R" | cut -d" " -f${UI_T}`
   UD_P=`echo "MPa bar atm torr psia" | cut -d" " -f${UI_P}`
   UD_D=`echo "mol/l mol/m3 g/ml kg/m3 lb-mole/ft3 lbm/ft3" | cut -d" " -f${UI_D}`
   UD_E=`echo "kJ/mol kJ/kg kcal/mol Btu/lb-mole kcal/g Btu/lbm" | cut -d" " -f${UI_E}`
   UD_V=`echo "m/s ft/s mph" | cut -d" " -f${UI_V}`
   UD_W=`echo "uPa*s Pa*s cP lbm/ft*s" | cut -d" " -f${UI_W}`
   UD_S=`echo "N/m dyn/cm lb/ft lb/in" | cut -d" " -f${UI_S}`
   UD_VO=`echo "l/mol m3/mol ml/g m3/kg ft3/lb-mole ft3/lbm" | cut -d" " -f${UI_D}`
   UD_E2=`echo "J/mol*K J/g*K cal/mol*K Btu/lb-mole*R cal/g*K Btu/lbm*R" | cut -d" " -f${UI_E}`
   # generate control elements for URL
   UU_T=`echo $UD_T | sed "s/\//%2F/g" | cut -d" " -f${UI_T}`
   UU_P=`echo $UD_P | sed "s/\//%2F/g" | cut -d" " -f${UI_P}`
   UU_D=`echo $UD_D | sed "s/\//%2F/g" | cut -d" " -f${UI_D}`
   UU_E=`echo $UD_E | sed "s/\//%2F/g" | cut -d" " -f${UI_E}`
   UU_V=`echo $UD_V | sed "s/\//%2F/g" | cut -d" " -f${UI_V}`
   UU_W=`echo $UD_W | sed "s/\//%2F/g" | cut -d" " -f${UI_W}`
   UU_S=`echo $UD_S | sed "s/\//%2F/g" | cut -d" " -f${UI_S}`
}

setui () {
   if [ `echo $1 | wc -w` -eq 7 ]; then
      UI_T=`echo $1 | cut -d" " -f1`
      UI_P=`echo $1 | cut -d" " -f2`
      UI_D=`echo $1 | cut -d" " -f3`
      UI_E=`echo $1 | cut -d" " -f4`
      UI_V=`echo $1 | cut -d" " -f5`
      UI_W=`echo $1 | cut -d" " -f6`
      UI_S=`echo $1 | cut -d" " -f7`
   else
      echo "Error! Number of ids/parameter for '-u' mismatch."
      unitshelp
      exit
   fi
}

setsi () {
   setui "1 1 4 2 1 2 1"
}

unitshelp() {
   cat << EOF
   
 Option Usage: -u '%t %p %d %e %v %m %g'
   %t Temperatur: 1=Kelvin, 2=Celsius, 3=Fahrenheit, 4=Rankine
   %p Pressure: 1=MPa, 2=bar, 3=atm, 4=torr, 5=psia
   %d Density: 1=mol/l, 2=mol/m3, 3=g/ml, 4=kg/m3, 5=lb-mole/ft3, 6=lbm/ft3
   %e Energy: 1=kJ/mol, 2=kJ/kg, 3=kcal/mol, 4=Btu/lb-mole, 5=kcal/g, 6=Btu/lbm
   %v Velocity: 1=m/s, 2=ft/s, 3=mph
   %m Viscosity: 1=uPa*s, 2=Pa*s, 3=cP, 4=lbm/ft*s
   %g Surface tension: 1=N/m, 2=dyn/cm, 3=lb/ft, 4=lb/in

EOF
}

unitsabout() {
	manunits
   cat << EOF
   
 About units handling in fluids.sh:
  The default units for out and input properties are defined right at the
  beginning (line 56 to 62) of the fluids.sh script.
  To define differing units one can use the '-u' option.
EOF
	unitshelp
	unitsdef
}

unitsdef() {
   if [ $UOP -eq 1 ]; then 
      tun="Actual"
   elif [ $SI -eq 1 ]; then 
      tun="SI"
   else
      tun="Default"
   fi
   cat << EOF
 $tun units:
  -Temperatur     : ${UD_T}
  -Pressure       : ${UD_P}
  -Density        : ${UD_D}
  -Energy         : ${UD_E}
  -Velocity       : ${UD_V}
  -Viscosity      : ${UD_W}
  -Surface tension: ${UD_S}

EOF
}

printHelp () {
	manunits
   cat << EOF

 Usage: 
  fluids.sh -id {ID} {-ib|-it|-ic|-st|-sp & spec.para.} [-s {digits} -o {outfile} -r|-R -ref {REF} -si|-u '{%t}...{%g}']
  fluids.sh [-R] -show 
  fluids.sh [-u '{%t}...{%g}'|-si] -units
  fluids.sh -h|--help
 
 Common options:
  -id            NIST ID of the substance (e.g. C7732185 = Water)
  -s             number of digits in output (default: 5)
  -o             name of the output file (default: fluids_*.dat)
  -r             resolve substance name of NIST ID
  -R             like '-r' and enforce to renew catalogue
  -ref           standard state convention (default: "default for fluid")
  -si            use SI units instead of default
  -u             define units (use '-units' for more info)
  -show          print the catalogue of available substances (NIST IDs) and exit
  -units         print a help about handling of units and exit
  -h, --help     print this help and exit
  -V, --version  print version number and exit

 Specific options:
  (isobar)   -ib -p {p/${UD_P}] -Tl {T_low/${UD_T}} -Th {T_high/${UD_T}} [-i {T_inc/${UD_T}}]
  (isotherm) -it -T {T/${UD_T}] -pl {p_low/${UD_P}} -ph {p_high/${UD_P}} [-i {p_inc/${UD_P}}]
  (isochor)  -ic -d {dens/(${UD_D})] -Tl {T_low/${UD_T}} -Th {T_high/${UD_T}} [-i {T_inc/${UD_T}}]
  (satur.T)  -st -pl {p_low/${UD_P}} -ph {p_high/${UD_P}} [-i {p_inc/${UD_P}}]
  (satur.P)  -sp -Tl {T_low/${UD_T}} -Th {T_high/${UD_T}} [-i {T_inc/${UD_T}}]

EOF
}

saveInputToFile () {
   sed -e "s/^[ \t] *//" > $1
}

addColumnsToFile () {
   sed -e "s/^[ \t] *//" | column -t -s"${1}" >> $2
}

echoColumns () {
   column -t -s"${1}"
}

checkAgeListfile() {
   if [ -f $LISTFILE ]; then
      LCDATE=`stat -c %z $LISTFILE`
      LCSEC=`date +%s -d "$LCDATE"`
      NOWSEC=`date +%s` 
      LFAGE=$(($NOWSEC-$LCSEC))
   else
      LFAGE=9999999999
   fi
   echo $LFAGE
}

subst2id() {
   ID=`cat $LISTFILE | grep -v "#" | grep ":$1" | cut -d":" -f1`
   [ "$ID" = '' ] && ID="NA"
   echo $ID
}

id2subst() {
   SUBST=`cat $LISTFILE | grep -v "#" | grep "$1:" | cut -d":" -f2`
   [ "$SUBST" = '' ] && SUBST="NA"
   echo $SUBST
}

getListfile() {
   TF1=`mktemp tmp.XXXXXXXXXX`
   ADDR="http://webbook.nist.gov/chemistry/fluid/"
   echo -n " <=> contact NIST to retrieve catalogue ... "
   wget -O ${TF1} -o /dev/null "$ADDR"
   echo "done!"
   h0=`cat ${TF1} | wc -l`
   h1=`grep -n '<select' ${TF1}|cut -d":" -f1`
   h2=`grep -n '</select' ${TF1}|cut -d":" -f1`
   h1=`echo $h1 | cut -d" " -f1`
   h2=`echo $h2 | cut -d" " -f1`
   h3=$(($h2-$h1))
   echo "# Available (IDs) Fluids @ NIST webbook"  > $LISTFILE
   head -n $h2 ${TF1} | tail -n $h3 | grep '<option ' | grep -v '<!' \
   | sed "s/<\/option>//g" | sed "s/<option value=\"//g" | sed "s/\">/:/g" >> $LISTFILE
   rm  $TF1
}

checkListfile() {
   AGE=`checkAgeListfile`
   if [ $AGE -gt $MAXAGE ]; then
      echo " -> catalogue file is to old or didn't exist!"
      getListfile
   elif [ $RES -eq 2 ]; then
      echo " -> enforce to renew catalogue file!"
      getListfile
   else
      DAYS=`echo "scale=2; ${AGE}/86400"|bc -l`
      echo " -> catalogue file is $DAYS days ($AGE sec.) old"
   fi
}

showListfile() {
	checkListfile
   echo " -> show available (IDs) fluids @ NIST Chemistry WebBook:"
   echo
	echo 'ID         Substance'
	echo '---------  ----------------'
   cat $LISTFILE | grep -v "#" | column -t -s ':'
   echo 
   exit
}

version() {
	echo "fluids.sh version $VERSION"
	echo "Copyright (c) 2013 by Frank Roemer"
	echo "fluids.sh comes with ABSOLUTELY NO WARRANTY."
	echo "You may redistribute copies of fluids.sh"
	echo "under the terms of the MIT License (MIT)."
	echo
	exit
}

welcome() {
cat << EOF

fluids.sh - get fluid properies from NIST Chemistry WebBook
=========================================================================
Note! There are no sanity checks implemented. Your input parameters must 
be reasonable. Incorrect entries can lead to unpredictable behaviour.
-------------------------------------------------------------------------
EOF
}

# (re)set variables and flags
#--------------------------------------------------------------------
VERSION='1.01'
LISTFILE="$HOME/.fluids"  # catalogue file
SOUTF="fluids"            # default prefix for output file name
MAXAGE="86400"            # max. allowed age of catalogue in sec.
DATE=`date +%c`           # time stamp in output files
SUBST=""; SUBH=0; RES=0; USELF=0; SI=0; UOP=0

# read in command line parameter
#--------------------------------------------------------------------
while [ "$1" ]; do
   case $1 in
    '-id')  ID=$2; shift ;;
    '-p')   P=$2; shift ;;
    '-pl')  P0=$2; shift ;;
    '-ph')  P1=$2; shift ;;
    '-T')   T=$2; shift ;;
    '-Tl')  T0=$2; shift ;;
    '-Th')  T1=$2; shift ;;
    '-d')   D=$2; shift ;;
    '-s')   DIGI=$2; shift ;;
    '-i')   INC=$2; shift ;;
    '-o')   OUTF=$2; shift ;;
    '-ref') REFSTATE=$2; shift ;;
    '-si')  SI=1; setsi ;;
    '-u')   setui "$2"; UOP=1; shift ;;
    '-ib')  ISOX=1 ;;
    '-it')  ISOX=2 ;;
    '-ic')  ISOX=3 ;;
    '-st')  ISOX=4 ;;
    '-sp')  ISOX=5 ;;
    '-r')   RES=1; USELF=1 ;;
    '-R')   RES=2; USELF=1 ;;
    '-show') showListfile; exit ;;
    '-units') unitsabout; exit ;;
    '-h'|'--help') printHelp; exit ;;
    '-V'|'--version') version; exit ;;
   esac
   shift
done

# check if wget is available
#--------------------------------------------------------------------
type wget >/dev/null 2>&1 || { \
	echo >&2 "Error! I require 'wget' but it's not installed. Aborting."; \
	exit 1; }

# 'welcome' message with note
#--------------------------------------------------------------------
welcome

# if needed: check the catalogue file
#--------------------------------------------------------------------
[ $USELF -eq 1 ] && checkListfile

# capture if _no_ ID is defined
#--------------------------------------------------------------------
if [ ! "$ID" ]; then
   echo " Error! You must define a substance."
   echo " Type 'fluids.sh -h' for further help."
   echo " "
   exit 1
fi

# resolve the NIST ID <-> substance name
#--------------------------------------------------------------------
if [ $RES -gt 0 ]; then
   SUBST=`id2subst "$ID"`
   if [ "$SUBST" = "NA" ]; then
      echo " Error! The ID you entered is invalid!"
      echo " Type 'fluids.sh -show' to get a list of available ID's/fluids."
      echo " "
      exit 1
   else
      echo " -> resolve ID:${ID} = $SUBST"
   fi        
else
   SUBST="ID:$ID"
fi

# manage units
#--------------------------------------------------------------------
[ $SI -eq 1 ] && setsi
manunits
# construct UNITS part for URL
UNITS="TUnit=${UU_T}&PUnit=${UU_P}&DUnit=${UU_D}&HUnit=${UU_E}&WUnit=${UU_V}&VisUnit=${UU_W}&STUnit=${UU_S}"

# select type of calculation
#--------------------------------------------------------------------
if [ $ISOX -eq 1 ]; then   # isobar
   PARA="Type=IsoBar&P=${P}&TLow=${T0}&THigh=${T1}&TInc=${INC}"
   TYP="isobar"
   echo " ** isobaric properties **"
   echoColumns '_' << EOF
   NIST ID_= ${ID}
   P/${UD_P}_= ${P}
   T(low)/${UD_T}_= ${T0}
   T(high)/${UD_T}_= ${T1}
   T(inc)/${UD_T}_= ${INC}
   Digits/#_= ${DIGI}
EOF
elif [ $ISOX -eq 2 ]; then  # isotherm   
   PARA="Type=IsoTherm&T=${T}&PLow=${P0}&PHigh=${P1}&PInc=${INC}"
   TYP="isotherm"
   echo " ** isothermal properties **"
   echoColumns '_' << EOF
   NIST ID_= ${ID}
   T/${UD_T}_= ${T}
   P(low)/${UD_P}_= ${P0}
   P(high)/${UD_P}_= ${P1}
   P(inc)/${UD_P}_= ${INC}
   Digits/#_= ${DIGI}
EOF
elif [ $ISOX -eq 3 ]; then  # isochor
   PARA="Type=IsoChor&D=${D}&TLow=${T0}&THigh=${T1}&TInc=${INC}"
   TYP="isochor"
   echo " ** isochoric properties **"
   echoColumns '_' << EOF
   NIST ID_= ${ID}
   Dens/${UD_D}_= ${D}
   T(low)/${UD_T}_= ${T0}
   T(high)/${UD_T}_= ${T1}
   T(inc)/${UD_T}_= ${INC}
   Digits/#_= ${DIGI}
EOF
elif [ $ISOX -eq 4 ]; then  # Saturation Properties - Pressure Increments
   PARA="Type=SatT&PLow=${P0}&PHigh=${P1}&PInc=${INC}"
   TYP="satT"
   echo " ** saturation properties **"
   echoColumns '_' << EOF
   NIST ID_= ${ID}
   P(low)/${UD_P}_= ${P0}
   P(high)/${UD_P}_= ${P1}
   P(inc)/${UD_P}_= ${INC}
   Digits/#_= ${DIGI}
EOF
elif [ $ISOX -eq 5 ]; then  # Saturation Properties - Temperature Increments
   PARA="Type=SatP&TLow=${T0}&THigh=${T1}&TInc=${INC}"
   TYP="satP"
   echo " ** saturation properties **"
   echoColumns '_' << EOF
   NIST ID_= ${ID}
   T(low)/${UD_T}_= ${T0}
   T(high)/${UD_T}_= ${T1}
   T(inc)/${UD_T}_= ${INC}
   Digits/#_= ${DIGI}
EOF
else   # error!
   echo " Error! You must define a typ: '-ib|-it|-ic'."
   echo " Type 'fluids.sh -h' for further help."
   echo " "
   exit 1
fi

# output file name?
#--------------------------------------------------------------------
[ -z "$OUTF" ] && OUTF="${SOUTF}_${TYP}.dat"

# construct URL's by concatenate address and GET parameter
#--------------------------------------------------------------------
NIST="http://webbook.nist.gov/cgi/fluid.cgi"
EOSID="ID=${ID}&RefState=${REFSTATE}"
SET="${EOSID}&${UNITS}&${PARA}&Digits=${DIGI}"
URL1="${NIST}?Action=Load&${SET}"
URL2="${NIST}?Action=Data&Wide=on&${SET}"

# Do the request from NIST webbook!
#--------------------------------------------------------------------
# Prepare data at NIST web page...
echo -n " <= send request to NIST ..."
wget -O /dev/null -o /dev/null "$URL1"
echo " done!"
# ,and retrieve the data.
echo -n " => retrieve data from NIST ..."
wget -O nwb.temp -o /dev/null "$URL2"
echo " done!"

# check retrieved file
#--------------------------------------------------------------------
h1=$((`cat nwb.temp | wc -l`-1))
h2=`tail -n 1 nwb.temp | wc -w`

# output of header to data file
#--------------------------------------------------------------------
saveInputToFile $OUTF << EOF
   # Fluid properties from NIST Chemistry WebBook (http://webbook.nist.gov/chemistry/)
   # $SUBST ($TYP) $DATE
   # ---------------------------------------------------------------------------
EOF
if [ $h2 -eq 14 ]; then
   SUBH=1
   addColumnsToFile '_' $OUTF << EOF
        #  1) Temperature (${UD_T})_ 2) Pressure (${UD_P})_ 3) Density (${UD_D})
        #  4) Volume (${UD_VO})_ 5) Int. Energy (${UD_E})_ 6) Enthalpy (${UD_E})
        #  7) Entropy (${UD_E2})_ 8) Cv (${UD_E2})_ 9) Cp (${UD_E2})
        # 10) Sound Spd. (${UD_V})_11) Joule-Thomson (${UD_T}/${UD_P})_12) Viscosity (${UD_W})
        # 13) Therm. Cond. (W/m*K)_14) Phase
EOF
elif [ $h2 -eq 28 ]; then
   SUBH=1
   addColumnsToFile '_' $OUTF << EOF
       #  1) Temperature (${UD_T})_ 2) Pressure (${UD_P}) 
       #  3) Quality (l+v)_ 4) Internal Energy (l+v, ${UD_E})
       #  5) Enthalpy (l+v, ${UD_E})_ 6) Entropy (l+v, ${UD_E2})   
       #  7) Density (l, ${UD_D})_ 8) Volume (l, ${UD_VO})
       #  9) Internal Energy (l, ${UD_E})_10) Enthalpy (l, ${UD_E})
       # 11) Entropy (l, ${UD_E2})_12) Cv (l, ${UD_E2})
       # 13) Cp (l, ${UD_E2})_14) Sound Spd. (l, ${UD_V})
       # 15) Joule-Thomson (l, ${UD_T}/${UD_P})_16) Viscosity (l, ${UD_W})
       # 17) Therm. Cond. (l, W/m*K)_18) Density (v, ${UD_D})
       # 19) Volume (v, ${UD_VO})_20) Internal Energy (v, ${UD_E})
       # 21) Enthalpy (v, ${UD_E})_22) Entropy (v, ${UD_E2})
       # 23) Cv (v, ${UD_E2})_24) Cp (v, ${UD_E2})
       # 25) Sound Spd. (v, ${UD_V})_26) Joule-Thomson (v, ${UD_T}/${UD_P})
       # 27) Viscosity (v, ${UD_W})_28) Therm. Cond. (v, W/m*K)
EOF
elif [ $h2 -eq 25 ]; then
   SUBH=1
   addColumnsToFile '_' $OUTF << EOF
       #  1) Temperature (${UD_T})_ 2) Pressure (${UD_P}) 
       #  3) Density (l, ${UD_D})_ 4) Volume (l, ${UD_VO})
       #  5) Internal Energy (l, ${UD_E})_ 6) Enthalpy (l, ${UD_E})
       #  7) Entropy (l, ${UD_E2})_ 8) Cv (l, ${UD_E2})
       #  9) Cp (l, ${UD_E2})_10) Sound Spd. (l, ${UD_V})
       # 11) Joule-Thomson (l, ${UD_T}/${UD_P})_12) Viscosity (l, ${UD_W})
       # 13) Therm. Cond. (l, W/m*K)_14) Surf. Tension (l, ${UD_S})
       # 15) Density (v, ${UD_D})_16) Volume (v, ${UD_VO})
       # 17) Internal Energy (v, ${UD_E})_18) Enthalpy (v, ${UD_E})
       # 19) Entropy (v, ${UD_E2})_20) Cv (v, ${UD_E2})
       # 21) Cp (v, ${UD_E2})_22) Sound Spd. (v, ${UD_V})
       # 23) Joule-Thomson (v, ${UD_T}/${UD_P})_24) Viscosity (v, ${UD_W})
       # 25) Therm. Cond. (v, W/m*K)
EOF
fi

# filter retrieved file and substitute header
#--------------------------------------------------------------------
if [ $SUBH -eq 1 ]; then
   tail -n $h1 nwb.temp >> $OUTF
   echo " -> found $h2 columns"
else
   cat nwb.temp >> $OUTF
   echo "Warning! Can't identify the output format. ($h2)"
fi
rm nwb.temp

# 'good bye' message
#--------------------------------------------------------------------
echo " -> table with $h1 data points written to $OUTF!"
echo "script finished!"
echo " "
exit

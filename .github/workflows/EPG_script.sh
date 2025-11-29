#!/bin/bash
# ============================================================================== 
# Script: miEPG.sh 
# Versión: 3.2 (corregido)
# Función: Combina múltiples XMLs, renombra canales, cambia logos y ajusta hora 
# ============================================================================== 

sed -i '/^ *$/d' epgs.txt
sed -i '/^ *$/d' canales.txt

rm -f EPG_temp* canales_epg*.txt

epg_count=0

while IFS=, read -r epg; do
	((epg_count++))
    extension="${epg##*.}"

    if [ "$extension" = "gz" ]; then
        echo "Descargando y descomprimiendo: $epg"
        wget -O EPG_temp00.xml.gz -q "$epg"
        if [ ! -s EPG_temp00.xml.gz ]; then
            echo "  Error: Archivo vacío o fallo en la descarga"
            continue
        fi
        if ! gzip -t EPG_temp00.xml.gz 2>/dev/null; then
            echo "  Error: No es un gzip válido"
            continue
        fi
        gzip -d -f EPG_temp00.xml.gz
    else
        echo "Descargando: $epg"
        wget -O EPG_temp00.xml -q "$epg"
        if [ ! -s EPG_temp00.xml ]; then
            echo "  Error: Archivo descargado vacío"
            continue
        fi
    fi

	if [ -f EPG_temp00.xml ]; then
        listado="canales_epg${epg_count}.txt"
        echo "# Fuente: $epg" > "$listado"

		awk '
		/<channel / {
		    match($0, /id="([^"]+)"/, a); id=a[1]; name=""; logo="";
		}
		/<display-name[^>]*>/ && name == "" {
		    match($0, /<display-name[^>]*>([^<]+)<\/display-name>/, a);
		    name=a[1];
		}
		/<icon src/ {
		    match($0, /src="([^"]+)"/, a); logo=a[1];
		}
		/<\/channel>/ {
		    print id "," name "," logo;
		}
		' EPG_temp00.xml >> "$listado"

		cat EPG_temp00.xml >> EPG_temp.xml
        sed -i 's/></>\n</g' EPG_temp.xml		
    fi	

done < epgs.txt


# =========================================
# Cargar canales desde canales.txt
# =========================================

mapfile -t canales

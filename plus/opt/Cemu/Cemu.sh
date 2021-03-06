#!/bin/sh

# Variáveis externas
JOGO="$1"
CORE="$2"

# Variáveis da instalação e execução do Cemu
CEMU_DIR='/opt/Cemu'
CEMU="$HOME/configs/cemu"
SAVE="$HOME/../saves/wiiu"

# Executa o Cemu/Wine se não estiver sendo executado
if [ "$(pidof wineserver)" ]; then
    exit 1
fi

# Instalação do Cemu
if [ ! "$(ls -A "${CEMU}" 2> /dev/null)" ] || [ ! "$(ls -A "${SAVE}"  2> /dev/null)" ]; then
    # Montando o cemu em "system/configs/cemu"
    mkdir -p "$(dirname "${CEMU}/log.txt")"                     || exit $?
    ln -s "${CEMU}/log.txt" "${HOME}/logs/cemu.log"
    cp -r "${CEMU_DIR}/emulator/resources"            "${CEMU}" || exit $?
    cp -r "${CEMU_DIR}/cemuextras/sharedFonts"        "${CEMU}" || exit $?
    cp -r "${CEMU_DIR}/cemuhook/keystone.dll"         "${CEMU}" || exit $?
    cp -r "${CEMU_DIR}/emulator/Cemu.exe"             "${CEMU}" || exit $?
    cp -r "${CEMU_DIR}/cemuextras/cemuhook.ini"       "${CEMU}" || exit $?
    cp -r "${CEMU_DIR}/cemuhook/dbghelp.dll"          "${CEMU}" || exit $?
    cp -r "${CEMU_DIR}/cemuextras/keys.txt"           "${CEMU}" || exit $?
    cp -r "${CEMU_DIR}/fakefiles/otp.bin"             "${CEMU}" || exit $?
    cp -r "${CEMU_DIR}/fakefiles/seeprom.bin"         "${CEMU}" || exit $?
    cp -r "${CEMU_DIR}/cemuextras/settings.xml"       "${CEMU}" || exit $?

    # Montando o cemu em "share/save/wiiu"
    mkdir -p "${SAVE}/hfiomlc01"                                || exit $?
    cp -r "${CEMU_DIR}/cemuextras/controllerProfiles" "${SAVE}" || exit $?
    cp -r "${CEMU_DIR}/emulator/gameProfiles"         "${SAVE}" || exit $?
    cp -r "${CEMU_DIR}/emulator/graphicPacks"         "${SAVE}" || exit $?
    cp -r "${CEMU_DIR}/cemuhook/graphicPacks"         "${SAVE}" || exit $?
    cp -r "${CEMU_DIR}/cemuextras/graphicPacks"       "${SAVE}" || exit $?
    cp -r "${CEMU_DIR}/fakefiles/mlc01"               "${SAVE}" || exit $?
    cp -r "${CEMU_DIR}/emulator/shaderCache"          "${SAVE}" || exit $?

    # Criando links simbólicos para a pasta "system/configs/cemu"
    ln -s "${SAVE}/"* "${CEMU}"
fi

# Muda a linguagem do Cemu de acordo com a liguagem do sistema
SLANG="$(batocera-settings -command load -key system.language)"
case $SLANG in
    fr_FR)             sed -i 's/<language>.*/<language>79<\/language>/'  "$CEMU/settings.xml" ;;
    en_US|en_GB|eu_ES) sed -i 's/<language>.*/<language>57<\/language>/'  "$CEMU/settings.xml" ;;
    de_DE)             sed -i 's/<language>.*/<language>88<\/language>/'  "$CEMU/settings.xml" ;;
    pt_BR)             sed -i 's/<language>.*/<language>153<\/language>/' "$CEMU/settings.xml" ;;
    es_ES)             sed -i 's/<language>.*/<language>179<\/language>/' "$CEMU/settings.xml" ;;
    it_IT)             sed -i 's/<language>.*/<language>109<\/language>/' "$CEMU/settings.xml" ;;
    tr_TR)             sed -i 's/<language>.*/<language>214<\/language>/' "$CEMU/settings.xml" ;;
    zh_CN)             sed -i 's/<language>.*/<language>44<\/language>/'  "$CEMU/settings.xml" ;;
 esac

# Checa se a interface foi executada de forma correta na última vez
# Esse site salvou minha vida https://dwaves.de/tools/escape/
if [ "$(grep '<check_update>true<\/check_update>' "${CEMU}/settings.xml" )" ]; then
    sed -i 's/<check_update>true<\/check_update>/<check_update>false<\/check_update>/' "${CEMU}/settings.xml"
fi

# Habilita as dependências necessárias para a execução do Cemu no menu F1
export WINEDLLOVERRIDES="keystone.dll=n,b;dbghelp.dll=n,b"

# Checa se as otimizações foram ativadas no emulationstation ALTAMENTE EXPERIMENTAL!
if [ "${CORE}" == 'cemu-nvidia' ] ; then
    export mesa_glthread=true
    export vblank_mode=0
    export WINEESYNC=1
elif [ "${CORE}" == 'cemu-amd' ] ; then
    export R600_DEBUG=nohyperz
    export mesa_glthread=true
    export vblank_mode=0
    export WINEESYNC=1
fi

# Checa se tem uma rom válida na variável JOGO
# Este também é o gatilho pra decidir se o GUI será aberto ou se o jogo será executado em linha de comando
EXT='.wud .wux .iso .wad .rpx .elf .WUD .WUX .ISO .WAD .RPX .ELF'
for i in ${EXT}; do
    if [ "$(echo "${JOGO}" | grep "${i}")" ]; then
        JOGO="$(echo "Z:${JOGO}" | sed -e 's#/#\\#g')"
        break
    fi
done

# Ativa autoupdate do Cemu se ele for executado pelo menu F1
if [ "$(grep '<check_update>false<\/check_update>' "$CEMU/settings.xml" )" ] && [ "${JOGO}" == '' ]; then
    sed -i 's/<check_update>false<\/check_update>/<check_update>true<\/check_update>/' "${CEMU}/settings.xml"
fi

# É sempre bom avisar ao usuário porque o controle dele não funciona.
if ! [ "$(ls -1 "$CEMU/controllerProfiles" | grep '.txt' | tail -n 1)" ] && [ "${JOGO}" == '' ]; then
      /bin/echo -e "\nAVISO\nConfigure um controle\npara o Cemu no menu F1" | LC_ALL=C HOME=/userdata/system DISPLAY=:0.0 osd_cat -f -*-*-bold-*-*-*-32-120-*-*-*-*-*-* -cred -s 2 -d 4 -l 100 -cgreen -o 480 -A center
fi

# Captura a resolução da tela antes de iniciar o jogo
RES_START="$(batocera-resolution currentMode)"

# Executa o Cemu com as configurações selecionadas
if [ "${JOGO}" == '' ]; then
    wine "${CEMU}/Cemu.exe"
    sed -i 's/<check_update>true<\/check_update>/<check_update>false<\/check_update>/' "${CEMU}/settings.xml"
else
    wine "${CEMU}/Cemu.exe" -f -g "${JOGO}"
fi

# Aguarda o Cemu encerrar a execução
while [ "$(pidof wineserver)" ]; do
    sleep 1
done

# Restaura a resolução do jogo caso tenha mudado
RES_STOP="$(batocera-resolution currentResolution)"
if [ "${RES_START}" != "${RES_STOP}" ]; then
    batocera-resolution setMode "${RES_START}"
fi

exit 0
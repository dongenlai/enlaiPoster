echo "[run all MahJongVip_HaErBin_process ......]"
who=`whoami`
echo $who

limitsFile=/etc/security/limits.conf
if [ "unlimited" != `egrep "^*.*soft.*core.*" $limitsFile | awk -F' ' '{print $4}'` ]; then
    echo "set core size to unlimited"
    sed  -i  's/^#\*\(.*soft\)\(.*core\)\(.*\)0/* \1\2\3unlimited/' $limitsFile
fi

if [ "$who" = "root" ]
then
    echo "start server via root"
fi

path=`pwd`
${path}/MahJongVip_HaErBin_DbMgr ./cfgDbMgr.ini 2 &
${path}/MahJongVip_HaErBin_AreaMgr ./cfgAreaMgr.ini 1 &
${path}/MahJongVip_HaErBin_GameArea ./cfgArea62601001.ini 62601001 &

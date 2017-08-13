/*----------------------------------------------------------------
// 模块名：type_area
// 模块描述：area相关数据类型定义。
//----------------------------------------------------------------*/


#include "type_area.h"
#include "global_var.h"


TTableRuleInfo::TTableRuleInfo(TTableRuleInfo& other)
{
    isChunJia = other.isChunJia;
    isLaizi = other.isLaizi;
    isGuaDaFeng = other.isGuaDaFeng;
    isSanQiJia = other.isSanQiJia;
    isDanDiaoJia = other.isDanDiaoJia;
    isZhiDuiJia = other.isZhiDuiJia;
    isZhanLiHu = other.isZhanLiHu;
    isMenQingJiaFen = other.isMenQingJiaFen;
    isAnKeJiaFen = other.isAnKeJiaFen;
    isKaiPaiZha = other.isKaiPaiZha;
    isBaoZhongBao = other.isBaoZhongBao;
    isHEBorDQ = other.isHEBorDQ;
}

void TTableRuleInfo::setTableRule(bool chunjia, bool hongzhongBao, bool guadafeng, bool sanqijia, bool dandiaojia, bool zhiduijia, bool zhanli, bool menqing, bool anke, bool kaipaizha, bool baozhongbao, int haerbinOrdaqing)
{
    isChunJia = chunjia;
    isLaizi = hongzhongBao;
    isGuaDaFeng = guadafeng;
    isSanQiJia = sanqijia;
    isDanDiaoJia = dandiaojia;
    isZhiDuiJia = zhiduijia;
    isZhanLiHu = zhanli;
    isMenQingJiaFen = menqing;
    isAnKeJiaFen = anke;
    isKaiPaiZha = kaipaizha;
    isBaoZhongBao = baozhongbao;
    isHEBorDQ = haerbinOrdaqing;

    LogInfo("TTableRuleInfo::setTableRule", "isChunJia:%d - isLaizi:%d - isGuaDaFeng:%d - isSanQiJia:%d - isDanDiaoJia:%d - isZhiDuiJia:%d - isZhanLiHu:%d - isMenQingJiaFen:%d - isAnKeJiaFen:%d - isKaiPaiZha:%d - isBaoZhongBao:%d- isHEBorDQ:%d",
                                                isChunJia, isLaizi, isGuaDaFeng, isSanQiJia, isDanDiaoJia, isZhiDuiJia, isZhanLiHu, isMenQingJiaFen, isAnKeJiaFen, isKaiPaiZha, isBaoZhongBao,  isHEBorDQ);//try
}

void TTableRuleInfo::WriteTableRuleToPluto(CPluto& u)
{
    u << int32_t(isChunJia) << int32_t(isLaizi) << int32_t(isGuaDaFeng) << int32_t(isSanQiJia) << int32_t(isDanDiaoJia) << int32_t(isZhiDuiJia) << int32_t(isZhanLiHu)
        << isMenQingJiaFen << isAnKeJiaFen << isKaiPaiZha << isBaoZhongBao << isHEBorDQ;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////

CPlayerUserInfo::CPlayerUserInfo()
{
    Clear();
}

CPlayerUserInfo::~CPlayerUserInfo()
{

}

void CPlayerUserInfo::Clear()
{
}

void CPlayerUserInfo::RoundClear()
{
}

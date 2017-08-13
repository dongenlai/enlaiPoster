﻿#ifndef __EXCEPTION__HEAD__
#define __EXCEPTION__HEAD__

#include "win32def.h"
#include "my_stl.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include "util.h"




//自定义异常类
class CException
{
    public:
        CException(int nCode, const string& strMsg);
        CException(int nCode, const char* pszMsg);
        //CException(int nCode, const char* pszMsg, ...);
        ~CException();

    public:
        inline int GetCode() const
        {
            return m_nCode;
        }

        inline string GetMsg() const
        {
            return m_strMsg;
        }

    private:
        int m_nCode;
        string m_strMsg;

};


inline void ThrowException(int n, const string& s)
{
    throw CException(n, s);
}

extern void ThrowException(int n, const char* s, ...);


#endif

#ifndef __WORLD_SELECT_HEAD__
#define __WORLD_SELECT_HEAD__

#include "world.h"

extern world* g_pTheWorld;

inline world* GetWorld()
{
    return g_pTheWorld;
}


#endif


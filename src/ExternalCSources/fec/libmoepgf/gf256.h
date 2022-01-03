//
// Created by consti10 on 03.01.22.
//

#ifndef WIFIBROADCAST_XX_GF256_H
#define WIFIBROADCAST_XX_GF256_H

#include "gf256tables285.h"

static const uint8_t mult[MOEPGF256_SIZE][MOEPGF256_SIZE] = MOEPGF256_MUL_TABLE;

static void
xorr_scalar(uint8_t *region1, const uint8_t *region2, size_t length)
{
    for(; length; region1++, region2++, length--)
        *region1 ^= *region2;
}

static void
maddrc256_flat_table(uint8_t *region1, const uint8_t *region2,
                     uint8_t constant, size_t length)
{
    if (constant == 0)
        return;

    if (constant == 1) {
        xorr_scalar(region1, region2, length);
        return ;
    }

    for (; length; region1++, region2++, length--) {
    	*region1 ^= mult[constant][*region2];
    }

}

#endif //WIFIBROADCAST_XX_GF256_H
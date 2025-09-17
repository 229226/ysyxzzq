#ifndef __DIFF_TEST_HPP_
#define __DIFF_TEST_HPP_

#include "common.hpp"

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };

void diff_init();
void diff_step();

#endif
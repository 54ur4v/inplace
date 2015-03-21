#pragma once

#include "introspect.h"
#include "index.h"
#include "equations.h"

namespace inplace {

namespace c2r {
void transpose(bool row_major, float* data, int m, int n);
void transpose(bool row_major, double* data, int m, int n);
}
namespace r2c {
void transpose(bool row_major, float* data, int m, int n);
void transpose(bool row_major, double* data, int m, int n);
}

void transpose(bool row_major, float* data, int m, int n);
void transpose(bool row_major, double* data, int m, int n);

namespace variants {

  template<typename T>
  void r2c_transpose(bool row_major, T* data, int m, int n);

  template<typename T>
  void c2r_transpose(bool row_major, T* data, int m, int n);

  template<typename T>
  void r2c_skinny_transpose(bool row_major, T* data, int m, int n);

  template<typename T>
  void c2r_skinny_transpose(bool row_major, T* data, int m, int n);

} // ns variants

}


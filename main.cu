#include <iostream>
#include "transpose.h"

#include <thrust/device_vector.h>
#include <thrust/iterator/counting_iterator.h>

#include <cstdlib>

template<typename T>
struct column_major_order {
    typedef T result_type;

    int m_m;
    int m_n;

    __host__ __device__
    column_major_order(const int& m, const int& n) :
        m_m(m), m_n(n) {}
    
    __host__ __device__ T operator()(const int& idx) {
        int row = idx % m_n;
        int col = idx / m_n;
        return row * m_m + col;
    }
};

template<typename T>
struct row_major_order {
    typedef T result_type;

    int m_m;
    int m_n;

    __host__ __device__
    row_major_order(const int& m, const int& n) :
        m_m(m), m_n(n) {}

    __host__ __device__ T operator()(const int& idx) {
        int row = idx % m_n;
        int col = idx / m_n;
        return col * m_n + row;
    }
};

template<typename T, typename F>
bool is_ordered(const thrust::device_vector<T>& d,
                F fn) {
    return thrust::equal(d.begin(), d.end(),
                         thrust::make_transform_iterator(
                             thrust::counting_iterator<int>(0),
                             fn));
}


template<typename T>
void print_array(int m, int n, const thrust::device_vector<T>& d) {
    thrust::host_vector<T> h = d;
    for(int i = 0; i < m; i++) {
        for(int j = 0; j < n; j++) {
            T x = h[i * n + j];
            if (x < 100) {
                std::cout << " ";
            }
            if (x < 10) {
                std::cout << " ";
            }
            std::cout << x << " ";
        }
        std::cout << std::endl;
    }
}

void visual_test(int m, int n) {
    thrust::device_vector<int> x(m*n);
    thrust::counting_iterator<int> c(0);
    thrust::transform(c, c+(m*n), x.begin(), column_major_order<int>(m, n));
    print_array(m, n, x);
    inplace::transpose_rm(m, n, thrust::raw_pointer_cast(x.data()));
    std::cout << std::endl;
    print_array(n, m, x);

}

void time_test(int m, int n) {
    std::cout << "Checking results for transpose of a " << m << " x " <<
        n << " matrix...";
    
    thrust::device_vector<int> x(m*n);
    thrust::counting_iterator<int> c(0);
    thrust::transform(c, c+(m*n), x.begin(), column_major_order<int>(m, n));
    //Preallocate temporary storage.
    thrust::device_vector<int> t(max(m,n)*inplace::n_ctas());
    cudaEvent_t start,stop;
    float time=0;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start, 0);

    
    inplace::transpose_rm(m, n,
                          thrust::raw_pointer_cast(x.data()),
                          thrust::raw_pointer_cast(t.data()));


    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&time, start, stop);
    std::cout << "  Time: " << time << " ms" << std::endl;
    float gbs = (float)(m * n * sizeof(float)) / (time * 1000000);
    std::cout << "  Throughput: " << gbs << " GB/s" << std::endl
              << std::endl;

    
    bool correct = is_ordered(x, row_major_order<int>(n, m));
    if (correct) {
        std::cout << "PASSES" << std::endl;
    } else {
        std::cout << "FAILS" << std::endl;
        exit(2);
    }
}

void generate_random_size(int& m, int &n) {
    size_t memory_size = inplace::gpu_memory_size();
    size_t ints_size = memory_size / sizeof(int);
    size_t e = (size_t)sqrt(double(ints_size));
    while(true) {
        long long lm = rand() % e;
        long long ln = rand() % e;
        size_t extra = inplace::n_ctas() * max(lm, ln);
        if ((lm * ln > 0) && ((lm * (ln + extra)) < ints_size)) {
            m = (int)lm;
            n = (int)ln;
            return;
        }
    }
}

int main() {
    cudaDeviceSetCacheConfig(cudaFuncCachePreferL1);

    for(int i = 0; i < 1000; i++) {
        int m, n;
        generate_random_size(m, n);
        time_test(m, n);
    }

}
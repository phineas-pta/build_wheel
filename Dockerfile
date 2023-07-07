FROM rocm/jax-build:rocm5.4.0-jax0.4.6.540-py3.10.0

WORKDIR /code

ENV PATH /code/cmake-3.26.3-linux-x86_64/bin:${PATH}
# cmake path not existed by default but installed below
# use cmake see https://github.com/microsoft/onnxruntime/blob/rel-1.15.0/dockerfiles/scripts/install_common_deps.sh

RUN wget --quiet https://github.com/Kitware/CMake/releases/download/v3.26.3/cmake-3.26.3-linux-x86_64.tar.gz &&\
    tar zxf cmake-3.26.3-linux-x86_64.tar.gz &&\
    git clone --single-branch --branch rel-1.15.0 --recursive https://github.com/Microsoft/onnxruntime &&\
    cd onnxruntime &&\
    python3.10 -m pip install -r requirements-dev.txt &&\
    python3.10 tools/ci_build/build.py \
      --allow_running_as_root \
      --build_dir=build/Linux \
      --config=Release \
      --enable_pybind \
      --build_wheel \
      --compile_no_warning_as_error \
      --parallel \
      --skip-keras-test \
      --skip_tests \
      --numpy_version=1.23.5 \
      --use_rocm \
      --rocm_home=/opt/rocm
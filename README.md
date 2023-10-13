# build some wheels

unofficial helper for `roop` users: https://github.com/s0md3v/roop<br />also other projects derived from `roop`

some packages are difficult to install with `pip`

this repo setup GitHub Actions for easy wheel building, go to Releases to download wheels

to have 100% unchanged code, instead of a fork, packages source code are taken using https://github.com/actions/checkout

DISCLAIMER: use at your own risk, not related or affiliated to the original packages devs

wheels are built with custom commands instead of using https://github.com/pypa/cibuildwheel

## `insightface` on Windows

original: https://github.com/deepinsight/insightface

installing failed usually because of the `mesh` C++ extension in `insightface/python-package/insightface/thirdparty/face3d/mesh/cython`

if error `'stdio.h' not found` copy file `stdio.h` from `C:\Program Files\Microsoft Visual Studio\2022\Community\SDK\ScopeCppSDK\vc15\SDK\include\ucrt` to `C:\Program Files (x86)\Windows Kits\10\Include\10.0.x.x\ucrt`

## `onnxruntime-silicon` on macOS

original: https://github.com/microsoft/onnxruntime … but versions ≤ 1.14.1 have memory leak, versions ≥ 1.15 make blurry face

introducing unofficial v1.14.2: https://github.com/verback2308/onnxruntime/tree/rel-1.14.2 (use at your own risk)

since there is no Apple Silicon runner with GitHub Actions (yet), the wheels aren’t `arm64`

for Apple Silicon: better build on local PC, see below

### guide to locally build `onnxruntime`

inspired from https://github.com/cansik/onnxruntime-silicon/blob/main/README.md

make sure to have Python arm64 not x64

```bash
file $(which python3)
# should get something like 'Mach-O ... arm64' without any 'x86_64' nor 'universal 2'
```

install build tools `brew install cmake pkg-config wget git git-lfs protobuf`

prepare another `venv` / `pyenv` / `conda` environment with python3.10 (compatible with `roop`)

clone the repo (pretty heavy but “download as zip” cause building error) `git clone --single-branch --branch rel-1.14.2 --depth 1 --recurse-submodules --shallow-submodules https://github.com/verback2308/onnxruntime`

install building dependencies `pip install -r requirements-dev.txt`

build with

```bash
python3 tools/ci_build/build.py \
  --build_dir=build/MacOS \
  --config=Release \
  --enable_pybind \
  --build_wheel \
  --compile_no_warning_as_error \
  --parallel \
  --skip-keras-test \
  --skip_tests \
  --numpy_version=1.24.3 \
  --wheel_name_suffix=-silicon \
  --osx_arch=arm64 \
  --use_coreml
```

the wheels should be in `build/MacOS/Release/dist` with name like `onnxruntime_silicon-1.14.2-cp310-cp310-macosx_..._arm64.whl`

#### troubleshooting with local building

if error with `libre2.9.dylib` run

```bash
# see hidden comments in https://github.com/s0md3v/roop/issues/321
brew install re2
cd /opt/homebrew/lib
cp libre2.10.dylib libre2.9.dylib
# ln -s libre2.9.dylib ~/miniconda3/envs/███/lib/libre2.9.dylib
```

if error with `flatbuffers` run `brew install flatbuffers` and grab some header files from https://github.com/google/flatbuffers

## `onnxruntime-rocm` on Linux

since it’s still painful to install ROCm in Linux, better use docker, but the official dockerfile is Python 3.7: https://github.com/microsoft/onnxruntime/blob/rel-1.15.0/dockerfiles/Dockerfile.rocm

here my dockerfile to build wheel on Python 3.10 + ROCm 5.4 compatible with ONNXruntime 1.15

```dockerfile
FROM rocm/jax-build:rocm5.4.0-jax0.4.6.540-py3.10.0

WORKDIR /code

ENV PATH /code/cmake-3.26.3-linux-x86_64/bin:${PATH}
# cmake path not existed by default but installed below
# use cmake see https://github.com/microsoft/onnxruntime/blob/rel-1.15.0/dockerfiles/scripts/install_common_deps.sh

RUN wget --quiet https://github.com/Kitware/CMake/releases/download/v3.26.3/cmake-3.26.3-linux-x86_64.tar.gz &&\
    tar zxf cmake-3.26.3-linux-x86_64.tar.gz &&\
    git clone \
      --single-branch \
      --branch rel-1.15.0 \
      --depth 1 \
      --recurse-submodules \
      --shallow-submodules \
      https://github.com/microsoft/onnxruntime &&\
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
      --numpy_version=1.24.3 \
      --use_rocm \
      --rocm_home=$ROCM_PATH
```

build image with `docker build -t onnxruntime-rocm -f Dockerfile .` (up to 1h of 100% cpu usage)

run image `docker run -v $PWD:/opt/mount -w /code/onnxruntime/build/Linux/Release/dist --rm -it onnxruntime-rocm`

in container console, copy wheel `cp *.whl /opt/mount` when done `exit`

get image file size `docker inspect -f "{{ .Size }}" onnxruntime-rocm | numfmt --to=si`

remove image `docker rmi -f onnxruntime-rocm`

**UPDATE** with `facefusion`

```dockerfile
ARG ROCM_VERSION=5.6
ARG CMAKE_VERSION=3.27.4
ARG ONNXRUNTIME_VERSION=1.16.0
ARG NUMPY_VERSION=1.24.3
ARG FACEFUSION_VERSION=1.3.1

FROM rocm/dev-ubuntu-22.04:${ROCM_VERSION}-complete AS base

RUN apt-get update
RUN apt-get install -y wget git python3-dev ffmpeg

# ~14gb rocm

###############################################################################

FROM base AS builder

ARG CMAKE_VERSION
ARG ONNXRUNTIME_VERSION
ARG NUMPY_VERSION
ARG CMAKE_FULL="cmake-${CMAKE_VERSION}-linux-x86_64"

RUN wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${CMAKE_FULL}.tar.gz
RUN tar zxf ${CMAKE_FULL}.tar.gz
ENV PATH /${CMAKE_FULL}/bin:${PATH}

RUN git clone \
      --depth 1 \
      --single-branch \
      --branch "rel-${ONNXRUNTIME_VERSION}" \
      --recurse-submodules \
      --shallow-submodules \
      https://github.com/microsoft/onnxruntime

WORKDIR /onnxruntime

RUN python3 -m pip install -q ninja
RUN python3 tools/ci_build/build.py \
      --allow_running_as_root \
      --build_dir "build" \
      --config "Release" \
      --enable_pybind \
      --build_wheel \
      --cmake_generator "Ninja" \
      --compile_no_warning_as_error \
      --parallel \
      --skip_tests \
      --skip_submodule_sync \
      --numpy_version $NUMPY_VERSION \
      --use_rocm \
      --enable_nccl \
      --rocm_home /opt/rocm \
      --nccl_home /opt/rocm

# 14gb rocm + 4gb onnxruntime

###############################################################################

FROM base AS server

ARG ROCM_VERSION
ARG FACEFUSION_VERSION

RUN wget -q https://github.com/facefusion/facefusion/archive/refs/tags/${FACEFUSION_VERSION}.tar.gz
RUN tar zxf ${FACEFUSION_VERSION}.tar.gz
RUN mv /facefusion-${FACEFUSION_VERSION} /facefusion

WORKDIR /facefusion

COPY --from=builder /onnxruntime/build/Release/dist /mywheels

RUN pip install \
      -q --no-cache-dir \
      -r requirements.txt \
      --extra-index-url https://download.pytorch.org/whl/rocm${ROCM_VERSION}
RUN pip uninstall -y onnxruntime
RUN pip install /mywheels/*.whl

ENV GRADIO_SERVER_NAME=0.0.0.0

# 14gb rocm + 14gb python (torch ~8gb), if enable + 6gb pip cache
```

## misc

Windows + AMD GPU → DirectML → need `pip install torch-directml tensorflow-directml onnxruntime-directml`

Linux + AMD GPU → ROCm → need `pip install tensorflow-rocm`, built above `onnxruntime-rocm` wheel and `torch torchvision --index-url https://download.pytorch.org/whl/rocm5.4.2`

Apple Silicon → CoreML + Metal → need `pip install tensorflow-macos tensorflow-metal`, built above `onnxruntime-silicon` wheel and additionally `torch device "mps"`

Intel hardware only → OpenVino + Ipex → need `pip install onnxruntime-openvino intel_extension_for_pytorch`

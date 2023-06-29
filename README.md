# build some wheels

unofficial helper for `roop` users: https://github.com/s0md3v/roop

some packages are difficult to install with `pip`

this repo setup GitHub Actions for easy wheel building, go to Releases to download wheels

to have 100% unchanged code, instead of a fork, packages source code are taken using https://github.com/actions/checkout

DISCLAIMER: use at your own risk, not related or affiliated to the original packages devs

wheels are built with custom commands instead of using https://github.com/pypa/cibuildwheel

## `insightface` on Windows

original: https://github.com/deepinsight/insightface

installing failed usually because of the `mesh` c++ extension in `insightface/python-package/insightface/thirdparty/face3d/mesh/cython`

## `onnxruntime-silicon` on macOS

original: https://github.com/microsoft/onnxruntime … but versions ≤ 1.14.1 have memory leak, versions ≥ 1.15 make blurry face

introducing unofficial v1.14.2: https://github.com/verback2308/onnxruntime/tree/rel-1.14.2 (use at your own risk)

since there is no Apple Silicon runner with GitHub Actions (yet), the wheels aren’t `arm64`

for Apple Silicon: better build on local PC, see below

### guide to locally build `onnxruntime`

inspired from https://github.com/cansik/onnxruntime-silicon/blob/main/README.md

make sure to have python arm64 not x64

```python
# see https://stackoverflow.com/q/71548156/10805680
import sysconfig
FULL_INFO = sysconfig.get_config_vars()
print({k: FULL_INFO[k] for k in ('HOST_GNU_TYPE', 'CONFIG_ARGS')})
# should get something like 'arm64-apple-darwin...'
```

install build tools `brew install cmake pkg-config wget git git-lfs protobuf`

prepare another `venv` / `pyenv` / `conda` environment with python3.10 (compatible with `roop`)

clone the repo (pretty heavy but “download as zip” cause building error) `git clone --recursive -b rel-1.14.2 https://github.com/verback2308/onnxruntime`

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
  --wheel_name_suffix=-silicon \
  --osx_arch=arm64 \
  --use_coreml
```

the wheels should be in `build/MacOS/Release/dist` with name like `onnxruntime_silicon-1.14.2-cp310-cp310-macosx_..._arm64.whl`

#### troubleshooting with local building

in case error with `libre2.9.dylib` run

```bash
# see hidden comments in https://github.com/s0md3v/roop/issues/321
brew install re2
cd /opt/homebrew/lib
cp libre2.10.dylib libre2.9.dylib
# ln -s libre2.9.dylib ~/miniconda3/envs/███/lib/libre2.9.dylib
```

in case error with `flatbuffers` run `brew install flatbuffers` and grab some header files from https://github.com/google/flatbuffers

## `onnxruntime-rocm` on Linux

since there is no AMD Linux runner with GitHub Actions (yet), there is no wheel here

just an attempt to build locally, inspired from above and https://onnxruntime.ai/docs/build/eps.html#amd-rocm

install ROCm and `cmake`, `gcc` version <12

prepare another `venv` / `pyenv` / `conda` environment with python3.10 (compatible with `roop`)

clone the repo (pretty heavy but “download as zip” cause building error) `git clone --recursive https://github.com/microsoft/onnxruntime`

install building dependencies `pip install -r requirements-dev.txt`

build with

```bash
python3 tools/ci_build/build.py \
  --build_dir=build/Linux \
  --config=Release \
  --enable_pybind \
  --build_wheel \
  --compile_no_warning_as_error \
  --parallel \
  --skip-keras-test \
  --skip_tests \
  --wheel_name_suffix=-rocm \
  --use_rocm \
  --rocm_home=<path to ROCm>
```

## `onnxruntime-tensorrt`

supposed to work with `onnxruntime-gpu` but not always

just an attempt to build locally, inspired from above and https://onnxruntime.ai/docs/build/eps.html#tensorrt

install CUDA, cuDNN, TensorRT and `cmake`, `gcc` version <12

prepare another `venv` / `pyenv` / `conda` environment with python3.10 (compatible with `roop`)

clone the repo (pretty heavy but “download as zip” cause building error) `git clone --recursive https://github.com/microsoft/onnxruntime`

install building dependencies `pip install -r requirements-dev.txt`

build with

```bash
python3 tools/ci_build/build.py \
  --build_dir=build/Linux \
  --config=Release \
  --enable_pybind \
  --build_wheel \
  --compile_no_warning_as_error \
  --parallel \
  --skip-keras-test \
  --skip_tests \
  --wheel_name_suffix=-tensorrt \
  --use_tensorrt \
  --tensorrt_home=<path to TensorRT> \
  --cudnn_home=<path to cuDNN> \
  --cuda_home=<path to CUDA>
```

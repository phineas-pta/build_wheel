# build some wheels

unofficial helper for `roop` users: https://github.com/s0md3v/roop

some packages are difficult to install with `pip`

this repo setup GitHub Actions for easy wheel building, go to Releases to download wheels

to have 100% unchanged code, instead of a fork, packages source code are taken using https://github.com/actions/checkout

DISCLAIMER: use at your own risk, not related or affiliated to the original packages devs

wheels are built with custom commands, not using https://github.com/pypa/cibuildwheel

## `insightface` on Windows

original: https://github.com/deepinsight/insightface

installing failed usually because of the `mesh` c++ extension in `insightface/python-package/insightface/thirdparty/face3d/mesh/cython`

## `onnxruntime-silicon` on macOS

since there is no Apple Silicon runner with GitHub Actions (yet), the wheels aren’t `arm64` (maybe not best performance)

original: https://github.com/microsoft/onnxruntime … but versions ≤ 1.14.1 have memory leak, versions ≥ 1.15 make blurry face

introducing unofficial v1.14.2: https://github.com/verback2308/onnxruntime/tree/rel-1.14.2 (use at your own risk)

guide for local building, inspired from https://github.com/cansik/onnxruntime-silicon/blob/main/README.md
- install build tools `brew install cmake pkg-config wget git git-lfs protobuf`
- prepare another `venv` / `pyenv` / `conda` environment with python3.10 (compatible with `roop`)
- clone the repo (pretty heavy but “download as zip” cause building error) `git clone -b rel-1.14.2 https://github.com/verback2308/onnxruntime`
- install building dependencies `pip install -r requirements-dev.txt`
- build with `python3 tools/ci_build/build.py --build_dir build/MacOS --skip-keras-test --skip_tests --config=Release --enable_pybind --build_wheel --wheel_name_suffix=-silicon --osx_arch=arm64 --use_coreml --parallel=8`
- the wheels should be in `build/MacOS/Release/dist`

some weird error with `flatbuffers` run `brew install flatbuffers` and search some files in https://github.com/google/flatbuffers

in case of error with `libre2.9.dylib` run `brew install re2`, optionally symlink to ??
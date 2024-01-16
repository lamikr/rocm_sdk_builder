source /opt/rocm/bin/env_rocm.sh
python -m pip install --upgrade pip
pip install future leveldb numpy protobuf pydot python-gflags pyyaml scikit-image setuptools six hypothesis typing tqdm typing_extensions jupyterlab notebook pandas seaborn matplotlib opencv-python cufflinks ipywidgets wheel opt_einsum
pip install keras_preprocessing --no-deps



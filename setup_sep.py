# This script is to set up FlashPy with FlashMatrix, which is built separately.
from distutils.core import setup, Extension
from Cython.Build import cythonize
import os 
dir_path = os.path.dirname(os.path.realpath(__file__))

ext_modules = cythonize(Extension(
    "flashpy.mat",                                # the extension name
    sources=["flashpy/mat.pyx", "flashpy/MatrixWrapper.cpp"], # the Cython source and
    # additional C++ source files
    include_dirs = ["../matrix", "../libsafs"],
    libraries = ["hwloc", "cblas", "aio", "numa"],
    language="c++",                               # generate&compile C++ code
    extra_compile_args=['-fopenmp', '-std=c++11', '-O2'],
    extra_link_args=['-fopenmp'],
    extra_objects = ["../build/matrix/libFMatrix.a", "../build/libsafs/libsafs.a"],
    ))

setup(
    name="flashpy",
    version="0.0.1",
    description="A parallel and scalable library for matrix operations",
    long_description="FlashPy parallelizes and scales the API in NumPy, " +\
            "and the algorithms in SciPy. It extends " +\
            "memory capacity with SSDs and is optimized for NUMA machines",
    url="https://github.com/flashxio/FlashX",
    author="Da Zheng",
    author_email="zhengda1936@gmail.com",
    license="Apache License, Version 2.0",
    keywords="parallel scalable machine-learning NumPy SciPy",
    install_requires=[
        "numpy",
        "Cython==0.23.5",
        "cython==0.23.5",
        ],
    package_dir = {"flashpy": os.path.join("flashpy")},
    packages=["flashpy", "flashpy.linalg", "flashpy.special", "flashpy.sparse"],
    ext_modules = ext_modules,
)

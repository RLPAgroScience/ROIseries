from setuptools import setup

with open("README.rst") as f:
    long_description = f.read()

setup(
    name='ROIseries',
    description="Multitemporal Remote Sensing Feature Mining for Machine Learning Applications",
    license="AGPLv3",
    long_description=long_description,
    author="Niklas Keck",
    packages=["ROIseries",
              "ROIseries.feature_sommelier",
              "ROIseries.sub_routines", ]
)

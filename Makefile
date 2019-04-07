.DEFAULT_GOAL := all

inplace:
	python setup.py build_ext --inplace

all:
	python setup.py build_ext

clean:
	rm -rf build

clean-inplace:
	rm -rf autogentoo_api/*.so

install:
	python setup.py install

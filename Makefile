.DEFAULT_GOAL := all

all:
	python setup.py build_ext --inplace

clean:
	rm -rf build

install:
	python setup.py install

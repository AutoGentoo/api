.DEFAULT_GOAL := all

all:
	python setup.py build_ext

clean:
	rm -rf build

install:
	python setup.py install

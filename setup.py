from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
from Cython.Compiler import Options
from Cython.Distutils import build_ext

ex = [
	"vector",
	"dynamic_binary",
	"d_malloc",
	"request",
]

extensions = [
	Extension("autogentoo_api.%s" % x, ["autogentoo_api/%s.pyx" % x], extra_link_args=["-lautogentoo", "-lhacksaw", "-lssl"]) for x in ex]

Options.language_level = "3"

setup(
	name="autogentoo_api",
	version="2.01",
	ext_modules=cythonize(extensions, compiler_directives={'language_level': "3"}, build_dir="build"),
	cmdclass={'build_ext': build_ext},
	include_dirs=["."],
	#ext_package="autogentoo"
)

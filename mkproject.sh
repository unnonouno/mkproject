#!/bin/sh

# Copyright (c) 2012, Yuya Unno
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the Yuya Unno nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


if [ ! -f waf ]; then
    wget http://ftp.waf.io/pub/release/waf-1.7.16 -O waf
    chmod +x waf
fi

if [ ! -f unittest_gtest.py ]; then
    wget https://github.com/tanakh/waf-unittest/raw/master/unittest_gtest.py --no-check-certificate -O unittest_gtest.py
fi

if [ ! -f README.rst ]; then
    touch README.rst
fi

if [ ! -f wscript ]; then
    cat > wscript <<EOF
VERSION = '0.0.0'
APPNAME = 'appname'

def options(opt):
    opt.load('compiler_cxx')
    opt.load('unittest_gtest')

def configure(conf):
    conf.env.CXXFLAGS += ['-O2', '-Wall', '-g', '-pipe']
    conf.load('compiler_cxx')
    conf.load('unittest_gtest')

    # conf.check_cfg(package='pficommon', args='--cflags --libs')
    # conf.check_cxx(lib='libname', header_name='header.h')

def build(bld):
    bld.program(
        source='source.cpp',
        target='target',
        use=''
    )

def cpplint(ctx):
    cpplint_args = '--filter=-runtime/references,-build/include_order --extensions=cpp,hpp'

    src_dir = ctx.path.find_node('src')
    files = []
    for f in src_dir.ant_glob('**/*.cpp **/*.hpp'):
        files.append(f.path_from(ctx.path))

    args = 'cpplint.py %s %s 2>&1 | grep -v ^Done' % (cpplint_args,' '.join(files))
    result = ctx.exec_command(args)
    if result == 0:
        ctx.fatal('cpplint failed')

def gcovr(ctx):
    excludes = [
        '.*\\.unittest-gtest.*',
        '.*_test\\.cpp',
      ]

    args = 'gcovr --branches -r . '
    for e in excludes:
        args += ' -e "%s"' % e

    ctx.exec_command(args)
EOF
fi

if [ ! -f .gitignore ]; then
    cat > .gitignore <<EOF
*~
#*#
*_flymake.*
*.pyc
.unittest-gtest
.waf-*
build
.lock-waf*
EOF
fi

if [ ! -d src ]; then
    mkdir src
fi

cd src

if [ ! -f cmdline.h ]; then
    wget https://raw.github.com/tanakh/cmdline/master/cmdline.h --no-check-certificate -O cmdline.h
fi

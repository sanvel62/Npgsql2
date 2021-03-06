#!/bin/sh
#
# runtests.sh
#
# Copyright (C) 2002 The Npgsql Development Team
# npgsql-general@gborg.postgresql.org
# http://gborg.postgresql.org/project/npgsql/projdisplay.php
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


# -----------------------------------------------------------------------------
#
# Prepare the TestConnectionString class file used by all test files
#
# -----------------------------------------------------------------------------
echo "//
// This is an autogenerated file. DO NOT EDIT
//
// Npgsql.NpgsqlTests.cs
// 
// Copyright (C) 2002 The Npgsql Development Team
// npgsql-general@gborg.postgresql.org
// http://gborg.postgresql.org/project/npgsql/projdisplay.php
//

// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
// 
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

using System;

namespace Npgsql
{
    public sealed class NpgsqlTests
    {
	public static String getConnectionString()
	{
	    return     \"Server=${NPGSQL_HOST};User Id=${NPGSQL_UID};Password=${NPGSQL_PWD};Database=${NPGSQL_DB}\";
	}

    }
}
" > ${NPGSQL_TESTS_SHARED_SRC}

# Compile the autogenerated class
echo -n "Compiling autogenerated class file ${NPGSQL_TESTS_SHARED_SRC}..." && ( ${CC} --target library -o ${NPGSQL_TESTS_SHARED_LIB} ${NPGSQL_TESTS_SHARED_SRC} 2>&1 > /dev/null && echo "OK") || echo "FAILED"
CPPFLAGS="${CPPFLAGS} -r ${NPGSQL_TESTS_SHARED_LIB}"


# -----------------------------------------------------------------------------
#
# Run the tests
#
# -----------------------------------------------------------------------------
echo "All tests are compiled with: 
 \$ ${CC} ${CPPFLAGS} test_<name>.cs"
echo "All tests are run with:
 \$ ${MONO} test_<name>.exe"
test_failed=0
for file in `ls test_*.cs | sed -e s/test_// -e s/.cs//`;
do
    echo "------------------------------------------------------------"
    echo -n "Compiling test file test_$file.cs..." && \
    ( ${CC} ${CPPFLAGS} test_${file}.cs >> ${NPGSQL_TESTS_LOG} 2>&1 && echo "OK") || echo "FAILED"
    echo -n "Running test file test_${file}.exe..." && \
    ( ${MONO} test_${file}.exe 2>&1 |tee out_$file 2>&1 > /dev/null);
    if diff out_$file expected_$file 2>&1 > /dev/null
    then
	echo "OK"
    else
	test_failed=1
	echo "TEST FAILED. Differences are:"
	diff -u out_$file expected_$file
    fi
done

if [ $test_failed == 0 ];
then
    echo "==========================="
    echo "**** All tests passed  ****"
    echo "==========================="
    echo "OK" > ${NPGSQL_TEST_STATUS_FILE}
    exit 0
else
    echo "============================="
    echo "**** Some test(s) failed ****"
    echo "============================="
    echo "FAILED" > ${NPGSQL_TEST_STATUS_FILE}
    exit 1
fi

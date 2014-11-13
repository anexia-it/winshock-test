#!/bin/bash
#
# winshock_test.sh
#
# This script tries to determine whether the target system has the
# winshock (MS14-066) patches applied or not.
# This is done by checking if the SSL ciphers introduced by MS14-066 are
# available on the system.
#
#
# Authors:
#  Stephan Peijnik <speijnik@anexia-it.com>
#
# The MIT License (MIT)
#
# Copyright (c) 2014 ANEXIA Internetdienstleistungs GmbH
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


HOST=$1
PORT=${2:-443}

if [ -z "$HOST" -o -z "$PORT" ]
then
  echo "Usage: $0 host [port]"
  echo "port defaults to 443."
  exit 1
fi

SERVER=$HOST:$PORT
echo "Testing ${SERVER} for ciphers added in MS14-066..."

# According to https://technet.microsoft.com/library/security/ms14-066 the
# following ciphers were added with the patch:
# * TLS_DHE_RSA_WITH_AES_256_GCM_SHA384
# * TLS_DHE_RSA_WITH_AES_128_GCM_SHA256
# * TLS_RSA_WITH_AES_256_GCM_SHA384
# * TLS_RSA_WITH_AES_128_GCM_SHA256
#
# The OpenSSL cipher names for these ciphers are:
MS14_066_CIPHERS="DHE-RSA-AES256-GCM-SHA384 DHE-RSA-AES128-GCM-SHA256 AES256-GCM-SHA384 AES128-GCM-SHA256"

patched="no"
for cipher in ${MS14_066_CIPHERS}
do
  echo -en "Testing cipher ${cipher}: "
  result=$(echo -n | openssl s_client -cipher "$cipher" -connect $SERVER 2>&1)
  if [[ "$result" =~ "Cipher is ${cipher}" || "$result" =~ "Cipher    : ${cipher}" ]]
  then
    echo -e "\033[92mPASS\033[39m"
    if [[ "$patched" == "no" ]]
    then
      patched="yes"
    fi
  else
    echo -e "\033[91mFAIL\033[39m"
  fi
done

# added by @stoep: check whether a 443 port runs IIS
if [[ "$PORT" == "443" ]]
then
  iis=$(curl -I https://$SERVER 2> /dev/null | grep "Server" )
  echo -en "Testing whether IIS is running on 443 "
  if [[ $iis == *Microsoft-IIS* ]]
  then 
    echo -e "\033[91mYES\033[39m"

  else
    echo -e "\033[92mNO\033[39m"
    exit 0
  fi
fi

if [[ "$patched" == "yes" ]]
then
  patched="\033[92mYES\033[39m"
else
  patched="\033[91mDONTKNOW\033[39m"
fi

echo -e "System at $SERVER seems to be patched: $patched"
exit 0

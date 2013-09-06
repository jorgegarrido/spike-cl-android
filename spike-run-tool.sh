#!/system/bin/sh
#
# Copyright (c) 2012-2013, Jorge Garrido <zgbjgg@gmail.com>
# All rights reserved.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This script is intended for start an erlang node in detached mode, 
# the erlang node is running in background and others nodes can
# communicate with this using epmd
#

# Path(s)
ERTS_PATH=/data/data/com.ernovation.erlangforandroid/files/erlang/erts-5.10.1

HOME_PATH=/data/data/com.zgbjgg.erldroid/app_HOME

LOCAL=$PWD

# This settings is for distributed communication with other erlang nodes
# NOTE: As this erlang node runs over Android device the name of the node should be
#       the IMEI (next release could implement this)
NODE=zgbjgg

COOKIE=zgbjgg

# Get ip address by use IFS (Internal Field Separator)
NET_CONFIG=`ifconfig wlan0`
OLD_IFS="$IFS"
IFS=" "
STR_ARRAY=( $NET_CONFIG )
IFS="$OLD_IFS"
HOST="${STR_ARRAY[2]}" 

# Deployment Application Settings #
# ------------------------------- #

# Startup
$ERTS_PATH/bin/erl -noshell -pa $LOCAL/ebin -detached -heart -name $NODE@$HOST -setcookie $COOKIE 

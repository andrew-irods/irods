#!/bin/bash -e

IRODS_CONFIG_FILE="./iRODS/config/irods.config"
SETUP_RESOURCE_FLAG="/tmp/setup_resource.flag"

# get temp file from prior run, if it exists
if [ -f $SETUP_RESOURCE_FLAG ] ; then
    # have run this before, read the existing config file
    ICATHOSTORIP=`grep "IRODS_ICAT_HOST =" $IRODS_CONFIG_FILE | awk -F\' '{print $2}'`
    ICATPORT=`grep "IRODS_PORT =" $IRODS_CONFIG_FILE | awk -F\' '{print $2}'`
    ICATZONE=`grep "ZONE_NAME =" $IRODS_CONFIG_FILE | awk -F\' '{print $2}'`
    ADMINUSER=`grep "IRODS_ADMIN_NAME =" $IRODS_CONFIG_FILE | awk -F\' '{print $2}'`
    STATUS="loop"
else
    # no temp file, this is the first run
    STATUS="firstpass"
fi

echo "==================================================================="
echo ""
echo "You are installing an E-iRODS resource server.  Resource servers"
echo "cannot be started until they have been properly configured to"
echo "communicate with a live iCAT server."
echo ""
while [ "$STATUS" != "complete" ] ; do

  # set default values from an earlier loop
  if [ "$STATUS" != "firstpass" ] ; then
    LASTICATHOSTORIP=$ICATHOSTORIP
    LASTICATPORT=$ICATPORT
    LASTICATZONE=$ICATZONE
    LASTADMINUSER=$ADMINUSER
  fi

  # get host
  echo -n "iCAT server's hostname or IP address"
  if [ "$LASTICATHOSTORIP" ] ; then echo -n " [$LASTICATHOSTORIP]"; fi
  echo -n ": "
  read ICATHOSTORIP
  if [ "$ICATHOSTORIP" == "" ] ; then
    if [ "$LASTICATHOSTORIP" ] ; then ICATHOSTORIP=$LASTICATHOSTORIP; fi
  fi
  echo ""

  # get port
  echo -n "iCAT server's port"
  if [ "$LASTICATPORT" ] ; then
    echo -n " [$LASTICATPORT]"
  else
    echo -n " [1247]"
  fi
  echo -n ": "
  read ICATPORT
  if [ "$ICATPORT" == "" ] ; then
    if [ "$LASTICATPORT" ] ; then
      ICATPORT=$LASTICATPORT
    else
      ICATPORT=1247
    fi
  fi
  echo ""

  # get zone
  echo -n "iCAT server's ZoneName"
  if [ "$LASTICATZONE" ] ; then echo -n " [$LASTICATZONE]"; fi
  echo -n ": "
  read ICATZONE
  if [ "$ICATZONE" == "" ] ; then
    if [ "$LASTICATZONE" ] ; then ICATZONE=$LASTICATZONE; fi
  fi
  echo ""

  # get admin user
  echo -n "iRODS admin username"  
  if [ "$LASTADMINUSER" ] ; then
    echo -n " [$LASTADMINUSER]"
  else
    echo -n " [rods]"
  fi
  echo -n ": "
  read ADMINUSER
  if [ "$ADMINUSER" == "" ] ; then
    if [ "$LASTADMINUSER" ] ; then
      ADMINUSER=$LASTADMINUSER
    else
      ADMINUSER=rods
    fi
  fi
  echo ""

  # confirm
  echo "-------------------------------------------"
  echo "Hostname or IP:   $ICATHOSTORIP"
  echo "iCAT Port:        $ICATPORT"
  echo "iCAT Zone:        $ICATZONE"
  echo "Admin User:       $ADMINUSER"
  echo "-------------------------------------------"
  echo -n "Please confirm these settings [yes]: "
  read CONFIRM
  if [ "$CONFIRM" == "" -o "$CONFIRM" == "y" -o "$CONFIRM" == "Y" -o "$CONFIRM" == "yes" ]; then
    STATUS="complete"
  else
    STATUS="loop"
  fi
  echo ""
  echo ""

done
touch $SETUP_RESOURCE_FLAG
echo "==================================================================="

IRODS_CONFIG_TEMPFILE="/tmp/tmp.irods.config"
echo "Updating irods.config..."
sed -e "/^\$IRODS_ICAT_HOST/s/^.*$/\$IRODS_ICAT_HOST = '$ICATHOSTORIP';/" $IRODS_CONFIG_FILE > $IRODS_CONFIG_TEMPFILE
mv $IRODS_CONFIG_TEMPFILE $IRODS_CONFIG_FILE
sed -e "/^\$IRODS_PORT/s/^.*$/\$IRODS_PORT = '$ICATPORT';/" $IRODS_CONFIG_FILE > $IRODS_CONFIG_TEMPFILE
mv $IRODS_CONFIG_TEMPFILE $IRODS_CONFIG_FILE
sed -e "/^\$ZONE_NAME/s/^.*$/\$ZONE_NAME = '$ICATZONE';/" $IRODS_CONFIG_FILE > $IRODS_CONFIG_TEMPFILE
mv $IRODS_CONFIG_TEMPFILE $IRODS_CONFIG_FILE
sed -e "/^\$IRODS_ADMIN_NAME/s/^.*$/\$IRODS_ADMIN_NAME = '$ADMINUSER';/" $IRODS_CONFIG_FILE > $IRODS_CONFIG_TEMPFILE
mv $IRODS_CONFIG_TEMPFILE $IRODS_CONFIG_FILE
# clear unneeded resource name
sed -e "/^\$RESOURCE_NAME/s/^.*$/\$RESOURCE_NAME = '';/" $IRODS_CONFIG_FILE > $IRODS_CONFIG_TEMPFILE
mv $IRODS_CONFIG_TEMPFILE $IRODS_CONFIG_FILE
# clear unneeded resource directory name (vault path)
sed -e "/^\$RESOURCE_DIR/s/^.*$/\$RESOURCE_DIR = '';/" $IRODS_CONFIG_FILE > $IRODS_CONFIG_TEMPFILE
mv $IRODS_CONFIG_TEMPFILE $IRODS_CONFIG_FILE

echo "Running eirods_setup.pl..."
cd iRODS
perl ./scripts/perl/eirods_setup.pl


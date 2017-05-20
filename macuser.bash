#!/bin/bash
# =========================
# Add User OSX Command Line
# =========================

# An easy add user script for Max OSX.
# Although I wrote this for 10.7 Lion Server, these commands have been the same since 10.5 Leopard.
# It's pretty simple as it uses and strings together the (rustic and ancient) commands that OSX 
# already uses to add users.

# ====

## CUSTOM METHODSMB ##
# Exit if user already exists
if id -u $SHORTNAME "$1" >/dev/null 2>&1; then echo "The user already exists." && exit 1; fi
## END CUSTOM METHODSMB ##

# A list of (secondary) groups the user should belong to
# This makes the difference between admin and non-admin users.


if [ $MAKEADMIN = false ] ; then
    SECONDARY_GROUPS="staff"  # for a non-admin user
elif [ $MAKEADMIN = true ] ; then
    SECONDARY_GROUPS="admin _lpadmin _appserveradm _appserverusr" # for an admin user
else
    echo "You did not make a valid selection!  ($MAKEADMIN)"
fi

# ====

# Create a UID that is not currently in use
echo "Creating an unused UID for new user..."

# if  $UID -ne 0 ; then echo "Please run $0 as root." && exit 1; fi
## REMOVED - returning errors "command not found". not needed since AEM runs as root

# Find out the next available user ID
MAXID=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -ug | tail -1)
USERID=$((MAXID+1))


# Create the user account by running dscl (normally you would have to do each of these commands one
# by one in an obnoxious and time consuming way.
echo "Creating necessary files..."

dscl . -create /Users/$SHORTNAME
dscl . -create /Users/$SHORTNAME UserShell /bin/bash
dscl . -create /Users/$SHORTNAME RealName "$FULLNAME"
dscl . -create /Users/$SHORTNAME UniqueID "$USERID"
dscl . -create /Users/$SHORTNAME PrimaryGroupID 20
dscl . -create /Users/$SHORTNAME NFSHomeDirectory /Users/$SHORTNAME
dscl . -passwd /Users/$SHORTNAME $PASSWORD


# Add user to any specified groups
echo "Adding user to specified groups..."

for GROUP in $SECONDARY_GROUPS ; do
    dscl . -append /Groups/$GROUP GroupMembership $SHORTNAME
done

if [ "$(fdesetup isactive)" = 'true' ]; then
	echo "This device is encrypted. Adding user to filevault login."
        expect -c "spawn fdesetup add -usertoadd \"$SHORTNAME\"; expect \":\"; send \"$ADMINPW\n\" ; expect \":\"; send \"$PASSWORD\n\"; expect eof"
fi

# Create the home directory - REMOVED DUE TO ERRORS. NOT NEEDED.
# echo "Creating home directory..."
# createhomedir -c 2>&1 | grep -v "shell-init"

## BEGIN CUSTOM OPTIONS FOR METHODSMB ##
# option to hide user from login screen
dscl . create /Users/$SHORTNAME IsHidden $MAKEHIDDEN
# Future: add user to filevault logins
# fdesetup add -usertoadd $SHORTNAME | echo $PASSWORD
## END CUSTOM OPTIONS FOR METHODSMB ##

echo "Created user #$USERID: $SHORTNAME ($FULLNAME) with Password $PASSWORD"

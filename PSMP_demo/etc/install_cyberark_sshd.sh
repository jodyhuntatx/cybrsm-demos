#!/bin/bash

#**********************Consts Section**********************************#
# Required files
SSHD_SRV_INITD_F=/etc/init.d/sshd
PAM_SSHD_CONFIG_F=/etc/pam.d/sshd
SSHD_CONFIG_F=/etc/ssh/sshd_config
SSHD_TO_COPY_F="$1/sshd"
SSHD_BIN_DIR=/usr/sbin
SSH_PRIVATE_KEYS_F=/etc/ssh/*key

# Commands
SSHD_SRV_CMD="service sshd"

# Open SSH required RPMs
OLDER_6_1_OPEN_SSH_VERSION=6.1
OLDER_7_1_OPEN_SSH_VERSION=7.1
OLDER_7_3_OPEN_SSH_VERSION=7.3
REQUIRED_OPEN_SSH_VERSION=7.7
PREREQ_OPEN_SSH_RPM_POSTFIX=p1-1.x86_64.rpm
PREREQ_OPEN_SSH_SERVER_RPM=openssh-server-$REQUIRED_OPEN_SSH_VERSION$PREREQ_OPEN_SSH_RPM_POSTFIX
PREREQ_OPEN_SSH_CLIENTS_RPM=openssh-clients-$REQUIRED_OPEN_SSH_VERSION$PREREQ_OPEN_SSH_RPM_POSTFIX
PREREQ_OPEN_SSH_RPM=openssh-$REQUIRED_OPEN_SSH_VERSION$PREREQ_OPEN_SSH_RPM_POSTFIX

# Prerequisites
PRE_REQUISITES_D="$1/Pre-Requisites"
PRE_REQUISITES_OPEN_SSH_D="$PRE_REQUISITES_D/OpenSSH_RPM_RHEL"

# RC codes
RC_SUCCESS=0
RC_ERROR=1

# Should show logs
SHOULD_SHOW_LOGS=1 

# install modes - if received by $2 parameter to the script
current_install_mode="$2"
install_mode_clean="Installation"
install_mode_repair="Repair installation"
install_mode_upgrade="Upgrade installation"


#---------------------------------------
# SSHD bin and configration backup files
#---------------------------------------
backup_dir=/opt/CARKpsmp/backup
sshd_bin_backup_f="$backup_dir"/sshd_backup
sshd_bin_orig_f="$SSHD_BIN_DIR"/sshd
pam_sshd_config_backup_f="$backup_dir"/pamd_sshd_backup
sshd_config_backup_f="$backup_dir"/sshd_config_backup
PAM_SSHD_CONFIG_BACKUP_F=$pam_sshd_config_backup_f
SSHD_CONFIG_BACKUP_F=$sshd_config_backup_f
pam_sshd_config_file=$PAM_SSHD_CONFIG_F  
sshd_config_file=$SSHD_CONFIG_F

# Log files
VAR_TMP_D=/var/tmp
VAR_INSTALL_LOG_F=$VAR_TMP_D/psmp_install.log

# SELinux new PSM policy
PSMP_SSHD_SELINUX_POLICY_NAME=psmp_sshd
PSMP_SSHD_SELINUX_POLICY_EXT1_NAME=psmp_sshd_ext1
PSMP_SELINUX_DIR=/etc/opt/CARKpsmp/selinux
PSMP_SSH_SELINUX=$PSMP_SELINUX_DIR/$PSMP_SSHD_SELINUX_POLICY_NAME.pp
PSMP_SSH_SELINUX_EXT1=$PSMP_SELINUX_DIR/$PSMP_SSHD_SELINUX_POLICY_EXT1_NAME.pp

# OpenSSH version codes
VER_SSH_NOT_INST=0
VER_SSH_OTHER=1
VER_SSH_6_1=2
VER_SSH_7_1=3
VER_SSH_7_3=4
VER_SSH_REQ=5

# Global
VER_CURRENT_OPEN_SSH=$VER_SSH_NOT_INST

#**********************End of Consts Section**********************************#

#**********************Global Variables**********************************#
#OS version
IsRHEL5=0
IsRHEL6=0

# Setting the default values of ssh params found in sshd_config.
UsePAMValueBackup=""
PasswordAuthValueBackup=""
ChangRespAuthValueBackup=""
PermitRootLogValueBackup=""

# Setting the default values of PSMP custom params found in sshd_config.
PSMP_AddDelimValueBackup=""
PSMP_OpenSSHLogFValueBackup=""
PSMP_OpenSSHTrcLevValueBackup=""
PSMP_TargetAddrPortDelimValueBackup=""
PSMP_MaintUsersValueBackup=""
#**********************End of Global Variables Section**********************************#


# Writing a message to the log (or terminal) in case logging is enabled
WriteLog()
{
	if [ $SHOULD_SHOW_LOGS = "1" ] ; then
		echo `date` "| $1" >> $VAR_INSTALL_LOG_F
	fi
}

WriteToTerminal()
{
   echo `date` "| $1" >> $VAR_INSTALL_LOG_F
   echo "$1"
}

# Check for error code. If an error code was received, print an error and exit
TestForErrors()
{
   if [ "$?" != "$RC_SUCCESS" ] ; then
      echo "$1"
      echo `date` "| error: $1" >> $VAR_INSTALL_LOG_F
      exit $RC_ERROR
   fi
}

CopyFile()
{
	local mode=$1
	local from=$2
	local to=$3

   if [ -f $from ] ; then
	   WriteLog "$mode file [$from] to [$to]."

  	   cp -f $from $to >> $VAR_INSTALL_LOG_F 2>&1

 	   # if a failure occured
      TestForErrors "Failed to $mode file [$from] to [$to]"
   fi
}

RestoreFile()
{
	local orig_file=$1
	local backup_file=$2

   if [ ! -f $backup_file ] ; then
      WriteToTerminal "Error: Can't find backup file [$backup_file]. File [$orig_file] was not restored."
      exit $RC_ERROR
   else
      CopyFile "restore" $backup_file $orig_file
   fi
}

CreateBackupDir()
{
   if [ ! -d $backup_dir ] ; then 
	   WriteLog "Creating backup dir [$backup_dir]."
      mkdir -m 0750 $backup_dir >/dev/null 2>&1

	   # if a failure occured
	   if [ $? != $RC_SUCCESS ] ; then
		   WriteToTerminal "Failed to create [$backup_dir] directory"
         exit $RC_ERROR
	   fi
   fi
}

BackupFile()
{
	local orig_file=$1
	local backup_file=$2
   
   CreateBackupDir
   CopyFile backup $orig_file $backup_file
}

BackupRestoreFile()
{
	local mode=$1
	local orig_file=$2
	local backup_file=$3
   
   if [ $mode = "backup" ] ; then   
      BackupFile $orig_file $backup_file
   elif [ $mode = "restore" ] ; then 
      RestoreFile $orig_file $backup_file
   fi
}

BackupRestoreSSHDFile()
{
   local mode=$1
   
   if [ "$2" = "bin" ] ; then 
	   BackupRestoreFile $mode $sshd_bin_orig_f $sshd_bin_backup_f
   elif [ "$2" = "config" ] ; then 
     	BackupRestoreFile $mode $sshd_config_file $sshd_config_backup_f
   elif [ "$2" = "pam" ] ; then 
      BackupRestoreFile $mode $pam_sshd_config_file $pam_sshd_config_backup_f
   fi
}

BackupSSHDFiles()
{
	local mode="backup"

	if [ "$current_install_mode" != "$install_mode_repair" ] ; then
      BackupRestoreSSHDFile $mode $1
      BackupRestoreSSHDFile $mode $2
      BackupRestoreSSHDFile $mode $3
      TestForErrors "Failed to $mode OpenSSH files and configuration."
   fi
}

SetSSHDConfigProperty()
{
	local recievedKey=$1
	local recievedValue=$2
	local recievedFileName=$3

	local keySearchResult=$(grep -i ^$recievedKey $recievedFileName | head -1)
	local commentedKeySearchResult=$(grep -i ^#$recievedKey $recievedFileName | head -1)
	

	# in case the key isn't commented out we just update its value
	if [ ! -z "$keySearchResult" ] ; then
		sed -i 's|'"$keySearchResult"'|'"$recievedKey $recievedValue"'|' $recievedFileName
	
	# in case the key is commented out we just uncomment it and set the received value
	elif [ ! -z "$commentedKeySearchResult" ] ; then
		sed -i 's|'"$commentedKeySearchResult"'|'"$recievedKey $recievedValue"'|' $recievedFileName

	# in case the key is doesn't exist in the file we add it with the received value
 	else
		echo -e "\n$recievedKey $recievedValue">>$recievedFileName
	fi
	
	TestForErrors "Failed to set [sshd] configuration property: [$recievedKey] to [$recievedValue]."
}

AddNewSSHDConfigProperty()
{
	local recievedNewProperty=$1
	local recievedFileName=$2
	
	echo -e "\n$recievedNewProperty">>$recievedFileName
	
	TestForErrors "Failed to add new [sshd] configuration property: [$recievedNewProperty]."
}

GetSSHDConfigProperty()
{
	local recievedKey=$1
	local recievedFileName=$2
	local value=""
	
	local keySearchResult=$(grep -i ^$recievedKey $recievedFileName | head -1)
	local commentedKeySearchResult=$(grep -i ^#$recievedKey $recievedFileName | head -1)
	local anyKeySearchResult=$(grep -i $recievedKey $recievedFileName | head -1)
	
	# In case the key isn't commented out.
	if [ ! -z "$keySearchResult" ] ; then
		value=$keySearchResult
	
	# In case the key is commented out, this value is also relevant because we don't want the user to 
	# experience behaviour change.
	elif [ ! -z "$commentedKeySearchResult" ] ; then
		value=$commentedKeySearchResult
	
	# In case the key appears but with spaces before key or before #.
	elif [ ! -z "$anyKeySearchResult" ] ; then
		value=$anyKeySearchResult
	fi
	
	echo "$value"
}

# $1 - path of file to change the context type.
# $2 - the new context type.
ChangeContextType()
{
   local file_dir="$1"
   local context_type="$2"

   chcon -t $context_type $file_dir > /dev/null 2>&1
   
   # in case change context failed we will set rc_err.
   if [ "$?" != "$RC_SUCCESS" ] ; then
      WriteLog "error: Failure occurred while trying to change security context type of file [$file_dir] to [$context_type]."
   fi
}

LoadSELinuxPolicy()
{
	local selinuxEnabled=""
	local isSeLinuxPsmpSshdPolicyInstalled=""
	
	selinuxEnabled=$(sestatus | grep enabled )

	#Do not continue if RHEL5 - no need for the policy in RHEL5 
	if [ "$IsRHEL5" -gt "0" ] || [ -z "$selinuxEnabled" ] ; then
		return
	fi

	WriteToTerminal "Loading PSMP SELinux policy..."
	
	#remove psmp_sshd selinux policy - in case we might have a leftover old psmp_sshd policy already installed
	isSeLinuxPsmpSshdPolicyInstalled=$(semodule -l | grep -i -c "$PSMP_SSHD_SELINUX_POLICY_NAME")
	if [ "$isSeLinuxPsmpSshdPolicyInstalled" -gt "0" ] ; then
		WriteLog "Removing existing PSMP SELinux policy [sshd]..."
		semodule -r "$PSMP_SSHD_SELINUX_POLICY_NAME" >> $VAR_INSTALL_LOG_F 2>&1
		TestForErrors "Failed to remove existing PSMP SELinux policy [sshd]."
	fi

	#remove psmp_sshd_ext1 selinux policy - in case we might have a leftover old psmp_sshd_ext1 policy already installed
	isSeLinuxPsmpSshdPolicyInstalled=$(semodule -l | grep -i -c "$PSMP_SSHD_SELINUX_POLICY_EXT1_NAME")
	if [ "$isSeLinuxPsmpSshdPolicyInstalled" -gt "0" ] ; then
		WriteLog "Removing existing PSMP ext1 SELinux policy [sshd]..."
		semodule -r "$PSMP_SSHD_SELINUX_POLICY_EXT1_NAME" >> $VAR_INSTALL_LOG_F 2>&1
		TestForErrors "Failed to remove existing PSMP ext1 SELinux policy [sshd]."
	fi

	#load new psmp_sshd selinux policy
	WriteLog "Loading PSMP SELinux policy..."
	semodule -i "$PSMP_SSH_SELINUX" >> $VAR_INSTALL_LOG_F 2>&1

	#load new psmp_sshd_ext1 selinux policy extension 1 for RHEL7 and above
	if [ "$IsRHEL6" -eq "0" ] && [ "$IsRHEL5" -eq "0" ] ; then
		WriteLog "Loading PSMP ext1 SELinux policy (RHEL7 and above)..."
		semodule -i "$PSMP_SSH_SELINUX_EXT1" >> $VAR_INSTALL_LOG_F 2>&1
		TestForErrors "Failed to load PSMP ext1 SELinux policy."
	fi

  	WriteLog "PSMP SELinux policy was loaded."
}

ReplaceSSHDExecutable()
{
	local selinuxEnforcing=""

	WriteLog "Replacing the [sshd] executable..."
	
	SSHD_TO_COPY_PATH=`printf "$SSHD_TO_COPY_F" | tr -s '//'`
	cp -f "$SSHD_TO_COPY_PATH" $SSHD_BIN_DIR
	TestForErrors "Failed to replace the [sshd] executable."
	
	chmod +x $SSHD_BIN_DIR/sshd
	TestForErrors "Failed to set permissions for the [sshd] executable."
	
	selinuxEnforcing=$(sestatus | grep enabled )

	# Restore the original SELinux domain of the sshd (it may be bin_t after the copy or textrel_shlib_t because of previous versions)
	if [ ! -z "$selinuxEnforcing" ] ; then
		WriteLog "Restoring default context type of executable [sshd]..."
		SSHD_BIN_FULL_PATH=`printf "$SSHD_BIN_DIR/sshd" | tr -s '//'`
		restorecon -i $SSHD_BIN_FULL_PATH
		TestForErrors "Failed to restore original SELinux type context of [sshd] executable."
	fi
	
	LoadSELinuxPolicy

        chmod go-wrx $SSH_PRIVATE_KEYS_F
	systemctl daemon-reload
	
	# If sshd running - restart, otherwise - start
	pgrep -fx $SSHD_BIN_DIR/sshd >/dev/null 2>&1
	if [ "$?" == "$RC_SUCCESS" ] ; then
		WriteLog "Restarting the [sshd] executable..."
		systemctl restart sshd
		TestForErrors "Failed to restart the [sshd] service."
		WriteLog "The [sshd] executable was started successfully."
	else
	    WriteLog "Starting the [sshd] executable..."
	    systemctl start sshd
	    TestForErrors "Failed to start the [sshd] service."
	    WriteLog "The [sshd] executable was started successfully."
	fi
	
	WriteLog "Replacing the [sshd] executable has finished."
}

UpdateSSHD()
{
	WriteLog "Updating [sshd]..."
	
	#replace sshd
	ReplaceSSHDExecutable
	
	WriteLog "Updating [sshd] has finished."
}

# in case the script is excuted from an RPM, the RPM lock file will prevent the script installing or removing RPM's
ReleaseRPMLock()
{
    # if an RPM lock file exists
   lockFile=/var/lib/rpm/.rpm.lock
   if [ -f $lockFile ] ; then
	 ERR=$(mv -f $lockFile $lockFile.bak )
     TestForErrors "Failed to release RPM lock [$lockFile]. Error: $ERR."
   fi
   
   # for RHEL 5 we saw that this the lock file
   lockDBFile=/var/lib/rpm/__db.000
   if [ -f $lockDBFile ] ; then
	 ERR=$(mv -f $lockDBFile $lockDBFile.bak)
     TestForErrors "Failed to release RPM lock [$lockDBFile]. Error: $ERR."
   fi
}

RecoverRPMLock()
{
    # if an RPM lock file exists
   lockFile=/var/lib/rpm/.rpm.lock
   if [ -f $lockFile.bak ] ; then
	  ERR=$(mv -f $lockFile.bak $lockFile )
     if [ "$?" != "$RC_SUCCESS" ] ; then
        WriteLog "Failed to recover RPM lock [$lockFile]. Error: $ERR."
     fi
   fi
   
   # for RHEL 5 we saw that this the lock file
   lockDBFile=/var/lib/rpm/__db.000
   if [ -f $lockDBFile.bak ] ; then
	  ERR=$(mv -f $lockDBFile.bak $lockDBFile)
     if [ "$?" != "$RC_SUCCESS" ] ; then
        WriteLog "Failed to recover RPM lock [$lockDBFile]. Error: $ERR."
     fi
   fi
}

RemoveCurrrentOpenSSH()
{
	WriteLog "Removing currently installed OpenSSH..."
	$SSHD_SRV_CMD stop >/dev/null 2>&1
	ReleaseRPMLock
	rpm -e --nodeps openssh-clients >/dev/null 2>&1
	rpm -e --nodeps openssh-server >/dev/null 2>&1
	rpm -e  --nodeps openssh-askpass >/dev/null 2>&1
	rpm -e  --nodeps openssh  >/dev/null 2>&1
   RecoverRPMLock
	WriteLog "Removing OpenSSH has finished."
}

InstallPrerequisiteOpenSSH()
{
	ReleaseRPMLock

	WriteLog "Installing prerequisite OpenSSH..."

	RPM_PATH=`printf "$PRE_REQUISITES_OPEN_SSH_D/openssh*.rpm" | tr -s '//'`
	rpm -i "$RPM_PATH" >> $VAR_INSTALL_LOG_F 2>&1
   RecoverRPMLock
	TestForErrors "Failed to install prerequisite OpenSSH."

	WriteLog "Installing prerequisite OpenSSH has finished."
}

UpgradePrerequisiteOpenSSH()
{
	ReleaseRPMLock

	WriteLog "Upgrading prerequisite OpenSSH..."

	RPM_PATH=`printf "$PRE_REQUISITES_OPEN_SSH_D/openssh*.rpm" | tr -s '//'`
	rpm -U --nodeps "$RPM_PATH" >> $VAR_INSTALL_LOG_F 2>&1
   RecoverRPMLock
	TestForErrors "Failed to upgrade prerequisite OpenSSH."

	WriteLog "Installing prerequisite OpenSSH has finished."
}

SetSSHDPamConfigurationRHEL5()
{
	echo "#%PAM-1.0">$PAM_SSHD_CONFIG_F
	echo "auth       include      system-auth">>$PAM_SSHD_CONFIG_F
	echo "account    required     pam_nologin.so">>$PAM_SSHD_CONFIG_F
	echo "account    include      system-auth">>$PAM_SSHD_CONFIG_F
	echo "password   include      system-auth">>$PAM_SSHD_CONFIG_F
	echo "session    optional     pam_keyinit.so force revoke">>$PAM_SSHD_CONFIG_F
	echo "session    include      system-auth">>$PAM_SSHD_CONFIG_F
	echo "session    required     pam_loginuid.so">>$PAM_SSHD_CONFIG_F
	
	TestForErrors "Failed to set the [sshd] pam configuration."
}


SetSSHDPamConfigurationRHEL6()
{
	echo "#%PAM-1.0">$PAM_SSHD_CONFIG_F
	echo "auth	   required	pam_sepermit.so">>$PAM_SSHD_CONFIG_F
	echo "auth       include      password-auth">>$PAM_SSHD_CONFIG_F
	echo "account    required     pam_nologin.so">>$PAM_SSHD_CONFIG_F
	echo "account    include      password-auth">>$PAM_SSHD_CONFIG_F
	echo "password   include      password-auth">>$PAM_SSHD_CONFIG_F
	echo "# pam_selinux.so close should be the first session rule">>$PAM_SSHD_CONFIG_F
	echo "session    required     pam_selinux.so close">>$PAM_SSHD_CONFIG_F
	echo "session    required     pam_loginuid.so">>$PAM_SSHD_CONFIG_F
	echo "# pam_selinux.so open should only be followed by sessions to be executed in the user context">>$PAM_SSHD_CONFIG_F
	echo "session    required     pam_selinux.so open env_params">>$PAM_SSHD_CONFIG_F
	echo "session    optional     pam_keyinit.so force revoke">>$PAM_SSHD_CONFIG_F
	echo "session    include      password-auth">>$PAM_SSHD_CONFIG_F
	
	TestForErrors "Failed to set the [sshd] pam configuration."
}


OverwriteSSHDPamConfiguration()
{
	# if the OS is RHEL 5
	if [ "$IsRHEL5" -gt "0" ] ; then
		WriteLog "Updating the [sshd] pam configuration file for RHEL 5..."
		SetSSHDPamConfigurationRHEL5
	else
		WriteLog "Updating the [sshd] pam configuration file..."
		SetSSHDPamConfigurationRHEL6
	fi
	
	WriteLog "Updating the [sshd] pam configuration file has finished."
}


BackupPAMConfiguration()
{
	WriteLog "Backing up [sshd] pam parameters ..."
	
	# Backup existing sshd PAM configuration file
	cp -f $PAM_SSHD_CONFIG_F $PAM_SSHD_CONFIG_BACKUP_F
	
	TestForErrors "Failed to back up the [sshd] pam configuration."
	WriteLog "Backing up [sshd] pam parameters has finished..."
}

BackupSSHDConfiguration()
{
	WriteLog "Backing up [sshd] PSMP parameters ..."
	
	# Backup existing sshd_config file
	cp -f $SSHD_CONFIG_F $SSHD_CONFIG_BACKUP_F
	
	# Backup the PSMP_AdditionalDelimiter value from the '/etc/ssh/sshd_config' file
	PSMP_AddDelimValueBackup=$(GetSSHDConfigProperty "PSMP_AdditionalDelimiter" $SSHD_CONFIG_F)
	# Backup the PSMP_OpenSSHLogFolder value from the '/etc/ssh/sshd_config' file
	PSMP_OpenSSHLogFValueBackup=$(GetSSHDConfigProperty "PSMP_OpenSSHLogFolder" $SSHD_CONFIG_F)
	# Backup the PSMP_OpenSSHTraceLevels value from the '/etc/ssh/sshd_config' file
	PSMP_OpenSSHTrcLevValueBackup=$(GetSSHDConfigProperty "PSMP_OpenSSHTraceLevels" $SSHD_CONFIG_F)
	# Backup the PSMP_TargetAddressPortAdditionalDelimiter value from the '/etc/ssh/sshd_config' file
	PSMP_TargetAddrPortDelimValueBackup=$(GetSSHDConfigProperty "PSMP_TargetAddressPortAdditionalDelimiter" $SSHD_CONFIG_F)
	# Backup the PSMP_MaintenanceUsers value from the '/etc/ssh/sshd_config' file
	PSMP_MaintUsersValueBackup=$(GetSSHDConfigProperty "PSMP_MaintenanceUsers" $SSHD_CONFIG_F)
	
	WriteLog "Backing up [sshd] PSMP parameters has finished..."
}

CheckOpenSSHVersion()
{
	WriteLog "Checking the version of the installed OpenSSH package..."
	
	# Check if any OpenSSH rpm is installed
	if [ ! -z "$(rpm -qa | grep -i openssh-*)" ] ; then
		VER_CURRENT_OPEN_SSH=$VER_SSH_OTHER
		# Check if the OpenSSH rpm installed is either 6.1 or the required one.
		if [ ! -z "$(rpm -qa | grep -i openssh-$OLDER_6_1_OPEN_SSH_VERSION)" ] ; then
			VER_CURRENT_OPEN_SSH=$VER_SSH_6_1
		elif [ ! -z "$(rpm -qa | grep -i openssh-$OLDER_7_1_OPEN_SSH_VERSION)" ] ; then
			VER_CURRENT_OPEN_SSH=$VER_SSH_7_1
		elif [ ! -z "$(rpm -qa | grep -i openssh-$OLDER_7_3_OPEN_SSH_VERSION)" ] ; then
			VER_CURRENT_OPEN_SSH=$VER_SSH_7_3
		elif [ ! -z "$(rpm -qa | grep -i openssh-$REQUIRED_OPEN_SSH_VERSION)" ] ; then
			VER_CURRENT_OPEN_SSH=$VER_SSH_REQ
		fi
	fi

	WriteLog "Finished checking the version of the installed OpenSSH package."
}

UpdateOpenSSH()
{
	CheckOpenSSHVersion

	# if any openssh is installed -> backup the sshd_config and pam configuration files
	if [ "$VER_CURRENT_OPEN_SSH" != "$VER_SSH_NOT_INST" ] ; then
	      BackupSSHDFiles config pam
	fi

	# Check if the OpenSSH package installed is other than 6.1 or the required.
	if [ "$VER_CURRENT_OPEN_SSH" = "$VER_SSH_OTHER" ] ; then
		# Backing up pam sshd file, because maybe the client inserted there some custome changes.
		BackupPAMConfiguration
		
		# Backing up the sshd_config. When upgrading from 6.1 the sshd_config file is not replaced so 
		# there is no need to backup the file in that case.
		BackupSSHDConfiguration
	fi
	
	# If the installed Open-SSH version is the prerequisite one
	if [ "$VER_CURRENT_OPEN_SSH" = "$VER_SSH_REQ" ] ; then
		WriteLog "Prerequisite OpenSSH is already installed."
      if [ ! -f $sshd_bin_backup_f ] && [ "$current_install_mode" = "$install_mode_clean" ]  ; then
         BackupSSHDFiles bin
      fi
	elif [ "$VER_CURRENT_OPEN_SSH" != "$VER_SSH_OTHER" ]; then
		# Upgrade the openssh because if we try to remove the openssh-6.1p1-server, the ssh session (remote install) will be disconnected
		# and the install process will be unexpectedly terminated. The user will have two CARKpsmp installations.
		UpgradePrerequisiteOpenSSH
        BackupSSHDFiles bin
	else
		echo "REMOVING CURRENT OPENSSH PACKAGE"
		# Remove current SSH package 
		RemoveCurrrentOpenSSH
		
		# Install prerequisite Open-SSH  package
		InstallPrerequisiteOpenSSH
        	BackupSSHDFiles bin
	fi

   # if openssh was not installed before -> backup the sshd_config and pam configuration files
	if [ "$VER_CURRENT_OPEN_SSH" = "$VER_SSH_NOT_INST" ] ; then
		BackupSSHDFiles config pam
	fi

	# If previous ssh installed was Open-SSH version is 6.1 then overwrite the sshd pam content.
	if [ "$VER_CURRENT_OPEN_SSH" = "$VER_SSH_6_1" ] || [ "$VER_CURRENT_OPEN_SSH" = "$VER_SSH_7_1" ] || [ "$VER_CURRENT_OPEN_SSH" = "$VER_SSH_NOT_INST" ] ; then
		# Set RHEL's default sshd PAM configuration file
		OverwriteSSHDPamConfiguration
	# Else, if openssh version was other than required, use the backup file.
	elif [ "$VER_CURRENT_OPEN_SSH" = "$VER_SSH_OTHER" ] ; then
		#restore sshd PAM configuration file
		if [ -f $PAM_SSHD_CONFIG_BACKUP_F ] ; then
			cp -f $PAM_SSHD_CONFIG_BACKUP_F $PAM_SSHD_CONFIG_F
			TestForErrors "Failed to restore the [sshd] pam configuration."
		fi
	fi

}

CheckOSVersion5()
{
	SearchForRHELVersionResult=$(cat /etc/redhat-release | grep -i -c "release 5.")
	
	if [ "$SearchForRHELVersionResult" -gt "0" ] ; then
	    IsRHEL5="1"
		WriteLog "OS version is 5.x"
	else
		IsRHEL5="0"
	fi
}

CheckOSVersion6()
{
	SearchForRHELVersionResult=$(cat /etc/redhat-release | grep -i -c "release 6.")
   SearchForAMAZONVersionResult=$(cat /etc/issue | grep -i -c "Amazon")
	
	if [ "$SearchForRHELVersionResult" -gt "0" ] || [ "$SearchForAMAZONVersionResult" -gt "0" ] ; then
	    IsRHEL6="1"
		WriteLog "OS version is 6.x"
	else
		IsRHEL6="0"
	fi
}

CheckOSVersion()
{
    WriteLog "Checking OS version..."
    CheckOSVersion5
    if [ "$IsRHEL5" -eq "0" ] ; then
        CheckOSVersion6
		if [ "$IsRHEL6" -eq "0" ] ; then
			WriteLog "OS version is 7.x or above"
		fi
    fi   
	WriteLog "Checking OS version has finished."
}


SupportNewSyntax()
{
	WriteLog "Starting script execution..."
	# checking for the OS version
	CheckOSVersion
	
	# update OpenSSH rpm's 
	UpdateOpenSSH
	
	#update sshd binary and configuration
	UpdateSSHD
	WriteLog "Script execution has finished."
}


# The script starts here
#SupportNewSyntax
UpdateSSHD

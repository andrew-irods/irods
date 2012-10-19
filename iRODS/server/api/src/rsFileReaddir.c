/*** Copyright (c), The Regents of the University of California            ***
 *** For more information please refer to files in the COPYRIGHT directory ***/
/* This is script-generated code (for the most part).  */ 
/* See fileReaddir.h for a description of this API call.*/

#include "fileReaddir.h"
#include "miscServerFunct.h"
#include "rsGlobalExtern.h"

// =-=-=-=-=-=-=-
// eirods includes
#include "eirods_log.h"
#include "eirods_collection_object.h"

int
rsFileReaddir (rsComm_t *rsComm, fileReaddirInp_t *fileReaddirInp, 
rodsDirent_t **fileReaddirOut)
{
    rodsServerHost_t *rodsServerHost;
    int remoteFlag;
    int status;

    *fileReaddirOut = NULL;

    remoteFlag = getServerHostByFileInx (fileReaddirInp->fileInx,
      &rodsServerHost);

    if (remoteFlag == LOCAL_HOST) {
        status = _rsFileReaddir (rsComm, fileReaddirInp, fileReaddirOut);
    } else if (remoteFlag == REMOTE_HOST) {
        status = remoteFileReaddir (rsComm, fileReaddirInp, fileReaddirOut,
	 rodsServerHost);
    } else {
        if (remoteFlag < 0) {
            return (remoteFlag);
        } else {
            rodsLog (LOG_NOTICE,
              "rsFileReaddir: resolveHost returned unrecognized value %d",
               remoteFlag);
            return (SYS_UNRECOGNIZED_REMOTE_FLAG);
        }
    }

    /* Manually insert call-specific code here */

    return (status);
}

int
remoteFileReaddir (rsComm_t *rsComm, fileReaddirInp_t *fileReaddirInp,
rodsDirent_t **fileReaddirOut, rodsServerHost_t *rodsServerHost)
{   
    int status;

    if (rodsServerHost == NULL) {
        rodsLog (LOG_NOTICE,
          "remoteFileReaddir: Invalid rodsServerHost");
        return SYS_INVALID_SERVER_HOST;
    }

    if ((status = svrToSvrConnect (rsComm, rodsServerHost)) < 0) {
        return status;
    }

    fileReaddirInp->fileInx = convL3descInx (fileReaddirInp->fileInx);
    status = rcFileReaddir (rodsServerHost->conn, fileReaddirInp, fileReaddirOut);

    if (status < 0) { 
        if (status != -1) {     /* eof */
            rodsLog (LOG_NOTICE,
             "remoteFileReaddir: rcFileReaddir failed for %s",
              FileDesc[fileReaddirInp->fileInx].fileName);
	}
    }

    return status;
}

// =-=-=-=-=-=-=-
// local function to call readdir via resource plugin
int _rsFileReaddir( rsComm_t*         _comm, 
                    fileReaddirInp_t* _file_readdir_inp, 
                    rodsDirent_t**    _rods_dirent ) {
	// =-=-=-=-=-=-=-
    // create a collection_object, and extract dir ptr from the file desc table
	eirods::collection_object coll_obj( FileDesc[ _file_readdir_inp->fileInx].fileName, 0, 0 );
	coll_obj.directory_pointer( reinterpret_cast< DIR* >( FileDesc[ _file_readdir_inp->fileInx].driverDep ) ); 

	// =-=-=-=-=-=-=-
    // make call to readdir via resource plugin and handle errors, if necessary
    eirods::error readdir_err = fileReaddir( coll_obj, _rods_dirent );
    if( !readdir_err.ok() ) {
		std::stringstream msg;
		msg << "_rsFileReaddir: fileReaddir for ";
		msg << FileDesc[ _file_readdir_inp->fileInx].fileName;
		msg << ", status = ";
		msg << readdir_err.code();
		eirods::error err = PASS( false, readdir_err.code(), msg.str(), readdir_err );
		eirods::log ( err );

        return readdir_err.code();
    } else {
		// =-=-=-=-=-=-=-
		// case for handle end of file 
        if( -1 == readdir_err.code() ) {
			return readdir_err.code();
		}
	}

    // =-=-=-=-=-=-=-
    // error code holds 'status' of api call
    return readdir_err.code();

} // _rsFileReaddir 















//
//  efrtclient.swift
//  FitForm
//
//  Created by Paul Williams on 23/11/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

class EfrtClient {
    
  static let sharedInstance = DropboxWrapper()
    
    let dropboxFolder = "/Apps/tapiriik"
    var fileList : [String]
    
    init () {
        fileList = []
    }
    
    
    func loadFileList(whenDone: @escaping (Bool) -> Void) {
        let client = DropboxClientsManager.authorizedClient
        _ = client?.files.listFolder(path: dropboxFolder ).response { response, error in
            if let result = response {
                print ("Dropbox sent me a list of files...")
                //print (result.entries)
                for entry in result.entries {
                    if entry.name.hasSuffix(".tcx") || entry.name.hasSuffix(".fit") {
                        if !ActivityRecords.instance.activityExists(cfilename: entry.name) {
                            //create temporary entry in database
                            let _ = ActivityRecords.instance.addTempActivity(cfilename: entry.name)
                            self.fileList.append(entry.name)
                            
                            print ("Found New Dropbox file : \(entry.name)")
                        } else {
                            //   print ("...already in database = \(entry.name)")
                        }
                    } else {
                        print ("...not a .tcx or .fit file")
                    }
                }
                if self.fileList.count == 0 {
                    whenDone (false)
                } else {
                    whenDone(true)
                }
            } else {
                print("DROPBOX Error: \(error!) \n")
            }
            
        }
    } //loadFileList
    
    
    
    func loadTCX (whenDone: @escaping (ActivityData) -> Void, TCXFilename : String)  {
        let client = DropboxClientsManager.authorizedClient
        let DropboxPath = Globals.sharedInstance.DropboxPath + TCXFilename
        // Download to Data
        client?.files.download(path: DropboxPath)
            .response { response, error in
                if let response = response {
                    _ = response.0  //responseMetaData
                    let fileContents = response.1
                    let newActivityData = ActivityData(Filename : TCXFilename, TCXFileData: fileContents)
                    if newActivityData.dataOK {
                        _ = ActivityRecords.instance.updateActivityRecordFromFITData(cfilename: TCXFilename, cActivityData : newActivityData)
                        whenDone(newActivityData)
                    }
                } else if let error = error {
                    print(error)
                }
            }
            .progress { progressData in
                print(progressData)
        }
    }
    
}


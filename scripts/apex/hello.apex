// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents



ParseJson.parse();
String fileName = 'movieData'; 
List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion
                                        WHERE Title = :fileName
                                        LIMIT 1];
String jsonFileId = contentVersions[0].ContentDocumentId;
System.debug('The ContentDocumentId for ' + fileName + ' is: ' + jsonFileId);
//String jsonFileId = '0695j00000LJHWNAA5';
ContentVersion jsonFileText = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :jsonFileId AND IsLatest = true LIMIT 1];
Blob csvFileBody = jsonFileText.VersionData; 
String csvAsString= csvFileBody.toString();
System.debug(csvAsString);



MovieApiDataUpdaterBatch batchJob = new MovieApiDataUpdaterBatch();
Id batchJobId = Database.executeBatch(batchJob, 5);
AsyncApexJob aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
                    FROM AsyncApexJob WHERE ID =: batchJobId ];
System.debug('Job Id: ' + batchJobid + ' Status: ' + aaj.Status);


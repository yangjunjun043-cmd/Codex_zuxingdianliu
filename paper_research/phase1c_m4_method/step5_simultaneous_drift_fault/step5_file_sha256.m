function hash = step5_file_sha256(path)
%STEP5_FILE_SHA256 Return uppercase SHA-256 for one file.

fileId = fopen(path,'rb');
if fileId < 0
    error('Phase1C:Step5Hash','Unable to open %s.',path);
end
cleanupObject = onCleanup(@() fclose(fileId));
bytes = fread(fileId,Inf,'*uint8');
clear cleanupObject
digester = java.security.MessageDigest.getInstance('SHA-256');
digester.update(bytes);
hashBytes = typecast(digester.digest(),'uint8');
hash = upper(string(reshape(dec2hex(hashBytes,2).',1,[])));
end

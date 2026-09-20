function digest = step6_file_sha256(path)
%STEP6_FILE_SHA256 Return an uppercase SHA-256 digest for one file.
fileId = fopen(path,'rb');
if fileId < 0
    error('Phase1C:Step6Hash','Unable to open %s.',path);
end
cleanupObject = onCleanup(@() fclose(fileId));
bytes = fread(fileId,Inf,'*uint8');
clear cleanupObject
digester = java.security.MessageDigest.getInstance('SHA-256');
digester.update(bytes);
hashBytes = typecast(digester.digest(),'uint8');
digest = upper(string(reshape(dec2hex(hashBytes,2).',1,[])));
end

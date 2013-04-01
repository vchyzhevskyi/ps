[Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq") | Out-Null

function Get-AmazonS3Buckets ($AccessKeyId, $SecretAccessKey) {
    $timeStamp = [System.DateTime]::UtcNow;
    $strToSign = [System.String]::Format("GET`n`n`n{0}`n{1}", $timeStamp.ToString("ddd, dd MMM yyyy HH:mm:ss 'GMT'"), "/");
    $utf8 = New-Object System.Text.UTF8Encoding;
    $hasher = New-Object System.Security.Cryptography.HMACSHA1;
    $hasher.Key = $utf8.GetBytes($SecretAccessKey);
    $req = [System.Net.HttpWebRequest][System.Net.WebRequest]::Create("http://s3.amazonaws.com/");
    $req.Headers.Add("Authorization", [System.String]::Format("AWS {0}:{1}", $AccessKeyId, [System.Convert]::ToBase64String($hasher.ComputeHash($utf8.GetBytes($strToSign)))));
    ([System.Net.HttpWebRequest]$req).Date = $timeStamp;
    try {
        foreach($xmlObj in ([xml](New-Object System.IO.StreamReader -arg ([System.Net.HttpWebRequest]$req).GetResponse().GetResponseStream()).ReadToEnd()).ListAllMyBucketsResult.Buckets.Bucket) {
            $obj = New-Object psobject -Property @{
                Name = $xmlObj.Name;
                CreationDate = [System.DateTime]::Parse($xmlObj.CreationDate);
            }
            $obj;
        }
    }
    catch [System.Net.WebException] {
        $respStreamReader = New-Object System.IO.StreamReader -arg $_.Exception.Response.GetResponseStream();
        Write-Host $respStreamReader.ReadToEnd();
    }
}
Esh7N API
======================
Esh7N API is a JSON/REST API for sending an image consisting of numbers and returning the detected digits.

###Project
The project consists of three parts:

- InitAPI:                      HTTPGET method.
- DetectNumbers:  	        	HTTPPost method.
- GetNumbersByOperationId: 		HTTPGET method.
- SendRechargeFlag:	            HTTPGET method.

### API Initialization

You can use the following method to init Esh7n API; you can call this method in start of your app.

```
URL: http://esh7n.byorca.com/InitAPI
Parameters: appid, appSecret
```

The URL parameters to be passed to the method are as follows :
-	appid , appSecret  : User’s Credentials  used to access the web service . Note : To request your credentials ,please send us on [info@byorca.com](mailto:info@byorca.com).  (Mandatory fields)



### Sending Image consisting of numbers to be detected

You can use the following method in addition to the image required for number detection.

```
URL: http://esh7n.byorca.com/DetectNumbers
Parameters: appid, appSecret, country, manufacture, model, os, networkOperatorName, phoneSerialNo, minDetectedNumbers, notes, isTestMode
```
The URL parameters to be passed to the method are as follows :
-	appid , appSecret  : User’s Credentials  used to access the web service . Note : To request your credentials ,please send us on [info@byorca.com](mailto:info@byorca.com).  (Mandatory fields)
-	Country : SIM country. (Optional field)
-	Manufacture : User’s device manufacturer. (Optional field)
-	Model : User’s device model. (Optional field)
-	Os : User’s device operating system. (Optional field)
-	networkOperatorName : SIM network operator name. (Optional field)
-	phoneSerialNo : User’s device serial #.(Optional field)
-	minDetectedNumbers : Minimum number of digits to be detected to record as a successful operation [Default = 6]. (Optional field)
-	Notes : Miscellaneous notes . (Optional field)
-	isTestMode : used to activate/deactivate test mode [Default = false].  (Optional field)

NOTE : The image byte data to be sent for detection has to be :
-   Content-Type: image/jpeg
-	Cropped area of the image with the numbers to be detected included.
-	Image of the cropped area has a minimum height of 70px.


Result Example:
```
{
    "operationid": "dfefe2230z13as1",
    "numbers":  "112 145 987 354 129",
    "errorno": "-1"
}
```

### Receiving the detected digits  

You can use the following method to receive the detected digits from the sent image.

```
URL: http://esh7n.byorca.com/GetNumbersByOperationId
Parameters: appid, appSecret, operationId
```
The URL parameters to be passed to the method are as follows :
-	appid , appSecret  : User’s Credentials  used to access the web service . Note : To request your credentials ,please send us on [info@byorca.com](mailto:info@byorca.com).  (Mandatory field)
-	operationId : This parameter carry unique id # for the detection activity. (Mandatory field)

Result Example:
```
{
    "operationid": "dfefe2230z13as1",
    "numbers":  "112 145 987 354 129",
    "errorno": "-1"
}
```

### Sending successful recharge flag

You can use the following method to send flag representing a successful recharge process.


```
URL: http://esh7n.byorca.com/SendRechargeFlag
Parameters: appid, appSecret, operationId
```
The URL parameters to be passed to the method are as follows :
-	appid , appSecret  : User’s Credentials  used to access the web service . Note : To request your credentials ,please send us on [info@byorca.com](mailto:info@byorca.com).  (Mandatory field)
-	operationId : This parameter carry unique id # for the detection activity. (Mandatory field)

Result Example:

```
{
    "operationid": "dfefe2230z13as1",
    "numbers":  "",
    "errorno": "-1"
}
```


### Error Codes

```
    Esh7NErrorCodes
    {
        ErrorFree = -1,
        ErrorUnexpected = -2,
        ErrorInvalidAppidOrAppsecret = 0,
        ErrorInvalidImageFile = 1,
        ErrorServerDown = 2,
        ErrorOperationidNotfound = 3,
        ErrorTrialHasEnded = 4
    }
```




# LazyREST #

![logo](https://user-images.githubusercontent.com/13463023/132789582-6b3fc6c4-411b-4106-8bbd-fe6aed35c1ca.png)


LazyREST is a quick HTTP(s) web server that will accept JSON data for any simple endpoint. It stores data in flat JSON files to allow quick setup for mock and testing environments. 

![image](https://user-images.githubusercontent.com/13463023/132789488-c5f7b138-ca4d-43ee-885c-eadd0f3d3229.png)

For example

- https://localhost:14544/json
- https://localhost:14544/customer
- https://localhost:14544/delphirocks


Postman samples are included in the installation or source

- [Postman](https://www.postman.com/)
- [Postman Samples](https://github.com/littleearth/lazy-rest/tree/main/resources/server/all/postman)

Web pages can also be served by placing them into the HTML folder. 

A default template modified from [HTML5UP](https://html5up.net/) has been provided. 

Icons are from [Icons8](https://icons8.com/)


## Post ##


- https://localhost:14544/json?validatejson=false
- https://localhost:14544/json?validatejson=true&id=123
- https://localhost:14544/json

Body should contain valid JSON. The server has a global Validate JSON option but you can also toggle on each call. 

    {
     "firstName": "Mary",
     "lastName": "Jane"
    }

The REST endpoint will generate a GUID your data is stored into and respond with the ID or an ID can be forced with the id parameter

    {
		"id": "123"
    }


## Put ##

https://localhost:14544/json/A90F3635-DFC7-4BA9-BB65-08C9BCAFA894
https://localhost:14544/json/123

Body should contain valid JSON eg

    {
     "firstName": "Mary",
     "lastName": "Jane"
    }

A PUT request will update and existing entry or create a new entry with the specified ID. The response will be the ID

    {
		"id": "123"
    }


## Get ##

- https://localhost:14544/json?limit=3&offset=2&search=Mary
- https://localhost:14544/json/04F8E7F8-4BE4-42EE-971B-66E8EF44CE80
- https://localhost:14544/json/123

 
Get supports simple text searching as well as a limit and offset to allow simple pagination
    
    [
     {
      "firstName": "Mary",
      "lastName": "Jane"
     },
     {
      "firstName": "Fred",
      "lastName": "Bloggs"
     }
    ]
    

## Delete ##

- https://localhost:14544/json/A90F3635-DFC7-4BA9-BB65-08C9BCAFA894?softdelete=true
- https://localhost:14544/json/A90F3635-DFC7-4BA9-BB65-08C9BCAFA894
- https://localhost:14544/json
- https://localhost:14544/json?softdelete=true

Delete can delete a specific entry or all entries. The softdelete parameter will just rename the file from .json to .del to allow quick restoration of a record. The response will be the ID or list of ID's deleted.
    
    [
    {
    "ID": "04F8E7F8-4BE4-42EE-971B-66E8EF44CE80"
    },
    {
    "ID": "123"
    },
    {
    "ID": "3F686925-672F-44A9-925C-BA7743DF0D8F"
    },
    {
    "ID": "443A668F-DF83-4B2D-B3D4-B151E59F3E37"
    }
    ]


# Use Cases #

## Prototype ##

Prototype a Web or [Firemonkey mobile application](https://www.embarcadero.com/products/rad-studio/fm-application-platform) and make it actually work with simple REST endpoints but no need for schema or database

## Data Gathering ##

Submitted PC details via powershell to quickly generate a report on makes and model

    $url = "http://localhost:14544/pcdata"
    $url = "$url/$id"
    Write-Host "Status: Submitting PC details to $url"
    try {
    $result = Invoke-WebRequest -Uri $url -ContentType "application/json" -Method PUT -Body $json 
    if ($result.StatusCode -eq 200) {
    Write-Host "Success: Data has been submitted for PC id $id"
    } else {
    Write-Host $result.StatusDescription
    }
    } catch {
      Write-Host "Failed: Failed to submit data, error: $_"
    }


---
title: "Go Api Part 2"
date: 2021-04-06T02:23:55+03:00
draft: true
summary: "REST API with golang part 2"
tags: ["tutorial", "programming", "golang", "api"]
---

## Previous relevant tutorial
The introduction, setup and explanation of basic concepts and operations was covered [in part 1]({{< ref "tutorials/go-api-part-1" >}}) so make sure to read that first.

## Intro
In this part we will be developing a full CRUD REST API in Go except without a real database because I realize that it's too much to go over at once.
The rest of what I promised is true though, we'll use real data that is more than just a basic todo, explore routing options, subrouters and even middleware.

## Starting point
The place we start at is a basic `main.go` file with our structs that represent the models we'll work with as well as a simple `gorilla/mux` setup.
The first part of CRUD that we will implement is the simplest one, Read.
More specifically reading all the entries.
We will also create a slice (essentially a list) of pointers for the instances of `Delivery` that will exist.
The HTTP Method we specify that we accept is `http.MethodGet` since whoever is accessing the API is getting data from us, not sending us anything.
In addition, we set the http status code to `http.StatusOK` in order to communicate that the request went well.

```go
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"log"
	"net/http"
)

type DeliveryDriver struct {
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
}

type Delivery struct {
	OrderNumber      int            `json:"ordernumber"`
	City             string         `json:"city"`
	Zipcode          string         `json:"zipcode"`
	Address          string         `json:"address"`
	Phone1           string         `json:"phone1"`
	Phone2           string         `json:"phone2,omitempty"`
	Cancelled        bool           `json:"cancelled"`
	Delivered        bool           `json:"delivered"`
	DeliveryAttempts int            `json:"deliveryattempts"`
	Driver           DeliveryDriver `json:"deliverydriver"`
}

// type deliveries is slice of Delivery pointers
type deliveryList []*Delivery

// variable deliveryList is of type deliveries
var deliveries deliveryList = []*Delivery{}

// Read all deliveries
func GetAllDeliveries(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(deliveries)
}

func main() {
	// Set up router
	router := mux.NewRouter()
	// Set up subrouter for api version 1
	apiV1 := router.PathPrefix("/api/v1").Subrouter()
	// Set up routes
	apiV1.HandleFunc("/deliveries", GetAllDeliveries).Methods(http.MethodGet)
	// Start http server
	log.Fatal(http.ListenAndServe(":8000", router))
}
```

As you can see it's fairly familiar.
The subrouter is based on the path so anything starting with `/api/v1` is sent to that subrouter and all the `HandleFunc` only needs to specify the path under the path of the subrouter, in this case `/deliveries`.
We can run this using `go run main.go` and visit `localhost:8000/api/v1/deliveries` to see a measly `[]` which is an empty json array.

## Get all
Let's add some data then, 3 example entries should suffice:

```go
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"log"
	"net/http"
)

type DeliveryDriver struct {
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
}

type Delivery struct {
	OrderNumber      int            `json:"ordernumber"`
	City             string         `json:"city"`
	Zipcode          string         `json:"zipcode"`
	Address          string         `json:"address"`
	Phone1           string         `json:"phone1"`
	Phone2           string         `json:"phone2,omitempty"`
	Cancelled        bool           `json:"cancelled"`
	Delivered        bool           `json:"delivered"`
	DeliveryAttempts int            `json:"deliveryattempts"`
	Driver           DeliveryDriver `json:"deliverydriver"`
}

// type deliveries is slice of Delivery pointers
type deliveryList []*Delivery

// variable deliveryList is of type deliveries
var deliveries deliveryList = []*Delivery{
	&Delivery{
		OrderNumber:      1,
		City:             "Here",
		Zipcode:          "52011",
		Address:          "Home",
		Phone1:           "6945123789",
		Phone2:           "2313722903",
		Cancelled: false,
		Delivered:        false,
		DeliveryAttempts: 0,
		Driver: DeliveryDriver{
			FirstName: "Mhtsos",
			LastName:  "Iwannou",
		},
	},
	&Delivery{
		OrderNumber:      2,
		City:             "There",
		Zipcode:          "1701",
		Address:          "Office",
		Phone1:           "6932728091",
		Cancelled: false,
		Delivered:        true,
		DeliveryAttempts: 1,
		Driver: DeliveryDriver{
			FirstName: "Lucas",
			LastName:  "Johnson",
		},
	},
	&Delivery{
		OrderNumber:      3,
		City:             "FarAway",
		Zipcode:          "920639",
		Address:          "Island",
		Phone1:           "6900777123",
		Cancelled: true,
		Delivered:        false,
		DeliveryAttempts: 24,
		Driver: DeliveryDriver{
			FirstName: "Pilotos",
			LastName:  "Aeroplanou",
		},
	},
}

// Read all deliveries
func GetAllDeliveries(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(deliveries)
}

func main() {
	// Set up router
	router := mux.NewRouter()
	// Set up subrouter for api version 1
	apiV1 := router.PathPrefix("/api/v1").Subrouter()
	// Set up routes
	apiV1.HandleFunc("/deliveries", GetAllDeliveries).Methods(http.MethodGet)
	// Start http server
	log.Fatal(http.ListenAndServe(":8000", router))
}
```

Now after running `go run main.go` and going to `localhost:8000/api/v1/deliveries` we can see a whole lot more and if you're using firefox you'll get some pretty sweet formatting too (that's due to setting `Content-Type` to `application/json`, if you delete that line it won't format it).

## Get one
Seeing all the entires is fine and dandy but we might want to see information about only one of them.
In contrast to the previous one where we used `/api/v1/deliveries` which means many (in fact it means all because we didn't specify a range), here we're going to do something different.
We'll use `/api/v1/delivery/ordernumber` (notice that `delivery` is singular) and we'll specify the ordernumber since it is unique as seen from the example entries.
As for the code within the function, we'll check the parameters to make sure that the argument is actually a number we can use to find the delivery and if it's fine we will return the delivery as JSON as well as set the status code to `http.StatusOK`.
However if it's wrong, we'll set the status code to `http.StatusNotFound` and then return an error message.

```go
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"strconv"
)

type DeliveryDriver struct {
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
}

type Delivery struct {
	OrderNumber      int            `json:"ordernumber"`
	City             string         `json:"city"`
	Zipcode          string         `json:"zipcode"`
	Address          string         `json:"address"`
	Phone1           string         `json:"phone1"`
	Phone2           string         `json:"phone2,omitempty"`
	Cancelled        bool           `json:"cancelled"`
	Delivered        bool           `json:"delivered"`
	DeliveryAttempts int            `json:"deliveryattempts"`
	Driver           DeliveryDriver `json:"deliverydriver"`
}

// type deliveries is slice of Delivery pointers
type deliveryList []*Delivery

// variable deliveryList is of type deliveries
var deliveries deliveryList = []*Delivery{
	&Delivery{
		OrderNumber:      1,
		City:             "Here",
		Zipcode:          "52011",
		Address:          "Home",
		Phone1:           "6945123789",
		Phone2:           "2313722903",
		Cancelled: false,
		Delivered:        false,
		DeliveryAttempts: 0,
		Driver: DeliveryDriver{
			FirstName: "Mhtsos",
			LastName:  "Iwannou",
		},
	},
	&Delivery{
		OrderNumber:      2,
		City:             "There",
		Zipcode:          "1701",
		Address:          "Office",
		Phone1:           "6932728091",
		Cancelled: false,
		Delivered:        true,
		DeliveryAttempts: 1,
		Driver: DeliveryDriver{
			FirstName: "Lucas",
			LastName:  "Johnson",
		},
	},
	&Delivery{
		OrderNumber:      3,
		City:             "FarAway",
		Zipcode:          "920639",
		Address:          "Island",
		Phone1:           "6900777123",
		Cancelled: true,
		Delivered:        false,
		DeliveryAttempts: 24,
		Driver: DeliveryDriver{
			FirstName: "Pilotos",
			LastName:  "Aeroplanou",
		},
	},
}

// Constant for Bad Request
const BadReq string = `{"error": "bad request"}`
// Constant for Not Found
const NotFound string = `{"error": "not found"}`

// Read all deliveries
func GetAllDeliveries(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(deliveries)
}

// Read a specific delivery
func GetDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	params := mux.Vars(r)
	orderNum, err := strconv.Atoi(params["ordernumber"])
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	for _, d := range deliveries {
		if d.OrderNumber == orderNum {
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(d)
			return
		}
	}
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte(NotFound))
	return
}

func main() {
	// Set up router
	router := mux.NewRouter()
	// Set up subrouter for api version 1
	apiV1 := router.PathPrefix("/api/v1").Subrouter()
	// Set up routes
	apiV1.HandleFunc("/deliveries", GetAllDeliveries).Methods(http.MethodGet)
	apiV1.HandleFunc("/delivery/{ordernumber}", GetDelivery).Methods(http.MethodGet)
	// Start http server
	log.Fatal(http.ListenAndServe(":8000", router))
}
```

I went ahead and made the errors `const` variables in the global scope so we can use them anywhere we want without having to repeat ourselves, this is not necessary but it makes life a bit easier.
Let's look at a couple things that seem a bit odd.
First what's that `mux.Vars(r)`?
That's from `gorilla/mux` and one of the reasons we are using it.
It takes a request as an argument and can tell us a lot of stuff about that request.
The variable `params` is a type `map[string]string` which means that the key is a string and the value is a string.
If you've used dictionaries in Python I think it's pretty similar.
We give it the `ordernumber` key which is what we specified in `apiV1.HandleFunc("/delivery/{ordernumber}", GetDelivery).Methods(http.MethodGet)` and then use the `strconv` library to convert it from string to an integer.
Second, the `for` loop looks a bit weird, what's up with that `range deliveries`?
Using `range` we can iterate over something, in this case a slice (essentially a list).
This returns two variables, in this case one that is the key/index which we are ignoring by using `_` and the other one is the value `d` which is a single delivery from the list of deliveries we set up.
With all that out of the way, time to test it.
Run the server with `go run main.go` and visit `localhost:8000/api/v1/deliveries/2` to see the information about the second delivery returned.
Pretty good, right?

## Add one
After we're done with the Read part of CRUD, let's move on to Create.
Here we will add a delivery after it is sent to us as JSON.
I will use [cURL](https://curl.se/) for this purpose but you can use [hoppscotch](https://hoppscotch.io/) if you want.
Let's look at the code first though.
In our `addDelivery` function we will create an empty delivery item, `d`, that will later on receive the JSON data.
Then we'll see what the next order number should be according to the length of our list and use that instead of whatever the user has provided, it is up to us to decide where to fit the delivery.
After than, we unpack the contents of the request body into `d` and check for errors, if there are any, we will handle it like previously since the sender made a mistake.
If the `ordernumber` in their JSON is empty, we don't mind since we'll override it before saving it anyway.
Following that, we will use `append` to add the delivery to the list and then set the HTTP status code to `http.StatusCreated`.
Finally we will return the item that we actually inserted into our list of deliveries so the sender knows what was actually saved.

```go
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"strconv"
)

type DeliveryDriver struct {
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
}

type Delivery struct {
	OrderNumber      int            `json:"ordernumber"`
	City             string         `json:"city"`
	Zipcode          string         `json:"zipcode"`
	Address          string         `json:"address"`
	Phone1           string         `json:"phone1"`
	Phone2           string         `json:"phone2,omitempty"`
	Cancelled        bool           `json:"cancelled"`
	Delivered        bool           `json:"delivered"`
	DeliveryAttempts int            `json:"deliveryattempts"`
	Driver           DeliveryDriver `json:"deliverydriver"`
}

// type deliveries is slice of Delivery pointers
type deliveryList []*Delivery

// variable deliveryList is of type deliveries
var deliveries deliveryList = []*Delivery{
	&Delivery{
		OrderNumber:      1,
		City:             "Here",
		Zipcode:          "52011",
		Address:          "Home",
		Phone1:           "6945123789",
		Phone2:           "2313722903",
		Cancelled: false,
		Delivered:        false,
		DeliveryAttempts: 0,
		Driver: DeliveryDriver{
			FirstName: "Mhtsos",
			LastName:  "Iwannou",
		},
	},
	&Delivery{
		OrderNumber:      2,
		City:             "There",
		Zipcode:          "1701",
		Address:          "Office",
		Phone1:           "6932728091",
		Cancelled: false,
		Delivered:        true,
		DeliveryAttempts: 1,
		Driver: DeliveryDriver{
			FirstName: "Lucas",
			LastName:  "Johnson",
		},
	},
	&Delivery{
		OrderNumber:      3,
		City:             "FarAway",
		Zipcode:          "920639",
		Address:          "Island",
		Phone1:           "6900777123",
		Cancelled: true,
		Delivered:        false,
		DeliveryAttempts: 24,
		Driver: DeliveryDriver{
			FirstName: "Pilotos",
			LastName:  "Aeroplanou",
		},
	},
}

// Constant for Bad Request
const BadReq string = `{"error": "bad request"}`
// Constant for Not Found
const NotFound string = `{"error": "not found"}`

// Read all deliveries
func GetAllDeliveries(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(deliveries)
}

// Read a specific delivery
func GetDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	params := mux.Vars(r)
	orderNum, err := strconv.Atoi(params["ordernumber"])
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	for _, d := range deliveries {
		if d.OrderNumber == orderNum {
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(d)
			return
		}
	}
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte(NotFound))
	return
}

// Create a new delivery
func AddDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	d := &Delivery{}
	// because deliveries start from 1
	orderNum := int(len(deliveries)) + 1
	err := json.NewDecoder(r.Body).Decode(d)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	// Override whatever the sender had sent
	d.OrderNumber = orderNum
	// Append the delivery to deliveries list
	deliveries = append(deliveries, d)
	w.WriteHeader(http.StatusCreated)
	// Send back the delivery that was saved
	json.NewEncoder(w).Encode(d)
	return
}

func main() {
	// Set up router
	router := mux.NewRouter()
	// Set up subrouter for api version 1
	apiV1 := router.PathPrefix("/api/v1").Subrouter()
	// Set up routes
	apiV1.HandleFunc("/deliveries", GetAllDeliveries).Methods(http.MethodGet)
	apiV1.HandleFunc("/delivery/{ordernumber}", GetDelivery).Methods(http.MethodGet)
	apiV1.HandleFunc("/delivery", AddDelivery).Methods(http.MethodPost)
	// Start http server
	log.Fatal(http.ListenAndServe(":8000", router))
}
```

We've also added another route that is used when the HTTP method is `POST` which calls the `AddDelivery` function we just created.
In order to test it out, I made this [`delivery.json` file](https://gitlab.com/insanitywholesale/ongoing/-/blob/master/delivery.json) that you can also use.
This is what it contains:
```json
{
  "city": "ExperimentValley",
  "zipcode": "0000",
  "address": "REDACTED",
  "phone1": "6900999111",
  "cancelled": false,
  "delivered": false,
  "deliveryattempts": 3,
  "deliverydriver": {
    "firstname": "Mike",
    "lastname": "REDACTED"
  }
}
```
I saved it in my home directory with the name `delivery.json` and from the same place, after starting the server with `go run main.go` I ran:
```bash
curl -H "Content-Type: application/json" -X POST --data-binary '@delivery.json' http://localhost:8000/api/v1/delivery
```
to send it over to the server which then returned
```json
{"ordernumber":4,"city":"ExperimentValley","zipcode":"0000","address":"REDACTED","phone1":"6900999111","cancelled":false,"delivered":false,"deliveryattempts":3,"deliverydriver":{"firstname":"Mike","lastname":"REDACTED"}}
```
which as we can see has `ordernumber` set to `4` even though I didn't explicitly set it.
Feel free to try setting `ordernumber` to `27` or something inside `delivery.json` and see what you get.

## Upd8 1
Next up we're going to update an entry.
The appropriate HTTP method for this is `PUT` and the status code is `http.StatusAccepted` or `http.StatusOK` and I prefer the first one so that's what I'll use.
The `UpdateDelivery` function we're going to make has elements we saw previously in `GetDelivery` as well as `AddDelivery`.
Not much of this is new so let's see how we get things done.

```go
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"strconv"
)

type DeliveryDriver struct {
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
}

type Delivery struct {
	OrderNumber      int            `json:"ordernumber"`
	City             string         `json:"city"`
	Zipcode          string         `json:"zipcode"`
	Address          string         `json:"address"`
	Phone1           string         `json:"phone1"`
	Phone2           string         `json:"phone2,omitempty"`
	Cancelled        bool           `json:"cancelled"`
	Delivered        bool           `json:"delivered"`
	DeliveryAttempts int            `json:"deliveryattempts"`
	Driver           DeliveryDriver `json:"deliverydriver"`
}

// type deliveries is slice of Delivery pointers
type deliveryList []*Delivery

// variable deliveryList is of type deliveries
var deliveries deliveryList = []*Delivery{
	&Delivery{
		OrderNumber:      1,
		City:             "Here",
		Zipcode:          "52011",
		Address:          "Home",
		Phone1:           "6945123789",
		Phone2:           "2313722903",
		Cancelled: false,
		Delivered:        false,
		DeliveryAttempts: 0,
		Driver: DeliveryDriver{
			FirstName: "Mhtsos",
			LastName:  "Iwannou",
		},
	},
	&Delivery{
		OrderNumber:      2,
		City:             "There",
		Zipcode:          "1701",
		Address:          "Office",
		Phone1:           "6932728091",
		Cancelled: false,
		Delivered:        true,
		DeliveryAttempts: 1,
		Driver: DeliveryDriver{
			FirstName: "Lucas",
			LastName:  "Johnson",
		},
	},
	&Delivery{
		OrderNumber:      3,
		City:             "FarAway",
		Zipcode:          "920639",
		Address:          "Island",
		Phone1:           "6900777123",
		Cancelled: true,
		Delivered:        false,
		DeliveryAttempts: 24,
		Driver: DeliveryDriver{
			FirstName: "Pilotos",
			LastName:  "Aeroplanou",
		},
	},
}

// Constant for Bad Request
const BadReq string = `{"error": "bad request"}`
// Constant for Not Found
const NotFound string = `{"error": "not found"}`

// Read all deliveries
func GetAllDeliveries(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(deliveries)
}

// Read a specific delivery
func GetDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	params := mux.Vars(r)
	orderNum, err := strconv.Atoi(params["ordernumber"])
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	for _, d := range deliveries {
		if d.OrderNumber == orderNum {
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(d)
			return
		}
	}
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte(NotFound))
	return
}

// Create a new delivery
func AddDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	d := &Delivery{}
	// because deliveries start from 1
	orderNum := int(len(deliveries)) + 1
	err := json.NewDecoder(r.Body).Decode(d)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	// Override whatever the sender had sent
	d.OrderNumber = orderNum
	// Append the delivery to deliveries list
	deliveries = append(deliveries, d)
	w.WriteHeader(http.StatusCreated)
	// Send back the delivery that was saved
	json.NewEncoder(w).Encode(d)
	return
}

// Update an existing delivery
func UpdateDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	params := mux.Vars(r)
	orderNum, err := strconv.Atoi(params["ordernumber"])
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	for _, d := range deliveries {
		if d.OrderNumber == orderNum {
			err := json.NewDecoder(r.Body).Decode(d)
			if err != nil {
				w.WriteHeader(http.StatusBadRequest)
				w.Write([]byte(BadReq))
				return
			}
			d.OrderNumber = orderNum
			w.WriteHeader(http.StatusAccepted)
			json.NewEncoder(w).Encode(d)
			return
		}
	}
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte(NotFound))
	return
}

func main() {
	// Set up router
	router := mux.NewRouter()
	// Set up subrouter for api version 1
	apiV1 := router.PathPrefix("/api/v1").Subrouter()
	// Set up routes
	apiV1.HandleFunc("/deliveries", GetAllDeliveries).Methods(http.MethodGet)
	apiV1.HandleFunc("/delivery/{ordernumber}", GetDelivery).Methods(http.MethodGet)
	apiV1.HandleFunc("/delivery", AddDelivery).Methods(http.MethodPost)
	apiV1.HandleFunc("/delivery/{ordernumber}", UpdateDelivery).Methods(http.MethodPut)
	// Start http server
	log.Fatal(http.ListenAndServe(":8000", router))
}
```

As we can see, nothing special, same stuff we've done before.
Check order number, return error bad request if it's bad.
Go through the deliveries to find the one, if it doesn't exist return not found.
If it's found, try to unpack the sender's json to the existing delivery and if that fails return bad request otherwise save changes and return the delivery that was saved in our list.
Note that we also override the value that the sender gave to keep our deliveries the way we want them and not have duplicates of what is supposed to be a unique identifier.
Also we added the route on the bottom to make it usable.
Similar to what we did to test it earlier, start the server with `go run main.go` and then run the following to change the data of delivery number 2:

```bash
curl -H "Content-Type: application/json" -X PUT --data-binary '@delivery.json' http://localhost:8000/api/v1/delivery/2
```

which returns:

```json
{"ordernumber":2,"city":"ExperimentValley","zipcode":"0000","address":"REDACTED","phone1":"6900999111","cancelled":false,"delivered":false,"deliveryattempts":3,"deliverydriver":{"firstname":"Mike","lastname":"REDACTED"}}
```

and we can tell from `ordernumber` that it saved it there.
To make sure, we can also run

```bash
curl http://localhost:8000/api/v1/deliveries
```

to get a list of all deliveries.

## Delete one
I know that Delete is left and we will implement it but we're not actually going to delete anything.
This is an important point to make, we have to consider what the application is doing.
If we want to have a history of deliveries, we don't want any of them to be lost.
What we're going to do instead is set the `Cancelled` to true.
Let's think about why for a bit.
If the order is successfully delivered, we use the `UpdateDelivery` method to set it and it's all good.
So it's the job of `DeleteDelivery` to handle completed deliveries but rather deliveries that need to be invalidated in some other way.
The only other way I can think of is if they're cancelled so that's what we'll do.
We do the normal check for the path parameter, if we find a delivery with that number we set it to cancelled and if not we return error not found.
Here is the code:

```go
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"strconv"
)

type DeliveryDriver struct {
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
}

type Delivery struct {
	OrderNumber      int            `json:"ordernumber"`
	City             string         `json:"city"`
	Zipcode          string         `json:"zipcode"`
	Address          string         `json:"address"`
	Phone1           string         `json:"phone1"`
	Phone2           string         `json:"phone2,omitempty"`
	Cancelled        bool           `json:"cancelled"`
	Delivered        bool           `json:"delivered"`
	DeliveryAttempts int            `json:"deliveryattempts"`
	Driver           DeliveryDriver `json:"deliverydriver"`
}

// type deliveries is slice of Delivery pointers
type deliveryList []*Delivery

// variable deliveryList is of type deliveries
var deliveries deliveryList = []*Delivery{
	&Delivery{
		OrderNumber:      1,
		City:             "Here",
		Zipcode:          "52011",
		Address:          "Home",
		Phone1:           "6945123789",
		Phone2:           "2313722903",
		Cancelled: false,
		Delivered:        false,
		DeliveryAttempts: 0,
		Driver: DeliveryDriver{
			FirstName: "Mhtsos",
			LastName:  "Iwannou",
		},
	},
	&Delivery{
		OrderNumber:      2,
		City:             "There",
		Zipcode:          "1701",
		Address:          "Office",
		Phone1:           "6932728091",
		Cancelled: false,
		Delivered:        true,
		DeliveryAttempts: 1,
		Driver: DeliveryDriver{
			FirstName: "Lucas",
			LastName:  "Johnson",
		},
	},
	&Delivery{
		OrderNumber:      3,
		City:             "FarAway",
		Zipcode:          "920639",
		Address:          "Island",
		Phone1:           "6900777123",
		Cancelled: true,
		Delivered:        false,
		DeliveryAttempts: 24,
		Driver: DeliveryDriver{
			FirstName: "Pilotos",
			LastName:  "Aeroplanou",
		},
	},
}

// Constant for Bad Request
const BadReq string = `{"error": "bad request"}`
// Constant for Not Found
const NotFound string = `{"error": "not found"}`

// Read all deliveries
func GetAllDeliveries(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(deliveries)
}

// Read a specific delivery
func GetDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	params := mux.Vars(r)
	orderNum, err := strconv.Atoi(params["ordernumber"])
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	for _, d := range deliveries {
		if d.OrderNumber == orderNum {
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(d)
			return
		}
	}
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte(NotFound))
	return
}

// Create a new delivery
func AddDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	d := &Delivery{}
	// because deliveries start from 1
	orderNum := int(len(deliveries)) + 1
	err := json.NewDecoder(r.Body).Decode(d)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	// Override whatever the sender had sent
	d.OrderNumber = orderNum
	// Append the delivery to deliveries list
	deliveries = append(deliveries, d)
	w.WriteHeader(http.StatusCreated)
	// Send back the delivery that was saved
	json.NewEncoder(w).Encode(d)
	return
}

// Update an existing delivery
func UpdateDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	params := mux.Vars(r)
	orderNum, err := strconv.Atoi(params["ordernumber"])
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	for _, d := range deliveries {
		if d.OrderNumber == orderNum {
			err := json.NewDecoder(r.Body).Decode(d)
			if err != nil {
				w.WriteHeader(http.StatusBadRequest)
				w.Write([]byte(BadReq))
				return
			}
			d.OrderNumber = orderNum
			w.WriteHeader(http.StatusAccepted)
			json.NewEncoder(w).Encode(d)
			return
		}
	}
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte(NotFound))
	return
}

// Delete a delivery (not really)
func DeleteDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	params := mux.Vars(r)
	orderNum, err := strconv.Atoi(params["ordernumber"])
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	for _, d := range deliveries {
		if d.OrderNumber == orderNum {
			w.WriteHeader(http.StatusOK)
			d.Cancelled = true
			json.NewEncoder(w).Encode(d)
			return
		}
	}
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte(NotFound))
	return
}

func main() {
	// Set up router
	router := mux.NewRouter()
	// Set up subrouter for api version 1
	apiV1 := router.PathPrefix("/api/v1").Subrouter()
	// Set up routes
	apiV1.HandleFunc("/deliveries", GetAllDeliveries).Methods(http.MethodGet)
	apiV1.HandleFunc("/delivery/{ordernumber}", GetDelivery).Methods(http.MethodGet)
	apiV1.HandleFunc("/delivery", AddDelivery).Methods(http.MethodPost)
	apiV1.HandleFunc("/delivery/{ordernumber}", UpdateDelivery).Methods(http.MethodPut)
	apiV1.HandleFunc("/delivery/{ordernumber}", DeleteDelivery).Methods(http.MethodDelete)
	// Start http server
	log.Fatal(http.ListenAndServe(":8000", router))
}
```

First we start the server with `go run main.go` and then to test our newly added functionality, in my case with cURL, we can run:

```bash
curl -X DELETE http://localhost:8000/api/v1/delivery/3
```

and get back:

```json
{"ordernumber":1,"city":"Here","zipcode":"52011","address":"Home","phone1":"6945123789","phone2":"2313722903","cancelled":true,"delivered":false,"deliveryattempts":0,"deliverydriver":{"firstname":"Mhtsos","lastname":"Iwannou"}}
```

## Conclusion
That's it for this part then. You now have a fully functional REST API written in Go that you can play around with.
There are a few more things that you can do with `gorilla/mux` and the code can be made a little bit nicer so if you're interested in that, check out my [completed version](https://gitlab.com/insanitywholesale/ongoing/-/blob/master/gorestapi.go).
Thank you for reading and I hope you enjoyed.
